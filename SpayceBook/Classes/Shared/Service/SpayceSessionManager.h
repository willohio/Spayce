//
//  SpayceSessionManager.h
//  SpayceBook
//
//  Created by Dmitry Miller on 7/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * PersistedSessionFileName;
extern NSString * kSpayceAuthenticationService;
extern NSString * kSpayceUUIDToken;

@interface SpayceSessionManager : NSObject

@property (strong, nonatomic) NSString *currentSessionId;

// Shared instance
+ (SpayceSessionManager *)sharedInstance;
// Session
- (void)persistCurrentSession;
- (void)loadPersistedCurrentSession;
- (void)deletePersistedSession;
// UUID
- (NSString *)getUUID;

@end
