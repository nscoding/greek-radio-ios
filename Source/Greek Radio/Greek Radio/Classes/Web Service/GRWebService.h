//
//  GRWebService.h
//  Greek Radio
//
//  Created by Patrick on 4/30/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//



@interface GRWebService : NSObject <NSXMLParserDelegate>

+ (GRWebService *)shared;
- (void)parseXML;

@end
