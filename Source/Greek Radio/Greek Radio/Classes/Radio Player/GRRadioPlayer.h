//
//  GRRadioPlayer.h
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "AudioStreamer.h"

@interface GRRadioPlayer : NSObject
{
    NSString *currentStreamURL;
    AudioStreamer *audioStreamer;
}

+ (GRRadioPlayer *)shared;

- (void)playStationWithStreamURL:(NSString *)streamURL;
- (void)stopPlayingStation;
- (BOOL)isPlaying;

@end
