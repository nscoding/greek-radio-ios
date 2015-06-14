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

@interface GRStationsManager () <UITableViewDataSource, UITableViewDelegate,
                                   NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation GRStationsManager
{
    NSFetchedResultsController *_stationsFetchedResultsController;
    NSFetchRequest *_stationsFetchRequest;
    UITableView *_tableView;
}
#pragma mark - Initialization

- (instancetype)initWithTableView:(UITableView *)tableView stationsLayout:(GRStationsLayout)layout
{
    if (self = [super init]) {
        _tableView = tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        self.stationsLayout = layout;
        [self setupFetchedResultsControllers];
    }
    
    return self;
}

#pragma mark - Setup

- (void)setupFetchedResultsControllers
{
    _stationsFetchRequest = nil;
    _stationsFetchedResultsController.delegate = nil;
    _stationsFetchedResultsController = nil;

    NSManagedObjectContext *moc = [GRCoreDataStack shared].managedObjectContext;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"server == YES"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"GRStation"
                                              inManagedObjectContext:moc];
    _stationsFetchRequest = [[NSFetchRequest alloc] init];
    _stationsFetchRequest.entity = entity;
    _stationsFetchRequest.predicate = predicate;
    
    NSString *sectionKeyPath = @"";
    switch (self.stationsLayout) {
        case GRStationsLayoutGenre:{
            _stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"genre"
                                                                                  ascending:YES
                                                                                   selector:@selector(localizedCaseInsensitiveCompare:)],
                                                      [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                  ascending:YES
                                                                                   selector:@selector(localizedCaseInsensitiveCompare:)]];
            sectionKeyPath = @"genre";
            break;
        }
        case GRStationsLayoutCity:{
            _stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"location"
                                                                                  ascending:YES
                                                                                   selector:@selector(localizedCaseInsensitiveCompare:)],
                                                      [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                  ascending:YES
                                                                                   selector:@selector(localizedCaseInsensitiveCompare:)]];

            sectionKeyPath = @"location";
            break;
        }
        case GRStationsLayoutAlphabetical:{
            _stationsFetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"favourite"
                                                                                  ascending:NO],
                                                      [[NSSortDescriptor alloc] initWithKey:@"title"
                                                                                  ascending:YES
                                                                                   selector:@selector(localizedCaseInsensitiveCompare:)]];

            sectionKeyPath = @"favourite";
            break;
        }
    }
    
    _stationsFetchedResultsController
        = [[NSFetchedResultsController alloc] initWithFetchRequest:_stationsFetchRequest
                                              managedObjectContext:moc
                                                sectionNameKeyPath:sectionKeyPath
                                                         cacheName:nil];
    
    NSError *error;    
    _stationsFetchedResultsController.delegate = self;
    if ([_stationsFetchedResultsController performFetch:&error] == NO) {
        DLog(@"Fetching non-sticky events failed: %@ %@", [error description], [error userInfo]);
    }
}

- (void)setupFetchedResultsControllersWithString:(NSString *)filter
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"server == YES"];
    if (filter.length > 0) {
        switch (self.stationsLayout) {
            case GRStationsLayoutGenre:{
                predicate = [NSPredicate predicateWithFormat:
                             @"server == YES AND (title CONTAINS[cd] %@ OR genre CONTAINS[cd] %@)", filter, filter];
                break;
            }
            case GRStationsLayoutCity:{
                predicate = [NSPredicate predicateWithFormat:
                             @"server == YES AND (title CONTAINS[cd] %@ OR location CONTAINS[cd] %@)", filter, filter];
                break;
            }
            case GRStationsLayoutAlphabetical:{
                predicate = [NSPredicate predicateWithFormat:@"server == YES AND title CONTAINS[cd] %@", filter];
                break;
            }
        }
    }

    _stationsFetchRequest.predicate = predicate;
    NSError *error;
    if ([_stationsFetchedResultsController performFetch:&error] == NO) {
        DLog(@"Fetching non-sticky events failed: %@ %@", [error description], [error userInfo]);
    }
    
    [_tableView reloadData];
}

- (void)setStationsLayout:(GRStationsLayout)stationsLayout
{
    if (_stationsLayout != stationsLayout) {
        _stationsLayout = stationsLayout;
        [self setupFetchedResultsControllers];
        [_tableView reloadData];
    }
}

