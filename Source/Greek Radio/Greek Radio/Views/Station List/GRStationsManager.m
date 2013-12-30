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


static const NSUInteger kFavoriteStickySection = 0;
static const NSUInteger kNonStickySection = 1;
static const NSUInteger kLazyLoadSection = 2;


// ------------------------------------------------------------------------------------------



@interface GRStationsManager () <UITableViewDataSource, UITableViewDelegate,
                                   NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, assign) NSUInteger updatesDelta;

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
                                                                                       selector:@selector(caseInsensitiveCompare:)],
                                                          [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                      ascending:YES
                                                                                       selector:@selector(caseInsensitiveCompare:)]];
            sectionKeyPath = @"genre";
            break;
        }
        case GRStationsLayoutCity:
        {
            self.stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"location"
                                                                                      ascending:YES
                                                                                       selector:@selector(caseInsensitiveCompare:)],
                                                          [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                      ascending:YES
                                                                                       selector:@selector(caseInsensitiveCompare:)]];

            sectionKeyPath = @"location";
            break;
        }
        case GRStationsLayoutAlphabetical:
        {
            self.stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"favourite"
                                                                                      ascending:NO],
                                                          [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                      ascending:YES
                                                                                       selector:@selector(caseInsensitiveCompare:)]];

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
        NSLog(@"Fetching non-sticky events failed: %@ %@", [error description], [error userInfo]);
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
        NSLog(@"Fetching non-sticky events failed: %@ %@", [error description], [error userInfo]);
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
        cell = [[GRStationCellView alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:identifier];
    }
    
    GRStation *station = [self stationForIndexPath:indexPath];
    cell.title.text = [NSString stringWithFormat:@"%@",station.title];
    cell.subtitle.text = [NSString stringWithFormat:@"%@, %@", station.location, station.genre];
    cell.station = station;

    if ([[GRRadioPlayer shared].currentStation isEqual:station])
    {
        cell.iconImageView.image = [UIImage imageNamed:@"GRNote"];
    }
    else
    {
        cell.iconImageView.image = [UIImage imageNamed:@"GRMicrophone"];
    }
    
    [cell setNeedsDisplay];
    
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.stationsFetchedResultsController.sectionIndexTitles indexOfObject:title];
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
    sectionHeader.autoresizingMask = UIViewAutoresizingNone;
    sectionHeader.backgroundColor = self.tableView.backgroundColor;
    sectionHeader.textAlignment = NSTextAlignmentCenter;
    sectionHeader.font = [UIFont boldSystemFontOfSize:13];
    sectionHeader.textColor = [UIColor whiteColor];
    
    id<NSFetchedResultsSectionInfo> sectionInfo = self.stationsFetchedResultsController.sections[section];
    if (self.stationsLayout == GRStationsLayoutAlphabetical)
    {
        if (section == 0)
        {
            sectionHeader.text = [NSString stringWithFormat:@"%@ (%i)",
                                  NSLocalizedString(@"label_favorites", @""), sectionInfo.numberOfObjects];
        }
        else if (section == 1)
        {
            sectionHeader.text = [NSString stringWithFormat:@"%@ (%i)",
                                  NSLocalizedString(@"label_stations", @""), sectionInfo.numberOfObjects];
        }
    }
    else
    {
        sectionHeader.text = [NSString stringWithFormat:@"%@ (%i)",
                              sectionInfo.name, sectionInfo.numberOfObjects];
    }
    
    return sectionHeader;
}


// ------------------------------------------------------------------------------------------
#pragma mark - NSFetchedResultsControllerDelegate Methods
// ------------------------------------------------------------------------------------------
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    self.updatesDelta += 1;
    [self.tableView beginUpdates];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    self.updatesDelta -= 1;
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
            [self.tableView moveRowAtIndexPath:indexPath
                                   toIndexPath:newIndexPath];
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
    [self playStationAtIndexPath:newIndexPath];
    
    [self.tableView scrollToRowAtIndexPath:newIndexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:YES];
}


- (void)playPreviousStation
{
    NSIndexPath *oldIndexPath = [self.selectedIndexPath copy];
    NSIndexPath *newIndexPath = [self.tableView previousIndexPathForPath:oldIndexPath];
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
