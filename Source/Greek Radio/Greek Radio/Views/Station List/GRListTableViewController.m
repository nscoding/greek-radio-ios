//
//  GRListTableViewController.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRListTableViewController.h"
#import "GRStationsDAO.h"
#import "GRStationCellView.h"
#import "GRPlayerViewController.h"


// ------------------------------------------------------------------------------------------


@interface GRListTableViewController ()

@property (nonatomic, strong) GRStationsDAO *stationsDAO;
@property (nonatomic, strong) NSMutableArray *serverStations;
@property (nonatomic, strong) NSMutableArray *localStations;
@property (nonatomic, strong) NSMutableArray *favouriteStations;

@end


// ------------------------------------------------------------------------------------------


@implementation GRListTableViewController

// ------------------------------------------------------------------------------------------
#pragma mark - Initializer
// ------------------------------------------------------------------------------------------
- (id)init
{
    if ((self = [super initWithNibName:@"GRListTableViewController" bundle:nil]))
    {
        self.searchBar.delegate = self;
        [self.tableView setBackgroundColor:[UIColor colorWithPatternImage:
                                            [UIImage imageNamed:@"GRPaperBackground"]]];
    }
    
    return self;
}


// ------------------------------------------------------------------------------------------
#pragma mark -
// ------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    /* https://gist.github.com/jeksys/1070394 */
    [self configureTrackClearButton];
    
    // add the pull to refresh view
    [self buildAndConfigurePullToRefresh];
    [self buildAndConfigureMadeWithLove];
    
    [super viewDidLoad];
    
    // create the DAO object
    self.stationsDAO = [[GRStationsDAO alloc] init];
    
    // get the stations
    [self configureStationsWithFilter:self.searchBar.text
                              animate:NO];
    
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    
    // register notifications
    [self registerObservers];
    
    
    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.frame = CGRectMake(0, 0, 40, 12);
    
    [moreButton setImage:[UIImage imageNamed:@"GRMore"] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(moreButtonPressed:)
        forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]
                               initWithCustomView:moreButton];

    self.navigationItem.rightBarButtonItem = rightButton;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self configureStationsWithFilter:self.searchBar.text animate:YES];
    
    [self.searchBar resignFirstResponder];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Build and Configure
// ------------------------------------------------------------------------------------------
- (void)configureTrackClearButton
{
    for (UIView *view in self.searchBar.subviews)
    {
        if ([view isKindOfClass: [UITextField class]])
        {
            UITextField *tf = (UITextField *)view;
            tf.delegate = self;
            break;
        }
    }
}


- (void)configureStationsWithFilter:(NSString *)filter
                            animate:(BOOL)animate
{
    NSUInteger serverCount = self.serverStations.count;
    NSUInteger favouriteCount = self.favouriteStations.count;
    NSUInteger localCount = self.localStations.count;
    
    [self.serverStations removeAllObjects];
    self.serverStations = [NSMutableArray arrayWithArray:[self.stationsDAO retrieveAllServerBased:filter]];
    [self.localStations removeAllObjects];
    self.localStations = [NSMutableArray arrayWithArray:[self.stationsDAO retrieveAllLocalBased:filter]];
    [self.favouriteStations removeAllObjects];
    self.favouriteStations = [NSMutableArray arrayWithArray:[self.stationsDAO retrieveAllFavourites:filter]];
    [self.tableView reloadData];

    if (serverCount == self.serverStations.count &&
        favouriteCount == self.favouriteStations.count &&
        localCount == self.localStations.count)
    {
        animate = NO;
    }
    
    if (animate)
    {
        NSIndexSet *indexesReload = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 1)];
        [self.tableView reloadSections:indexesReload withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        [self.tableView reloadData];
    }
    

}


- (void)buildAndConfigurePullToRefresh
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refresh Stations"];
    [self.refreshControl addTarget:self
                            action:@selector(updateStations)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.refreshControl endRefreshing];
}


- (void)buildAndConfigureMadeWithLove
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15];
    label.textColor = [UIColor colorWithRed:0.000f green:0.000f blue:0.000f alpha:1.00f];
    label.shadowColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    label.shadowOffset = CGSizeMake(0, 1);
    label.textAlignment = NSTextAlignmentCenter;
    label.text =  @"Made in Berlin with ❤\n❝Patrick - Vasileia❞";
    label.numberOfLines = 0;
    label.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 100);

    self.tableView.tableFooterView = label;
}

// ------------------------------------------------------------------------------------------
#pragma mark - Pull to refresh
// ------------------------------------------------------------------------------------------
- (void)updateStations
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[GRWebService shared] parseXML];
    });
}


// ------------------------------------------------------------------------------------------
#pragma mark - Notifications
// ------------------------------------------------------------------------------------------
- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncDidEnd:)
                                                 name:GRNotificationSyncManagerDidEnd
                                               object:nil];
}

