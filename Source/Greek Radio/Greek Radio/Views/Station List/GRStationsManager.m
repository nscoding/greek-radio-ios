//
//  GRStationsManager.m
//  Greek Radio
//
//  Created by Patrick Chamelo on 29/12/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


#import "GRStationsManager.h"

#import "GRCoreDataStack.h"
#import "GRStationCellView.h"


// ------------------------------------------------------------------------------------------


static const NSUInteger kFavoriteStickySection = 0;
static const NSUInteger kNonStickySection = 1;
static const NSUInteger kLazyLoadSection = 2;


// ------------------------------------------------------------------------------------------



@interface GRStationsManager () <UITableViewDataSource, UITableViewDelegate,
                                   NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *stationsFetchedResultsController;
@property (nonatomic, strong) NSFetchRequest *stationsFetchRequest;

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
    NSManagedObjectContext *moc = [GRCoreDataStack shared].managedObjectContext;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"server == YES"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"GRStation"
                                              inManagedObjectContext:moc];
	
    self.stationsFetchRequest = [[NSFetchRequest alloc] init];
    self.stationsFetchRequest.entity = entity;
    self.stationsFetchRequest.predicate = predicate;
    self.stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"favourite"
                                                                              ascending:NO],
                                                  [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                              ascending:YES
                                                                               selector:@selector(caseInsensitiveCompare:)],
                                                  [[NSSortDescriptor alloc] initWithKey:@"location"
                                                                              ascending:YES
                                                                               selector:@selector(caseInsensitiveCompare:)],
                                                  [[NSSortDescriptor alloc] initWithKey:@"genre"
                                                                              ascending:YES
                                                                               selector:@selector(caseInsensitiveCompare:)]];
    

    self.stationsFetchedResultsController.delegate = nil;
    self.stationsFetchedResultsController = nil;
    
    switch (self.stationsLayout)
    {
        case GRStationsLayoutGenre:
        {
            self.stationsFetchedResultsController
            = [[NSFetchedResultsController alloc] initWithFetchRequest:self.stationsFetchRequest
                                                  managedObjectContext:moc
                                                    sectionNameKeyPath:@"genre"
                                                             cacheName:nil];
            break;
        }
        case GRStationsLayoutCity:
        {
            self.stationsFetchedResultsController
            = [[NSFetchedResultsController alloc] initWithFetchRequest:self.stationsFetchRequest
                                                  managedObjectContext:moc
                                                    sectionNameKeyPath:@"location"
                                                             cacheName:nil];
            break;
        }
        case GRStationsLayoutAlphabetical:
        {
            self.stationsFetchedResultsController
            = [[NSFetchedResultsController alloc] initWithFetchRequest:self.stationsFetchRequest
                                                  managedObjectContext:moc
                                                    sectionNameKeyPath:@"favourite"
                                                             cacheName:nil];
            break;
        }
    }
    
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
        predicate = [NSPredicate predicateWithFormat:@"server == YES AND title CONTAINS[cd] %@", filter];
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
    
    if ([UIDevice isFlatUI])
    {
        sectionHeader.backgroundColor = self.tableView.backgroundColor;
    }
    else
    {
        sectionHeader.backgroundColor = [UIColor colorWithRed:0.604f
                                                        green:0.651f
                                                         blue:0.690f
                                                        alpha:1.00f];
    }
    
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
    GRStation *station = [self stationForIndexPath:indexPath];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(stationManager:shouldPlayStation:)])
    {
        [self.delegate stationManager:self shouldPlayStation:station];
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (GRStation *)stationForIndexPath:(NSIndexPath *)indexPath
{
    return [self.stationsFetchedResultsController objectAtIndexPath:indexPath];
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
