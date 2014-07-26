//
//  GRUserDefaults.h
//  Greek Radio
//
//  Created by Patrick Chamelo on 31/12/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


// ------------------------------------------------------------------------------------------


@interface GRUserDefaults : NSObject

/// Method to check if the automatic lock is disabled
+ (BOOL)isAutomaticLockDisabled;
+ (void)setAutomaticLockDisabled:(BOOL)disabled;

/// Method to check if the shake for shuffle is enabled
+ (BOOL)isShakeForRandomStationEnabled;
+ (void)setShakeForRandomStationEnabled:(BOOL)enabled;

/// Method to remember the last selected search scope
+ (NSUInteger)currentSearchScope;
+ (void)setCurrentSearchScope:(NSInteger)searchScope;

@end