- (void)syncDidEnd:(NSNotification *)notification
{
    [self configureStationsWithFilter:self.searchBar.text
                              animate:YES];
    
    [self.refreshControl performSelector:@selector(endRefreshing)];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Table View delegate
// ------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.favouriteStations.count;
    }
    else if (section == 1)
    {
        return self.localStations.count;
    }    
    else if (section == 2)
    {
        return self.serverStations.count;
    }

    return 0;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
    cell.subtitle.text = [NSString stringWithFormat:@"%@", station.location];
    [cell setBadgeText:[NSString stringWithFormat:@"%@", station.genre]];

    [cell setNeedsDisplay];
    
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName = @"";
    switch (section)
    {
        case 0:
        {
            sectionName = (self.favouriteStations.count > 0) ?
            [NSString stringWithFormat:@"%@ (%i)",
             NSLocalizedString(@"Favorites", @""), self.favouriteStations.count] : @"";
        }
            break;
        case 1:
        {
            sectionName = (self.localStations.count > 0) ?
            [NSString stringWithFormat:@"%@ (%i)",
             NSLocalizedString(@"Local Stations", @""), self.localStations.count] : @"";
        }
            break;
        case 2:
        {
            sectionName = (self.serverStations.count > 0) ?
            [NSString stringWithFormat:@"%@ (%i)",
             NSLocalizedString(@"Stations", @""), self.serverStations.count] : @"";
        }
            break;
    }
    
    return sectionName;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GRStation *station = [self stationForIndexPath:indexPath];
    GRPlayerViewController *playController = [[GRPlayerViewController alloc] initWithStation:station
                                                                                previousView:self.view];

    [self.navigationController pushViewController:playController animated:YES];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return YES;
    }

    return NO;
}


-  (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        GRStation *station = [self stationForIndexPath:indexPath];
        station.favourite = [NSNumber numberWithBool:NO];
        [station.managedObjectContext save:nil];
        
        [self configureStationsWithFilter:self.searchBar.text
                                  animate:YES];
    }
}


- (NSString *)tableView:(UITableView *)tableView
titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}


// ------------------------------------------------------------------------------------------
#pragma mark - Table View Helpers
// ------------------------------------------------------------------------------------------
- (GRStation *)stationForIndexPath:(NSIndexPath *)indexPath
{
    GRStation *station = nil;
    
    if (indexPath.section == 0)
    {
        station = [self.favouriteStations objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1)
    {
        station = [self.localStations objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 2)
    {
        station = [self.serverStations objectAtIndex:indexPath.row];
    }

    return station;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (void)moreButtonPressed:(UIButton *)sender
{
    BlockActionSheet *sheet = [BlockActionSheet sheetWithTitle:@""];
    [sheet setCancelButtonWithTitle:@"Dismiss"
                              block:nil];
    
    [sheet addButtonWithTitle:@"Suggest a station"
                        block:^
    {
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
        mailController.subject = @"New station proposal";
        [mailController setToRecipients:@[@"vasileia@nscoding.co.uk"]];

        [GRAppearanceHelper setUpDefaultAppearance];
        [self.navigationController presentModalViewController:mailController animated:YES];
    }];
    
    [sheet setDestructiveButtonWithTitle:@"Report a problem"
                                   block:^
    {
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
        mailController.subject = @"Something is wrong...";        
        [mailController setToRecipients:@[@"team@nscoding.co.uk"]];

        [GRAppearanceHelper setUpDefaultAppearance];
        [self.navigationController presentModalViewController:mailController animated:YES];
    }];
    
    [sheet showInView:self.view];
}


- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [GRAppearanceHelper setUpGreekRadioAppearance];
    [controller dismissModalViewControllerAnimated:YES];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Search Delegate
// ------------------------------------------------------------------------------------------
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self configureStationsWithFilter:self.searchBar.text
                              animate:YES];
    
    [searchBar resignFirstResponder];
}


- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText
{
    [self configureStationsWithFilter:self.searchBar.text
                              animate:YES];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    searchBar.text = @"";
    [searchBar resignFirstResponder];
}


- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    //if we only try and resignFirstResponder on textField or searchBar,
    //the keyboard will not dissapear (at least not on iPad)!
    [self performSelector:@selector(searchBarCancelButtonClicked:)
               withObject:self.searchBar
               afterDelay:0.1];
    
    return YES;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Memory
// ------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    if ([GRRadioPlayer shared].isPlaying)
    {
        [[GRRadioPlayer shared] stopPlayingStation];
        [BlockAlertView showInfoAlertWithTitle:@"Low Memory"
                                       message:@"The amount of available memory on your device is low, "
                                               @"Greek Radio stopped playing to avoid crashing."];
    }
  
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObject:self];
}


@end
