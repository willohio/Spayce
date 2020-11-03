//
//  SPCMemoryCoordinator.h
//  Spayce
//
//  Created by Pavel Dusatko on 10/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Memory.h"

@interface SPCMemoryCoordinator : NSObject

// Access type
- (void)updateMemory:(Memory *)memory accessType:(MemoryAccessType)accessType completionHandler:(void (^)(MemoryAccessType accessType))completionHandler;
// Tagged users
- (void)updateMemory:(Memory *)memory taggedUsers:(NSArray *)taggedUsers completionHandler:(void (^)())completionHandler;
// Delete memory
- (void)deleteMemory:(Memory *)memory completionHandler:(void (^)(BOOL success))completionHandler;
// Report memory
- (void)reportMemory:(Memory *)memory withType:(SPCReportType)reportType text:(NSString *)text completionHandler:(void (^)(BOOL success))completionHandler;
// Share memory
- (void)shareMemory:(Memory *)memory serviceName:(NSString *)serviceName completionHandler:(void (^)())completionHandler;

@end
