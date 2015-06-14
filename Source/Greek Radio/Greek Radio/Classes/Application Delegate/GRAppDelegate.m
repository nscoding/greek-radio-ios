//
//  GRAppDelegate.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAppDelegate.h"
#import "GRNavigationController.h"
#import "GRStationsTableViewController.h"
#import "Appirater.h"

@implementation GRAppDelegate
{
    GRStationsTableViewController *_listTableViewController;
    GRNavigationController *_menuNavigationController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication sharedApplication].idleTimerDisabled = [GRUserDefaults isAutomaticLockDisabled];

    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:appVersionString forKey:@"currentVersionKey"];
    [GRAppearanceHelper setUpGreekRadioAppearance];

    [self buildAndConfigureMainWindow];
    [self buildAndConfigureStationsViewController];
    [self configureAppirater];
    [self registerObservers];
    
    if ([NSInternetDoctor shared].connected)
    {
        [UIAlertView showWithTitle:NSLocalizedString(@"app_welcome_title", @"")
                           message:NSLocalizedString(@"app_welcome_subtitle", @"")
                 cancelButtonTitle:NSLocalizedString(@"button_enjoy", @"")
                 otherButtonTitles:nil
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [_listTableViewController.tableView setContentOffset:CGPointZero animated:YES];

            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,(int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [Appirater appLaunched:YES];
            });
        }];
    }
    
    [[GRWebService shared] parseXML];

    return YES;
}

#pragma mark - Build and configure

- (void)buildAndConfigureMainWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
}

- (void)buildAndConfigureStationsViewController
{
    _listTableViewController = [[GRStationsTableViewController alloc] init];
    _menuNavigationController = [[GRNavigationController alloc] initWithRootViewController:_listTableViewController];
    _menuNavigationController.navigationBar.translucent = NO;
    _menuNavigationController.navigationBarHidden = NO;
    _listTableViewController.navigationController = _menuNavigationController;
    self.window.rootViewController = _menuNavigationController;
}

- (void)configureAppirater
{
    [Appirater setAppId:@"321094050"];
    [Appirater setDaysUntilPrompt:3];
    [Appirater setUsesUntilPrompt:3];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:3];
    [Appirater setUsesAnimation:YES];
    [Appirater setDebug:NO];
}

#pragma mark - Notfications

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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)activityDidEnd:(NSNotification *)notification
{
    if ([GRRadioPlayer shared].isPlaying == NO) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

@end
