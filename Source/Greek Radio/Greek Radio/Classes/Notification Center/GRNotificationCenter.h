//
//  GRNotificationCenter.h
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


extern NSString *const GRNotificationSyncManagerDidStart;
extern NSString *const GRNotificationSyncManagerDidEnd;

@interface GRNotificationCenter : NSObject

+ (void)postNotificationOnMainThread:(NSNotification *)notification;

+ (void)postSyncManagerDidStartNotificationWithSender:(id)sender;
+ (void)postSyncManagerDidEndNotificationWithSender:(id)sender;

@end
