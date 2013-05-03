//
//  GRShareHelper.m
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRShareHelper.h"
#import "GRRadioPlayer.h"
#import "BlockAlertView.h"


// ------------------------------------------------------------------------------------------


#define kSorryTitle @"Sorry"
#define kAppiTunesURL @"https://itunes.apple.com/app/id321094050?ls=1&mt=8"
#define kTextNoStation @"I am listening to Greek music on my iPhone using Greek Radio"
#define kTextWithStation @"I am listening to %@ using Greek Radio"
#define kErrorTwitter @"You can't send a tweet right now, please make sure your device has at least one Twitter account setup"
#define kErrorFacebook @"You can't update your status right now, please make sure your device has at least one Facebook account setup"


// ------------------------------------------------------------------------------------------


@implementation GRShareHelper

+ (void)tweetTappedOnController:(UIViewController *)controller
{
    if ([[NSInternetDoctor shared] connected] == NO)
    {
        [[NSInternetDoctor shared] showNoInternetAlert];
        return;
    }
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:SLServiceTypeTwitter];
        
        if ([GRRadioPlayer shared].stationName.length > 0)
        {
            [tweetSheet setInitialText:[NSString stringWithFormat:kTextWithStation,
                                        [GRRadioPlayer shared].stationName]];
        }
        else
        {
            [tweetSheet setInitialText:[NSString stringWithFormat:kTextNoStation]];
        }
        
        [tweetSheet addURL:[NSURL URLWithString:kAppiTunesURL]];
        [controller presentViewController:tweetSheet
                                 animated:YES
                               completion:nil];
    }
    else
    {
        [BlockAlertView showInfoAlertWithTitle:kSorryTitle
                                       message:kErrorTwitter];
    }
}


+ (void)facebookTappedOnController:(UIViewController *)controller
{
    if ([[NSInternetDoctor shared] connected] == NO)
    {
        [[NSInternetDoctor shared] showNoInternetAlert];
        return;
    }
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *facebookSheet = [SLComposeViewController
                                                  composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        if ([GRRadioPlayer shared].stationName.length > 0)
        {
            [facebookSheet setInitialText:[NSString stringWithFormat:kTextWithStation,
                                        [GRRadioPlayer shared].stationName]];
        }
        else
        {
            [facebookSheet setInitialText:[NSString stringWithFormat:kTextNoStation]];
        }
        
        [facebookSheet addURL:[NSURL URLWithString:kAppiTunesURL]];
        [controller presentViewController:facebookSheet
                                 animated:YES
                               completion:nil];
    }
    else
    {
        [BlockAlertView showInfoAlertWithTitle:kSorryTitle
                                       message:kErrorFacebook];
    }
}


@end
