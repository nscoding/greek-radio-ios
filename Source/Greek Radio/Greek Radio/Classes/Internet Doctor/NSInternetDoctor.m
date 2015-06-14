//
//  NSInternetDoctor.m
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "NSInternetDoctor.h"

#import "Reachability.h"

static NSString *kServerURL = @"www.nscoding.co.uk";

@interface NSInternetDoctor()

@property (nonatomic, strong) Reachability *nscodingReachability;

@end

@implementation NSInternetDoctor

#pragma mark - Singleton

+ (NSInternetDoctor *)shared
{
    static dispatch_once_t pred;
    static NSInternetDoctor *shared = nil;
    
    dispatch_once(&pred, ^() {
        shared = [[NSInternetDoctor alloc] init];
    });
    
    return shared;
}

#pragma mark - Initializer

- (instancetype)init
{
    if (self = [super init]) {
        _connected = YES;
        [self registerObservers];
        [self pingNSCoding];
    }
    
    return self;
}

#pragma mark - Build and Configure

- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *reach = [notification object];
    if (reach == self.nscodingReachability)
    {
        self.connected = [reach isReachable];
    }
}

#pragma mark - Ping

- (void)pingNSCoding
{
    self.nscodingReachability = [Reachability reachabilityWithHostname:kServerURL];
    
    WEAKIFY(self);
    self.nscodingReachability.reachableBlock = ^(Reachability *reachability) {
        STRONGIFY(self);
        self.connected = YES;
    };
    
    self.nscodingReachability.unreachableBlock = ^(Reachability *reachability) {
        STRONGIFY(self);
        self.connected = NO;
    };
    
    [self.nscodingReachability startNotifier];
}

#pragma mark - Exposed Method

- (void)showNoInternetAlert
{
    [UIAlertView showWithTitle:NSLocalizedString(@"app_no_internet_title", @"")
                       message:NSLocalizedString(@"app_no_internet_subtitle", @"")
             cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
             otherButtonTitles:nil
                      tapBlock:nil];

    [self.nscodingReachability stopNotifier];
    [self.nscodingReachability startNotifier];
}

@end
