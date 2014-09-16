//
//  GRRadioPlayer.h
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStation.h"

@interface GRRadioPlayer : NSObject

@property (nonatomic, strong) NSString *stationName;
@property (nonatomic, strong) NSString *streamURL;
@property (nonatomic, weak) GRStation *currentStation;

/// Singleton
+ (GRRadioPlayer *)shared;

/// Method to start the playback for a given station
- (void)playStation:(GRStation *)station;

/// Method to stop the playback
- (void)stopPlayingStation;

/// Method to check if the player is currently playing.
- (BOOL)isPlaying;

@end
