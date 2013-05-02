//
//  GRListTableViewController.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRListTableViewController.h"
#import "GRStationsDAO.h"
#import "GRStationCellView.h"
#import "GRPlayerViewController.h"
#import "GRAddStationViewController.h"
#import "BlockAlertView.h"

#import "GRWebService.h"


// ------------------------------------------------------------------------------------------


@interface GRListTableViewController ()

@property (nonatomic, strong) GRStationsDAO *stationsDAO;
@property (nonatomic, strong) NSMutableArray *stations;

@end


// ------------------------------------------------------------------------------------------


@implementation GRListTableViewController

// ------------------------------------------------------------------------------------------
#pragma mark - Initializer
// ------------------------------------------------------------------------------------------
- (id)init
{
    if ((self = [super initWithNibName:@"GRListTableViewController" bundle:nil]))
    {
        [self.tableView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"GRPaperBackground"]]];
    }
    
    return self;
}


// ------------------------------------------------------------------------------------------
#pragma mark -
// ------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Welcome to Greek Radio"
                                                   message:@"This is a very long message, designed just to show you how smart this class is"];
    
    [alert setCancelButtonWithTitle:@"Dismiss" block:nil];
    [alert show];

    
    // add the pull to refresh view
    [self buildAndConfigurePullToRefresh];

    [super viewDidLoad];
        
    // create the DAO object
    self.stationsDAO = [[GRStationsDAO alloc] init];
    
    // get the stations
    [self configureStations];
    
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    
    // register notifications
    [self registerObservers];
    
    
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    addButton.frame = CGRectMake(0, 0, 30, 30);
    
    [addButton setImage:[UIImage imageNamed:@"GRAddIcon"] forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(addButtonPressed:)
        forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]
                               initWithCustomView:addButton];

    self.navigationItem.rightBarButtonItem = rightButton;
}


- (void)configureStations
{
    [self.stations removeAllObjects];
    self.stations = [NSMutableArray arrayWithArray:[self.stationsDAO retrieveAll]];
    [self.tableView reloadData];
}


- (void)buildAndConfigurePullToRefresh
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refresh Stations"];
    [self.refreshControl addTarget:self
                            action:@selector(updateStations)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.refreshControl endRefreshing];
}

// ------------------------------------------------------------------------------------------
#pragma mark - Pull to refresh
// ------------------------------------------------------------------------------------------
- (void)updateStations
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[GRWebService shared] parseXML];
    });
}


// ------------------------------------------------------------------------------------------
#pragma mark - Notifications
// ------------------------------------------------------------------------------------------
- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncDidEnd:)
                                                 name:GRNotificationSyncManagerDidEnd
                                               object:nil];
}

- (void)syncDidEnd:(NSNotification *)notification
{
    [self configureStations];
    [self.refreshControl performSelector:@selector(endRefreshing)];
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



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    GRStation *station = [self.stations objectAtIndex:indexPath.row];
    GRPlayerViewController *playController = [[GRPlayerViewController alloc] initWithStation:station];
    [self.navigationController pushViewController:playController animated:YES];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (void)addButtonPressed:(UIButton *)sender
{
    GRAddStationViewController *addStationController = [[GRAddStationViewController alloc] init];
    [self.navigationController presentModalViewController:addStationController animated:YES];
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
