//
//  SPCMemoryCoordinator.m
//  Spayce
//
//  Created by William Santiago on 10/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCMemoryCoordinator.h"

// Manager
#import "MeetManager.h"

@implementation SPCMemoryCoordinator

- (void)updateMemory:(Memory *)memory accessType:(MemoryAccessType)accessType completionHandler:(void (^)(MemoryAccessType accessType))completionHandler {
    if (accessType == MemoryAccessTypePublic) {
        [MeetManager updateMemoryAccessTypeWithMemoryId:memory.recordID accessType:@"PUBLIC" completionHandler:^(){
            if (completionHandler) {
                completionHandler(MemoryAccessTypePublic);
            }
        } errorHandler:nil];
    }
    else if (accessType == MemoryAccessTypePrivate) {
        [MeetManager updateMemoryAccessTypeWithMemoryId:memory.recordID accessType:@"PRIVATE" completionHandler:^(){
            if (completionHandler) {
                completionHandler(MemoryAccessTypePrivate);
            }
        } errorHandler:nil];
    }
}

- (void)updateMemory:(Memory *)memory taggedUsers:(NSArray *)taggedUsers completionHandler:(void (^)())completionHandler {
    [MeetManager updateMemoryParticipantsWithMemoryID:memory.recordID taggedUserIdsUserIds:taggedUsers
                                       resultCallback:^(NSDictionary *results) {
                                           if (completionHandler) {
                                               completionHandler();
                                           }
                                       } faultCallback:nil];
}

- (void)deleteMemory:(Memory *)memory completionHandler:(void (^)(BOOL success))completionHandler {
    NSInteger memoryId = memory.recordID;
    
    [MeetManager deleteMemoryWithMemoryId:memoryId
                           resultCallback:^(NSDictionary *result) {
                               BOOL success = [result[@"number"] boolValue];
                               
                               if (completionHandler) {
                                   completionHandler(success);
                               }
                           } faultCallback:^(NSError *error) {
                               if (completionHandler) {
                                   completionHandler(NO);
                               }
                           }];
}

- (void)reportMemory:(Memory *)memory withType:(SPCReportType)reportType text:(NSString *)text completionHandler:(void (^)(BOOL success))completionHandler {
    NSInteger memoryId = memory.recordID;
    
    [MeetManager reportMemoryWithMemoryId:memoryId
                               reportType:reportType
                                     text:text
                           resultCallback:^(NSDictionary *result) {
                               
                               BOOL success = [result[@"number"] boolValue];
                               
                               if (completionHandler) {
                                   completionHandler(success);
                               }
                           } faultCallback:^(NSError *error) {
                               if (completionHandler) {
                                   completionHandler(NO);
                               }
                           }];
}

- (void)shareMemory:(Memory *)memory serviceName:(NSString *)serviceName completionHandler:(void (^)())completionHandler {
    [MeetManager shareMemoryWithMemoryId:memory.recordID serviceName:serviceName completionHandler:^{
        if (completionHandler) {
            completionHandler();
        }
    } errorHandler:nil];
}

@end
