//
//  GRListTableViewController.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRListTableViewController.h"
#import "GRPlayerViewController.h"
#import "GRStationCellView.h"
#import "GRStationsDAO.h"

#import "UIDevice+Extensions.h"

#import <CoreMotion/CoreMotion.h>


// ------------------------------------------------------------------------------------------


@interface GRListTableViewController () <GRStationCellViewDelegate, UIAccelerometerDelegate>
{
	CFTimeInterval lastTime;
	CGFloat	shakeAccelerometer[3];
}

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) GRStationsDAO *stationsDAO;
@property (nonatomic, strong) NSMutableArray *serverStations;
@property (nonatomic, strong) NSMutableArray *localStations;
@property (nonatomic, strong) NSMutableArray *favouriteStations;
@property (nonatomic, strong) CMMotionManager *motionManager;

@end


// ------------------------------------------------------------------------------------------


#define kAccelerometerFrequency			105
#define kFilteringFactor				0.1
#define kMinEraseInterval				0.5
#define kEraseAccelerationThreshold		4.0


// ------------------------------------------------------------------------------------------


@implementation GRListTableViewController

// ------------------------------------------------------------------------------------------
#pragma mark - Initializer
// ------------------------------------------------------------------------------------------
- (id)init
{
    return [super initWithNibName:@"GRListTableViewController" bundle:nil];
}


// ------------------------------------------------------------------------------------------
#pragma mark -
// ------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureDataSource];
    [self configureTableViewAndSearchBar];
    [self configureTrackClearButton];
    [self registerObservers];
    [self buildAndConfigureNavigationButtons];
    [self buildAndConfigureMotionDetector];
    [self buildAndConfigurePullToRefresh];
    [self buildAndConfigureMadeWithLove];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Greek Radio";
    [self configureStationsWithFilter:self.searchBar.text animate:YES];
    [self.searchBar resignFirstResponder];
    [self becomeFirstResponder];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.title = @"";
}


// ------------------------------------------------------------------------------------------
#pragma mark - Build and Configure
// ------------------------------------------------------------------------------------------
- (void)configureTableViewAndSearchBar
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.180f
                                                       green:0.180f
                                                        blue:0.161f
                                                       alpha:1.00f]];
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    
    self.searchBar.delegate = self;
    self.searchBar.placeholder = NSLocalizedString(@"label_search", @"");
}


- (void)configureDataSource
{
    self.stationsDAO = [[GRStationsDAO alloc] init];
    [self configureStationsWithFilter:self.searchBar.text
                              animate:NO];
}


- (void)configureTrackClearButton
{
    /* https://gist.github.com/jeksys/1070394 */
    for (UIView *view in self.searchBar.subviews)
    {
        if ([view isKindOfClass:[UITextField class]])
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
    if (self.refreshControl == nil)
    {
        self.refreshControl = [[UIRefreshControl alloc] init];
        
        NSMutableAttributedString *refreshTitleString
            = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"label_refresh_stations", @"")];
        
        [refreshTitleString addAttribute:NSForegroundColorAttributeName
                                   value:[UIColor colorWithRed:0.471f green:0.471f blue:0.471f alpha:1.00f]
                                   range:NSMakeRange(0, refreshTitleString.string.length)];

        self.refreshControl.attributedTitle = refreshTitleString;
        self.refreshControl.tintColor = [UIColor colorWithRed:0.671f green:0.671f blue:0.671f alpha:1.00f];

        [self.refreshControl addTarget:self
                                action:@selector(updateStations)
                      forControlEvents:UIControlEventValueChanged];
        
        [self.refreshControl endRefreshing];
    }
}


- (void)buildAndConfigureMadeWithLove
{
    if (self.tableView.tableFooterView == nil)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15];
        label.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.00f];
        label.shadowColor = [UIColor colorWithWhite:0.0 alpha:1.0];
        label.shadowOffset = CGSizeMake(0, 1);
        label.textAlignment = NSTextAlignmentCenter;
        label.text =  @"Made in Berlin with ❤\n❝Patrick - Vasileia❞";
        label.numberOfLines = 0;
        label.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 100);
        
        UITapGestureRecognizer *tapGestureRecognizer
            = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(madeWithLovePressed)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        label.userInteractionEnabled = YES;

        [label addGestureRecognizer:tapGestureRecognizer];

        self.tableView.tableFooterView = label;
    }
}


