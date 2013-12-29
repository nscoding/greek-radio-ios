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
    if ([UIDevice isFlatUI])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.757f
                                                                      green:0.533f
                                                                       blue:0.286f
                                                                      alpha:1.00f]];
        
        [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                [UIColor whiteColor], UITextAttributeTextColor,
                                [UIFont boldSystemFontOfSize:16.0f], UITextAttributeFont,
                                [UIColor darkGrayColor], UITextAttributeTextShadowColor,
                                [NSValue valueWithCGSize:CGSizeMake(0.0, -1.0)], UITextAttributeTextShadowOffset,
                                                  nil]
                                                    forState:UIControlStateNormal];

    }
    else
    {
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"GRWoodHeader06"]
                                           forBarMetrics:UIBarMetricsDefault];
    }
    
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:2
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
