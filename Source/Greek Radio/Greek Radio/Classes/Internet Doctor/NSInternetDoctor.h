//
//  NSInternetDoctor.h
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "Reachability.h"

@interface NSInternetDoctor : NSObject

@property (nonatomic, assign) BOOL connected;

+ (NSInternetDoctor *)shared;

- (void)showNoInternetAlert;


@end
