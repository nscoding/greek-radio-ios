
//
//  GRStationCellView.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStationCellView.h"
#import "GRRadioPlayer.h"

@implementation GRStationCellView
{
    UIView *_selectionColor;
    UIView *_lineView;
}

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[[self class] reusableIdentifier]])
    {
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        [self setUpLine];
        [self configureMenuController];
        [self configureLongTapGesture];
        [self configureLabels];
    }

    return self;
}

#pragma mark - Configure

- (void)setUpLine
{
    _lineView = [[UIView alloc] initWithFrame:CGRectMake(40.0, self.frame.size.height - 1.0, self.frame.size.width - 40.0, 1.0)];
    _lineView.backgroundColor = [UIColor lightGrayColor];
    _lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:_lineView];
}

- (void)configureMenuController
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.menuItems =
        @[
          [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"button_mark_as_favorite", @"") action:@selector(markAsFavorite:)],
          [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"button_unmark_as_favorite", @"") action:@selector(removeFromFavorite:)],
          [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"button_visit_station", @"") action:@selector(visitStation:)]
         ];
}


- (void)configureLongTapGesture
{
    UILongPressGestureRecognizer *longTap
        = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showLongTapMenu:)];
    [self addGestureRecognizer:longTap];
}

- (void)configureLabels
{
    self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.textLabel.textAlignment = NSTextAlignmentNatural;
    self.textLabel.numberOfLines = 1;
    self.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.detailTextLabel.textAlignment = NSTextAlignmentNatural;
    self.detailTextLabel.numberOfLines = 1;
}

#pragma mark - Overrides

- (void)setShowDivider:(BOOL)showDivider
{
    _showDivider = showDivider;
    _lineView.alpha = _showDivider;
}

- (void)prepareForReuse
{
    [self configureLabels];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        _selectionColor = [[UIView alloc] init];
        _selectionColor.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height - 2.0);
        _selectionColor.backgroundColor = [UIColor colorWithRed:0.614 green:0.635 blue:0.619 alpha:0.40];
        [self.backgroundView addSubview:_selectionColor];
    } else {
        [UIView animateWithDuration:0.4f
                         animations:^{
             _selectionColor.alpha = 0.0;
        }
        completion:^(BOOL finished) {
            [_selectionColor removeFromSuperview];
        }];
    }
}

#pragma mark - Menu

- (void)showLongTapMenu:(UIGestureRecognizer *)sender
{
    [sender.view becomeFirstResponder];
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setTargetRect:sender.view.frame inView:sender.view.superview];
    [menuController setMenuVisible:YES animated:NO];
}

#pragma mark - Actions

- (void)markAsFavorite:(UIMenuController *)sender
{
    [self.station setFavourite:@YES];
    [self.station.managedObjectContext save:nil];
}


- (void)removeFromFavorite:(UIMenuController *)sender
{
    [self.station setFavourite:@NO];
    [self.station.managedObjectContext save:nil];
}


- (void)visitStation:(UIMenuController *)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.station.stationURL]];
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL favorite = self.station.favourite.boolValue;
    
    if (action == @selector(markAsFavorite:)) {
        return (favorite == NO);
    }

    if (action == @selector(removeFromFavorite:)) {
        return favorite;
    }
    
    if (action == @selector(visitStation:)) {
        if ([self.station.stationURL rangeOfString:@"www"].location != NSNotFound) {
            return YES;
        }
        return NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

#pragma mark - Class Methods

+ (NSString *)reusableIdentifier
{
    return NSStringFromClass([self class]);
}

@end
