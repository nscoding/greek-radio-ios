//
//  GRWebService.m
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRWebService.h"
#import "GRStationsDAO.h"


// ------------------------------------------------------------------------------------------


#define kWebServiceURL @"http://nscoding.co.uk/xml/RadioStations.xml"
//#define kWebServiceURL @"http://nscoding.co.uk/xml/RadioStationsBeta.xml"

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
@property (nonatomic, strong) NSMutableString *currentTitle;
@property (nonatomic, strong) NSMutableString *currentGenre;
@property (nonatomic, strong) NSMutableString *currentStationURL;
@property (nonatomic, strong) NSMutableString *currentStreamURL;
@property (nonatomic, strong) NSMutableString *currentLocation;
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
        self.stationsDAO = [[GRStationsDAO alloc] init];
    }
    
    return self;
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
        self.isParsing = NO;
        [[NSInternetDoctor shared] showNoInternetAlert];
        [GRNotificationCenter postSyncManagerDidEndNotificationWithSender:nil];
        
        return;
    }

    self.isParsing = YES;    
    self.dateLastSynced = [NSDate date];
    
    [GRNotificationCenter postSyncManagerDidStartNotificationWithSender:nil];
    [self parseXMLFileAtURL:kWebServiceURL];
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
    
    if ([[NSInternetDoctor shared] connected])
    {
        NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"app_fetch_stations_error", @"")];
        [BlockAlertView showInfoAlertWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                                       message:errorString];
    }
    
    [GRNotificationCenter postSyncManagerDidEndNotificationWithSender:nil];
    
    self.isParsing = NO;
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError;
{

}


- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    
//    NSLog(@"found this element: %@", elementName);
	self.currentElement = [elementName copy];
	
    if ([elementName isEqualToString:kTopElement])
    {
		// clear out our story item caches...
		self.currentTitle = [[NSMutableString alloc] init];
        self.currentGenre = [[NSMutableString alloc] init];
		self.currentStationURL = [[NSMutableString alloc] init];
		self.currentStreamURL = [[NSMutableString alloc] init];
		self.currentLocation = [[NSMutableString alloc] init];
	}
	
}


- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
//    NSLog(@"end this element: %@", elementName);

	if ([elementName isEqualToString:kTopElement])
    {
        [self.stationsDAO createStationWithTitle:[self.currentTitle copy]
                                         siteURL:[self.currentStationURL copy]
                                       streamURL:[self.currentStreamURL copy]
                                           genre:[self.currentGenre copy]
                                        location:[self.currentLocation copy]
                                     serverBased:YES];
	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
//    NSLog(@"found characters: %@", string);
    [[self propertyForCurrentElement] appendString:string];
}


- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    parser = nil;
    
    self.isParsing = NO;
    if (self.dateLastSynced)
    {
        [self.stationsDAO removeAllStationsBeforeDate:self.dateLastSynced];
    }
    
    [GRNotificationCenter postSyncManagerDidEndNotificationWithSender:nil];
}


// ------------------------------------------------------------------------------------------
#pragma mark -
// ------------------------------------------------------------------------------------------
- (NSMutableString *)propertyForCurrentElement
{
	if ([self.currentElement isEqualToString:kElementTitle])
    {
        return self.currentTitle;
	}
    else if ([self.currentElement isEqualToString:kElementStreamURL])
    {
        return self.currentStreamURL;
	}
    else if ([self.currentElement isEqualToString:kElementStationURL])
    {
        return self.currentStationURL;
	}
    else if ([self.currentElement isEqualToString:kElementGenre])
    {
        return self.currentGenre;
	}
    else if ([self.currentElement isEqualToString:kElemenLocation])
    {
        return self.currentLocation;
	}

    return nil;
}


@end

