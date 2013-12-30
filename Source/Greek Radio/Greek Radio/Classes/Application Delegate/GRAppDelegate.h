//
//  GRAppDelegate.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRNavigationController.h"

@class GRSplashViewController;
@class GRStationsTableViewController;

@interface GRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) GRStationsTableViewController *listTableViewController;
@property (strong, nonatomic) GRSplashViewController *splashViewController;
@property (strong, nonatomic) GRNavigationController *menuNavigationController;

@end
