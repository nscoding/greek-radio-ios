
//
//  GRStationCellView.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStationCellView.h"

@implementation GRStationCellView

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        [[NSBundle mainBundle] loadNibNamed:@"GRStationCellView" owner:self options:nil];
        [self addSubview:self.backgroundView];
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        self.title.textColor = [UIColor colorWithRed:0.153f green:0.075f blue:0.024f alpha:1.00f];
        self.title.shadowColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        self.title.shadowOffset = CGSizeMake(0, 1);
        self.title.textAlignment = NSTextAlignmentLeft;
        self.title.numberOfLines = 1;

        self.subtitle.textColor = [UIColor colorWithRed:0.153f green:0.075f blue:0.024f alpha:1.00f];
        self.subtitle.shadowColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        self.subtitle.shadowOffset = CGSizeMake(0, 1);
        self.subtitle.textAlignment = NSTextAlignmentLeft;
        self.subtitle.numberOfLines = 1;
    }

    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}


+ (NSString *)reusableIdentifier
{
    return @"GRStationCellView";
}


@end
