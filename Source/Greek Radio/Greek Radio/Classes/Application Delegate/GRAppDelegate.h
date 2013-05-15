//
//  GRAppDelegate.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "JASidePanelController.h"

@class GRSplashViewController;
@class GRListTableViewController;

@interface GRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) GRListTableViewController *listTableViewController;
@property (strong, nonatomic) GRSplashViewController *splashViewController;
@property (strong, nonatomic) UINavigationController *menuNavigationController;
@property (strong, nonatomic) JASidePanelController *viewController;

@end
