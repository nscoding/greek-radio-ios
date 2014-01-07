
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

@end


// ------------------------------------------------------------------------------------------


@implementation GRStationCellView

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        self.backgroundColor = [UIColor whiteColor];
        
        UIMenuItem *markAsFavorite =
            [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"button_mark_as_favorite", @"")
                                       action:@selector(markAsFavorite:)];
        
        UIMenuItem *removeFromFavorite =
        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"button_unmark_as_favorite", @"")
                                   action:@selector(removeFromFavorite:)];

        UIMenuItem *visitStation =
            [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"button_visit_station", @"")
                                       action:@selector(visitStation:)];

        UIMenuController *menuController = [UIMenuController sharedMenuController];
        menuController.menuItems = [NSArray arrayWithObjects:markAsFavorite, removeFromFavorite, visitStation, nil];

        UILongPressGestureRecognizer *longGesture
            = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                            action:@selector(onShowMenu:)];
        [self addGestureRecognizer:longGesture];

        [[NSBundle mainBundle] loadNibNamed:@"GRStationCellView" owner:self options:nil];
        [self addSubview:self.backgroundView];
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        self.title.textAlignment = NSTextAlignmentLeft;
        self.title.numberOfLines = 1;
        self.subtitle.textAlignment = NSTextAlignmentLeft;
        self.subtitle.numberOfLines = 1;
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
        [UIView animateWithDuration:0.4
                         animations:^
        {
            self.selectionColor.alpha = 0.0f;
        }
        completion:^(BOOL finished)
         {
            [self.selectionColor removeFromSuperview];
        }];
    }
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
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setTargetRect:sender.view.frame
                           inView:sender.view.superview];
    [menuController setMenuVisible:YES animated:NO];
}


- (void)markAsFavorite:(UIMenuController*)sender
{
    [self.station setFavourite:@YES];
    [self.station.managedObjectContext save:nil];
}


- (void)removeFromFavorite:(UIMenuController*)sender
{
    [self.station setFavourite:@NO];
    [self.station.managedObjectContext save:nil];
}


- (void)visitStation:(UIMenuController*)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.station.stationURL]];
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL favorite = self.station.favourite.boolValue;

    if (action == @selector(markAsFavorite:))
    {
        return (favorite == NO);
    }

    if (action == @selector(removeFromFavorite:))
    {
        return favorite;
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
