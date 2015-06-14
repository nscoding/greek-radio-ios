//
//  GRStationsManager.h
//  Greek Radio
//
//  Created by Patrick Chamelo on 29/12/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


typedef NS_ENUM(NSUInteger, GRStationsLayout)
{
    GRStationsLayoutGenre = 0,
    GRStationsLayoutCity,
    GRStationsLayoutAlphabetical
};

@class GRStationsManager;
@class GRStation;

@protocol GRStationsManagerDelegate <NSObject>

@required
- (void)stationManager:(GRStationsManager *)stationManager shouldPlayStation:(GRStation *)station;

@end

@interface GRStationsManager : NSObject

@property (nonatomic, weak) id<GRStationsManagerDelegate> delegate;
@property (nonatomic, assign) GRStationsLayout stationsLayout;

- (instancetype)initWithTableView:(UITableView *)tableView stationsLayout:(GRStationsLayout)layout;
- (void)setupFetchedResultsControllersWithString:(NSString *)filter;
- (void)playStationAtIndexPath:(NSIndexPath *)indexPath;
- (void)playNextStation;
- (void)playPreviousStation;
- (NSUInteger)numberOfStations;

@end
