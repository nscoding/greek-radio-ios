//
//  NSInternetDoctor.m
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "NSInternetDoctor.h"


// ------------------------------------------------------------------------------------------


#define kPingServerNSCoding @"www.nscoding.co.uk"


// ------------------------------------------------------------------------------------------


@interface NSInternetDoctor()

@property (nonatomic, strong) Reachability *nscodingReachability;

@end


@implementation NSInternetDoctor


+ (NSInternetDoctor *)shared
{
    static dispatch_once_t pred;
    static NSInternetDoctor *shared = nil;
    
    dispatch_once(&pred, ^()
                  {
                      shared = [[NSInternetDoctor alloc] init];
                      [shared buildAndConfigure];
                  });
    
    return shared;
}



// ------------------------------------------------------------------------------------------
#pragma mark - Build and Configure
// ------------------------------------------------------------------------------------------
- (void)buildAndConfigure
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    self.connected = YES;
    
    [self pingNSCoding];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Ping
// ------------------------------------------------------------------------------------------
-(void)pingNSCoding
{
    self.nscodingReachability = [Reachability reachabilityWithHostname:kPingServerNSCoding];
    
    __weak NSInternetDoctor *blockSelf = self;
    
    self.nscodingReachability.reachableBlock = ^(Reachability *reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            blockSelf.connected = YES;
        });
    };
    
    self.nscodingReachability.unreachableBlock = ^(Reachability *reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            blockSelf.connected = NO;
        });
    };
    
    [self.nscodingReachability startNotifier];
}



// ------------------------------------------------------------------------------------------
#pragma mark - Reachability notifications
// ------------------------------------------------------------------------------------------
-(void)reachabilityChanged:(NSNotification*)notification
{
    Reachability *reach = [notification object];
    if (reach == self.nscodingReachability)
    {
        self.connected = [reach isReachable];
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Alert panel
// ------------------------------------------------------------------------------------------
- (void)showNoInternetAlert
{
    [BlockAlertView showInfoAlertWithTitle:NSLocalizedString(@"app_no_internet_title", @"")
                                   message:NSLocalizedString(@"app_no_internet_subtitle", @"")];

    [self.nscodingReachability stopNotifier];
    [self.nscodingReachability startNotifier];
}


@end
