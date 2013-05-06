//
//  GRAppDelegate.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAppDelegate.h"
#import "GRListTableViewController.h"
#import "GRSplashViewController.h"

#import "TestFlight.h"


// ------------------------------------------------------------------------------------------


@implementation GRAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !APPSTORE
    [TestFlight takeOff:@"fbd248aa-5493-47ee-9487-de4639b10d0b"];
#endif

    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:appVersionString forKey:@"currentVersionKey"];

    [GRAppearanceHelper setUpGreekRadioAppearance];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [self buildAndConfigureMainWindow];
    [self buildAndConfigureStationsViewController];
    
    if ([NSInternetDoctor shared].connected)
    {
        BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Welcome to Greek Radio"
                                                       message:@"Listen. Feel. Share."];
        
        [alert setCancelButtonWithTitle:@"Enjoy!" block:nil];
        [alert show];
    }
    
    [self registerObservers];
    
    // [self performSelector:@selector(flipSplashScreen) withObject:nil afterDelay:1.0f];
    // [self buildAndConfigureSplashViewController];
    
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


- (void)buildAndConfigureSplashViewController
{
    // Add the splash view
	self.splashViewController = [[GRSplashViewController alloc] init];
    [self.splashViewController.view setFrame:self.window.frame];
    [self.window addSubview:self.splashViewController.view];
}


- (void)flipSplashScreen
{
    // Page flip transition
	[UIView beginAnimations:@"pageFlipTransition" context:nil];
	[UIView setAnimationDelay:0.0];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.8];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.window cache:YES];
	[UIView commitAnimations];
    
    [self.splashViewController.view removeFromSuperview];
}


- (void)buildAndConfigureStationsViewController
{
    // Override point for customization after application launch.
    self.listTableViewController = [[GRListTableViewController alloc] init];
    
    self.menuNavigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:self.listTableViewController];
    self.menuNavigationController.navigationBarHidden = NO;
    self.window.rootViewController = self.menuNavigationController;
    self.listTableViewController.navigationController = self.menuNavigationController;
    self.menuNavigationController.navigationBar.topItem.title = @"Greek Radio";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[GRWebService shared] parseXML];
    });
}


@end
