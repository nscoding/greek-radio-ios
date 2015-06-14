//
//  GRStationCellView.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStation.h"

@interface GRStationCellView : UITableViewCell

@property (nonatomic, weak) GRStation *station;
@property (nonatomic, assign, getter=isShowingDivider) BOOL showDivider;

+ (NSString *)reusableIdentifier;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