#pragma mark - Table delegate and Data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _stationsFetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = _stationsFetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [GRStationCellView reusableIdentifier];
    GRStationCellView *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[GRStationCellView alloc] init];
    }
    
    GRStation *station = [self stationForIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",station.title];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", station.location, station.genre];
    cell.station = station;
    
    id<NSFetchedResultsSectionInfo> sectionInfo = _stationsFetchedResultsController.sections[indexPath.section];
    cell.showDivider = (indexPath.row != (sectionInfo.numberOfObjects - 1));
    
    if ([[GRRadioPlayer shared].currentStation isEqual:station]) {
        cell.imageView.image = [UIImage imageNamed:@"GRNote"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"GRMicrophone"];
    }
    
    [cell setNeedsDisplay];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 20.0;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [_stationsFetchedResultsController.sectionIndexTitles indexOfObject:title];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 20.0)];
    sectionHeader.autoresizingMask = UIViewAutoresizingNone;
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.180f green:0.180f blue:0.161f alpha:1.00f];
    sectionHeader.textAlignment = NSTextAlignmentCenter;
    sectionHeader.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    sectionHeader.textColor = [UIColor whiteColor];
    
    id<NSFetchedResultsSectionInfo> sectionInfo = _stationsFetchedResultsController.sections[section];
    if (self.stationsLayout == GRStationsLayoutAlphabetical) {
        if (section == 0 && tableView.numberOfSections == 2) {
            sectionHeader.text = [NSString stringWithFormat:@"%@ (%lu)",
                                  NSLocalizedString(@"label_favorites", @""), (unsigned long)sectionInfo.numberOfObjects];
        } else {
            sectionHeader.text = [NSString stringWithFormat:@"%@ (%lu)",
                                  NSLocalizedString(@"label_stations", @""), (unsigned long)sectionInfo.numberOfObjects];
        }
    } else {
        sectionHeader.text = [NSString stringWithFormat:@"%@ (%lu)",
                              sectionInfo.name, (unsigned long)sectionInfo.numberOfObjects];
    }
    
    return sectionHeader;
}

#pragma mark - NSFetchedResultsControllerDelegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [_tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)changeType
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (changeType){
        case NSFetchedResultsChangeInsert:{
            [_tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeDelete:{
            [_tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeUpdate:{
            [_tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeMove:{
            [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
            [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
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
    switch(type) {
        case NSFetchedResultsChangeInsert:{
            [_tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:{
            [_tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:{
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
    NSIndexPath *oldIndexPath = [_selectedIndexPath copy];
    _selectedIndexPath = indexPath;

    GRStation *station = [self stationForIndexPath:indexPath];
    if (_delegate && [_delegate respondsToSelector:@selector(stationManager:shouldPlayStation:)]) {
        [_delegate stationManager:self shouldPlayStation:station];

        if (indexPath && indexPath.row != NSNotFound) {
            [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        if (oldIndexPath && oldIndexPath.row != NSNotFound){
            [_tableView reloadRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)playNextStation
{
    NSIndexPath *oldIndexPath = [_selectedIndexPath copy];
    NSIndexPath *newIndexPath = [_tableView nextIndexPathForPath:oldIndexPath];
    if (newIndexPath == nil) {
        newIndexPath = [_tableView firstIndexPath];
    }
    
    [self playStationAtIndexPath:newIndexPath];
    [_tableView scrollToRowAtIndexPath:newIndexPath
                      atScrollPosition:UITableViewScrollPositionMiddle
                              animated:YES];
}

- (void)playPreviousStation
{
    NSIndexPath *oldIndexPath = [_selectedIndexPath copy];
    NSIndexPath *newIndexPath = [_tableView previousIndexPathForPath:oldIndexPath];
    if (newIndexPath == nil) {
        newIndexPath = [_tableView lastIndexPath];
    }
    
    [self playStationAtIndexPath:newIndexPath];
    [_tableView scrollToRowAtIndexPath:newIndexPath
                      atScrollPosition:UITableViewScrollPositionMiddle
                              animated:YES];
}

#pragma mark - Helpers

- (GRStation *)stationForIndexPath:(NSIndexPath *)indexPath
{
    return [_stationsFetchedResultsController objectAtIndexPath:indexPath];
}

- (NSUInteger)numberOfStations
{
    return _stationsFetchedResultsController.fetchedObjects.count;
}

#pragma mark - Dealloc

- (void)dealloc
{
    _delegate = nil;
    _tableView = nil;
    _stationsFetchedResultsController.delegate = nil;
    _stationsFetchedResultsController = nil;
}

@end
