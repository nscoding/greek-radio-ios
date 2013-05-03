//
//  GRRadioPlayer.m
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRRadioPlayer.h"


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
                  });
    
    return shared;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Build and Configure
// ------------------------------------------------------------------------------------------
- (void)playStation:(NSString *)aStationName
      withStreamURL:(NSString *)aStreamURL
{
    if ([self.streamURL isEqualToString:aStreamURL] == NO)
    {
        [self stopPlayingStation];
    }
    
    if (audioStreamer.isPlaying)
    {
        return;
    }
    else
    {
        [self stopPlayingStation];
    }
    
    NSURL *url = [NSURL URLWithString:aStreamURL];
    audioStreamer = [[AudioStreamer alloc] initWithURL:url];
    audioStreamer.delegate = self;
    [audioStreamer start];
    
    self.streamURL = [NSString stringWithFormat:@"%@",aStreamURL];
    self.stationName = [NSString stringWithFormat:@"%@",aStationName];
}


- (void)streamerStatusDidChange
{
    if ([audioStreamer isPlaying])
    {
        [GRNotificationCenter postPlayerDidStartNotificationWithSender:nil];
    }
    else
    {
        [GRNotificationCenter postPlayerDidEndNotificationWithSender:nil];
        audioStreamer = nil;
    }
}


- (void)stopPlayingStation
{
    self.stationName = @"";
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
    
    NSLog(@"Application entered background state.");
    
	NSAssert(backgroundOperation == UIBackgroundTaskInvalid, nil);
	backgroundOperation = [application beginBackgroundTaskWithExpirationHandler:^{
        // Synchronize the cleanup call on the main thread in case
        // the task actually finishes at around the same time.
		dispatch_async(dispatch_get_main_queue(), ^{
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
}


@end
