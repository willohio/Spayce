//
//  FaultUtils.m
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "FaultUtils.h"

@implementation FaultUtils

+ (NSError *)generalErrorWithCode:(NSNumber *)code {
    return [FaultUtils generalErrorWithCode:code title:nil description:nil];
}

+ (NSError *)generalErrorWithCode:(NSNumber *)code title:(NSString *)title description:(NSString *)description {
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    if (title != nil) {
        userInfo[@"title"] = title;
    }
    if (description != nil) {
        userInfo[@"description"] = description;
    }
    
    return [NSError errorWithDomain:@"GeneralError"
                               code:[code integerValue]
                           userInfo:userInfo];
}

@end
