//
//  UITableView+Extensions.m
//  Wunderlist
//
//  Created by Patrick Chamelo on 01/11/13.
//  Copyright (c) 2013 6Wunderkinder. All rights reserved.
//

#import "UITableView+Extensions.h"


// ------------------------------------------------------------------------------------------


@implementation UITableView (Extensions)

// ------------------------------------------------------------------------------------------
#pragma mark - Index Path helpers
// ------------------------------------------------------------------------------------------
- (NSIndexPath *)previousIndexPathForPath:(NSIndexPath *)path
{
    NSIndexPath *previousIndexPath = nil;
    NSInteger nextRow = path.row - 1;
    NSInteger currentSection = path.section;
    
    if (nextRow >= 0)
    {
        previousIndexPath = [NSIndexPath indexPathForRow:nextRow
                                               inSection:currentSection];
    }
    else
    {
        NSInteger nextSection = currentSection - 1;
        if (nextSection >= 0)
        {
            previousIndexPath = [NSIndexPath indexPathForRow:0
                                                   inSection:nextSection];
        }
    }
    
    return previousIndexPath;
}


- (NSIndexPath *)nextIndexPathForPath:(NSIndexPath *)path
{
    NSIndexPath *nextIndexPath = nil;
    NSInteger rowCount = [self numberOfRowsInSection:path.section];
    NSInteger nextRow = path.row + 1;
    NSInteger currentSection = path.section;
    
    if (nextRow < rowCount)
    {
        nextIndexPath = [NSIndexPath indexPathForRow:nextRow
                                           inSection:currentSection];
    }
    else
    {
        NSInteger sectionCount = self.numberOfSections;
        NSInteger nextSection = currentSection + 1;

        if (nextSection < sectionCount)
        {
            nextIndexPath = [NSIndexPath indexPathForRow:0
                                               inSection:nextSection];
        }
    }
    
    return nextIndexPath;
}


@end
