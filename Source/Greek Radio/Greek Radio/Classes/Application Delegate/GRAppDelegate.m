//
//  GRAppDelegate.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAppDelegate.h"
#import "GRListTableViewController.h"
#import "GRWebService.h"
#import "GRSplashViewController.h"
#import "TestFlight.h"
#import "GRAppearance‎Helper.h"
#import "BlockAlertView.h"

// ------------------------------------------------------------------------------------------


@implementation GRAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !APPSTORE
    [TestFlight takeOff:@"fbd248aa-5493-47ee-9487-de4639b10d0b"];
#endif
    
    [GRAppearanceHelper setUpGreekRadioAppearance];

    [self buildAndConfigureMainWindow];
    [self buildAndConfigureStationsViewController];
    
    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Welcome to Greek Radio"
                                                   message:@"Feel. Listen. Share."];
    
    [alert setCancelButtonWithTitle:@"Dismiss" block:nil];
    [alert show];

    
//    [self performSelector:@selector(flipSplashScreen) withObject:nil afterDelay:1.0f];
//    [self buildAndConfigureSplashViewController];
    
    return YES;
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[GRWebService shared] parseXML];
    });
}


// ------------------------------------------------------------------------------------------
#pragma mark - Application notifications
// ------------------------------------------------------------------------------------------
- (void)applicationWillResignActive:(UIApplication *)application
{
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
}


- (void)applicationWillTerminate:(UIApplication *)application
{
}


@end
