//
//  GRPlayerViewController.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRPlayerViewController.h"
#import "GRShareHelper.h"
#import "GRShoutCastHelper.h"
#import "UIDevice+Extensions.h"

#import <MediaPlayer/MediaPlayer.h>

typedef NS_ENUM(NSUInteger, GRInformationBarOption) {
  GRInformationBarOptionGenre     = 0,
  GRInformationBarOptionSong      = 1,
  GRInformationBarOptionArtist    = 2,
};

@interface GRPlayerViewController ()

@property (nonatomic, weak) GRStation *currentStation;
@property (nonatomic, assign) GRInformationBarOption informationBarOption;
@property (nonatomic, copy) NSString *currentSong;
@property (nonatomic, copy) NSString *currentArtist;
@property (nonatomic, strong) NSTimer *informationTimer;
@property (nonatomic, weak) id<GRPlayerViewControllerDelegate> delegate;

@end

@implementation GRPlayerViewController

#pragma mark - Initializer

- (instancetype)initWithStation:(GRStation *)station
                       delegate:(id<GRPlayerViewControllerDelegate>)delegate
                   previousView:(UIView *)preView
{
    if (self = [super initWithNibName:@"GRPlayerViewController" bundle:nil]){
        self.delegate = delegate;
        self.currentStation = station;        
        [self.view setFrame:preView.frame];
        
        [self buildAndConfigureStationName:station.title];
        [self buildAndConfigureStationGenre:station.genre];
        [self buildAndConfigureVolumeSlider];
        [self registerObservers];
        
        [[GRRadioPlayer shared] playStation:self.currentStation];
        [self configurePlayButton];
        [self animateStatus];
        
        self.informationTimer = [NSTimer scheduledTimerWithTimeInterval:30.0f
                                                                 target:self
                                                               selector:@selector(updateSongInformation)
                                                               userInfo:nil
                                                                repeats:YES];
        
        [self.informationTimer fire];

    }
    
    return self;
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
    self.navigationItem.title = NSLocalizedString(@"label_now_playing", @"");
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self configureNavigationBarBackTitle];
    [super viewDidLoad];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [UIView animateWithDuration:0.4f
                     animations:^ {
        self.stationLabel.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4f
                         animations:^{
            self.genreLabel.alpha = 1.0f;
        }];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[GRShoutCastHelper shared] cancelGet];
    [self.informationTimer invalidate];
    self.informationTimer = nil;
}

#pragma mark - Build and configure

- (void)configureNavigationBarBackTitle
{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
}

- (void)buildAndConfigureStationName:(NSString *)name
{
    self.stationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.stationLabel.backgroundColor = [UIColor clearColor];
    self.stationLabel.font = [UIFont boldSystemFontOfSize:29.0f];
    self.stationLabel.textColor = [UIColor colorWithRed:0.839f green:0.839f blue:0.839f alpha:1.00f];
    self.stationLabel.shadowColor = [UIColor colorWithWhite:0.3f alpha:0.5f];
    self.stationLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.stationLabel.textAlignment = NSTextAlignmentCenter;
    self.stationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.stationLabel.text =  [name copy];
    self.stationLabel.numberOfLines = 1;
    self.stationLabel.minimumScaleFactor = 0.3f;
    self.stationLabel.adjustsFontSizeToFitWidth = YES;
    self.stationLabel.alpha = 0.0f;
    [self.view addSubview:self.stationLabel];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.stationLabel
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.stationLabel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0f
                                                           constant:20.0f]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.stationLabel
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0f
                                                           constant:20.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.stationLabel
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0f
                                                           constant:-20.0f]];
}

- (void)buildAndConfigureStationGenre:(NSString *)genre
{
    self.genreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.genreLabel.backgroundColor = [UIColor clearColor];
    self.genreLabel.font = [UIFont systemFontOfSize:23.0f];
    self.genreLabel.textColor = [UIColor colorWithRed:0.839f green:0.839f blue:0.839f alpha:1.00f];
    self.genreLabel.shadowColor = [UIColor colorWithWhite:0.3f alpha:0.5f];
    self.genreLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.genreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.genreLabel.textAlignment = NSTextAlignmentCenter;
    self.genreLabel.text =  [genre copy];
    self.genreLabel.numberOfLines = 1;
    self.genreLabel.alpha = 0.0f;
    [self.view addSubview:self.genreLabel];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.genreLabel
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.genreLabel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0f
                                                           constant:60.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.genreLabel
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.genreLabel
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0f
                                                           constant:0.0f]];
}

