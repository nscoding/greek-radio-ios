//
//  GRAddStationViewController.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRAddStationViewController.h"

@interface GRAddStationViewController ()

@end


@implementation GRAddStationViewController


// ------------------------------------------------------------------------------------------
#pragma mark - Initializer
// ------------------------------------------------------------------------------------------
- (id)init
{
    if ((self = [super initWithNibName:@"GRAddStationViewController" bundle:nil]))
    {
        [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"GRPaperBackground"]]];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (IBAction)cancelPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)donePressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}


@end
