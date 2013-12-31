//
//  GRAppDelegate.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAppDelegate.h"
#import "GRStationsTableViewController.h"

#import "Appirater.h"
#import "TestFlight.h"


// ------------------------------------------------------------------------------------------


@implementation GRAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication sharedApplication].idleTimerDisabled = [GRUserDefaults isAutomaticLockDisabled];

    [TestFlight takeOff:@"fbd248aa-5493-47ee-9487-de4639b10d0b"];

    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:appVersionString forKey:@"currentVersionKey"];

    [GRAppearanceHelper setUpGreekRadioAppearance];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [self buildAndConfigureMainWindow];
    [self buildAndConfigureStationsViewController];
    [self registerObservers];
    
    [Appirater setAppId:@"321094050"];
    [Appirater setDaysUntilPrompt:3];
    [Appirater setUsesUntilPrompt:3];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:3];
    [Appirater setUsesAnimation:YES];    
    [Appirater setDebug:NO];
    
    if ([NSInternetDoctor shared].connected)
    {
        [UIAlertView showWithTitle:NSLocalizedString(@"app_welcome_title", @"")
                           message:NSLocalizedString(@"app_welcome_subtitle", @"")
                 cancelButtonTitle:NSLocalizedString(@"button_enjoy", @"")
                 otherButtonTitles:nil
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
        {
            [self.listTableViewController.tableView setContentOffset:CGPointZero animated:YES];

            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                                                    (int64_t)(delayInSeconds * NSEC_PER_SEC));
            
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [Appirater appLaunched:YES];
            });
        }];
    }
    
    return YES;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Notfications
// ------------------------------------------------------------------------------------------
- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activityDidStart:)
                                                 name:GRNotificationSyncManagerDidStart
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activityDidStart:)
                                                 name:GRNotificationStreamDidStart
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activityDidEnd:)
                                                 name:GRNotificationSyncManagerDidEnd
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activityDidEnd:)
                                                 name:GRNotificationStreamDidEnd
                                               object:nil];
}


- (void)activityDidStart:(NSNotification *)notification
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}


- (void)activityDidEnd:(NSNotification *)notification
{
    if ([GRRadioPlayer shared].isPlaying == NO)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Build and configure
// ------------------------------------------------------------------------------------------
- (void)buildAndConfigureMainWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
}


- (void)buildAndConfigureStationsViewController
{
    // Override point for customization after application launch.
    self.listTableViewController = [[GRStationsTableViewController alloc] init];
    
    self.menuNavigationController
        = [[GRNavigationController alloc] initWithRootViewController:self.listTableViewController];
    
    self.menuNavigationController.navigationBar.translucent = NO;
    self.menuNavigationController.navigationBarHidden = NO;
    self.listTableViewController.navigationController = self.menuNavigationController;
    self.window.rootViewController = self.menuNavigationController;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[GRWebService shared] parseXML];
    });
}


@end
