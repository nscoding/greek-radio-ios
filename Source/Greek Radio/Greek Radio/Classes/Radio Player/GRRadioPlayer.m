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
- (void)playStationWithStreamURL:(NSString *)streamURL
{
    if ([currentStreamURL isEqualToString:streamURL] == NO)
    {
        [audioStreamer removeObserver:self forKeyPath:@"isPlaying"];
        [audioStreamer stop];
        audioStreamer = nil;
    }
    
    NSURL *url = [NSURL URLWithString:streamURL];
    audioStreamer = [[AudioStreamer alloc] initWithURL:url];
    [audioStreamer addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
    [audioStreamer start];
    
    currentStreamURL = [NSString stringWithFormat:@"%@",streamURL];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if ([keyPath isEqual:@"isPlaying"])
	{
		if ([(AudioStreamer *)object isPlaying])
		{
            [GRNotificationCenter postPlayerDidStartNotificationWithSender:nil];
		}
		else
		{
            [GRNotificationCenter postPlayerDidEndNotificationWithSender:nil];

			[audioStreamer removeObserver:self forKeyPath:@"isPlaying"];
			audioStreamer = nil;
		}
        
        return;
	}
	
	[super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
						  context:context];
}


- (void)stopPlayingStation
{
    [audioStreamer stop];
    [audioStreamer removeObserver:self forKeyPath:@"isPlaying"];
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
	
		
    // Start the long-running task and return immediately.
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    
        // Do the work associated with the task.
        // Synchronize the cleanup call on the main thread in case
        // the expiration handler is fired at the same time.
		dispatch_async(dispatch_get_main_queue(), ^{
			
            if (audioStreamer != nil)
            {
                [audioStreamer addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
                [audioStreamer start];
            }            
        });
	});
}


- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    UIApplication *application = [notification object];
	[application endBackgroundTask:self->backgroundOperation];
	self->backgroundOperation = UIBackgroundTaskInvalid;
}



@end
