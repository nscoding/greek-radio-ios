//
//  UITableView+Extensions.m
//  Wunderlist
//
//  Created by Patrick Chamelo on 01/11/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "UITableView+Extensions.h"

@implementation UITableView (Extensions)

#pragma mark - Index Path helpers

- (NSIndexPath *)previousIndexPathForPath:(NSIndexPath *)path
{
    NSIndexPath *previousIndexPath = nil;
    NSInteger nextRow = path.row - 1;
    NSInteger currentSection = path.section;
    
    if (nextRow >= 0) {
        previousIndexPath = [NSIndexPath indexPathForRow:nextRow inSection:currentSection];
    } else {
        NSInteger nextSection = currentSection - 1;
        if (nextSection >= 0) {
            previousIndexPath = [NSIndexPath indexPathForRow:0 inSection:nextSection];
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
    
    if (nextRow < rowCount) {
        nextIndexPath = [NSIndexPath indexPathForRow:nextRow inSection:currentSection];
    } else {
        NSInteger sectionCount = self.numberOfSections;
        NSInteger nextSection = currentSection + 1;
        if (nextSection < sectionCount) {
            nextIndexPath = [NSIndexPath indexPathForRow:0 inSection:nextSection];
        }
    }
    return nextIndexPath;
}

- (NSIndexPath *)firstIndexPath
{
    NSInteger numberOfRowsInFirstSection = [self numberOfRowsInSection:0];
    if (numberOfRowsInFirstSection == 0) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (NSIndexPath *)lastIndexPath
{
    NSInteger numberOfSections = [self numberOfSections];
    NSInteger numberOfRowsInLastSection = [self numberOfRowsInSection:(numberOfSections - 1)];
    if (numberOfSections == 0 && numberOfRowsInLastSection == 0) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:(numberOfRowsInLastSection - 1) inSection:(numberOfSections - 1)];
}

@end
