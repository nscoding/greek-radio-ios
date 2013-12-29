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
    self.navigationController.navigationBar.topItem.title = NSLocalizedString(@"label_settings", @"");
    self.navigationController.navigationBar.translucent = NO;

    [self setupCloseButton];
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
#pragma mark - Table View
// ------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:@"SettingsCell"];
    
    UISwitch *stateSwitch = [[UISwitch alloc] init];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if (indexPath.section == 0)
    {
        [stateSwitch addTarget:self
                        action:@selector(lockSwitchDidChange:)
              forControlEvents:UIControlEventValueChanged];
        
        stateSwitch.on = [userDefaults boolForKey:@"GreekRadioAutoLockDisabled"];
        tableViewCell.textLabel.text = NSLocalizedString(@"label_auto_lock_header", @"");
    }
    else if (indexPath.section == 1)
    {
        [stateSwitch addTarget:self
                        action:@selector(shakeSwitchDidChange:)
              forControlEvents:UIControlEventValueChanged];

        stateSwitch.on = [userDefaults boolForKey:@"GreekRadioShakeRandom"];
        tableViewCell.textLabel.text = NSLocalizedString(@"label_shake_music_header", @"");
    }
    
    
    tableViewCell.accessoryView = stateSwitch;
    
    return tableViewCell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
    {
        return NSLocalizedString(@"label_auto_lock_text", @"");
    }
    else if (section == 1)
    {
        return NSLocalizedString(@"label_shake_music_text", @"");
    }
    
    return @"";
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (void)shakeSwitchDidChange:(UISwitch *)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:sender.isOn forKey:@"GreekRadioShakeRandom"];
    [userDefaults synchronize];
}


- (void)lockSwitchDidChange:(UISwitch *)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:sender.isOn forKey:@"GreekRadioAutoLockDisabled"];
    [userDefaults synchronize];
    [UIApplication sharedApplication].idleTimerDisabled = sender.selected;
}


- (void)closeSettingsViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
