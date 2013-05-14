
//
//  GRStationCellView.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStationCellView.h"
#import "GRRadioPlayer.h"


// ------------------------------------------------------------------------------------------


@interface GRStationCellView()

@property (nonatomic, strong) UIView *selectionColor;
@property (nonatomic, strong) JSBadgeView *genreBadgeView;

@end


// ------------------------------------------------------------------------------------------


@implementation GRStationCellView

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        UIMenuItem *markAsFavorite = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"button_mark_as_favorite", @"")
                                                                action:@selector(markAsFavorite:)];
        
        UIMenuItem *visitStation = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"button_visit_station", @"")
                                                                action:@selector(visitStation:)];

        UIMenuController *menuController = [UIMenuController sharedMenuController];
        menuController.menuItems = [NSArray arrayWithObjects:markAsFavorite, visitStation, nil];

        UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                  action:@selector(onShowMenu:)];
        [self addGestureRecognizer: longGesture];

        [[NSBundle mainBundle] loadNibNamed:@"GRStationCellView" owner:self options:nil];
        [self addSubview:self.backgroundView];
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        self.title.textColor = [UIColor colorWithRed:0.153f green:0.075f blue:0.024f alpha:1.00f];
        self.title.shadowColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        self.title.shadowOffset = CGSizeMake(0, 1);
        self.title.textAlignment = NSTextAlignmentLeft;
        self.title.numberOfLines = 1;

        self.subtitle.textColor = [UIColor colorWithRed:0.153f
                                                  green:0.075f
                                                   blue:0.024f
                                                  alpha:1.00f];
        
        self.subtitle.shadowColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        self.subtitle.shadowOffset = CGSizeMake(0, 1);
        self.subtitle.textAlignment = NSTextAlignmentLeft;
        self.subtitle.numberOfLines = 1;
        
        self.genreBadgeView = [[JSBadgeView alloc] initWithParentView:self
                                                            alignment:JSBadgeViewAlignmentCenterRight];

        self.genreBadgeView.badgeBackgroundColor = [UIColor colorWithRed:0.529f
                                                                   green:0.522f
                                                                    blue:0.482f
                                                                   alpha:1.00f];
        
        self.genreBadgeView.badgeText = [NSString stringWithFormat:@"..."];
    }

    return self;
}


- (BOOL)canBecomeFirstResponder
{
    return YES;
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


- (void)setBadgeText:(NSString *)badgeText
{
    if ([[[GRRadioPlayer shared] stationName] isEqualToString:self.title.text])
    {        
        self.genreBadgeView.badgeBackgroundColor = [UIColor colorWithRed:0.866f green:0.128f blue:0.115f alpha:1.00f];
        self.genreBadgeView.badgeText = [NSString stringWithFormat:NSLocalizedString(@"label_now_playing", @"")];
    }
    else
    {
        self.genreBadgeView.badgeBackgroundColor = [UIColor colorWithRed:0.529f green:0.522f blue:0.482f alpha:1.00f];
        self.genreBadgeView.badgeText = [NSString stringWithFormat:@"%@", badgeText];
    }
    
    
    CGRect titleFrame = self.title.frame;
    self.title.frame = CGRectMake(titleFrame.origin.x,
                                  titleFrame.origin.y,
                                  self.frame.size.width - self.genreBadgeView.sizeOfTextForCurrentSettings.width
                                  - titleFrame.origin.x - 20,
                                  titleFrame.size.height);
    
    CGRect subtitleFrame = self.subtitle.frame;
    self.subtitle.frame = CGRectMake(subtitleFrame.origin.x,
                                     subtitleFrame.origin.y,
                                     self.frame.size.width - self.genreBadgeView.sizeOfTextForCurrentSettings.width
                                     - titleFrame.origin.x - 20,
                                  subtitleFrame.size.height);
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [UIView animateWithDuration:0.2 animations:^{
        self.genreBadgeView.alpha = editing ? 0.0f : 1.0f;
    }];
    
    [super setEditing:editing animated:animated];
}


+ (NSString *)reusableIdentifier
{
    return @"GRStationCellView";
}


// ------------------------------------------------------------------------------------------
#pragma mark - Menu
// ------------------------------------------------------------------------------------------
- (void)onShowMenu:(UIGestureRecognizer *)sender
{
    [sender.view becomeFirstResponder];
    
    UIMenuController *mc = [UIMenuController sharedMenuController];
        
    [mc setTargetRect:sender.view.frame
               inView:sender.view.superview];
    
    [mc setMenuVisible:YES animated:YES];
}


- (void)markAsFavorite:(UIMenuController*)sender
{
    [self.station setFavourite:[NSNumber numberWithBool:YES]];
    [self.station.managedObjectContext save:nil];

    // inform about the change
    [GRNotificationCenter postChangeTriggeredByUserWithSender:self];
}


- (void)visitStation:(UIMenuController*)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.station.stationURL]];
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(markAsFavorite:))
    {
        BOOL favorite = self.station.favourite.boolValue;
        return !favorite;
    }
    
    if (action == @selector(visitStation:))
    {
        if ([self.station.stationURL rangeOfString:@"www"].location != NSNotFound)
        {
            return YES;
        }
        
        return NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}


@end
