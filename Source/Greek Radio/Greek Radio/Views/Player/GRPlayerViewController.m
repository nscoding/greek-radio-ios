//
//  GRPlayerViewController.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRPlayerViewController.h"
#import "GRShareHelper.h"

#import <MediaPlayer/MediaPlayer.h>


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
         previousView:(UIView *)preView
{
    if ((self = [super initWithNibName:@"GRPlayerViewController" bundle:nil]))
    {
        self.currentStation = station;        
        [self.view setFrame:preView.frame];
        [self.view setBackgroundColor:[UIColor blackColor]];
        
        [self buildAndConfigureStationName:station.title];
        [self buildAndConfigureListButton];
        [self buildAndConfigureLoadingView];
        [self registerObservers];
            
        
        CGRect bottomFrame = self.bottomBar.frame;
        bottomFrame.origin.y = self.view.frame.size.height - bottomFrame.size.height;
        [self.bottomBar setFrame:bottomFrame];
        
        
        MPVolumeView *myVolumeView =
        [[MPVolumeView alloc] initWithFrame:CGRectMake(20, self.bottomBar.frame.size.height - 34,
                                                       self.view.frame.size.width - 40, 20)];
        myVolumeView.layer.backgroundColor = [UIColor clearColor].CGColor;
        [self.bottomBar addSubview:myVolumeView];
        
        
        [[GRRadioPlayer shared] playStation:self.currentStation.title
                              withStreamURL:self.currentStation.streamURL];
        
        [self configurePlayButton];
    }
    
    return self;
}


- (void)viewDidLoad
{
    self.navigationItem.title = @"Now Playing";
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.favouriteButton.selected = [self.currentStation.favourite boolValue];
    [self.favouriteButton setNeedsDisplay];
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
    label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:24];
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
    [listButton addTarget:self action:@selector(listButtonPressed:)
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
        [self.playButton setImage:[UIImage imageNamed:@"GRPause"] forState:UIControlStateNormal];
    }
    else
    {
        [self.playButton setImage:[UIImage imageNamed:@"GRPlay"] forState:UIControlStateNormal];
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (void)listButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)shareButtonPressed:(UIButton *)sender
{
    BlockActionSheet *sheet = [BlockActionSheet sheetWithTitle:@""];
    [sheet setCancelButtonWithTitle:@"Dismiss" block:nil];
    
    
    [sheet addButtonWithTitle:@"Share via Email" block:^{
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
        mailController.subject = @"Greek Radio";
        [mailController setMessageBody:
         [NSString stringWithFormat:@"%@.\n\nYou can check it out at %@",kTextNoStation, kAppiTunesURL]
                                isHTML:NO];
        
        [GRAppearanceHelper setUpDefaultAppearance];
        [self.navigationController presentModalViewController:mailController animated:YES];
    }];
    
    if ([SLComposeViewController class])
    {
        [sheet addButtonWithTitle:@"Share via Twitter" block:^{
            [GRShareHelper tweetTappedOnController:self];
        }];
    }
    
    if ([SLComposeViewController class])
    {
        [sheet addButtonWithTitle:@"Share via Facebook" block:^{
            [GRShareHelper facebookTappedOnController:self];
        }];
    }
    
    [sheet showInView:self.view];
}


- (IBAction)playOrPause:(id)sender
{
    if ([GRRadioPlayer shared].isPlaying)
    {
        [[GRRadioPlayer shared] stopPlayingStation];
    }
    else
    {
        [[GRRadioPlayer shared] playStation:self.currentStation.title
                              withStreamURL:self.currentStation.streamURL];
    }
}


- (IBAction)markStationAsFavourite:(id)sender
{
    self.currentStation.favourite = [NSNumber numberWithBool:![self.currentStation.favourite boolValue]];
    [self.currentStation.managedObjectContext save:nil];
    
    self.favouriteButton.selected = [self.currentStation.favourite boolValue];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Mail Delegate
// ------------------------------------------------------------------------------------------
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [GRAppearanceHelper setUpGreekRadioAppearance];    
    [controller dismissModalViewControllerAnimated:YES];
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

