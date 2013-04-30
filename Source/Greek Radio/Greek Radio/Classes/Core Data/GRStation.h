//
//  GRStation.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GRStation : NSManagedObject

@property (nonatomic, retain) NSNumber * favourite;
@property (nonatomic, retain) NSString * genre;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * stationURL;
@property (nonatomic, retain) NSString * streamURL;
@property (nonatomic, retain) NSString * title;

@end
