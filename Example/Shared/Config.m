//
//  Config.m
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 05.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

#import "Config.h"

#define MACRO_STRING_(m) #m
#define MACRO_STRING(m) @MACRO_STRING_(m)

@implementation Config

+ (NSString *) extBundleId {
    return MACRO_STRING(EXT_BUNDLE_ID);
}

+ (NSString *) groupId {
    return MACRO_STRING(APP_GROUP);
}

@end