- (void)buildAndConfigureVolumeSlider
{
  MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(60.0f, 110.0f, self.view.frame.size.width - 90.0f, 20.0f)];
  volumeView.layer.backgroundColor = [UIColor clearColor].CGColor;
  volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:volumeView];
  
  UIImageView *volumeLowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GRVolumeUp"]];
  volumeLowImageView.center = CGPointMake(33.0f, volumeView.center.y);
  [self.view addSubview:volumeLowImageView];
}

- (void)configurePlayButton
{
    [self.playerTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Timer

- (void)updateSongInformation
{
    if ([GRRadioPlayer shared].isPlaying) {
        __weak GRPlayerViewController *weakSelf = self;
        [[GRShoutCastHelper shared] getMetadataForURL:self.currentStation.streamURL
                                         successBlock:^(NSString *songName, NSString *songArtist) {
             weakSelf.currentSong = [songName copy];
             weakSelf.currentArtist = [songArtist copy];
        } failBlock:^ {
             weakSelf.currentSong = nil;
             weakSelf.currentArtist = nil;
        }];
    }
}

- (void)animateStatus
{
    GRInformationBarOption currentOption = self.informationBarOption;
    GRInformationBarOption goToOption = self.informationBarOption;
    
    if (currentOption == GRInformationBarOptionArtist) {
        goToOption = GRInformationBarOptionGenre;
    } else {
        goToOption++;
    }
    
    if (goToOption == GRInformationBarOptionSong && self.currentSong.length == 0) {
        goToOption++;
    }
    
    if (goToOption == GRInformationBarOptionArtist && self.currentArtist.length == 0) {
        goToOption = GRInformationBarOptionGenre;
    }
    
    if ([GRRadioPlayer shared].isPlaying == NO) {
        goToOption = GRInformationBarOptionGenre;
    }
    
    __weak GRPlayerViewController *weakSelf = self;
    if (self.informationBarOption != goToOption)
    {
        self.informationBarOption = goToOption;
        
        [UIView animateWithDuration:6.0f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
             weakSelf.genreLabel.alpha = 1.0f;
             weakSelf.genreLabel.center = CGPointMake(-(weakSelf.genreLabel.frame.size.width / 2.0f),
                                                      weakSelf.genreLabel.center.y);
         } completion:^(BOOL finished) {
             
             weakSelf.genreLabel.alpha = 1.0f;
             weakSelf.genreLabel.text = [weakSelf titleForBar:goToOption];
             CGSize size = [weakSelf.genreLabel sizeThatFits:CGSizeMake(self.view.frame.size.width, FLT_MAX)];
             weakSelf.genreLabel.numberOfLines = 1;
             CGFloat centerY = weakSelf.genreLabel.center.y;
             weakSelf.genreLabel.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
             weakSelf.genreLabel.center = CGPointMake(weakSelf.view.frame.size.width +
                                                     (weakSelf.genreLabel.frame.size.width / 2.0f),
                                                       centerY);
             
             [UIView animateWithDuration:12.0f
                                   delay:0.0f
                                 options:UIViewAnimationOptionCurveLinear
                              animations:^{
                                  weakSelf.genreLabel.alpha = 1.0f;
                                  weakSelf.genreLabel.center =
                                  CGPointMake(-(weakSelf.genreLabel.frame.size.width / 2.0f),
                                              weakSelf.genreLabel.center.y);
                              } completion:^(BOOL finished) {
                                  [weakSelf animateStatus];
                              }];
         }];
    } else {
        double delayInSeconds = 5.0f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf animateStatus];
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

#pragma mark - Notifications

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

#pragma mark - Table View Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PlayerCell"];
    tableViewCell.textLabel.textColor = [UIColor blackColor];
    tableViewCell.imageView.image = nil;

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if ([GRRadioPlayer shared].isPlaying == NO) {
                tableViewCell.textLabel.text = NSLocalizedString(@"button_play", @"");
                tableViewCell.imageView.image = [UIImage imageNamed:@"GRPlay"];
                tableViewCell.textLabel.textColor = [UIColor colorWithRed:0.082f
                                                                    green:0.494f
                                                                     blue:0.984f
                                                                    alpha:1.00f];
            } else {
                tableViewCell.textLabel.text = NSLocalizedString(@"button_pause", @"");
                tableViewCell.imageView.image = [UIImage imageNamed:@"GRPause"];
            }
        } else if (indexPath.row == 1) {
            if (self.currentStation.favourite.boolValue) {
                tableViewCell.textLabel.text = NSLocalizedString(@"button_unmark_as_favorite", @"");
            } else {
                tableViewCell.textLabel.text = NSLocalizedString(@"button_mark_as_favorite", @"");
                tableViewCell.textLabel.textColor = [UIColor redColor];
            }
            tableViewCell.imageView.image = [UIImage imageNamed:@"GRHeart"];
        }
    }

    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            tableViewCell.textLabel.text = NSLocalizedString(@"button_previous_station", @"");
            tableViewCell.imageView.image = [UIImage imageNamed:@"GRPrevious"];
        } else if (indexPath.row == 1) {
            tableViewCell.textLabel.text = NSLocalizedString(@"button_next_station", @"");
            tableViewCell.imageView.image = [UIImage imageNamed:@"GRNext"];
        }
    }

    if (indexPath.section == 2) {
        tableViewCell.imageView.image = [UIImage imageNamed:@"GRNetwork"];
        if (indexPath.row == 0) {
            tableViewCell.textLabel.text = NSLocalizedString(@"share_via_email", @"");
        } else if (indexPath.row == 1) {
            tableViewCell.textLabel.text = NSLocalizedString(@"share_via_facebook", @"");
        } else if (indexPath.row == 2) {
            tableViewCell.textLabel.text = NSLocalizedString(@"share_via_twitter", @"");
        }
    }
    
    return tableViewCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || section == 1) {
        return 2;
    }
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if ([GRRadioPlayer shared].isPlaying) {
                [[GRRadioPlayer shared] stopPlayingCurrentStation];
            } else {
                [[GRRadioPlayer shared] playStation:self.currentStation];
            }
        } else if (indexPath.row == 1) {
            self.currentStation.favourite = [NSNumber numberWithBool:![self.currentStation.favourite boolValue]];
            [self.currentStation.managedObjectContext save:nil];
        }
        // set the value and save
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(playerViewControllerPlayPreviousStation:)]) {
                [self.delegate playerViewControllerPlayPreviousStation:self];
            }
        } else if (indexPath.row == 1) {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(playerViewControllerPlayNextStation:)]) {
                [self.delegate playerViewControllerPlayNextStation:self];
            }
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            if ([MFMailComposeViewController canSendMail]) {
                [GRAppearanceHelper setUpDefaultAppearance];

                MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
                mailController.mailComposeDelegate = self;
                mailController.modalPresentationStyle = UIModalPresentationFormSheet;
                mailController.subject = @"Greek Radio";
                
                NSString *listeningTo;
                if ([GRRadioPlayer shared].stationName.length > 0) {
                    listeningTo = [NSString stringWithFormat:NSLocalizedString(@"share_station_$_text", @""),
                                   [GRRadioPlayer shared].stationName];
                } else {
                    listeningTo = [NSString stringWithFormat:NSLocalizedString(@"share_station_$_text", @""),
                                   [NSLocalizedString(@"label_music", @"") lowercaseString]];
                }
                
                NSString *itunesCheckIt = [NSString stringWithFormat:
                                           NSLocalizedString(@"share_via_email_check_it_$", @""), kAppiTunesURL];
                [mailController setMessageBody:[NSString stringWithFormat:@"%@\n\n%@",listeningTo, itunesCheckIt]
                                        isHTML:YES];
                
                [self.navigationController presentViewController:mailController animated:YES completion:nil];
            } else {
                [UIAlertView showWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                                   message:NSLocalizedString(@"share_email_error", @"")
                         cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
                         otherButtonTitles:nil
                                  tapBlock:nil];
            }
        } else if (indexPath.row == 1) {
            if ([SLComposeViewController class]) {
                [GRShareHelper facebookTappedOnController:self];
            }
        } else if (indexPath.row == 2) {
            if ([SLComposeViewController class]) {
                [GRShareHelper tweetTappedOnController:self];
            }
        }
    }
}

#pragma mark - Mail Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [GRAppearanceHelper setUpGreekRadioAppearance];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Dealloc

- (void)dealloc
{
    [[GRShoutCastHelper shared] cancelGet];
    [self.informationTimer invalidate];
    self.informationTimer = nil;
    self.delegate = nil;
}

@end

