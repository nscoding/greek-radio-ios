//
//  GRStationCellView.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


@interface GRStationCellView : UITableViewCell

@property (nonatomic, assign) IBOutlet UILabel *title;
@property (nonatomic, assign) IBOutlet UILabel *subtitle;

+ (NSString *)reusableIdentifier;

@end
