//
//  GRSidebarViewController.m
//  Greek Radio
//
//  Created by Patrick on 5/15/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRSidebarViewController.h"


@implementation GRSidebarViewController

- (void)viewDidLoad
{
    self.autoLockHeader.text = NSLocalizedString(@"label_auto_lock_header", @"");
    self.autoLockText.text = NSLocalizedString(@"label_auto_lock_text", @"");
    self.shakeText.text = NSLocalizedString(@"label_shake_music_text", @"");
    self.shakeHeader.text = NSLocalizedString(@"label_shake_music_header", @"");
    self.settingsItem.title = NSLocalizedString(@"label_settings", @"");
  
    [super viewDidLoad];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL autoLockDisabled = [userDefaults boolForKey:@"GreekRadioAutoLockDisabled"];
    [UIApplication sharedApplication].idleTimerDisabled = autoLockDisabled;
    [self.lockSwitch setOn:autoLockDisabled animated:NO];

    BOOL shakeEnabled = [userDefaults boolForKey:@"GreekRadioShakeRandom"];
    [self.shakeSwitch setOn:shakeEnabled animated:NO];

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


@end
