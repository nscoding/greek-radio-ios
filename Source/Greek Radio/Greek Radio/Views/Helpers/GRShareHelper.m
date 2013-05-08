//
//  GRShareHelper.m
//  Greek Radio
//
//  Created by Patrick on 5/3/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRShareHelper.h"


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
            [tweetSheet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"share_station_$_text", @""),
                                        [GRRadioPlayer shared].stationName]];
        }
        else
        {
            [tweetSheet setInitialText:NSLocalizedString(@"share_generic_text", @"")];
        }
        
        [tweetSheet addURL:[NSURL URLWithString:kAppiTunesURL]];
        [controller presentViewController:tweetSheet
                                 animated:YES
                               completion:nil];
    }
    else
    {
        [BlockAlertView showInfoAlertWithTitle:NSLocalizedString(@"label_sorry", @"")
                                       message:NSLocalizedString(@"share_twitter_error", @"")];
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
            [facebookSheet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"share_station_$_text", @""),
                                        [GRRadioPlayer shared].stationName]];
        }
        else
        {
            [facebookSheet setInitialText:NSLocalizedString(@"share_generic_text", @"")];
        }
        
        [facebookSheet addURL:[NSURL URLWithString:kAppiTunesURL]];
        [controller presentViewController:facebookSheet
                                 animated:YES
                               completion:nil];
    }
    else
    {
        [BlockAlertView showInfoAlertWithTitle:NSLocalizedString(@"label_sorry", @"")
                                       message:NSLocalizedString(@"share_facebook_error", @"")];
    }
}


@end
