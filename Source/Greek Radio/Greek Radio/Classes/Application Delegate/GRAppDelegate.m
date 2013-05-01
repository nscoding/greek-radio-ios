//
//  GRAppDelegate.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAppDelegate.h"
#import "GRViewController.h"
#import "GRWebService.h"

#import "TestFlight.h"


// ------------------------------------------------------------------------------------------


@implementation GRAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !APPSTORE
    [TestFlight takeOff:@"fbd248aa-5493-47ee-9487-de4639b10d0b"];
#endif
    
    [self buildAndConfigureMainWindow];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[GRWebService shared] parseXML];
    });

    return YES;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Build and configure
// ------------------------------------------------------------------------------------------
- (void)buildAndConfigureMainWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    self.viewController = [[GRViewController alloc] initWithNibName:@"GRViewController" bundle:nil];
    
    self.menuNavigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:self.viewController];
    self.menuNavigationController.navigationBarHidden = YES;
    self.window.rootViewController = self.menuNavigationController;

    [self.window makeKeyAndVisible];
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
