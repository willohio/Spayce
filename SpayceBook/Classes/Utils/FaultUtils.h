//
//  FaultUtils.h
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FaultUtils : NSObject

+ (NSError *)generalErrorWithCode:(NSNumber *)code;
+ (NSError *)generalErrorWithCode:(NSNumber *)code title:(NSString *)title description:(NSString *)description;

@end
