
//
//  SpayceSessionManager.m
//  SpayceBook
//
//  Created by Dmitry Miller on 7/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SpayceSessionManager.h"
#import "Singleton.h"
#import "SFHFKeychainUtils.h"

NSString * PersistedSessionFileName = @"session.plist";
NSString * kSpayceAuthenticationService = @"com.spayce.social";
NSString * kSpayceUUIDToken = @"SpayceUUIDToken";

@implementation SpayceSessionManager

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

SINGLETON_GCD(SpayceSessionManager);

- (id)init {
    self = [super init];
    if (self) {
        [self loadPersistedCurrentSession];
    }
    
    return self;
}

#pragma mark - Private

- (NSString *)filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    
    return [documentsDirectory stringByAppendingPathComponent:PersistedSessionFileName];
}

#pragma mark - Session

- (void)persistCurrentSession {
    NSMutableData *archivedData = [[NSMutableData alloc] init];
    
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivedData];
    [archiver encodeObject:self.currentSessionId];
    [archiver finishEncoding];
    [archivedData writeToFile:[self filePath] atomically:YES];
}

- (void)loadPersistedCurrentSession {
    NSData *codedData = [[NSData alloc] initWithContentsOfFile:[self filePath]];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
    self.currentSessionId = (NSString *)[unarchiver decodeObject];
    [unarchiver finishDecoding];
}

- (void)deletePersistedSession {
    NSString *filePath = [self filePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        
        [fileManager removeItemAtPath:filePath error:&error];
    }
}

#pragma makr - Global

- (NSString *)getUUID {
    NSError *error;
    NSString *deviceUUID = [SFHFKeychainUtils getPasswordForUsername:kSpayceUUIDToken
                                                       andServiceName:kSpayceAuthenticationService
                                                                error:&error];

    if (!error && deviceUUID != nil && ![deviceUUID isEqualToString:@""]) {
        return deviceUUID;
    } else {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);

        deviceUUID = (__bridge NSString *)string;

        error = nil;

        [SFHFKeychainUtils storeUsername:kSpayceUUIDToken
                             andPassword:deviceUUID
                          forServiceName:kSpayceAuthenticationService
                          updateExisting:YES
                                   error:&error];

        if (!error) {
            return deviceUUID;
        }

        return @"";
    }
}

@end
