//
//  GRShoutCastHelper.h
//  Greek Radio
//
//  Created by Patrick on 5/16/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

typedef void (^ShoutcastSuccessBlock)(NSString *songName, NSString *songArtist);
typedef void (^ShoutcastFailBlock)();

@interface GRShoutCastHelper : NSObject
{
	NSMutableData *data;
}

+ (GRShoutCastHelper *)shared;

- (void)getMetadataForURL:(NSString *)string
             successBlock:(ShoutcastSuccessBlock)successBlock
                failBlock:(ShoutcastFailBlock)failBlock;

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, copy) ShoutcastSuccessBlock successBlock;
@property (nonatomic, copy) ShoutcastFailBlock failBlock;

@end
