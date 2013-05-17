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
#import "GRShoutCastHelper.h"

#import <MediaPlayer/MediaPlayer.h>


// ------------------------------------------------------------------------------------------


typedef enum GRInformationBarOption
{
    GRInformationBarOptionGenre = 0,
    GRInformationBarOptionSong = 1,
    GRInformationBarOptionArtist = 2,
} GRInformationBarOption;



// ------------------------------------------------------------------------------------------


@interface GRPlayerViewController ()

@property (nonatomic, assign) IBOutlet UIButton *favouriteButton;
@property (nonatomic, assign) IBOutlet UIButton *playButton;
@property (nonatomic, assign) IBOutlet UIView *bottomBar;
@property (nonatomic, weak) GRStation *currentStation;
@property (nonatomic, assign) GRInformationBarOption informationBarOption;
@property (nonatomic, copy) NSString *currentSong;
@property (nonatomic, copy) NSString *currentArtist;
@property (nonatomic, strong) NSTimer *informationTimer;

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
        [self buildAndConfigureStationGenre:station.genre];
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
        [self animateStatus];
        
        self.informationTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                                 target:self
                                                               selector:@selector(updateSongInformation)
                                                               userInfo:nil
                                                                repeats:YES];

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


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.4
                     animations:^
    {
        self.stationLabel.alpha = 1.0;
        self.stationLabel.center = CGPointMake(self.view.center.x, 255);
    }
    completion:^(BOOL finished)
    {
        [UIView animateWithDuration:0.4
                         animations:^
        {
            self.genreLabel.alpha = 1.0;
            self.genreLabel.center = CGPointMake(self.view.center.x, 292);
        }];
        
    }];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Timer
// ------------------------------------------------------------------------------------------
- (void)updateSongInformation
{
    NSLog(@"%s", __FUNCTION__);
    
    if ([GRRadioPlayer shared].isPlaying)
    {
        __weak GRPlayerViewController *blockSelf = self;
        [[GRShoutCastHelper shared] getMetadataForURL:self.currentStation.streamURL
                                         successBlock:^(NSString *songName, NSString *songArtist)
         {
             blockSelf.currentSong = [songName copy];
             blockSelf.currentArtist = [songArtist copy];
         }
         failBlock:^{
                blockSelf.currentSong = nil;
                blockSelf.currentArtist = nil;
         }];
    }
}


- (void)animateStatus
{
    GRInformationBarOption currentOption = self.informationBarOption;
    GRInformationBarOption goToOption = self.informationBarOption;

    if (currentOption == GRInformationBarOptionArtist) {
        currentOption = GRInformationBarOptionGenre;
        goToOption = GRInformationBarOptionGenre;
    }
    else
    {
        goToOption++;
    }
    
    if (goToOption == GRInformationBarOptionSong &&
        self.currentSong.length == 0)
    {
        goToOption++;
    }

    if (goToOption == GRInformationBarOptionArtist &&
        self.currentArtist.length == 0)
    {
        goToOption = GRInformationBarOptionGenre;
    }
    
    if ([GRRadioPlayer shared].isPlaying == NO)
    {
        currentOption = GRInformationBarOptionGenre;
        goToOption = GRInformationBarOptionGenre;
    }
    
    __weak GRPlayerViewController *blockSelf = self;
    
    if (self.informationBarOption != goToOption)
    {
        self.informationBarOption = goToOption;
        
        [UIView animateWithDuration:6.0
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
             blockSelf.genreLabel.alpha = 1.0;
             blockSelf.genreLabel.center = CGPointMake(-(blockSelf.genreLabel.frame.size.width / 2), 292);
                             
        } completion:^(BOOL finished) {
 
            blockSelf.genreLabel.alpha = 1.0;
            
            blockSelf.genreLabel.text = [blockSelf titleForBar:goToOption];
            CGSize size = [blockSelf.genreLabel sizeThatFits:CGSizeMake(FLT_MAX, 20)];
            blockSelf.genreLabel.numberOfLines = 1;
            blockSelf.genreLabel.frame = CGRectMake(0, 0, size.width, size.height);
            blockSelf.genreLabel.center = CGPointMake(blockSelf.view.frame.size.width +
                                                 (blockSelf.genreLabel.frame.size.width / 2), 292);

            [UIView animateWithDuration:12.0
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 blockSelf.genreLabel.alpha = 1.0;
                                 blockSelf.genreLabel.center = CGPointMake(-(blockSelf.genreLabel.frame.size.width / 2), 292);

                                 
                             } completion:^(BOOL finished) {                                 
                                     [blockSelf animateStatus];
                             }];
        }];
    }
    else
    {
        double delayInSeconds = 5.0f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [blockSelf animateStatus];

        });
    }
}


- (NSString *)titleForBar:(GRInformationBarOption)option
{
    switch (option) {
        case GRInformationBarOptionGenre:
            return self.currentStation.genre;
            break;
        case GRInformationBarOptionArtist:
            return self.currentArtist;
            break;
        case GRInformationBarOptionSong:
            return self.currentSong;
            break;
    }
    
    return @"";
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
    self.stationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.stationLabel.backgroundColor = [UIColor clearColor];
    self.stationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:26];
    self.stationLabel.textColor = [UIColor colorWithRed:0.839f green:0.839f blue:0.839f alpha:1.00f];
    self.stationLabel.shadowColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    self.stationLabel.shadowOffset = CGSizeMake(0, 1);
    self.stationLabel.textAlignment = NSTextAlignmentCenter;
    self.stationLabel.text =  [name copy];
    self.stationLabel.numberOfLines = 1;
    self.stationLabel.minimumFontSize = 17;
    self.stationLabel.adjustsFontSizeToFitWidth = YES;

    CGSize size = [self.stationLabel sizeThatFits:CGSizeMake(self.view.frame.size.width - 40, FLT_MAX)];

    self.stationLabel.frame = CGRectMake(0, 0, MIN(size.width, self.view.frame.size.width - 40), size.height);
    self.stationLabel.alpha = 0.0;
    
    [self.stationLabel setCenter:CGPointMake(-self.stationLabel.frame.size.width, 253)];
    [self.view addSubview:self.stationLabel];
}


- (void)buildAndConfigureStationGenre:(NSString *)genre
{
    self.genreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.genreLabel.backgroundColor = [UIColor clearColor];
    self.genreLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:21];
    self.genreLabel.textColor = [UIColor colorWithRed:0.839f green:0.839f blue:0.839f alpha:1.00f];
    self.genreLabel.shadowColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    self.genreLabel.shadowOffset = CGSizeMake(0, 1);
    self.genreLabel.textAlignment = NSTextAlignmentCenter;
    self.genreLabel.text =  [genre copy];
    self.genreLabel.numberOfLines = 1;
    self.genreLabel.alpha = 0.0;

    CGSize size = [self.genreLabel sizeThatFits:CGSizeMake(FLT_MAX, 20)];
    self.genreLabel.frame = CGRectMake(0, 0, size.width, size.height);
    [self.genreLabel setCenter:CGPointMake(self.view.frame.size.width + (self.genreLabel.frame.size.width / 2), 292)];
    [self.view addSubview:self.genreLabel];
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
    [[GRShoutCastHelper shared] cancelGet];
    [self.informationTimer invalidate];
    self.informationTimer = nil;

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


// ------------------------------------------------------------------------------------------
#pragma mark - Dealloc
// ------------------------------------------------------------------------------------------
- (void)dealloc
{
    [[GRShoutCastHelper shared] cancelGet];
    [self.informationTimer invalidate];
    self.informationTimer = nil;
}

@end

