//
//  GRPlayerViewController.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRPlayerViewController.h"
#import "GRShareHelper.h"
#import "TestFlight.h"

#import <MediaPlayer/MediaPlayer.h>


// ------------------------------------------------------------------------------------------


@interface GRPlayerViewController ()

@property (nonatomic, assign) IBOutlet UIButton *favouriteButton;
@property (nonatomic, assign) IBOutlet UIButton *playButton;
@property (nonatomic, assign) IBOutlet UIView *bottomBar;
@property (nonatomic, weak) GRStation *currentStation;

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
    self.navigationItem.title = NSLocalizedString(@"label_now_playing", @"");
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
}


- (void)playerDidEnd:(NSNotification *)notification
{
    [self configurePlayButton];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Build and configure
// ------------------------------------------------------------------------------------------
- (void)buildAndConfigureStationName:(NSString *)name
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:27];
    label.textColor = [UIColor colorWithRed:0.839f green:0.839f blue:0.839f alpha:1.00f];
    label.shadowColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    label.shadowOffset = CGSizeMake(0, 1);
    label.textAlignment = NSTextAlignmentCenter;
    label.text =  [name copy];
    label.numberOfLines = 0;
    
    CGSize size = [label sizeThatFits:CGSizeMake(self.view.frame.size.width - 40, FLT_MAX)];
    label.frame = CGRectMake(0, 0, size.width, size.height);
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



- (void)configurePlayButton
{
    if ([GRRadioPlayer shared].isPlaying)
    {
        [self.playButton setImage:[UIImage imageNamed:@"GRPause"]
                         forState:UIControlStateNormal];
    }
    else
    {
        [self.playButton setImage:[UIImage imageNamed:@"GRPlay"]
                         forState:UIControlStateNormal];
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
    [sheet setCancelButtonWithTitle:NSLocalizedString(@"button_dismiss", @"") block:nil];
    
    [sheet addButtonWithTitle:NSLocalizedString(@"share_via_email", @"")
                        block:^
    {
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
        mailController.subject = @"Greek Radio";

        NSString *listeningTo;
        if ([GRRadioPlayer shared].stationName.length > 0)
        {
            listeningTo = [NSString stringWithFormat:NSLocalizedString(@"share_station_$_text", @""),
                           [GRRadioPlayer shared].stationName];
        }
        else
        {
            listeningTo = [NSString stringWithFormat:NSLocalizedString(@"share_station_$_text", @""),
                          [NSLocalizedString(@"label_music", @"") lowercaseString]];
        }
        
        NSString *itunesCheckIt = [NSString stringWithFormat:NSLocalizedString(@"share_via_email_check_it_$", @""),
                           kAppiTunesURL];
                           
        [mailController setMessageBody:[NSString stringWithFormat:@"%@\n\n%@",listeningTo, itunesCheckIt]
                                isHTML:YES];
        
        [GRAppearanceHelper setUpDefaultAppearance];
        [self.navigationController presentModalViewController:mailController animated:YES];
    }];
    
    if ([SLComposeViewController class])
    {
        [sheet addButtonWithTitle:NSLocalizedString(@"share_via_twitter", @"") block:^{
            [GRShareHelper tweetTappedOnController:self];
        }];
    }
    
    if ([SLComposeViewController class])
    {
        [sheet addButtonWithTitle:NSLocalizedString(@"share_via_facebook", @"") block:^{
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
    // inform test flight
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"%@ - (Favorite)",self.currentStation.title]];
    
    // set the value and save
    self.currentStation.favourite = [NSNumber numberWithBool:![self.currentStation.favourite boolValue]];
    [self.currentStation.managedObjectContext save:nil];
    
    // inform about the change
    [GRNotificationCenter postChangeTriggeredByUserWithSender:self];
    
    // adjust the button state
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


@end