- (void)buildAndConfigureNavigationButtons
{
    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.frame = CGRectMake(0, 0, 40, 12);
    [moreButton setImage:[UIImage imageNamed:@"GRMore"] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(moreButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]
                                    initWithCustomView:moreButton];
    
    self.navigationItem.rightBarButtonItem = rightButton;
    
    
    UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    settingButton.frame = CGRectMake(0, 0, 22, 22);
    [settingButton setImage:[UIImage imageNamed:@"GRSettingsButtonWhite"] forState:UIControlStateNormal];
    [settingButton addTarget:self
                      action:@selector(settingsButtonPressed:)
            forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc]
                                   initWithCustomView:settingButton];
    
    self.navigationItem.leftBarButtonItem = leftButton;
}


- (void)buildAndConfigureMotionDetector
{
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.1;
    
    CMAccelerometerHandler accelerometerHandler = ^(CMAccelerometerData *accelerometerData, NSError *error)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GreekRadioShakeRandom"])
            {
                CMAcceleration acceleration = accelerometerData.acceleration;
                CGFloat length,	x, y, z;
                
                //Use a basic high-pass filter to remove the influence of the gravity
                shakeAccelerometer[0] = acceleration.x * kFilteringFactor +
                shakeAccelerometer[0] * (1.0 - kFilteringFactor);
                shakeAccelerometer[1] = acceleration.y * kFilteringFactor +
                shakeAccelerometer[1] * (1.0 - kFilteringFactor);
                shakeAccelerometer[2] = acceleration.z * kFilteringFactor +
                shakeAccelerometer[2] * (1.0 - kFilteringFactor);
                
                // Compute values for the three axes of the acceleromater
                x = acceleration.x - shakeAccelerometer[0];
                y = acceleration.y - shakeAccelerometer[0];
                z = acceleration.z - shakeAccelerometer[0];
                
                // Compute the intensity of the current acceleration
                length = sqrt(x * x + y * y + z * z);
                
                // If above a given threshold, play the erase sounds and erase the drawing view
                if((length >= kEraseAccelerationThreshold) &&
                   (CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval))
                {
                    lastTime = CFAbsoluteTimeGetCurrent();
                    
                    int random = arc4random() % (self.serverStations.count - 1);
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:random inSection:2];
                    
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        [self.tableView selectRowAtIndexPath:indexPath
                                                    animated:YES
                                              scrollPosition:UITableViewScrollPositionMiddle];
                        
                        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
                    });
                }
            }
        });
    };
    
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                             withHandler:accelerometerHandler];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Notifications
// ------------------------------------------------------------------------------------------
- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeTriggeredByUser:)
                                                 name:GRNotificationChangeTriggeredByUser
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncDidEnd:)
                                                 name:GRNotificationSyncManagerDidEnd
                                               object:nil];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Notifications
// ------------------------------------------------------------------------------------------
- (void)changeTriggeredByUser:(NSNotification *)notification
{
    // get the stations
    [self configureStationsWithFilter:self.searchBar.text
                              animate:YES];
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
    cell.subtitle.text = [NSString stringWithFormat:@"%@", station.location];
    cell.station = station;
    cell.delegate = self;
    [cell setBadgeText:[NSString stringWithFormat:@"%@", station.genre]];
    
    [cell setNeedsDisplay];
    
    return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self shouldShowHeaderForSection:section] == NO)
    {
        return nil;
    }
    
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

    if (section == 0)
    {
        sectionHeader.text = (self.favouriteStations.count > 0) ?
        [NSString stringWithFormat:@"%@ (%i)",
         NSLocalizedString(@"label_favorites", @""), self.favouriteStations.count] : @"";
    }
    else if (section == 1)
    {
        sectionHeader.text = (self.localStations.count > 0) ?
        [NSString stringWithFormat:@"%@ (%i)",
         NSLocalizedString(@"label_local_stations", @""), self.localStations.count] : @"";
    }
    else
    {
        sectionHeader.text = (self.serverStations.count > 0) ?
        [NSString stringWithFormat:@"%@ (%i)",
         NSLocalizedString(@"label_stations", @""), self.serverStations.count] : @"";
    }

    return sectionHeader;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self shouldShowHeaderForSection:section] == NO)
    {
        return 0.0f;
    }

    return 20.0f;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    if ([self shouldShowHeaderForSection:section] == NO)
    {
        return 0.0f;
    }
    
    return 20.0f;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GRStation *station = [self stationForIndexPath:indexPath];
    GRPlayerViewController *playController = [[GRPlayerViewController alloc] initWithStation:station
                                                                                previousView:self.view];
    
    if (self.navigationController.visibleViewController == self)
    {
        [UIMenuController sharedMenuController].menuVisible = NO;
        
        [self.navigationController pushViewController:playController
                                             animated:YES];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:NO];
        [self.navigationController pushViewController:playController
                                             animated:NO];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return YES;
    }

    return NO;
}


