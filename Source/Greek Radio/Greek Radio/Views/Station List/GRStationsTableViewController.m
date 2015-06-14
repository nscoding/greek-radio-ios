//
//  GRListTableViewController.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStationsTableViewController.h"
#import "GRPlayerViewController.h"
#import "GRSettingsViewController.h"
#import "GRNavigationController.h"
#import "GRStationsManager.h"

#import "UITableView+Extensions.h"
#import "UIDevice+Extensions.h"

#import <CoreMotion/CoreMotion.h>

@interface GRStationsTableViewController() <UIAccelerometerDelegate, GRStationsManagerDelegate,
                                            GRPlayerViewControllerDelegate, UISearchBarDelegate, UITextFieldDelegate>
{
	CFTimeInterval lastTime;
	CGFloat	shakeAccelerometer[3];
}

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) GRStationsManager *stationManager;
@property (nonatomic, strong) UISearchBar *searchBar;

@end

#define kAccelerometerFrequency			105
#define kFilteringFactor				0.1
#define kMinEraseInterval				0.5
#define kEraseAccelerationThreshold		4.0

@implementation GRStationsTableViewController

#pragma mark - Initializer

- (instancetype)init
{
    return [super init];
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureNavigationBarBackTitle];
    [self configureDataSource];
    [self configureTableView];
    [self configureTrackClearButton];
    [self registerObservers];
    
    [self buildAndConfigureSearchBar];
    [self buildAndConfigurePullToRefresh];
    [self buildAndConfigureNavigationButton];
    [self buildAndConfigureMotionDetector];
    [self buildAndConfigureRightGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.searchBar resignFirstResponder];
    [self becomeFirstResponder];

    self.navigationItem.title = @"Greek Radio";
}

#pragma mark - Build and Configure

- (void)configureNavigationBarBackTitle
{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
}

- (void)configureTableView
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 60.0f;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.180f green:0.180f blue:0.161f alpha:1.00f];
    [self.tableView setContentOffset:CGPointMake(0.0f, 44.0f) animated:YES];
}

- (void)configureDataSource
{
    GRStationsLayout stationsLayout = [GRUserDefaults currentSearchScope];
    self.stationManager = [[GRStationsManager alloc] initWithTableView:self.tableView
                                                        stationsLayout:stationsLayout];
    self.stationManager.delegate = self;
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

- (void)buildAndConfigureSearchBar
{
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.showsScopeBar = YES;
    self.searchBar.barStyle = UIBarStyleBlack;
    self.searchBar.delegate = self;
    self.searchBar.tintColor = [UIColor grayColor];
    self.searchBar.scopeButtonTitles = @[NSLocalizedString(@"label_genre", @""),
                                         NSLocalizedString(@"label_location", @""),
                                         NSLocalizedString(@"label_AZ", @"")];
    self.searchBar.placeholder = NSLocalizedString(@"label_search", @"");
    self.searchBar.selectedScopeButtonIndex = [GRUserDefaults currentSearchScope];
    
    // showsScopeBar default is NO. if YES, shows the scope bar. call sizeToFit: to update frame
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;
}

- (void)buildAndConfigurePullToRefresh
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

- (void)buildAndConfigureNavigationButton
{
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"label_settings", @"")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(settingsButtonPressed:)];
    
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
            if ([GRUserDefaults isShakeForRandomStationEnabled])
            {
                CMAcceleration acceleration = accelerometerData.acceleration;
                CGFloat length,	x, y, z;
                
                //Use a basic high-pass filter to remove the influence of the gravity
                shakeAccelerometer[0] = acceleration.x * kFilteringFactor +
                shakeAccelerometer[0] * (1.0f - kFilteringFactor);
                shakeAccelerometer[1] = acceleration.y * kFilteringFactor +
                shakeAccelerometer[1] * (1.0f - kFilteringFactor);
                shakeAccelerometer[2] = acceleration.z * kFilteringFactor +
                shakeAccelerometer[2] * (1.0f - kFilteringFactor);
                
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
                    int random = arc4random() % (self.stationManager.numberOfStations - 1);
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

- (void)buildAndConfigureRightGesture
{
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc]
                                                initWithTarget:self action:@selector(handleRightSwipe:)];
    recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:recognizer];
}

#pragma mark - Notifications

- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncDidEnd:)
                                                 name:GRNotificationSyncManagerDidEnd
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferredTextSizeChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidStart:)
                                                 name:GRNotificationStreamDidStart
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidEnd:)
                                                 name:GRNotificationStreamDidEnd
                                               object:nil];
}

- (void)syncDidEnd:(NSNotification *)notification
{
    [self.refreshControl performSelector:@selector(endRefreshing)];
}

- (void)preferredTextSizeChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)playerDidStart:(NSNotification *)notification
{
  [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows
                        withRowAnimation:UITableViewRowAnimationNone];
}

- (void)playerDidEnd:(NSNotification *)notification
{
  [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows
                        withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - GRStationsManager Delegate

- (void)stationManager:(GRStationsManager *)stationManager shouldPlayStation:(GRStation *)station
{
    GRPlayerViewController *playController = [[GRPlayerViewController alloc] initWithStation:station
                                                                                    delegate:self
                                                                                previousView:self.view];

    if (self.navigationController.visibleViewController == self)
    {
        [UIMenuController sharedMenuController].menuVisible = NO;
        [self.navigationController pushViewController:playController animated:YES];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:NO];
        [self.navigationController pushViewController:playController animated:NO];
    }
}

#pragma mark - Actions

- (void)updateStations
{
    [[GRWebService shared] parseXML];
}

- (void)settingsButtonPressed:(UIButton *)sender
{
    [self.searchBar resignFirstResponder];

    GRSettingsViewController *settingsNavigationController = [[GRSettingsViewController alloc] init];
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:settingsNavigationController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;

    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
}

- (void)nowPlayingButtonPressed:(UIBarButtonItem *)sender
{
    if ([GRRadioPlayer shared].currentStation)
    {
        [self.searchBar resignFirstResponder];

        GRPlayerViewController *playController =
            [[GRPlayerViewController alloc] initWithStation:[GRRadioPlayer shared].currentStation
                                                   delegate:self
                                               previousView:self.view];
        
        if (self.navigationController.visibleViewController == self)
        {
            [UIMenuController sharedMenuController].menuVisible = NO;
            [self.navigationController pushViewController:playController animated:YES];
        }
    }
}

- (void)handleRightSwipe:(UISwipeGestureRecognizer *)recognizer
{
    [self nowPlayingButtonPressed:nil];
}

#pragma mark - Search Delegate

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.stationManager setupFetchedResultsControllersWithString:self.searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.stationManager setupFetchedResultsControllersWithString:self.searchBar.text];
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

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    searchBar.text = @"";
    [searchBar resignFirstResponder];

    self.stationManager.stationsLayout = selectedScope;
    [GRUserDefaults setCurrentSearchScope:selectedScope];
}

#pragma mark - GRPlayerViewController delegate

- (void)playerViewControllerPlayNextStation:(GRPlayerViewController *)playViewController
{
    [self.stationManager playNextStation];
}

- (void)playerViewControllerPlayPreviousStation:(GRPlayerViewController *)playViewControllerl
{
    [self.stationManager playPreviousStation];
}

#pragma mark - Memory

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
