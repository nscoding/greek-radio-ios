//
//  UITableView+Extensions.h
//  Wunderlist
//
//  Created by Patrick Chamelo on 01/11/13.
//  Copyright (c) 2013 6Wunderkinder. All rights reserved.
//


@interface UITableView (Extensions)

- (NSIndexPath *)previousIndexPathForPath:(NSIndexPath *)path;
- (NSIndexPath *)nextIndexPathForPath:(NSIndexPath *)path;

@end
