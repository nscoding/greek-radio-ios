//
//  GRPlayerViewController.h
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStation.h"

@interface GRPlayerViewController : UIViewController

@property (nonatomic, assign) IBOutlet UIButton *favouriteButton;
@property (nonatomic, assign) IBOutlet UIButton *playButton;
@property (nonatomic, weak) GRStation *currentStation;

- (id)initWithStation:(GRStation *)station;
- (IBAction)markStationAsFavourite:(id)sender;
- (IBAction)playOrPause:(id)sender;

@end
