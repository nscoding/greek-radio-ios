//
//  GRRadioPlayer.m
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRRadioPlayer.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>


// ------------------------------------------------------------------------------------------


@interface GRRadioPlayer()

@property (nonatomic, strong) AVAudioSession *streamSession;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundOperation;

@end


// ------------------------------------------------------------------------------------------


@implementation GRRadioPlayer


// ------------------------------------------------------------------------------------------
#pragma mark - Singleton
// ------------------------------------------------------------------------------------------
+ (GRRadioPlayer *)shared
{
    static dispatch_once_t pred;
    static GRRadioPlayer *shared = nil;
    
    dispatch_once(&pred, ^()
    {
      shared = [[GRRadioPlayer alloc] init];
    });
    
    return shared;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Initializer
// ------------------------------------------------------------------------------------------
- (instancetype)init
{
    if ((self = [super init]))
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    
    return self;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Notifications
// ------------------------------------------------------------------------------------------
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    // Request permission to run in the background. Provide an
    // expiration handler in case the task runs long.
    UIApplication *application = [notification object];
    
    NSAssert(self.backgroundOperation == UIBackgroundTaskInvalid, nil);
    self.backgroundOperation = [application beginBackgroundTaskWithExpirationHandler:^{
        // Synchronize the cleanup call on the main thread in case
        // the task actually finishes at around the same time.
        dispatch_async(dispatch_get_main_queue(), ^
        {
            if (self.backgroundOperation != UIBackgroundTaskInvalid)
            {
                [application endBackgroundTask:self.backgroundOperation];
                self.backgroundOperation = UIBackgroundTaskInvalid;
            }
        });
    }];
}


- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    UIApplication *application = [notification object];
    [application endBackgroundTask:self.backgroundOperation];
    self.backgroundOperation = UIBackgroundTaskInvalid;
}


// ------------------------------------------------------------------------------------------
#pragma mark - KVO
// ------------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.player && [keyPath isEqualToString:NSStringFromSelector(@selector(rate))])
    {
        if (self.isPlaying)
        {
            [GRNotificationCenter postPlayerDidStartNotificationWithSender:nil];
        }
        else
        {
            [self stopPlayingCurrentStation];
        }
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Exposed Methods
// ------------------------------------------------------------------------------------------
- (void)playStation:(GRStation *)station
{
    if ([[NSInternetDoctor shared] isConnected])
    {
        if ([self.streamURL isEqualToString:station.streamURL] == NO)
        {
            [self stopPlayingCurrentStation];
        }
        
        if (self.player)
        {
            return;
        }
        
        [self tearDownPlayer];
        [self createPlayerForStation:station];
    }
    else
    {
        [self stopPlayingCurrentStation];
        [[NSInternetDoctor shared] showNoInternetAlert];
        [GRNotificationCenter postPlayerDidEndNotificationWithSender:nil];
    }
}


- (void)stopPlayingCurrentStation
{
    self.currentStation = nil;
    self.stationName = @"";
    self.streamURL = @"";
    
    [self tearDownPlayer];
}


- (BOOL)isPlaying
{
    if (self.player && self.player.rate != 0)
    {
        return YES;
    }
    
    return NO;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helper Methods
// ------------------------------------------------------------------------------------------
- (void)createPlayerForStation:(GRStation *)station
{
    self.currentStation = station;
    self.streamURL = [NSString stringWithFormat:@"%@", self.currentStation.streamURL];
    self.stationName = [NSString stringWithFormat:@"%@", self.currentStation.title];
    
    self.streamSession = [AVAudioSession sharedInstance];
    [self.streamSession setCategory:AVAudioSessionCategoryPlayAndRecord
                        withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                              error:nil];
    
    [self.streamSession setActive:YES error:nil];
    
    NSURL *url = [NSURL URLWithString:self.streamURL];
    self.player = [[AVPlayer alloc] initWithURL:url];
    [self.player addObserver:self forKeyPath:NSStringFromSelector(@selector(rate)) options:0 context:nil];
    [self.player.currentItem addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:0 context:nil];
    [self.player play];

    [GRNotificationCenter postPlayerDidStartNotificationWithSender:nil];
}


- (void)tearDownPlayer
{
    if (self.player)
    {
        [self.player.currentItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
        [self.player removeObserver:self forKeyPath:NSStringFromSelector(@selector(rate))];
        [self.player pause];
        self.player = nil;
    }
    
    [GRNotificationCenter postPlayerDidEndNotificationWithSender:nil];
}


- (void)stationPlaybackFailed
{
    if ([[NSInternetDoctor shared] isConnected])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                                                                message:NSLocalizedString(@"app_player_error_subtitle", @"")
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
                                                      otherButtonTitles:nil];
            [alertView show];
        });
    }
    else
    {
        [[NSInternetDoctor shared] showNoInternetAlert];
    }
    
    [self stopPlayingCurrentStation];
}


@end
