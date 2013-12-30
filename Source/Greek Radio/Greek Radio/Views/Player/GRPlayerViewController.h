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

@property (nonatomic, strong) UILabel *stationLabel;
@property (nonatomic, strong) UILabel *genreLabel;
@property (nonatomic, assign) IBOutlet UITableView *playerTableView;

- (id)initWithStation:(GRStation *)station
         previousView:(UIView *)preView;

@end
