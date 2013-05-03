//
//  GRStationsDAO.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRStationsDAO.h"
#import "GRStation.h"
#import "GRCoreDataStack.h"


// ------------------------------------------------------------------------------------------


@implementation GRStationsDAO


- (BOOL)createStationWithTitle:(NSString *)title
                       siteURL:(NSString *)stationURL
                     streamURL:(NSString *)streamURL
                         genre:(NSString *)genre
                      location:(NSString *)location
                   serverBased:(BOOL)server
{
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    stationURL = [stationURL stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    streamURL = [streamURL stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    genre = [genre stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    location = [location stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    if (title.length == 0 || streamURL.length == 0 ||
        genre.length == 0 || location.length == 0)
    {
        return NO;
    }
    
    NSManagedObjectContext *managedObjectContext = [[GRCoreDataStack shared] managedObjectContext];
    GRStation *newStation = [self retrieveByTitle:title];
    
    if (newStation == nil)
    {
        newStation = (GRStation *)[NSEntityDescription insertNewObjectForEntityForName:@"GRStation"
                                                                inManagedObjectContext:managedObjectContext];
    }
    
    newStation.title = title;
    newStation.stationURL = stationURL;
    newStation.streamURL = streamURL;
    newStation.genre = genre;
    newStation.location = location;
    newStation.server = [NSNumber numberWithBool:server];
    
    NSError *error = nil;
    
    if ([managedObjectContext save:&error] == NO)
    {
        return NO;
    }
    
    return YES;
    
}


- (BOOL)removeAll
{
    NSArray *stations = [self retrieveAll];
    NSManagedObjectContext *managedObjectContext = [[GRCoreDataStack shared] managedObjectContext];
    
    for (GRStation *station in stations)
    {
        [managedObjectContext deleteObject:station];
    }
    
    NSError *error = nil;
    
    if (![managedObjectContext save:&error] == NO)
    {
        return NO;
    }
    
    return YES;
}


- (GRStation *)retrieveByTitle:(NSString *)title
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", title];
    NSArray *stations = [[GRCoreDataStack shared] fetchObjectsForEntityName:@"GRStation"
                                                              withPredicate:predicate];
    
    if ([stations count] > 0)
    {
        return [stations objectAtIndex:0];
    }
    
    return nil;
}


- (NSArray *)retrieveAll
{
    NSArray *stations = [[GRCoreDataStack shared] fetchObjectsForEntityName:@"GRStation"
                                                              withPredicate:nil];
    
    return stations;
}


- (NSArray *)retrieveAllServerBased:(NSString *)filter
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"server == YES"];
    
    if (filter.length > 0)
    {
       predicate = [NSPredicate predicateWithFormat:@"server == YES AND (title CONTAINS[cd] %@ "
                                                     "|| location CONTAINS[cd] %@ || genre CONTAINS[cd] %@)",
                                                        filter, filter, filter];
    }
    
    NSArray *stations = [[GRCoreDataStack shared] fetchObjectsForEntityName:@"GRStation"
                                                              withPredicate:predicate];
    
    return stations;
}


- (NSArray *)retrieveAllLocalBased:(NSString *)filter
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"server == NO"];

    if (filter.length > 0)
    {
        predicate = [NSPredicate predicateWithFormat:@"server == NO AND (title CONTAINS[cd] %@ "
                     "|| location CONTAINS[cd] %@ || genre CONTAINS[cd] %@)",
                     filter, filter, filter];
    }

    NSArray *stations = [[GRCoreDataStack shared] fetchObjectsForEntityName:@"GRStation"
                                                              withPredicate:predicate];
    
    return stations;
}


- (NSArray *)retrieveAllFavourites:(NSString *)filter
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"favourite == YES"];
    
    if (filter.length > 0)
    {
        predicate = [NSPredicate predicateWithFormat:@"favourite == YES AND (title CONTAINS[cd] %@ "
                     "|| location CONTAINS[cd] %@ || genre CONTAINS[cd] %@)",
                     filter, filter, filter];
    }

    NSArray *stations = [[GRCoreDataStack shared] fetchObjectsForEntityName:@"GRStation"
                                                              withPredicate:predicate];
    
    return stations;
}


@end
