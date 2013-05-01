//
//  GRViewController.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRViewController.h"
#import "GRStationsDAO.h"
#import "GRStationCellView.h"


// ------------------------------------------------------------------------------------------


@interface GRViewController ()

@property (nonatomic, strong) GRStationsDAO *stationsDAO;
@property (nonatomic, strong) NSMutableArray *stations;

@end


// ------------------------------------------------------------------------------------------


@implementation GRViewController

// ------------------------------------------------------------------------------------------
#pragma mark -
// ------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];

    // create the DAO object
    self.stationsDAO = [[GRStationsDAO alloc] init];
    self.stations = [NSMutableArray arrayWithArray:[self.stationsDAO retrieveAll]];    
    [self.stationsTableView reloadData];
    
    // register notifications
    [self registerObservers];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Notifications
// ------------------------------------------------------------------------------------------
- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
}


- (void)contextDidSave:(NSNotification *)notification
{
    [self.stations removeAllObjects];
    self.stations = [NSMutableArray arrayWithArray:[self.stationsDAO retrieveAll]];
    
    [self.stationsTableView reloadData];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Table View delegate
// ------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.stations.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [GRStationCellView reusableIdentifier];
    GRStationCellView *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {
        cell = [[GRStationCellView alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    
        GRStation *station = [self.stations objectAtIndex:indexPath.row];
        cell.title.text = [NSString stringWithFormat:@"%@",station.title];
        cell.subtitle.text = [NSString stringWithFormat:@"%@", station.location];
    }
    
    [cell setNeedsDisplay];
    
    return cell;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Memory
// ------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObject:self];
}


@end
