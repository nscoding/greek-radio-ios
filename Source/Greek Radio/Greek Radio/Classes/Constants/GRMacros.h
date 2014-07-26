//
//  GRMacros.h
//  Greek Radio
//
//  Created by Patrick Chamelo on 31/12/13.
//  Copyright (c) 2013 Patrick Chamelo - nscoding. All rights reserved.
//


#ifdef DEBUG
#    define DLog(...) NSLog(__VA_ARGS__)
#else
#    define DLog(...)
#endif
#define ALog(...) NSLog(__VA_ARGS__)

#define WEAKIFY(var) \
__weak typeof(var) weakVar = var;

#define STRONGIFY(var) \
__strong typeof(var) var = weakVar; \
if (var == nil) return;
