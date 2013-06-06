//
//  GRSidebarViewController.h
//  Greek Radio
//
//  Created by Patrick on 5/15/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


@interface GRSidebarViewController : UIViewController

@property (nonatomic, assign) IBOutlet UILabel *autoLockHeader;
@property (nonatomic, assign) IBOutlet UILabel *autoLockText;
@property (nonatomic, assign) IBOutlet UILabel *shakeText;
@property (nonatomic, assign) IBOutlet UILabel *shakeHeader;
@property (nonatomic, assign) IBOutlet UINavigationItem *settingsItem;

@property (nonatomic, assign) IBOutlet UISwitch *lockSwitch;
@property (nonatomic, assign) IBOutlet UISwitch *shakeSwitch;

- (IBAction)shakeSwitchDidChange:(id)sender;
- (IBAction)lockSwitchDidChange:(id)sender;

@end
