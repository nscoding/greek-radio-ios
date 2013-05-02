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


#define kWebServiceURL @"http://nscoding.co.uk/xml/radioStations.xml"

#define kTopElement @"station"
    #define kElementTitle @"title"
    #define kElementStreamURL @"streamURL"
    #define kElementStationURL @"stationURL"
    #define kElementGenre @"genre"
    #define kElemenLocation @"location"


// ------------------------------------------------------------------------------------------


@interface GRWebService ()

@property (nonatomic, strong) NSXMLParser *rssParser;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSMutableString *currentTitle;
@property (nonatomic, strong) NSMutableString *currentGenre;
@property (nonatomic, strong) NSMutableString *currentStationURL;
@property (nonatomic, strong) NSMutableString *currentStreamURL;
@property (nonatomic, strong) NSMutableString *currentLocation;
@property (nonatomic, strong) GRStationsDAO *stationsDAO;

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
    [self parseXMLFileAtURL:kWebServiceURL];
}


// ------------------------------------------------------------------------------------------
#pragma mark - XML parsing
// ------------------------------------------------------------------------------------------
- (void)parseXMLFileAtURL:(NSString *)URL
{
    NSURL *xmlURL = [NSURL URLWithString:URL];
    self.rssParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    [self.rssParser setDelegate:self];
    [self.rssParser parse];
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSString * errorString = [NSString stringWithFormat:
                              @"Unable to download stations from nscoding (Error code %i )", [parseError code]];
	
    NSLog(@"Error parsing XML: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Something went wrong"
                                                          message:errorString
                                                         delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
	[errorAlert show];
}


- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    NSLog(@"found this element: %@", elementName);
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
	if ([elementName isEqualToString:kTopElement])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.stationsDAO createStationWithTitle:self.currentTitle
                                             siteURL:self.currentStationURL
                                           streamURL:self.currentStreamURL
                                               genre:self.currentGenre
                                            location:self.currentLocation];
        });

	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	NSLog(@"found characters: %@", string);

    
    [[self propertyForCurrentElement] appendString:string];
}


- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    NSLog(@"all done!");
    
    parser = nil;
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

