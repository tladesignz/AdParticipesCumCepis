//
//  Config.h
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 05.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Config : NSObject

@property (class, nonatomic, assign, readonly, nonnull) NSString *extBundleId NS_REFINED_FOR_SWIFT;

@property (class, nonatomic, assign, readonly, nonnull) NSString *groupId NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
