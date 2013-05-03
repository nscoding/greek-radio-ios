//
//  GRShareHelper.h
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


#define kSorryTitle @"Sorry"
#define kAppiTunesURL @"https://itunes.apple.com/app/id321094050?ls=1&mt=8"
#define kTextNoStation @"I am listening to Greek music on my iPhone using Greek Radio"
#define kTextWithStation @"I am listening to %@ using Greek Radio"
#define kErrorTwitter @"You can't send a tweet right now, please make sure your device has at least one Twitter account setup"
#define kErrorFacebook @"You can't update your status right now, please make sure your device has at least one Facebook account setup"


@interface GRShareHelper : NSObject

+ (void)tweetTappedOnController:(UIViewController *)controller;
+ (void)facebookTappedOnController:(UIViewController *)controller;

@end
