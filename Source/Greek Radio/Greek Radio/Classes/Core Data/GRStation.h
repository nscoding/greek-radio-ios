//
//  GRStation.h
//  Greek Radio
//
//  Created by Patrick on 5/6/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface GRStation : NSManagedObject

@property (nonatomic, retain) NSNumber *favourite;
@property (nonatomic, retain) NSString *genre;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSNumber *server;
@property (nonatomic, retain) NSString *stationURL;
@property (nonatomic, retain) NSString *streamURL;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *dateUpdated;
@property (nonatomic, retain) NSDate *dateCreated;

@end
