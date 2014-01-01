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


static NSString *kSettingCellIdentifier = @"GRSettingsCell";


// ------------------------------------------------------------------------------------------


@implementation GRSettingsViewController


// ------------------------------------------------------------------------------------------
#pragma mark - View life cycle
// ------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    self.navigationController.navigationBar.topItem.title = NSLocalizedString(@"label_settings", @"");
    self.navigationController.navigationBar.translucent = NO;

    [self.settingsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kSettingCellIdentifier];
    [self buildAndConfigureCloseButton];
}


- (void)buildAndConfigureCloseButton
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
#pragma mark - Table View Delegate
// ------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:kSettingCellIdentifier
                                                                     forIndexPath:indexPath];

    tableViewCell.textLabel.textColor = [UIColor blackColor];
    tableViewCell.textLabel.backgroundColor = [UIColor whiteColor];
    
    if (indexPath.section == 0 ||
        indexPath.section == 1)
    {
        UISwitch *stateSwitch = [[UISwitch alloc] init];
        
        if (indexPath.section == 0)
        {
            [stateSwitch addTarget:self
                            action:@selector(lockSwitchDidChange:)
                  forControlEvents:UIControlEventValueChanged];
            
            stateSwitch.on = [GRUserDefaults isAutomaticLockDisabled];
            tableViewCell.textLabel.text = NSLocalizedString(@"label_auto_lock_header", @"");
        }
        else if (indexPath.section == 1)
        {
            [stateSwitch addTarget:self
                            action:@selector(shakeSwitchDidChange:)
                  forControlEvents:UIControlEventValueChanged];
            
            stateSwitch.on = [GRUserDefaults isShakeForRandomStationEnabled];
            tableViewCell.textLabel.text = NSLocalizedString(@"label_shake_music_header", @"");
        }
        tableViewCell.imageView.image = nil;
        tableViewCell.accessoryView = stateSwitch;
    }
    else
    {
        if (indexPath.row == 0)
        {
            tableViewCell.imageView.image = [UIImage imageNamed:@"GREmail"];
            tableViewCell.textLabel.text = NSLocalizedString(@"button_sugggest", @"");
        }
        else if (indexPath.row == 1)
        {
            tableViewCell.imageView.image = [UIImage imageNamed:@"GREmail"];
            tableViewCell.textLabel.text = NSLocalizedString(@"button_report", @"");
            tableViewCell.textLabel.textColor = [UIColor redColor];
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
    if (section == 2)
    {
        return 2;
    }
    
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


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 2)
    {
        return NSLocalizedString(@"label_contact_us", @"");
    }
    
    return @"";
}


- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2)
    {
        return YES;
    }
    
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0)
    {
        if ([MFMailComposeViewController canSendMail])
        {
            [GRAppearanceHelper setUpDefaultAppearance];
            MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
            mailController.mailComposeDelegate = self;
            mailController.subject = NSLocalizedString(@"label_new_stations", @"");
            [mailController setToRecipients:@[@"vasileia@nscoding.co.uk"]];
            
            [self.navigationController presentViewController:mailController
                                                    animated:YES
                                                  completion:nil];
        }
        else
        {
            [UIAlertView showWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                               message:NSLocalizedString(@"share_email_error", @"")
                     cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
                     otherButtonTitles:nil
                              tapBlock:nil];
        }
    }
    else if (indexPath.row == 1)
    {
        if ([MFMailComposeViewController canSendMail])
        {
            [GRAppearanceHelper setUpDefaultAppearance];
            MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
            mailController.mailComposeDelegate = self;
            mailController.subject = NSLocalizedString(@"label_something_wrong", @"");
            [mailController setToRecipients:@[@"team@nscoding.co.uk"]];
            
            [self.navigationController presentViewController:mailController
                                                    animated:YES
                                                  completion:nil];
        }
        else
        {
            [UIAlertView showWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                               message:NSLocalizedString(@"share_email_error", @"")
                     cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
                     otherButtonTitles:nil
                              tapBlock:nil];
        }
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (void)shakeSwitchDidChange:(UISwitch *)sender
{
    [GRUserDefaults setShakeForRandomStationEnabled:sender.isOn];
}


- (void)lockSwitchDidChange:(UISwitch *)sender
{
    [GRUserDefaults setAutomaticLockDisabled:sender.isOn];
}


- (void)closeSettingsViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Mail Composer delegate
// ------------------------------------------------------------------------------------------
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [GRAppearanceHelper setUpGreekRadioAppearance];
    [controller dismissViewControllerAnimated:YES completion:nil];
}


@end
