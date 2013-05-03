//
//  GRPlayerViewController.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRPlayerViewController.h"
#import "GRRadioPlayer.h"
#import "BlockAlertView.h"


// ------------------------------------------------------------------------------------------


@interface GRPlayerViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end


// ------------------------------------------------------------------------------------------


@implementation GRPlayerViewController

// ------------------------------------------------------------------------------------------
#pragma mark - Initializer
// ------------------------------------------------------------------------------------------
- (id)initWithStation:(GRStation *)station
{
    if ((self = [super initWithNibName:@"GRPlayerViewController" bundle:nil]))
    {
        self.currentStation = station;
        [[GRRadioPlayer shared] playStation:self.currentStation.title
                              withStreamURL:self.currentStation.streamURL];
        

        [self.view setBackgroundColor:[UIColor blackColor]];
        [self buildAndConfigureStationName:station.title];
        [self buildAndConfigureListButton];
        [self buildAndConfigureLoadingView];
        [self registerObservers];
        
        CGRect frame = self.favouriteButton.frame;
        frame.origin.y = self.view.frame.size.height + frame.size.height;
        [self.favouriteButton setFrame:frame];
    }
    
    return self;
}


- (void)viewDidLoad
{
    self.navigationItem.title = @"Now Playing";
    [super viewDidLoad];
    
    [self configurePlayButton];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self animateFavouriteButton];
}


- (void)animateFavouriteButton
{
    if (self.currentStation.favourite.boolValue == NO)
    {
        [UIView animateWithDuration:0.4
                              delay:0.4
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             CGRect frame = self.favouriteButton.frame;
             frame.origin.y = self.view.frame.size.height - 41;
             [self.favouriteButton setFrame:frame];
         }
                         completion:nil];
    }
    else
    {
        [UIView animateWithDuration:0.4
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             CGRect frame = self.favouriteButton.frame;
             frame.origin.y = self.view.frame.size.height;
             [self.favouriteButton setFrame:frame];
         }
        completion:nil];
    }

}

// ------------------------------------------------------------------------------------------
#pragma mark - Notifications
// ------------------------------------------------------------------------------------------
- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidStart:)
                                                 name:GRNotificationStreamDidStart
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidEnd:)
                                                 name:GRNotificationStreamDidEnd
                                               object:nil];
}


- (void)playerDidStart:(NSNotification *)notification
{
    [self configurePlayButton];
    [self.loadingIndicator startAnimating];
}


- (void)playerDidEnd:(NSNotification *)notification
{
    [self configurePlayButton];
    [self.loadingIndicator stopAnimating];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Build and configure
// ------------------------------------------------------------------------------------------
- (void)buildAndConfigureStationName:(NSString *)name
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:19];
    label.textColor = [UIColor colorWithRed:0.839f green:0.839f blue:0.839f alpha:1.00f];
    label.shadowColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    label.shadowOffset = CGSizeMake(0, 1);
    label.textAlignment = NSTextAlignmentCenter;
    label.text =  [name copy];
    label.numberOfLines = 0;
    
    [label sizeToFit];
    [label setCenter:CGPointMake(self.view.center.x, 260)];
    
    [self.view addSubview:label];
}


- (void)buildAndConfigureListButton
{
    UIButton *listButton = [UIButton buttonWithType:UIButtonTypeCustom];
    listButton.frame = CGRectMake(0, 0, 30, 30);
    
    [listButton setImage:[UIImage imageNamed:@"GRList"] forState:UIControlStateNormal];
    [listButton addTarget:self action:@selector(moreButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithCustomView:listButton];
    
    self.navigationItem.leftBarButtonItem = backButton;
}


- (void)buildAndConfigureLoadingView
{
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.loadingIndicator];
    [self navigationItem].rightBarButtonItem = barButton;
    
    if ([[GRRadioPlayer shared] isPlaying])
    {
        [self.loadingIndicator startAnimating];
    }
}


- (void)configurePlayButton
{
    if ([GRRadioPlayer shared].isPlaying)
    {
        [self.playButton setImage:[UIImage imageNamed:@"GRPauseButton"] forState:UIControlStateNormal];
    }
    else
    {
        [self.playButton setImage:[UIImage imageNamed:@"GRPlayButton"] forState:UIControlStateNormal];
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (void)moreButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)playOrPause:(id)sender
{
    if ([GRRadioPlayer shared].isPlaying)
    {
        [GRNotificationCenter postPlayerDidEndNotificationWithSender:nil];
        [[GRRadioPlayer shared] stopPlayingStation];
    }
    else
    {
        [[GRRadioPlayer shared] playStation:self.currentStation.title
                              withStreamURL:self.currentStation.streamURL];
        
        [GRNotificationCenter postPlayerDidStartNotificationWithSender:nil];
    }
}


- (IBAction)markStationAsFavourite:(id)sender
{
    self.currentStation.favourite = [NSNumber numberWithBool:YES];
    [self.currentStation.managedObjectContext save:nil];
    
    [self animateFavouriteButton];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Memory
// ------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
#warning stop the player, show an alert
    [super didReceiveMemoryWarning];
}


@end

