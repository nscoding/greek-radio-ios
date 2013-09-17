//
//  GRSidebarViewController.h
//  Greek Radio
//
//  Created by Patrick on 5/15/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


@interface GRSidebarViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *autoLockHeader;
@property (nonatomic, weak) IBOutlet UILabel *autoLockText;
@property (nonatomic, weak) IBOutlet UILabel *shakeText;
@property (nonatomic, weak) IBOutlet UILabel *shakeHeader;
@property (nonatomic, weak) IBOutlet UINavigationItem *settingsItem;
@property (nonatomic, weak) IBOutlet UISwitch *lockSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *shakeSwitch;

- (IBAction)shakeSwitchDidChange:(id)sender;
- (IBAction)lockSwitchDidChange:(id)sender;

@end
