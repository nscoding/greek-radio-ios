//
//  UIDevice+Extensions.m
//  Greek Radio
//
//  Created by Patrick on 5/18/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//

#import "UIDevice+Extensions.h"


// ------------------------------------------------------------------------------------------


@implementation UIDevice (Extensions)


+ (BOOL)isIPad;
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}
#endif
	
    return NO;
}


+ (BOOL)isTallIphone;
{
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) &&
        ([UIScreen mainScreen].bounds.size.height >= 568.0f)) {
        return YES;
    }

    return NO;
}


@end
