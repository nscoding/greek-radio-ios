//
//  GRUserDefaults.m
//  Greek Radio
//
//  Created by Patrick Chamelo on 31/12/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRUserDefaults.h"


// ------------------------------------------------------------------------------------------


NSString *const GreekRadioAutoLockDisabled    = @"GreekRadioAutoLockDisabled";
NSString *const GreekRadioShakeRandom         = @"GreekRadioShakeRandom";
NSString *const GreekRadioSearchScope         = @"GreekRadioSearchScope";


// ------------------------------------------------------------------------------------------


@implementation GRUserDefaults


+ (BOOL)isAutomaticLockDisabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:GreekRadioAutoLockDisabled];
}


+ (void)setAutomaticLockDisabled:(BOOL)disabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:disabled forKey:GreekRadioAutoLockDisabled];
    [userDefaults synchronize];
    [UIApplication sharedApplication].idleTimerDisabled = disabled;
}


+ (BOOL)isShakeForRandomStationEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:GreekRadioShakeRandom];
}


+ (void)setShakeForRandomStationEnabled:(BOOL)enabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:enabled forKey:GreekRadioShakeRandom];
    [userDefaults synchronize];
}


+ (NSUInteger)currentSearchScope
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [[userDefaults valueForKey:GreekRadioSearchScope] integerValue];
}


+ (void)setCurrentSearchScope:(NSInteger)searchScope
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:@(searchScope) forKey:GreekRadioSearchScope];
    [userDefaults synchronize];
}


@end
