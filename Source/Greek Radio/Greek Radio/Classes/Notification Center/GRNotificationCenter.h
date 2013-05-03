//
//  GRNotificationCenter.h
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


extern NSString *const GRNotificationSyncManagerDidStart;
extern NSString *const GRNotificationSyncManagerDidEnd;

extern NSString *const GRNotificationStreamDidStart;
extern NSString *const GRNotificationStreamDidEnd;

@interface GRNotificationCenter : NSObject

+ (void)postNotificationOnMainThread:(NSNotification *)notification;

+ (void)postSyncManagerDidStartNotificationWithSender:(id)sender;
+ (void)postSyncManagerDidEndNotificationWithSender:(id)sender;

+ (void)postPlayerDidStartNotificationWithSender:(id)sender;
+ (void)postPlayerDidEndNotificationWithSender:(id)sender;

@end
