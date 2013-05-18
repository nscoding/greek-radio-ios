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


// ------------------------------------------------------------------------------------------
#pragma mark - Orientations
// ------------------------------------------------------------------------------------------
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait | UIInterfaceOrientationPortraitUpsideDown;
}


- (NSUInteger)supportedInterfaceOrientations
{
    UIViewController *top = self.topViewController;
    return top.supportedInterfaceOrientations;
}

- (BOOL)shouldAutorotate
{
    UIViewController *top = self.topViewController;
    return [top shouldAutorotate];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait) ||
           (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}


@end
