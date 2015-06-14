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

@implementation GRPlayerViewController
{
    GRStation *_currentStation;
    GRInformationBarOption _informationBarOption;
    NSString *_currentSong;
    NSString *_currentArtist;
    __weak id<GRPlayerViewControllerDelegate> _delegate;
    NSTimer *_informationTimer;
}

#pragma mark - Initializer

- (instancetype)initWithStation:(GRStation *)station
                       delegate:(id<GRPlayerViewControllerDelegate>)delegate
                   previousView:(UIView *)preView
{
    if (self = [super initWithNibName:@"GRPlayerViewController" bundle:nil]) {
        _delegate = delegate;
        _currentStation = station;        
        [self.view setFrame:preView.frame];
        
        [self buildAndConfigureStationName:station.title];
        [self buildAndConfigureStationGenre:station.genre];
        [self buildAndConfigureVolumeSlider];
        [self registerObservers];

        [[GRRadioPlayer shared] playStation:_currentStation];
        [self configurePlayButton];
        [self animateStatus];
        
        _informationTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                             target:self
                                                           selector:@selector(updateSongInformation)
                                                           userInfo:nil
                                                            repeats:YES];
        [_informationTimer fire];
    }
    
    return self;
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"label_now_playing", @"");
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self configureNavigationBarBackTitle];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [UIView animateWithDuration:0.4
                     animations:^ {
        self.stationLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4
                         animations:^{
            self.genreLabel.alpha = 1.0;
        }];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[GRShoutCastHelper shared] cancelGet];
    [_informationTimer invalidate];
    _informationTimer = nil;
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
    self.stationLabel.font = [UIFont boldSystemFontOfSize:29.0];
    self.stationLabel.textColor = [UIColor colorWithRed:0.839 green:0.839 blue:0.839 alpha:1.00];
    self.stationLabel.shadowColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    self.stationLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    self.stationLabel.textAlignment = NSTextAlignmentCenter;
    self.stationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.stationLabel.text =  [name copy];
    self.stationLabel.numberOfLines = 1;
    self.stationLabel.minimumScaleFactor = 0.3f;
    self.stationLabel.adjustsFontSizeToFitWidth = YES;
    self.stationLabel.alpha = 0.0;
    [self.view addSubview:self.stationLabel];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.stationLabel
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.stationLabel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:20.0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.stationLabel
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:20.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.stationLabel
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:-20.0]];
}

- (void)buildAndConfigureStationGenre:(NSString *)genre
{
    self.genreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.genreLabel.backgroundColor = [UIColor clearColor];
    self.genreLabel.font = [UIFont systemFontOfSize:23.0];
    self.genreLabel.textColor = [UIColor colorWithRed:0.839 green:0.839 blue:0.839 alpha:1.0];
    self.genreLabel.shadowColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    self.genreLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    self.genreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.genreLabel.textAlignment = NSTextAlignmentCenter;
    self.genreLabel.text =  [genre copy];
    self.genreLabel.numberOfLines = 1;
    self.genreLabel.alpha = 0.0;
    [self.view addSubview:self.genreLabel];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.genreLabel
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.genreLabel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:60.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.genreLabel
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.genreLabel
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0.0]];
}

- (void)buildAndConfigureVolumeSlider
{
  MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(60.0, 110.0, self.view.frame.size.width - 90.0, 20.0)];
  volumeView.layer.backgroundColor = [UIColor clearColor].CGColor;
  volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:volumeView];
  
  UIImageView *volumeLowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GRVolumeUp"]];
  volumeLowImageView.center = CGPointMake(33.0, volumeView.center.y);
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
        WEAKIFY(self);
        [[GRShoutCastHelper shared] getMetadataForURL:_currentStation.streamURL
                                         successBlock:^(NSString *songName, NSString *songArtist) {
            STRONGIFY(self);
            _currentSong = [songName copy];
            _currentArtist = [songArtist copy];
        } failBlock:^ {
            STRONGIFY(self);
            _currentSong = nil;
            _currentArtist = nil;
        }];
    }
}

