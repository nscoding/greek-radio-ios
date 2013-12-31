//
//  GRNavigationController.m
//  Greek Radio
//
//  Created by Patrick on 5/18/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRNavigationController.h"


// ------------------------------------------------------------------------------------------


@implementation GRNavigationController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureNavigationBar];
}


- (void)configureNavigationBar
{
    self.navigationBar.tintColor = [UIColor whiteColor];
}


@end
