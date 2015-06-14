//
//  GRWebService.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRWebService.h"
#import "GRStationsDAO.h"
#import "CWStatusBarNotification.h"

typedef NS_ENUM(NSUInteger, GRWebServiceSyncStatus)
{
    GRWebServiceSyncStatusError = -1,
    GRWebServiceSyncStatusNoInternet = 0,
    GRWebServiceSyncStatusSuccessful = 1,
};

#define kWebServiceURL @"http://nscoding.co.uk/xml/RadioStations.xml"
// #define kWebServiceURL @"http://nscoding.co.uk/xml/RadioStationsBeta.xml"

#define kTopElement @"station"
    #define kElementTitle @"title"
    #define kElementStreamURL @"streamURL"
    #define kElementStationURL @"siteURL"
    #define kElementGenre @"genre"
    #define kElemenLocation @"location"

@implementation GRWebService
{
    NSDate *_dateLastSynced;
    NSXMLParser *_rssParser;
    NSString *_currentElement;
    NSMutableDictionary *_data;
    GRStationsDAO *_stationsDAO;
    CWStatusBarNotification *_statusBarNotification;
    BOOL _parsing;
}
#pragma mark - Singleton

+ (GRWebService *)shared
{
    static dispatch_once_t pred;
    static GRWebService *shared = nil;
    dispatch_once(&pred, ^() {
        shared = [[GRWebService alloc] init];
    });
    
    return shared;
}

#pragma mark - Initializer

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        _stationsDAO = [[GRStationsDAO alloc] init];
    }
    return self;
}

#pragma mark - Notifications

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self parseXML];
}

#pragma mark - Actions

- (void)parseXML
{
    // Begin parsing the XML file located on our server www.nscoding.co.uk/..
    // with an asynchronous execution in global concurrent queue
    [self parseXMLInBackgroundThread];
}

- (void)parseXMLInBackgroundThread
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^ {
        if (_parsing) {
            return;
        }
        
        if ([[NSInternetDoctor shared] isConnected] == NO) {
            _parsing = NO;
            [self endSyncingOnMainThread:GRWebServiceSyncStatusNoInternet];
        } else {
            _parsing = YES;
            _dateLastSynced = [NSDate date];
            [self startSyncingOnMainThread];
            [self parseXMLFileAtURL:kWebServiceURL];
            [self endSyncingOnMainThread:GRWebServiceSyncStatusSuccessful];
        }
    });
}

- (void)startSyncingOnMainThread
{
    if (_statusBarNotification) {
        return;
    }
    
    WEAKIFY(self);
    dispatch_async(dispatch_get_main_queue(), ^() {
        STRONGIFY(self);
        _statusBarNotification = [CWStatusBarNotification new];
        
        // set default blue color (since iOS 7.1, default window tintColor is black)
        _statusBarNotification.notificationLabelBackgroundColor = [UIColor colorWithRed:0.180f green:0.180f blue:0.161f alpha:1.00f];
        _statusBarNotification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
        _statusBarNotification.notificationAnimationOutStyle = CWNotificationAnimationStyleBottom;
        [_statusBarNotification displayNotificationWithMessage:NSLocalizedString(@"label_syncing", @"") completion:NULL];
        [GRNotificationCenter postSyncManagerDidStartNotificationWithSender:self];
    });
}

- (void)endSyncingOnMainThread:(GRWebServiceSyncStatus)status
{
    NSAssert([NSThread isMainThread] == NO, @"End syncing should be on a background thread.");
    WEAKIFY(self);
    dispatch_sync(dispatch_get_main_queue(), ^()
    {
        STRONGIFY(self);
        NSAssert([NSThread isMainThread], @"UI and notifications should be on the main thread.");
        if (status == GRWebServiceSyncStatusNoInternet) {
            [[NSInternetDoctor shared] showNoInternetAlert];
        } else if (status == GRWebServiceSyncStatusError) {
            if ([[NSInternetDoctor shared] isConnected]) {
                [UIAlertView showWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                                   message:NSLocalizedString(@"app_fetch_stations_error", @"")
                         cancelButtonTitle:NSLocalizedString(@"button_dismiss", @"")
                         otherButtonTitles:nil
                                  tapBlock:nil];
            }
        }
        [_statusBarNotification dismissNotification];
        _statusBarNotification = nil;
        
        [GRNotificationCenter postSyncManagerDidEndNotificationWithSender:self];
    });
}

#pragma mark - XML parsing

- (void)parseXMLFileAtURL:(NSString *)URL
{
    NSURL *xmlURL = [NSURL URLWithString:URL];
    _rssParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    _rssParser.delegate = self;
    [_rssParser setShouldProcessNamespaces:NO];
    [_rssParser setShouldReportNamespacePrefixes:NO];
    [_rssParser setShouldResolveExternalEntities:NO];
    [_rssParser parse];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    _dateLastSynced = nil;
    _parsing = NO;
    [self endSyncingOnMainThread:GRWebServiceSyncStatusError];
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError;
{

}

-  (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
     attributes:(NSDictionary *)attributeDict
{
	_currentElement = [elementName copy];
    if ([elementName isEqualToString:kTopElement]) {
        _data = [NSMutableDictionary dictionary];
	}
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:kTopElement]) {
        [_stationsDAO createStationWithTitle:[_data[kElementTitle] copy]
                                     siteURL:[_data[kElementStationURL] copy]
                                   streamURL:[_data[kElementStreamURL] copy]
                                       genre:[_data[kElementGenre] copy]
                                    location:[_data[kElemenLocation] copy]
                                 serverBased:YES];
        [_data removeAllObjects];
        _data = nil;
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSMutableString *currentValue = [self valueForCurrentElement];
    [currentValue appendString:string];
    [_data setObject:currentValue forKey:_currentElement];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    parser = nil;
    _parsing = NO;
    if (_dateLastSynced) {
        [_stationsDAO removeAllStationsBeforeDate:_dateLastSynced];
    }
}

- (NSMutableString *)valueForCurrentElement
{
    NSMutableString *property = [_data objectForKey:_currentElement];
    if (property == nil) {
        property = [[NSMutableString alloc] init];
        [_data setObject:property forKey:_currentElement];
    }
    return property;
}

@end
