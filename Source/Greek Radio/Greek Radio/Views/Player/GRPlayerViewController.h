//
//  GRPlayerViewController.h
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStation.h"

#import <MessageUI/MessageUI.h>

@interface GRPlayerViewController : UIViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, assign) IBOutlet UIButton *favouriteButton;
@property (nonatomic, assign) IBOutlet UIButton *playButton;
@property (nonatomic, assign) IBOutlet UIView *bottomBar;

@property (nonatomic, weak) GRStation *currentStation;

- (id)initWithStation:(GRStation *)station
         previousView:(UIView *)preView;

- (IBAction)markStationAsFavourite:(id)sender;
- (IBAction)playOrPause:(id)sender;
- (IBAction)shareButtonPressed:(UIButton *)sender;

@end