- (BOOL)shouldShowHeaderForSection:(NSUInteger)section
{
    NSUInteger count = 0;
    if (section == 0)
    {
        count = self.favouriteStations.count;
    }
    else if (section == 1)
    {
        count = self.localStations.count;
    }
    else if (section == 2)
    {
        count = self.serverStations.count;
    }
    
    return (count > 0);
}


-  (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
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


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"button_remove", @"");
}


// ------------------------------------------------------------------------------------------
#pragma mark - Table View Helpers
// ------------------------------------------------------------------------------------------
- (GRStation *)stationForIndexPath:(NSIndexPath *)indexPath
{
    GRStation *station = nil;
    
    if (indexPath.section == 0)
    {
        station = self.favouriteStations[indexPath.row];
    }
    else if (indexPath.section == 1)
    {
        station = self.localStations[indexPath.row];
    }
    else if (indexPath.section == 2)
    {
        station = self.serverStations[indexPath.row];
    }

    return station;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (void)updateStations
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        [[GRWebService shared] parseXML];
    });
}


- (void)madeWithLovePressed
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.nscoding.co.uk"]];
}


- (void)moreButtonPressed:(UIButton *)sender
{
    [self.searchBar resignFirstResponder];

    [UIActionSheet showInView:self.view
                    withTitle:@""
            cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
       destructiveButtonTitle:NSLocalizedString(@"button_report", @"")
            otherButtonTitles:@[NSLocalizedString(@"button_sugggest", @"")]
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex)
    {
        if (buttonIndex == 1)
        {
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
                mailController.mailComposeDelegate = self;
                mailController.subject = NSLocalizedString(@"label_new_stations", @"");
                [mailController setToRecipients:@[@"vasileia@nscoding.co.uk"]];
                
                [GRAppearanceHelper setUpDefaultAppearance];
                [self.navigationController presentViewController:mailController
                                                        animated:YES
                                                      completion:nil];
            }
            else
            {
                [UIAlertView showWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                                   message:NSLocalizedString(@"share_email_error", @"")
                         cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
                         otherButtonTitles:nil
                                  tapBlock:nil];
            }
        }
        else if (buttonIndex == 0)
        {
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
                mailController.mailComposeDelegate = self;
                mailController.subject = NSLocalizedString(@"label_something_wrong", @"");
                [mailController setToRecipients:@[@"team@nscoding.co.uk"]];
                
                [GRAppearanceHelper setUpDefaultAppearance];
                [self.navigationController presentViewController:mailController
                                                        animated:YES
                                                      completion:nil];
            }
            else
            {
                [UIAlertView showWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                                   message:NSLocalizedString(@"share_email_error", @"")
                         cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
                         otherButtonTitles:nil
                                  tapBlock:nil];
            }
        }
    }];
}


- (void)settingsButtonPressed:(UIButton *)sender
{
    [self.searchBar resignFirstResponder];
    [self.layerController showLeftPanelAnimated:YES];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Mail Composer delegate
// ------------------------------------------------------------------------------------------
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [GRAppearanceHelper setUpGreekRadioAppearance];
    [controller dismissViewControllerAnimated:YES completion:nil];
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


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
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
#pragma mark - GRStationCellView Delegate implementation
// ------------------------------------------------------------------------------------------
- (void)userDidDoubleTapOnGenre:(NSString *)genre
{
    self.searchBar.text = genre;
    [self configureStationsWithFilter:self.searchBar.text
                              animate:YES];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Memory
// ------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    if ([GRRadioPlayer shared].isPlaying)
    {
        [UIAlertView showWithTitle:NSLocalizedString(@"app_low_memory_error_title", @"")
                           message:NSLocalizedString(@"app_low_memory_error_subtitle", @"")
                 cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
                 otherButtonTitles:nil
                          tapBlock:nil];
    }
  
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
