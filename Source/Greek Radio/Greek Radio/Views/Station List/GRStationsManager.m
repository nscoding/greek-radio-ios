//
//  GRStationsManager.m
//  Greek Radio
//
//  Created by Patrick Chamelo on 29/12/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


#import "GRStationsManager.h"
#import "GRRadioPlayer.h"
#import "GRCoreDataStack.h"
#import "GRStationCellView.h"

#import "UITableView+Extensions.h"


// ------------------------------------------------------------------------------------------



@interface GRStationsManager () <UITableViewDataSource, UITableViewDelegate,
                                   NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *stationsFetchedResultsController;
@property (nonatomic, strong) NSFetchRequest *stationsFetchRequest;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end


// ------------------------------------------------------------------------------------------


@implementation GRStationsManager


// ------------------------------------------------------------------------------------------
#pragma mark - Initialization
// ------------------------------------------------------------------------------------------
- (id)initWithTableView:(UITableView *)tableView stationsLayout:(GRStationsLayout)layout
{
    if (self = [super init])
    {
        self.tableView = tableView;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        self.stationsLayout = layout;
        [self setupFetchedResultsControllers];
    }
    
    return self;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Setup
// ------------------------------------------------------------------------------------------
- (void)setupFetchedResultsControllers
{
    self.stationsFetchRequest = nil;
    self.stationsFetchedResultsController.delegate = nil;
    self.stationsFetchedResultsController = nil;

    NSManagedObjectContext *moc = [GRCoreDataStack shared].managedObjectContext;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"server == YES"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"GRStation"
                                              inManagedObjectContext:moc];
	
    self.stationsFetchRequest = [[NSFetchRequest alloc] init];
    self.stationsFetchRequest.entity = entity;
    self.stationsFetchRequest.predicate = predicate;
    
    NSString *sectionKeyPath = @"";
    switch (self.stationsLayout)
    {
        case GRStationsLayoutGenre:
        {
            self.stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"genre"
                                                                                      ascending:YES
                                                                                       selector:@selector(localizedCaseInsensitiveCompare:)],
                                                          [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                      ascending:YES
                                                                                       selector:@selector(localizedCaseInsensitiveCompare:)]];
            sectionKeyPath = @"genre";
            break;
        }
        case GRStationsLayoutCity:
        {
            self.stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"location"
                                                                                      ascending:YES
                                                                                       selector:@selector(localizedCaseInsensitiveCompare:)],
                                                          [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                      ascending:YES
                                                                                       selector:@selector(localizedCaseInsensitiveCompare:)]];

            sectionKeyPath = @"location";
            break;
        }
        case GRStationsLayoutAlphabetical:
        {
            self.stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"favourite"
                                                                                      ascending:NO],
                                                          [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                      ascending:YES
                                                                                       selector:@selector(localizedCaseInsensitiveCompare:)]];

            sectionKeyPath = @"favourite";
            break;
        }
    }
    
    self.stationsFetchedResultsController
        = [[NSFetchedResultsController alloc] initWithFetchRequest:self.stationsFetchRequest
                                              managedObjectContext:moc
                                                sectionNameKeyPath:sectionKeyPath
                                                         cacheName:nil];
    
    NSError *error;    
    self.stationsFetchedResultsController.delegate = self;
    if ([self.stationsFetchedResultsController performFetch:&error] == NO)
    {
        DLog(@"Fetching non-sticky events failed: %@ %@", [error description], [error userInfo]);
    }
}


- (void)setupFetchedResultsControllersWithString:(NSString *)filter
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"server == YES"];
    if (filter.length > 0)
    {
        switch (self.stationsLayout)
        {
            case GRStationsLayoutGenre:
            {
                predicate = [NSPredicate predicateWithFormat:
                             @"server == YES AND (title CONTAINS[cd] %@ OR genre CONTAINS[cd] %@)", filter, filter];
                break;
            }
            case GRStationsLayoutCity:
            {
                predicate = [NSPredicate predicateWithFormat:
                             @"server == YES AND (title CONTAINS[cd] %@ OR location CONTAINS[cd] %@)", filter, filter];
                break;
            }
            case GRStationsLayoutAlphabetical:
            {
                predicate = [NSPredicate predicateWithFormat:@"server == YES AND title CONTAINS[cd] %@", filter];
                break;
            }
        }
    }

    self.stationsFetchRequest.predicate = predicate;
    NSError *error;
    if ([self.stationsFetchedResultsController performFetch:&error] == NO)
    {
        DLog(@"Fetching non-sticky events failed: %@ %@", [error description], [error userInfo]);
    }
    
    [self.tableView reloadData];
}


