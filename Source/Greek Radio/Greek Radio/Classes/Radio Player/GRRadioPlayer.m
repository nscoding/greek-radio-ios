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
    [audioStreamer removeObserver:self forKeyPath:@"isPlaying"];
    [audioStreamer stop];
}


- (BOOL)isPlaying
{
    if (audioStreamer)
    {
        return audioStreamer.isPlaying;
    }
    
    return NO;
}


@end
