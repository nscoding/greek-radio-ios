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
#import "GRWoodNavigationBar.h"
#import "GRSplashViewController.h"
#import "TestFlight.h"


// ------------------------------------------------------------------------------------------


@implementation GRAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !APPSTORE
    [TestFlight takeOff:@"fbd248aa-5493-47ee-9487-de4639b10d0b"];
#endif
    

    [self buildAndConfigureMainWindow];
    [self buildAndConfigureStationsViewController];
    
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
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"GRWoodHeader"]
                                       forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:0
                                       forBarMetrics:UIBarMetricsDefault];

    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
        [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], UITextAttributeTextColor,
        [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8], UITextAttributeTextShadowColor,
        [NSValue valueWithUIOffset:UIOffsetMake(0, 1)], UITextAttributeTextShadowOffset,
        [UIFont fontWithName:@"HelveticaNeue-Bold" size:21.0], UITextAttributeFont, nil]];

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
