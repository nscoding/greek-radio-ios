//
//  GRWebService.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRWebService.h"
#import "GRStationsDAO.h"
#import "MTStatusBarOverlay.h"


// ------------------------------------------------------------------------------------------


#define kWebServiceURL @"http://nscoding.co.uk/xml/RadioStations.xml"
// #define kWebServiceURL @"http://nscoding.co.uk/xml/RadioStationsBeta.xml"

#define kTopElement @"station"
    #define kElementTitle @"title"
    #define kElementStreamURL @"streamURL"
    #define kElementStationURL @"siteURL"
    #define kElementGenre @"genre"
    #define kElemenLocation @"location"


// ------------------------------------------------------------------------------------------


@interface GRWebService ()

@property (nonatomic, strong) NSDate *dateLastSynced;
@property (nonatomic, strong) NSXMLParser *rssParser;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSMutableDictionary *dataDictionary;
@property (nonatomic, strong) GRStationsDAO *stationsDAO;
@property (nonatomic, assign) BOOL isParsing;

@end


// ------------------------------------------------------------------------------------------


@implementation GRWebService

// ------------------------------------------------------------------------------------------
#pragma mark - Singleton
// ------------------------------------------------------------------------------------------
+ (GRWebService *)shared
{
    static dispatch_once_t pred;
    static GRWebService *shared = nil;
    
    dispatch_once(&pred, ^()
                  {
                      shared = [[GRWebService alloc] init];
                  });
    
    return shared;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Initializer
// ------------------------------------------------------------------------------------------
- (id)init
{
    if ((self = [super init]))
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        self.stationsDAO = [[GRStationsDAO alloc] init];
    }
    
    return self;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Notifications
// ------------------------------------------------------------------------------------------
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self parseXML];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Actions
// ------------------------------------------------------------------------------------------
- (void)parseXML
{
    if (self.isParsing)
    {
        return;
    }
    
    if ([[NSInternetDoctor shared] connected] == NO)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSInternetDoctor shared] showNoInternetAlert];
            [GRNotificationCenter postSyncManagerDidEndNotificationWithSender:nil];
        });

        self.isParsing = NO;
        
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [[MTStatusBarOverlay sharedOverlay] postImmediateMessage:NSLocalizedString(@"label_syncing", @"")
                                                        animated:YES];
        [GRNotificationCenter postSyncManagerDidStartNotificationWithSender:nil];
    });

    self.isParsing = YES;
    self.dateLastSynced = [NSDate date];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^
    {
        [self parseXMLFileAtURL:kWebServiceURL];
        
        dispatch_sync(dispatch_get_main_queue(), ^
        {

            [[MTStatusBarOverlay sharedOverlay] hide];
            [GRNotificationCenter postSyncManagerDidEndNotificationWithSender:nil];

        });
    });
}


// ------------------------------------------------------------------------------------------
#pragma mark - XML parsing
// ------------------------------------------------------------------------------------------
- (void)parseXMLFileAtURL:(NSString *)URL
{
    NSURL *xmlURL = [NSURL URLWithString:URL];
    self.rssParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    self.rssParser.delegate = self;
    [self.rssParser setShouldProcessNamespaces:NO];
    [self.rssParser setShouldReportNamespacePrefixes:NO];
    [self.rssParser setShouldResolveExternalEntities:NO];
    
    [self.rssParser parse];
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    self.dateLastSynced = nil;

    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[MTStatusBarOverlay sharedOverlay] hide];
        if ([[NSInternetDoctor shared] connected])
        {
            NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"app_fetch_stations_error", @"")];
            [BlockAlertView showInfoAlertWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                                           message:errorString];
        }
    
        [GRNotificationCenter postSyncManagerDidEndNotificationWithSender:nil];
    });
    
    self.isParsing = NO;
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
	self.currentElement = [elementName copy];
	
    if ([elementName isEqualToString:kTopElement])
    {
        self.dataDictionary = [NSMutableDictionary dictionary];
	}
}


- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:kTopElement])
    {
        [self.stationsDAO createStationWithTitle:[[self.dataDictionary objectForKey:kElementTitle] copy]
                                         siteURL:[[self.dataDictionary objectForKey:kElementStationURL] copy]
                                       streamURL:[[self.dataDictionary objectForKey:kElementStreamURL] copy]
                                           genre:[[self.dataDictionary objectForKey:kElementGenre] copy]
                                        location:[[self.dataDictionary objectForKey:kElemenLocation] copy]
                                     serverBased:YES];
        
        [self.dataDictionary removeAllObjects];
        self.dataDictionary = nil;
	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSMutableString *currentValue = [self valueForCurrentElement];
    [currentValue appendString:string];
    
    [self.dataDictionary setObject:currentValue
                            forKey:self.currentElement];
}


- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    parser = nil;
    
    self.isParsing = NO;
    if (self.dateLastSynced)
    {
        [self.stationsDAO removeAllStationsBeforeDate:self.dateLastSynced];
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark -
// ------------------------------------------------------------------------------------------
- (NSMutableString *)valueForCurrentElement
{
    NSMutableString *property = [self.dataDictionary objectForKey:self.currentElement];
    
    if (property == nil)
    {
        property = [[NSMutableString alloc] init];
        [self.dataDictionary setObject:property forKey:self.currentElement];
    }
    
    return property;
}


@end

