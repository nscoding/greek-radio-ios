//
//  GRRadioPlayer.h
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "AudioStreamer.h"

@interface GRRadioPlayer : NSObject <AudioStreamerDelegate>
{
    AudioStreamer *audioStreamer;
    UIBackgroundTaskIdentifier backgroundOperation;
    BOOL wasPlaying;
    BOOL wentBackground;
}

@property (nonatomic, strong) NSString *stationName;
@property (nonatomic, strong) NSString *streamURL;

+ (GRRadioPlayer *)shared;

- (void)playStation:(NSString *)aStationName
      withStreamURL:(NSString *)aStreamURL;

- (void)stopPlayingStation;
- (BOOL)isPlaying;

@end
