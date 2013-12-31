//
//  GRPlayerViewController.h
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStation.h"

@class GRPlayerViewController;

@protocol GRPlayerViewControllerDelegate <NSObject>

- (void)playerViewControllerPlayNextStation:(GRPlayerViewController *)playViewController;

- (void)playerViewControllerPlayPreviousStation:(GRPlayerViewController *)playViewControllerl;

@end


@interface GRPlayerViewController : UIViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UILabel *stationLabel;
@property (nonatomic, strong) UILabel *genreLabel;
@property (nonatomic, assign) IBOutlet UITableView *playerTableView;

- (id)initWithStation:(GRStation *)station
             delegate:(id<GRPlayerViewControllerDelegate>)delegate
         previousView:(UIView *)preView;

@end
