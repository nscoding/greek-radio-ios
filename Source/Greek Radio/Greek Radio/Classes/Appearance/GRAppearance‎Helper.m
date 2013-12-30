//
//  GRAppearance‎Helper.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAppearanceHelper.h"
#import "UIDevice+Extensions.h"

#import <MediaPlayer/MediaPlayer.h>

// ------------------------------------------------------------------------------------------


@implementation GRAppearanceHelper


+ (void)setUpGreekRadioAppearance
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.757f
                                                                  green:0.533f
                                                                   blue:0.286f
                                                                  alpha:1.00f]];
    
    UIColor *textColor = [UIColor colorWithRed:0.929f green:0.932f blue:0.881f alpha:1.00f];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(0, 1);

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                            NSForegroundColorAttributeName : textColor,
                                                            NSFontAttributeName : [UIFont boldSystemFontOfSize:16.0f],
                                                            NSShadowAttributeName : shadow
                                                           }
                                                forState:UIControlStateNormal];

    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:2
                                                       forBarMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName : textColor,
                                                           NSFontAttributeName : [UIFont boldSystemFontOfSize:21.0f],
                                                           NSShadowAttributeName : shadow
                                                           }];
    
    // Set the slider track images
	[[UISlider appearanceWhenContainedIn:[MPVolumeView class], nil]
                    setMinimumTrackImage:[[UIImage imageNamed:@"GRTrackFill"]
             resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 0)]
                                forState:UIControlStateNormal];
	
	[[UISlider appearanceWhenContainedIn:[MPVolumeView class], nil]
                    setMaximumTrackImage:[[UIImage imageNamed:@"GRTrackEmpty"]
             resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 6)]
                                forState:UIControlStateNormal];
    
    [[UISlider appearanceWhenContainedIn:[MPVolumeView class], nil]
                           setThumbImage:[UIImage imageNamed:@"GRKnobBase"]
                                forState:UIControlStateNormal];
}


+ (void)setUpDefaultAppearance
{
    [[UINavigationBar appearance] setBackgroundImage:nil
                                       forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:nil];
}


@end
