//
//  GRAppearance‎Helper.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAppearanceHelper.h"

@implementation GRAppearanceHelper


+ (void)setUpGreekRadioAppearance
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.757f green:0.533f blue:0.286f alpha:1.00f]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:1.0f forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:[self customNavigationBarAttributes]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[self customBarButtonItemAttributes]
                                                forState:UIControlStateNormal];
}


+ (void)setUpDefaultAppearance
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:[self defaultNavigationBarAttributes]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[self defaultBarButtonItemAttributes]
                                                forState:UIControlStateNormal];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Attributes
// ------------------------------------------------------------------------------------------
+ (NSDictionary *)customBarButtonItemAttributes
{
    UIColor *textColor = [UIColor colorWithRed:0.929f green:0.932f blue:0.881f alpha:1.00f];
    
    return @{
             NSForegroundColorAttributeName : textColor,
             NSFontAttributeName : [UIFont systemFontOfSize:18.0f]
            };
}


+ (NSDictionary *)customNavigationBarAttributes
{
    UIColor *textColor = [UIColor colorWithRed:0.929f green:0.932f blue:0.881f alpha:1.00f];
    
    return @{
             NSForegroundColorAttributeName : textColor,
             NSFontAttributeName : [UIFont boldSystemFontOfSize:18.0f]
            };
}


+ (NSDictionary *)defaultBarButtonItemAttributes
{
    return @{
             NSForegroundColorAttributeName : [UIColor blackColor],
             NSFontAttributeName : [UIFont boldSystemFontOfSize:13.0f],
            };
}


+ (NSDictionary *)defaultNavigationBarAttributes
{
    return @{
             NSForegroundColorAttributeName : [UIColor blackColor],
             NSFontAttributeName : [UIFont boldSystemFontOfSize:21.0f],
            };
}


@end
