//
//  GRListTableViewController.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@interface GRListTableViewController : UITableViewController<MFMailComposeViewControllerDelegate>

@property (nonatomic, assign) IBOutlet UINavigationController *navigationController;
@property (nonatomic, assign) IBOutlet UISearchBar *searchBar;

@end
