//
//  GRRadioPlayer.h
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStation.h"

@interface GRRadioPlayer : NSObject

@property (nonatomic, strong, readonly) NSString *stationName;
@property (nonatomic, strong, readonly) NSString *streamURL;
@property (nonatomic, weak, readonly) GRStation *currentStation;

/// Singleton
+ (GRRadioPlayer *)shared;

/// Method to start the playback for a given station
- (void)playStation:(GRStation *)station;

/// Method to stop the playback
- (void)stopPlayingCurrentStation;

/// Method to check if the player is currently playing.
- (BOOL)isPlaying;

@end
