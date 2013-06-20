//
//  GRShareHelper.h
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


#define kAppiTunesURL @"https://itunes.apple.com/app/id321094050?ls=1&mt=8"

@interface GRShareHelper : NSObject

+ (void)tweetTappedOnController:(UIViewController *)controller;
+ (void)facebookTappedOnController:(UIViewController *)controller;

@end