- (void)setStationsLayout:(GRStationsLayout)stationsLayout
{
    if (_stationsLayout != stationsLayout)
    {
        _stationsLayout = stationsLayout;
        [self setupFetchedResultsControllers];
        [self.tableView reloadData];
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Table delegate and Data source
// ------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.stationsFetchedResultsController.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = self.stationsFetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [GRStationCellView reusableIdentifier];
    GRStationCellView *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {
        cell = [[GRStationCellView alloc] init];
    }
    
    GRStation *station = [self stationForIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",station.title];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", station.location, station.genre];
    cell.station = station;
    
    id<NSFetchedResultsSectionInfo> sectionInfo = self.stationsFetchedResultsController.sections[indexPath.section];
    cell.showDivider = (indexPath.row != (sectionInfo.numberOfObjects - 1));
    
    if ([[GRRadioPlayer shared].currentStation isEqual:station])
    {
        cell.imageView.image = [UIImage imageNamed:@"GRNote"];
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"GRMicrophone"];
    }
    
    [cell setNeedsDisplay];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0f;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 20.0f;
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.stationsFetchedResultsController.sectionIndexTitles indexOfObject:title];
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.frame.size.width, 20.0f)];
    sectionHeader.autoresizingMask = UIViewAutoresizingNone;
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.180f green:0.180f blue:0.161f alpha:1.00f];
    sectionHeader.textAlignment = NSTextAlignmentCenter;
    sectionHeader.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    sectionHeader.textColor = [UIColor whiteColor];
    
    id<NSFetchedResultsSectionInfo> sectionInfo = self.stationsFetchedResultsController.sections[section];
    if (self.stationsLayout == GRStationsLayoutAlphabetical)
    {
        if (section == 0 && tableView.numberOfSections == 2)
        {
            sectionHeader.text = [NSString stringWithFormat:@"%@ (%lu)",
                                  NSLocalizedString(@"label_favorites", @""), (unsigned long)sectionInfo.numberOfObjects];
        }
        else
        {
            sectionHeader.text = [NSString stringWithFormat:@"%@ (%lu)",
                                  NSLocalizedString(@"label_stations", @""), (unsigned long)sectionInfo.numberOfObjects];
        }
    }
    else
    {
        sectionHeader.text = [NSString stringWithFormat:@"%@ (%lu)",
                              sectionInfo.name, (unsigned long)sectionInfo.numberOfObjects];
    }
    
    return sectionHeader;
}


// ------------------------------------------------------------------------------------------
#pragma mark - NSFetchedResultsControllerDelegate Methods
// ------------------------------------------------------------------------------------------
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)changeType
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (changeType)
    {
        case NSFetchedResultsChangeInsert:
        {
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeMove:
        {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}


- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
        {
            NSAssert(NO, @"We should not encounter a Move or Update section.");
            break;
        }
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self playStationAtIndexPath:indexPath];
}


- (void)playStationAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *oldIndexPath = [self.selectedIndexPath copy];
    self.selectedIndexPath = indexPath;

    GRStation *station = [self stationForIndexPath:indexPath];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(stationManager:shouldPlayStation:)])
    {
        [self.delegate stationManager:self shouldPlayStation:station];

        if (indexPath && indexPath.row != NSNotFound)
        {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];

        }
    
        if (oldIndexPath && oldIndexPath.row != NSNotFound)
        {
            [self.tableView reloadRowsAtIndexPaths:@[oldIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}


- (void)playNextStation
{
    NSIndexPath *oldIndexPath = [self.selectedIndexPath copy];
    NSIndexPath *newIndexPath = [self.tableView nextIndexPathForPath:oldIndexPath];
    
    if (newIndexPath == nil)
    {
        newIndexPath = [self.tableView firstIndexPath];
    }
    
    [self playStationAtIndexPath:newIndexPath];
    [self.tableView scrollToRowAtIndexPath:newIndexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:YES];
}


- (void)playPreviousStation
{
    NSIndexPath *oldIndexPath = [self.selectedIndexPath copy];
    NSIndexPath *newIndexPath = [self.tableView previousIndexPathForPath:oldIndexPath];
    
    if (newIndexPath == nil)
    {
        newIndexPath = [self.tableView lastIndexPath];
    }
    
    [self playStationAtIndexPath:newIndexPath];
    [self.tableView scrollToRowAtIndexPath:newIndexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:YES];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (GRStation *)stationForIndexPath:(NSIndexPath *)indexPath
{
    return [self.stationsFetchedResultsController objectAtIndexPath:indexPath];
}


- (NSUInteger)numberOfStations
{
    return self.stationsFetchedResultsController.fetchedObjects.count;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Dealloc
// ------------------------------------------------------------------------------------------
- (void)dealloc
{
    self.delegate = nil;
    self.tableView = nil;
    self.stationsFetchedResultsController.delegate = nil;
    self.stationsFetchedResultsController = nil;
}


@end
