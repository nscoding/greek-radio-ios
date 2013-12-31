//
//  GRMacros.h
//  Greek Radio
//
//  Created by Patrick Chamelo on 31/12/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


#define GRAssert(condition, ...) \
do \
{ \
if (!(condition)) { \
NSLog(@"(%s), %@", #condition, [NSString stringWithFormat:__VA_ARGS__]); \
} \
} while(0)

#ifdef DEBUG
#    define DLog(...) NSLog(__VA_ARGS__)
#else
#    define DLog(...)
#endif
#define ALog(...) NSLog(__VA_ARGS__)