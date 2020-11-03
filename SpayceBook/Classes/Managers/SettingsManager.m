//
//  SettingsManager.m
//  SpayceBook
//
//  Created by Dmitry Miller on 8/10/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SettingsManager.h"

// General
#import "Singleton.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"

// Utility
#import "APIService.h"
#import "TranslationUtils.h"
#import "Constants.h"
#import "SPCLiterals.h"

// Model
#import "UserProfile.h"
#import "ProfileDetail.h"

NSString *SettingsFileName = @"settings.plist";

@implementation SettingsManager

SINGLETON_GCD(SettingsManager);

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    self = [super init];
    if (self) {
        // Defaults
        self.friendsHereEnabled = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncSettings)
                                                     name:kAuthenticationDidFinishWithSuccessNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncSettings)
                                                     name:@"handleMAM"
                                                   object:nil];
     
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncSettings)
                                                     name:@"handleMAMFromModal"
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout:)
                                                     name:kAuthenticationDidLogoutNotification
                                                   object:nil];
    }

    return self;
}

#pragma mark - Private

- (void)saveSettings {
    NSMutableData *archivedData = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivedData];

    [archiver encodeBool:self.friendsHereEnabled forKey:@"friendsHereEnabled"];
    
    [archiver finishEncoding];
    [archivedData writeToFile:[self filePath] atomically:YES];
}

- (NSString *)filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    return [documentsDirectory stringByAppendingPathComponent:SettingsFileName];
}

-(void)syncSettings {
   NSString *url = @"/settings";
    //NSLog(@"sync settings??");

    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              //NSLog(@"/settings: %@",result);
                              if (JSON[@"findFriendsVisibility"]) {
                                  self.friendsHereEnabled = [TranslationUtils booleanValueFromDictionary:JSON withKey:@"findFriendsVisibility"];
                              }
                              if (JSON[@"autoShareToFacebook"]) {
                                  self.fbAutoShareEnabled = [TranslationUtils booleanValueFromDictionary:JSON withKey:@"autoShareToFacebook"];
                              }
                              if (JSON[@"autoShareToTwitter"]) {
                                  self.twitAutoShareEnabled = [TranslationUtils booleanValueFromDictionary:JSON withKey:@"autoShareToTwitter"];
                              }
                              if (JSON[@"canPostAnon"]) {
                                  self.anonPostingEnabled = [TranslationUtils booleanValueFromDictionary:JSON withKey:@"canPostAnon"];
                              }
                              if (JSON[@"numStarsMoreNeededToPostAnon"]) {
                                  self.numStarsNeeed = [TranslationUtils integerValueFromDictionary:JSON withKey:@"numStarsMoreNeededToPostAnon"];
                              }
                              if (JSON[@"anonMemoryReportedWarningNum"]) {
                                  self.currAnonWarningCount = [TranslationUtils integerValueFromDictionary:JSON withKey:@"anonMemoryReportedWarningNum"];
                                  
                                  NSString *lastWarningCountLiteralKey = [SPCLiterals literal:kSPCAnonWarningScreenLastWarningCountWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
                                  NSInteger lastWarningCount = [[NSUserDefaults standardUserDefaults] integerForKey:lastWarningCountLiteralKey];
                                  
                                  if (self.currAnonWarningCount > lastWarningCount) {
                                      self.anonWarningNeeded = YES;
                                  }
                              }
                              
                              if (JSON[@"adminWarningNum"]) {
                                  self.currAdminWarningCount = [TranslationUtils integerValueFromDictionary:JSON withKey:@"adminWarningNum"];
                                  
                                  NSString *lastWarningCountLiteralKey = [SPCLiterals literal:kSPCAdminWarningScreenLastWarningCountWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
                                  NSInteger lastWarningCount = [[NSUserDefaults standardUserDefaults] integerForKey:lastWarningCountLiteralKey];
                                  
                                  if (self.currAdminWarningCount > lastWarningCount) {
                                      self.adminWarningNeeded = YES;
                                  }
                              }
                              
                              if (self.anonPostingEnabled) {
                                  [self fetchAnonProfile];
                              }
                          } faultCallback:^(NSError *error) {
                              NSLog(@"error %@",error);
                          }];
}

-(void)fetchAnonProfile {
    NSString *url = [NSString stringWithFormat:@"/meet/getUserProfile/00000000-0000-0000-0000-0000000000n2"];
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              NSDictionary *src = (NSDictionary *)result;
                              for (NSDictionary *profile in src[@"spayceMeetProfiles"]) {
                                  NSString *profileType = profile[@"profileType"];
                                  if ([profileType isEqualToString:@"PERSONAL"]) {
                                      Asset *imageAsset = [Asset assetFromDictionary:profile withAssetKey:@"profilePhotoAssetInfo" assetIdKey:@"profilePhotoAssetId"];
                                      [ContactAndProfileManager sharedInstance].profile.profileDetail.anonImageAsset = imageAsset;
                                  }
                              }
                          } faultCallback:^(NSError *fault) {
                        
                          }];
    
}

- (void)removeSettings {
    NSString *filePath = [self filePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exists = [fm fileExistsAtPath:filePath];

    if (exists)
    {
        NSError *err = nil;
        [fm removeItemAtPath:filePath error:&err];
    }
}

#pragma mark - Accessors

- (void)updateAutoShareToFacebookEnabled:(BOOL)autoShareToFacebookEnabled
                       completionHandler:(void (^)(BOOL availability))completionHandler
                            errorHandler:(void (^)(NSError *error))errorHandler {
    int autoShareEnabled = 0;
    if (autoShareToFacebookEnabled) {
        autoShareEnabled = 1;
    }

    [APIService makeApiCallWithMethodUrl:@"/settings/toggleAutoShareToFacebook"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{ @"toggleValue": @(autoShareEnabled)}

                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;

                              BOOL enabled = [TranslationUtils booleanValueFromDictionary:JSON withKey:@"number"];

                              self.fbAutoShareEnabled = enabled;

                              [self saveSettings];

                              if (completionHandler) {
                                  completionHandler(enabled);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

- (void)updateAutoShareToTwitterEnabled:(BOOL)autoShareToTwitterEnabled
                      completionHandler:(void (^)(BOOL availability))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    int autoShareEnabled = 0;
    if (autoShareToTwitterEnabled) {
        autoShareEnabled = 1;
    }

    [APIService makeApiCallWithMethodUrl:@"/settings/toggleAutoShareToTwitter"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{ @"toggleValue": @(autoShareEnabled)}

                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;

                              BOOL enabled = [TranslationUtils booleanValueFromDictionary:JSON withKey:@"number"];

                              self.twitAutoShareEnabled = enabled;

                              [self saveSettings];

                              if (completionHandler) {
                                  completionHandler(enabled);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


- (void)updateProfileLocked:(BOOL)profileLocked
          completionHandler:(void (^)(BOOL locked))completionHandler
               errorHandler:(void (^)(NSError *error))errorHandler {
    int locked = 0;
    if (profileLocked) {
        locked = 1;
    }
    
    [APIService makeApiCallWithMethodUrl:@"/settings/toggleProfileLocked"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{ @"toggleValue": @(locked)}
     
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              BOOL lockedNow = [TranslationUtils booleanValueFromDictionary:JSON withKey:@"number"];
                              
                              if (completionHandler) {
                                  completionHandler(lockedNow);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}



#pragma mark - Notifications Methods

- (void)handleLogout:(NSNotification *)notification {
    [self removeSettings];
    self.numStarsNeeed = 0;
    self.anonPostingEnabled = NO;
    self.anonWarningNeeded = NO;
}

@end
