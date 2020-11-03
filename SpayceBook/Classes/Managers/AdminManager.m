//
//  AdminManager.m
//  Spayce
//
//  Created by Jake Rosin on 3/3/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "AdminManager.h"

// General
#import "Singleton.h"
#import "TranslationUtils.h"

// Model
#import "Memory.h"
#import "Person.h"

// Service
#import "APIService.h"

@implementation AdminManager

SINGLETON_GCD(AdminManager);

- (id)init {
    self = [super init];
    return self;
}



- (void)warnUserWithUserKey:(NSString *)userKey completionHandler:(void (^)())completionHandler errorHandler:(void (^)(NSError *))errorHandler{
    NSString *postURL = [NSString stringWithFormat:@"/admin/user/%@/warn", userKey];
    [APIService makeApiCallWithMethodUrl:postURL andRequestType:RequestTypePost andPathParams:nil andQueryParams:nil resultCallback:^(NSObject *result) {
        if (completionHandler) {
            completionHandler();
        }
    } faultCallback:^(NSError *fault) {
        if (errorHandler) {
            errorHandler(fault);
        }
    }];
}


- (void)deleteUserWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/user/%@/delete", userKey];
    [self performAdminActionWithPostURL:postURL requestType:RequestTypePost completionHandler:completionHandler errorHandler:errorHandler];
}

- (void)banUserWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/user/%@/ban", userKey];
    [self performAdminActionWithPostURL:postURL requestType:RequestTypePost completionHandler:completionHandler errorHandler:errorHandler];
}

- (void)unbanUserWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/user/%@/ban", userKey];
    [self performAdminActionWithPostURL:postURL requestType:RequestTypeDelete completionHandler:completionHandler errorHandler:errorHandler];
}

- (void)blockUserDeviceWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/user/%@/block", userKey];
    [self performAdminActionWithPostURL:postURL requestType:RequestTypePost completionHandler:completionHandler errorHandler:errorHandler];
}

- (void)unblockUserDeviceWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/user/%@/block", userKey];
    [self performAdminActionWithPostURL:postURL requestType:RequestTypeDelete completionHandler:completionHandler errorHandler:errorHandler];
}

- (void)muteUserWithUserKey:(NSString *)userKey shadow:(BOOL)shadow completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/user/%@/mute", userKey];
    NSDictionary *params = shadow ? @{@"shadow" : @(1)} : @{@"shadow" : @(0)};
    [self performAdminActionWithPostURL:postURL params:params requestType:RequestTypePost completionHandler:completionHandler errorHandler:errorHandler];
}

- (void)unmuteUserWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/user/%@/mute", userKey];
    [self performAdminActionWithPostURL:postURL requestType:RequestTypeDelete completionHandler:completionHandler errorHandler:errorHandler];
}


- (void)performAdminActionWithPostURL:(NSString *)postURL requestType:(RequestType)requestType completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    [self performAdminActionWithPostURL:postURL params:nil requestType:requestType completionHandler:completionHandler errorHandler:errorHandler];
}


- (void)performAdminActionWithPostURL:(NSString *)postURL params:(NSDictionary *)params requestType:(RequestType)requestType completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    
    [APIService makeApiCallWithMethodUrl:postURL
                          andRequestType:requestType
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              //NSLog(@"result %@", result);
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              // 1 indicates success, 2 queued, 3 redundant, and 4 not yet implemented.
                              NSNumber *value = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"number"]];
                              if (value) {
                                  if (completionHandler) {
                                      completionHandler(value.integerValue);
                                  }
                              } else {
                                  if (errorHandler) {
                                      errorHandler(nil);
                                  }
                              }                              
                          } faultCallback:^(NSError *fault) {
                              //NSLog(@"error %@", fault);
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


- (void)promoteMemory:(Memory *)memory completionHandler:(void (^)())completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/memory/%@/promote", memory.key];
    [APIService makeApiCallWithMethodUrl:postURL andRequestType:RequestTypePost andPathParams:nil andQueryParams:nil resultCallback:^(NSObject *result) {
        if (completionHandler) {
            completionHandler();
        }
    } faultCallback:^(NSError *fault) {
        if (errorHandler) {
            errorHandler(fault);
        }
    }];
}

- (void)demoteMemory:(Memory *)memory completionHandler:(void (^)())completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *postURL = [NSString stringWithFormat:@"/admin/memory/%@/demote", memory.key];
    [APIService makeApiCallWithMethodUrl:postURL andRequestType:RequestTypePost andPathParams:nil andQueryParams:nil resultCallback:^(NSObject *result) {
        if (completionHandler) {
            completionHandler();
        }
    } faultCallback:^(NSError *fault) {
        if (errorHandler) {
            errorHandler(fault);
        }
    }];
}


- (void)fetchSockPuppetListPageWithPageKey:(NSString *)pageKey completionHandler:(void (^)(NSArray *puppets, NSString *nextPageKey))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    NSString *url = @"/admin/sockpuppets";
    NSDictionary *params = nil;
    if (pageKey) {
        params = @{ @"pageKey" : pageKey };
    }
    
    [APIService makeApiCallWithMethodUrl:url andRequestType:RequestTypeGet andPathParams:nil andQueryParams:params resultCallback:^(NSObject *result) {
        NSDictionary *JSON = (NSDictionary *)result;
        
        // parse
        NSArray *users = JSON[@"friends"];
        NSMutableArray *usersArray = [NSMutableArray arrayWithCapacity:users.count];
        
        for (NSDictionary *attributes in users) {
            Person *person = [[Person alloc] initWithAttributes:attributes];
            
            BOOL isDuplicate = NO;
            
            for (int i = 0; i < usersArray.count; i++) {
                Person *addedPerson = (Person *)usersArray[i];
                if ([person.userToken isEqualToString:addedPerson.userToken]) {
                    isDuplicate = YES;
                    break;
                }
            }
            
            if (!isDuplicate) {
                [usersArray addObject:person];
            }
        }
        
        NSString *nextPageKey = JSON[@"nextPageKey"];
        
        if (completionHandler) {
            completionHandler(usersArray, nextPageKey);
        }
    } faultCallback:^(NSError *fault) {
        if (errorHandler) {
            errorHandler(fault);
        }
    }];
}

@end
