//
//  GRStationCellView.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "JSBadgeView.h"
#import "GRStation.h"


@protocol GRStationCellViewDelegate <NSObject>

- (void)userDidDoubleTapOnGenre:(NSString *)genre;

@end


@interface GRStationCellView : UITableViewCell

@property (nonatomic, assign) IBOutlet UILabel *title;
@property (nonatomic, assign) IBOutlet UILabel *subtitle;
@property (nonatomic, weak) GRStation *station;
@property (nonatomic, weak) id<GRStationCellViewDelegate> delegate;

- (void)setBadgeText:(NSString *)badgeText;
+ (NSString *)reusableIdentifier;

@end
