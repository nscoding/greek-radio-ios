//
//  GRAppDelegate.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GRViewController;

@interface GRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) GRViewController *viewController;
@property (strong, nonatomic) UINavigationController *menuNavigationController;

@end
