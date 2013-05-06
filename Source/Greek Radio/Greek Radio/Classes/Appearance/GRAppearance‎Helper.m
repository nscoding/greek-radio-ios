//
//  GRAppearance‎Helper.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAppearanceHelper.h"
#import <MediaPlayer/MediaPlayer.h>

// ------------------------------------------------------------------------------------------


@implementation GRAppearanceHelper


+ (void)setUpGreekRadioAppearance
{
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"GRWoodHeader"]
                                       forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:-1
                                                       forBarMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                           [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8], UITextAttributeTextShadowColor,
                                                           [NSValue valueWithUIOffset:UIOffsetMake(0, 1)], UITextAttributeTextShadowOffset,
                                                           [UIFont fontWithName:@"HelveticaNeue-Bold" size:21.0], UITextAttributeFont, nil]];
    
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
