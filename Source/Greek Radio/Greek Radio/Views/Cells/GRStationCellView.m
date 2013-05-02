
//
//  GRStationCellView.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStationCellView.h"


// ------------------------------------------------------------------------------------------


@interface GRStationCellView()

@property (nonatomic, strong) UIView *selectionColor;

@end


// ------------------------------------------------------------------------------------------


@implementation GRStationCellView

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
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
        
        self.genreBadgeView = [[JSBadgeView alloc] initWithParentView:self
                                                            alignment:JSBadgeViewAlignmentCenterRight];

        self.genreBadgeView.badgeBackgroundColor = [UIColor colorWithRed:0.529f green:0.522f blue:0.482f alpha:1.00f];
        self.genreBadgeView.badgeText = [NSString stringWithFormat:@"..."];
    }

    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted)
    {
        self.selectionColor = [[UIView alloc] init];
        self.selectionColor.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - 2);
        self.selectionColor.backgroundColor = [UIColor colorWithRed:0.614f green:0.635f blue:0.619f alpha:0.40];
        [self.backgroundView addSubview:self.selectionColor];
    }
    else
    {
        
        [UIView animateWithDuration:0.4 animations:^{
            self.selectionColor.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.selectionColor removeFromSuperview];
        }];
    }
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
