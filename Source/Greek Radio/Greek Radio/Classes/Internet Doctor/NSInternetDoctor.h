//
//  NSInternetDoctor.h
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


@interface NSInternetDoctor : NSObject

@property (nonatomic, assign, getter: isConnected) BOOL connected;

/// Signleton
+ (NSInternetDoctor *)shared;

/// Method to show the no internet alert
- (void)showNoInternetAlert;

@end