- (void)animateStatus
{
    GRInformationBarOption currentOption = _informationBarOption;
    GRInformationBarOption goToOption = _informationBarOption;
    
    if (currentOption == GRInformationBarOptionArtist) {
        goToOption = GRInformationBarOptionGenre;
    } else {
        goToOption++;
    }
    
    if (goToOption == GRInformationBarOptionSong && _currentSong.length == 0) {
        goToOption++;
    }
    
    if (goToOption == GRInformationBarOptionArtist && _currentArtist.length == 0) {
        goToOption = GRInformationBarOptionGenre;
    }
    
    if ([GRRadioPlayer shared].isPlaying == NO) {
        goToOption = GRInformationBarOptionGenre;
    }
    
    WEAKIFY(self);
    if (_informationBarOption != goToOption) {
        _informationBarOption = goToOption;
        [UIView animateWithDuration:6.0
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
            STRONGIFY(self);
            self.genreLabel.alpha = 1.0;
            self.genreLabel.center = CGPointMake(-(self.genreLabel.frame.size.width / 2.0), self.genreLabel.center.y);
         } completion:^(BOOL finished) {
            STRONGIFY(self);
            self.genreLabel.alpha = 1.0;
            self.genreLabel.text = [self titleForBar:goToOption];
            CGSize size = [self.genreLabel sizeThatFits:CGSizeMake(self.view.frame.size.width, FLT_MAX)];
            self.genreLabel.numberOfLines = 1;
            CGFloat centerY = self.genreLabel.center.y;
            self.genreLabel.frame = CGRectMake(0.0, 0.0, size.width, size.height);
            self.genreLabel.center = CGPointMake(self.view.frame.size.width + (self.genreLabel.frame.size.width / 2.0), centerY);
            [UIView animateWithDuration:12.0
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                  self.genreLabel.alpha = 1.0;
                                  self.genreLabel.center =
                                  CGPointMake(-(self.genreLabel.frame.size.width / 2.0), self.genreLabel.center.y);
                              } completion:^(BOOL finished) {
                                  [self animateStatus];
                              }];
         }];
    } else {
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            STRONGIFY(self);
            [self animateStatus];
        });
    }
}

- (NSString *)titleForBar:(GRInformationBarOption)option
{
    switch (option) {
        case GRInformationBarOptionGenre:
            return _currentStation.genre;
            break;
        case GRInformationBarOptionArtist:
            return _currentArtist;
            break;
        case GRInformationBarOptionSong:
            return _currentSong;
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
                tableViewCell.textLabel.textColor = [UIColor colorWithRed:0.082
                                                                    green:0.494
                                                                     blue:0.984
                                                                    alpha:1.00];
            } else {
                tableViewCell.textLabel.text = NSLocalizedString(@"button_pause", @"");
                tableViewCell.imageView.image = [UIImage imageNamed:@"GRPause"];
            }
        } else if (indexPath.row == 1) {
            if (_currentStation.favourite.boolValue) {
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
                [[GRRadioPlayer shared] playStation:_currentStation];
            }
        } else if (indexPath.row == 1) {
            _currentStation.favourite = [NSNumber numberWithBool:![_currentStation.favourite boolValue]];
            [_currentStation.managedObjectContext save:nil];
        }
        // set the value and save
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            if (_delegate &&
                [_delegate respondsToSelector:@selector(playerViewControllerPlayPreviousStation:)]) {
                [_delegate playerViewControllerPlayPreviousStation:self];
            }
        } else if (indexPath.row == 1) {
            if (_delegate &&
                [_delegate respondsToSelector:@selector(playerViewControllerPlayNextStation:)]) {
                [_delegate playerViewControllerPlayNextStation:self];
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
    [_informationTimer invalidate];
    _informationTimer = nil;
    _delegate = nil;
}

@end

