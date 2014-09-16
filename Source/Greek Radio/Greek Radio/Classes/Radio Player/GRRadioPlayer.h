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

+ (GRRadioPlayer *)shared;

- (void)playStation:(GRStation *)station;

- (void)stopPlayingStation;

- (BOOL)isPlaying;

@end
