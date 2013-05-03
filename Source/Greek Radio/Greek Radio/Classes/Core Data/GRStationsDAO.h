//
//  GRStationsDAO.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStation.h"

@interface GRStationsDAO : NSObject

- (BOOL)createStationWithTitle:(NSString *)title
                       siteURL:(NSString *)stationURL
                     streamURL:(NSString *)streamURL
                         genre:(NSString *)genre
                      location:(NSString *)location
                   serverBased:(BOOL)server;

- (BOOL)removeAll;
- (NSArray *)retrieveAll;
- (GRStation *)retrieveByTitle:(NSString *)title;

- (NSArray *)retrieveAllServerBased:(NSString *)filter;
- (NSArray *)retrieveAllLocalBased:(NSString *)filter;
- (NSArray *)retrieveAllFavourites:(NSString *)filter;

@end
