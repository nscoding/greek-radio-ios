//
//  GRWoodNavigationBar.m
//  Greek Radio
//
//  Created by Patrick on 5/2/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRWoodNavigationBar.h"

@implementation GRWoodNavigationBar


- (void)drawRect:(CGRect)rect
{
    UIImage *image = [UIImage imageNamed:@"GRWoodHeader"];
    [image drawInRect:rect];
    
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:@"Greek Radio"];
    [title drawAtPoint:CGPointMake(0, 0)];
}


@end
