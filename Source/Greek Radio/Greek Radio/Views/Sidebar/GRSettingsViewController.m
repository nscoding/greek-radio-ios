//
//  GRSidebarViewController.m
//  Greek Radio
//
//  Created by Patrick on 5/15/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRSettingsViewController.h"
#import "UIDevice+Extensions.h"


// ------------------------------------------------------------------------------------------


@implementation GRSettingsViewController


- (void)viewDidLoad
{
    [self setupCloseButton];

    self.autoLockHeader.text = NSLocalizedString(@"label_auto_lock_header", @"");
    self.autoLockText.text = NSLocalizedString(@"label_auto_lock_text", @"");
    self.shakeText.text = NSLocalizedString(@"label_shake_music_text", @"");
    self.shakeHeader.text = NSLocalizedString(@"label_shake_music_header", @"");
    self.navigationController.navigationBar.topItem.title = NSLocalizedString(@"label_settings", @"");
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL autoLockDisabled = [userDefaults boolForKey:@"GreekRadioAutoLockDisabled"];
    [UIApplication sharedApplication].idleTimerDisabled = autoLockDisabled;
    [self.lockSwitch setOn:autoLockDisabled animated:NO];

    BOOL shakeEnabled = [userDefaults boolForKey:@"GreekRadioShakeRandom"];
    [self.shakeSwitch setOn:shakeEnabled animated:NO];
}


- (void)setupCloseButton
{
    NSDictionary *titleTextAttributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:17.0],
                                           NSForegroundColorAttributeName : [UIColor whiteColor] };
    
    UIBarButtonItem *doneItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(closeSettingsViewController)];
    
    [doneItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = doneItem;
}



// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (IBAction)shakeSwitchDidChange:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:self.shakeSwitch.isOn forKey:@"GreekRadioShakeRandom"];
    [userDefaults synchronize];
}


- (IBAction)lockSwitchDidChange:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:self.lockSwitch.isOn forKey:@"GreekRadioAutoLockDisabled"];
    [userDefaults synchronize];
}


- (void)closeSettingsViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
