//
//  GRPlayerViewController.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRPlayerViewController.h"
#
@interface GRPlayerViewController ()

@end

@implementation GRPlayerViewController

// ------------------------------------------------------------------------------------------
#pragma mark - Initializer
// ------------------------------------------------------------------------------------------
- (id)initWithStation:(GRStation *)station
{
    if ((self = [super initWithNibName:@"GRPlayerViewController" bundle:nil]))
    {
        [self.view setBackgroundColor:[UIColor blackColor]];
        [self buildAndConfigureStationName:station.title];
    }
    
    return self;
}


- (void)buildAndConfigureStationName:(NSString *)name
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:21];
    label.textColor = [UIColor colorWithRed:0.839f green:0.839f blue:0.839f alpha:1.00f];
    label.shadowColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    label.shadowOffset = CGSizeMake(0, 1);
    label.textAlignment = NSTextAlignmentCenter;
    label.text =  [name copy];
    label.numberOfLines = 0;
    
    [label sizeToFit];
    [label setCenter:CGPointMake(self.view.center.x, 280)];
    
    [self.view addSubview:label];
}


- (void)viewDidLoad
{
    self.navigationItem.title = @"Now Playing";   
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
