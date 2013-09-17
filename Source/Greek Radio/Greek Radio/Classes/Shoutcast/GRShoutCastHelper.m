//
//  GRShoutCastHelper.m
//  Greek Radio
//
//  Created by Patrick on 5/16/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "GRShoutCastHelper.h"

@implementation GRShoutCastHelper


+ (GRShoutCastHelper *)shared
{
    static dispatch_once_t pred;
    static GRShoutCastHelper *shared = nil;
    
    dispatch_once(&pred, ^()
                  {
                      shared = [[GRShoutCastHelper alloc] init];
                  });
    
    return shared;
}


- (void)cancelGet
{
    if (self.failBlock)
    {
        self.failBlock();
    }

    [self.connection cancel];
    self.connection = nil;
}


- (void)getMetadataForURL:(NSString *)string
             successBlock:(ShoutcastSuccessBlock)successBlock
                failBlock:(ShoutcastFailBlock)failBlock
{
    self.successBlock = successBlock;
    self.failBlock = failBlock;

    if (string.length == 0)
    {        
        if (self.failBlock)
        {
            self.failBlock();
        }
        
        return;
    }
    
	//We need to make the url mutable as we need to append another string to it
	NSMutableString *value = [NSMutableString stringWithString:string];

	//Gets the last character of the string
	NSString *lastCharacter = [value substringFromIndex:([value length] - 1)];
	
    //Now checks if it is equal to "/"
	if ([lastCharacter isEqualToString:@"/"])
    {
		//She added the "/" to the end of the URL, we just need to append "7.html"
		[value appendFormat:@"7.html"];
	}
	else {
		//The last character isn't a "/", we need to append "/7.html"
		[value appendFormat:@"/7.html"];
	}
	//Now let's transform the URL entered by the user to a NSURL
	NSURL *URL = [NSURL URLWithString:value];

	//Check if the URL is valid
	if (URL == nil)
    {
        if (self.failBlock)
        {
            self.failBlock();
        }

		return;
	}

	//Now we need to create a URL request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	
    //Let's set the user-agent header. The app must identifies itself as browser, so the server will return a HTML file
	[request setValue:@"Mozilla/1.0 SHOUTcast example" forHTTPHeaderField:@"user-agent"];
	
    //Let's send the request
	self.connection = [NSURLConnection connectionWithRequest:request
                                  delegate:self];
}


- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    if (self.failBlock)
    {
        self.failBlock();
    }
}


// Once the server replies, this method gets called
- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
	// Now let's create the data that will hold the response file
	data = [[NSMutableData alloc]initWithLength:0];
}

// When the server sends data, this method will get called
- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)receivedData
{
	// Let's append the data we got to the NSMutableData object we created
	[data appendData:receivedData];
}


-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// Let's create a string from the data we've got from the server
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    data = nil;

    // Let's check if it's a valid string
	if (string == nil)
    {
        if (self.failBlock)
        {
            self.failBlock();
        }

		return;
	}

	//Let's parse the string
	[self parseMetadata:string];
}


- (void)parseMetadata:(NSString *)metadata
{
	// Checks if the returned file contains the <body> tag
	if ([metadata rangeOfString:@"<body>"].length == 0)
    {
        self.failBlock();
        
        self.failBlock = nil;
        self.successBlock = nil;

        return;
	}
    
	// Gets the index of the character after the body tag
	int index = ([metadata rangeOfString:@"<body>"].location + 1);
    
	// Removes the <html> and the <body> tag
	metadata = [metadata substringFromIndex:index];
	
    // Gets the index of the character before the <body> tag is closed
	index = [metadata rangeOfString:@"</body>"].location;
	
    // Removes the "</body></html>" string
    metadata = [metadata substringToIndex:index];

	// Keep checking if there are still any "," on the string
    while ([metadata rangeOfString:@","].length > 0)
    {
		// Removes the ","s and other junk like bitrate
		metadata = [NSString stringWithString:
                    [metadata substringFromIndex:([metadata rangeOfString:@","].location + 1)]];
	}
    
	// Checks if the artist name is provided
	if ([metadata rangeOfString:@" - "].length > 0)
    {
		// Gets the index of the "-"
		index = [metadata rangeOfString:@" - "].location;

		// Artist name comes first
		NSString *artistName = [metadata substringToIndex:index];
		
        // Gets the song name
		NSString *songName = [metadata substringFromIndex:(index + 3)];
		      
        if (artistName.length > 0 && songName.length > 0)
        {
            if (self.successBlock)
            {
                self.successBlock(songName, artistName);
            }
        }
	}
	else
    {
        if (metadata)
        {
            if (self.successBlock)
            {
                self.successBlock(metadata, nil);
            }
        }
        else
        {
            if (self.failBlock)
            {
                self.failBlock();
            }
        }
    }
}


@end
