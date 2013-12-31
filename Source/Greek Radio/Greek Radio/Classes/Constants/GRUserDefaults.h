//
//  GRUserDefaults.h
//  Greek Radio
//
//  Created by Patrick Chamelo on 31/12/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


// ------------------------------------------------------------------------------------------


@interface GRUserDefaults : NSObject

+ (BOOL)isAutomaticLockDisabled;
+ (void)setAutomaticLockDisabled:(BOOL)disabled;

+ (BOOL)isShakeForRandomStationEnabled;
+ (void)setShakeForRandomStationEnabled:(BOOL)enabled;

+ (NSUInteger)currentSearchScope;
+ (void)setCurrentSearchScope:(NSInteger)searchScope;

@end
