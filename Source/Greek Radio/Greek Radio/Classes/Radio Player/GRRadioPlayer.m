//
//  GRRadioPlayer.m
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRRadioPlayer.h"


// ------------------------------------------------------------------------------------------


@interface GRRadioPlayer()
{
    AudioStreamer *audioStreamer;
    UIBackgroundTaskIdentifier backgroundOperation;
    BOOL wasPlaying;
    BOOL wentBackground;
}

@end


// ------------------------------------------------------------------------------------------


@implementation GRRadioPlayer

+ (GRRadioPlayer *)shared
{
    static dispatch_once_t pred;
    static GRRadioPlayer *shared = nil;
    
    dispatch_once(&pred, ^()
    {
      shared = [[GRRadioPlayer alloc] init];
      
      [[NSNotificationCenter defaultCenter] addObserver:shared
                                               selector:@selector(applicationDidEnterBackground:)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];

      [[NSNotificationCenter defaultCenter] addObserver:shared
                                               selector:@selector(applicationDidBecomeActive:)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
      
      [[NSNotificationCenter defaultCenter] addObserver:shared
                                               selector:@selector(applicationWillResignActive:)
                                                   name:UIApplicationWillResignActiveNotification
                                                 object:nil];
    });
    
    return shared;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Build and Configure
// ------------------------------------------------------------------------------------------
- (void)playStation:(GRStation *)station
{
    if ([[NSInternetDoctor shared] connected] == NO)
    {
        [self stopPlayingStation];
        [[NSInternetDoctor shared] showNoInternetAlert];
        [GRNotificationCenter postPlayerDidEndNotificationWithSender:nil];
        
        return;
    }

    if ([self.streamURL isEqualToString:station.streamURL] == NO)
    {
        [self stopPlayingStation];
    }
    
    if (audioStreamer)
    {
        return;
    }

    [audioStreamer stop];
    audioStreamer = nil;
    
    self.currentStation = station;
    self.streamURL = [NSString stringWithFormat:@"%@",self.currentStation.streamURL];
    self.stationName = [NSString stringWithFormat:@"%@",self.currentStation.title];

    NSURL *url = [NSURL URLWithString:self.streamURL];
    audioStreamer = [[AudioStreamer alloc] initWithURL:url];
    audioStreamer.delegate = self;
    [audioStreamer start];
    audioStreamer.isPlaying = YES;
    
    [GRNotificationCenter postPlayerDidStartNotificationWithSender:nil];
}


- (void)streamerStatusDidChange
{
    if ([audioStreamer isPlaying])
    {
        [GRNotificationCenter postPlayerDidStartNotificationWithSender:nil];
    }
    else
    {
        [self stopPlayingStation];
    }
}


- (void)stopPlayingStation
{
    [GRNotificationCenter postPlayerDidEndNotificationWithSender:nil];

    self.currentStation = nil;
    self.stationName = @"";
    self.streamURL = @"";

    [audioStreamer stop];
    audioStreamer = nil;
}


- (BOOL)isPlaying
{
    if (audioStreamer)
    {
        return audioStreamer.isPlaying;
    }
    
    return NO;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Multitasking
// ------------------------------------------------------------------------------------------
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    // Request permission to run in the background. Provide an
    // expiration handler in case the task runs long.
    UIApplication *application = [notification object];
    wentBackground = YES;
    
    DLog(@"Application entered background state.");
    
	NSAssert(backgroundOperation == UIBackgroundTaskInvalid, nil);
	backgroundOperation = [application beginBackgroundTaskWithExpirationHandler:^{
        // Synchronize the cleanup call on the main thread in case
        // the task actually finishes at around the same time.
		dispatch_async(dispatch_get_main_queue(), ^
        {
			if (backgroundOperation != UIBackgroundTaskInvalid)
			{
				[application endBackgroundTask:backgroundOperation];
				backgroundOperation = UIBackgroundTaskInvalid;
			}
		});
	}];
}


- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    UIApplication *application = [notification object];
	[application endBackgroundTask:self->backgroundOperation];
	self->backgroundOperation = UIBackgroundTaskInvalid;
    
    if (wasPlaying && wentBackground == NO)
    {
        GRStation *currentStation = self.currentStation;
        [self stopPlayingStation];
        [self playStation:currentStation];
    }
    
    wentBackground = NO;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    wasPlaying = audioStreamer.isPlaying;
}


@end
