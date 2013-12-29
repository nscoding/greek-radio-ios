//
//  GRListTableViewController.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@interface GRListTableViewController : UITableViewController <MFMailComposeViewControllerDelegate,
                                            UISearchBarDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UINavigationController *navigationController;

@end
