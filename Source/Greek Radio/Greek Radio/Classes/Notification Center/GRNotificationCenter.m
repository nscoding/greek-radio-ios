//
//  GRNotificationCenter.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRNotificationCenter.h"

NSString *const GRNotificationSyncManagerDidStart = @"GRNotificationSyncManagerDidStart";
NSString *const GRNotificationSyncManagerDidEnd = @"GRNotificationSyncManagerDidEnd";
NSString *const GRNotificationStreamDidStart = @"GRNotificationStreamDidStart";
NSString *const GRNotificationStreamDidEnd = @"GRNotificationStreamDidEnd";


@implementation GRNotificationCenter

+ (void)postNotificationOnMainThread:(NSNotification *)notification
{
    @try {
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    } @catch (NSException *exception) {
        DLog(@"postNotifcationOnMainThread failed: %@, %@", exception.name, exception.userInfo);
    }
}

+ (void)postSyncManagerDidStartNotificationWithSender:(id)sender
{
    NSNotification *notification = [NSNotification notificationWithName:GRNotificationSyncManagerDidStart
                                                                 object:sender
                                                               userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                           withObject:notification
                                                        waitUntilDone:NO];
}

+ (void)postSyncManagerDidEndNotificationWithSender:(id)sender
{
    NSNotification *notification = [NSNotification notificationWithName:GRNotificationSyncManagerDidEnd
                                                                 object:sender
                                                               userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                           withObject:notification
                                                        waitUntilDone:NO];
}

+ (void)postPlayerDidStartNotificationWithSender:(id)sender
{
    NSNotification *notification = [NSNotification notificationWithName:GRNotificationStreamDidStart
                                                                 object:sender
                                                               userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                           withObject:notification
                                                        waitUntilDone:NO];
}

+ (void)postPlayerDidEndNotificationWithSender:(id)sender
{
    NSNotification *notification = [NSNotification notificationWithName:GRNotificationStreamDidEnd
                                                                 object:sender
                                                               userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                           withObject:notification
                                                        waitUntilDone:NO];
}

@end
