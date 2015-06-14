//
//  UITableView+Extensions.h
//  Wunderlist
//
//  Created by Patrick Chamelo on 01/11/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


@interface UITableView (Extensions)

- (NSIndexPath *)previousIndexPathForPath:(NSIndexPath *)path;
- (NSIndexPath *)nextIndexPathForPath:(NSIndexPath *)path;

- (NSIndexPath *)firstIndexPath;
- (NSIndexPath *)lastIndexPath;

@end
