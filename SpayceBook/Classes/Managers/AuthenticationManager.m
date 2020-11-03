//
//  AuthenticationManager.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "AuthenticationManager.h"

// Model
#import "User.h"
#import "UserProfile.h"
#import "ImageCache.h"

// General
#import "FaultUtils.h"
#import "Singleton.h"

// Manager
#import "LocationManager.h"
#import "MeetManager.h"
#import "SpayceSessionManager.h"
#import "PNSManager.h"
#import "ProfileManager.h"

// Utility
#import "APIService.h"
#import "TranslationUtils.h"
#import "Flurry.h"
#import <Crashlytics/Crashlytics.h>

NSString * kAuthenticationDidFinishWithSuccessNotification = @"AuthenticationDidFinishWithSuccessNotification";
NSString * kAuthenticationDidFailNotification = @"AuthenticationDidFailNotification";
NSString * kAuthenticationDidUpdateUserInfoNotification = @"AuthenticationDidUpdateUserInfoNotification";
NSString * kAuthenticationDidLogoutNotification = @"AuthenticationDidLogoutNotification";

NSString * kAuthenticationDidUpdateUserInfoForceOpenKey = @"forceOpen";

@implementation AuthenticationManager

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

SINGLETON_GCD(AuthenticationManager);

- (id)init {
    self = [super init];
    if (self) {
        [[SpayceSessionManager sharedInstance] loadPersistedCurrentSession];

        _currentUser = nil;
        _authenticationInProgress = NO;
        _isInitialized = NO;
        
        if ([SpayceSessionManager sharedInstance].currentSessionId.length > 0) {
            [self validateSession];
        } else {
            _isInitialized = YES;
        }
    }

    return self;
}

#pragma mark - Private

- (void)validateSession {
    [Flurry logEvent:@"VALIDATE_SESSION"];
    
    __weak typeof(self)weakSelf = self;
    
    //NSLog(@"starting session when already logged in!");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"validatingSession"];
    [APIService makeApiCallWithMethodUrl:@"/validateSession"
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              [Flurry logEvent:@"VALIDATE_SUCCESS"];
                              
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSNumber *needsHandle = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"shouldChangeHandle"]];
                              if (needsHandle && ![needsHandle boolValue]) {
                                  //NSLog(@"handle is set!");
                                  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shouldChangeHandle"];
                              }
                              
                              strongSelf.currentUser = [[User alloc] initWithAttributes:(NSDictionary *)result];
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidFinishWithSuccessNotification object:nil];
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"validateSessionComplete" object:nil];
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"validatingSession"];
                          } faultCallback:^(NSError *error) {
                              [Flurry logEvent:@"VALIDATE_FAILED"];
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"validateSessionComplete" object:nil];
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"validatingSession"];
                              [SpayceSessionManager sharedInstance].currentSessionId = nil;
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidLogoutNotification object:nil];
                              [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidFailNotification object:error];
                          }];
}


- (void)finishAuthenticationWithEmail:(NSString *)email firstName:(NSString *)firstName attributes:(NSDictionary *)attributes {
    NSString *sessionId = (NSString *)[TranslationUtils valueOrNil:[attributes valueForKeyPath:@"session.sessionId"]];
    self.currentUser = [[User alloc] initWithAttributes:attributes];
    
    if (sessionId.length > 0) {
        [SpayceSessionManager sharedInstance].currentSessionId = sessionId;
        [[SpayceSessionManager sharedInstance] persistCurrentSession];
    }
    NSLog(@"finish authentication!");
    self.authenticationInProgress = NO;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (email) {
        userInfo[@"email"] = email;
    }
    if (firstName) {
        userInfo[@"handle"] = firstName;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidFinishWithSuccessNotification object:nil userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeInitialLoadingScreen" object:nil];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [[LocationManager sharedInstance] sendLocationData];
    }
    __weak typeof(self) weakSelf = self;
    [ProfileManager fetchProfileWithUserToken:self.currentUser.userToken resultCallback:^(UserProfile *profile) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.currentUserProfile = profile;
    } faultCallback:nil];
}

#pragma mark - Login

- (void)loginWithEmail:(NSString *)email password:(NSString *)password {
    [Flurry logEvent:@"LOGIN"];
    
    self.authenticationInProgress = YES;
    
    __weak typeof(self)weakSelf = self;
    
    [APIService makeApiCallWithMethodUrl:@"/authV2"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{ @"email": email, @"password": password }
                          resultCallback:^(NSObject *result) {
                              NSLog(@"authV2 result %@", result);
                              
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              if (JSON[@"enrolled"]) {
                                  BOOL enrolled = [TranslationUtils booleanValueFromDictionary:JSON withKey:@"enrolled"];
                                  if (!enrolled) {
                                      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"forceEnrollment"];
                                  }
                              }
                              
                              NSNumber *needsHandle = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"shouldChangeHandle"]];
                              if (needsHandle && [needsHandle boolValue]) {
                                  NSLog(@"prompt handle change!");
                                  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shouldChangeHandle"];
                              }
                              else {
                                  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shouldChangeHandle"];
                              }
                              
                              [strongSelf finishAuthenticationWithEmail:email firstName:nil attributes:JSON];
                              
                              strongSelf.authenticationInProgress = NO;
                          } faultCallback:^(NSError *error) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              NSLog(@"auth error %@",error);
                              strongSelf.authenticationInProgress = NO;
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidLogoutNotification object:nil];
                              [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidFailNotification object:error];
                          }];
}

#pragma mark - Registration

- (void)registerWithEmail:(NSString *)email handle:(NSString *)handle password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName promoCode:(NSString *)promoCode completionHandler:(void (^)(BOOL codeValidated))completionHandler errorHandler:(void (^)(NSError *error))errorHandler {
    [Flurry logEvent:@"REGISTER"];
    
    self.authenticationInProgress = YES;
    
    __weak typeof(self)weakSelf = self;
    
    [APIService makeApiCallWithMethodUrl:@"/createuserV2"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{ @"email": email, @"handle": handle, @"password": password, @"firstName": firstName, @"lastName": lastName }
                          resultCallback:^(NSObject *result) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"toggleCoachShown"];
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"privacyCoachShown"];
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"nowCoachShown"];
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hereCoachShown"];
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"whoCoachShown"];
                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hideTourPromptInSpayceMeet"];
                              
                              [strongSelf finishAuthenticationWithEmail:email firstName:firstName attributes:JSON];
                              
                              if (completionHandler) {
                                  completionHandler(NO);
                              }
                          } faultCallback:^(NSError *error) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              // - HANDLE CASE WHERE HANDLE IS TAKEN (HOW??)

                              NSLog(@"error %@",error);
                              //HANDLE_TAKEN_ERROR = -2800;
                              
                              strongSelf.authenticationInProgress = NO;
                              
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidLogoutNotification object:nil];
                              [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidFailNotification object:error];
                          }];
}

- (void)isEmailAddressAvailable:(NSString *)emailAddress completionHandler:(void (^)(BOOL))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    
    [APIService makeApiCallWithMethodUrl:@"/emailAvailable"
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:@{ @"email": emailAddress }
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSNumber *value = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"value"]];
                              
                              if (completionHandler) {
                                  completionHandler([value boolValue]);
                              }
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

- (void)isHandleAvailable:(NSString *)handle completionHandler:(void (^)(BOOL))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    
    [APIService makeApiCallWithMethodUrl:@"/handleAvailable"
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:@{ @"handle": handle }
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSNumber *value = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"value"]];
                              
                              if (completionHandler) {
                                  completionHandler([value boolValue]);
                              }
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

#pragma mark - Forgot password

- (void)forgotPasswordWithEmail:(NSString *)email completionHandler:(void (^)(BOOL))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    self.authenticationInProgress = YES;
    
    __weak typeof(self)weakSelf = self;
    
    [APIService makeApiCallWithMethodUrl:@"/forgotPassword"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{ @"email": email }
                          resultCallback:^(NSObject *result) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSNumber *value = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"number"]];
                              
                              strongSelf.authenticationInProgress = NO;
                              
                              if (completionHandler) {
                                  completionHandler([value boolValue]);
                              }
                          } faultCallback:^(NSError *error) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              strongSelf.authenticationInProgress = NO;
                              
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

#pragma mark - Reset password

- (void)resetOldPassword:(NSString *)oldPassword forEmail:(NSString *)email passwordWithNewPassword:(NSString *)newPassword completionHandler:(void (^)(BOOL))completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    self.authenticationInProgress = YES;
    
    __weak typeof(self)weakSelf = self;
    
    [APIService makeApiCallWithMethodUrl:@"/resetPassword"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{ @"email": email, @"oldPassword": oldPassword, @"newPassword": newPassword }
                          resultCallback:^(NSObject *result) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSNumber *value = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"number"]];
                              
                              strongSelf.authenticationInProgress = NO;
                              
                              if (completionHandler) {
                                  completionHandler([value boolValue]);
                              }
                          } faultCallback:^(NSError *error) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              strongSelf.authenticationInProgress = NO;
                              
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

#pragma mark - Logout

- (void)logout {
    [Flurry logEvent:@"LOGOUT"];
    
    //unregister the device BEFORE deleting the session
    PNSManager *pnsManager = [PNSManager sharedInstance];
    
    [pnsManager unregisterPnsDeviceToken:pnsManager.pnsDeviceToken
                          resultCallback:^{
                          } faultCallback:^(NSError *error){
                              NSLog(@"unregister error %@",error);
                          }];
    
    
    [[SpayceSessionManager sharedInstance] deletePersistedSession];
    
    self.currentUser = nil;
    self.currentUserProfile = nil;
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shouldChangeHandle"];
    
    [ImageCache clearCachedImages];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:nil forKey:@"friendIds"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationDidLogoutNotification object:nil];
}

#pragma mark - Password

-(void)deleteAccountWithUser:(User *)user completionHandler:(void (^)(NSDictionary *result))completionHandler errorHandler:(void (^)(NSError *error))errorHandler {
    // Url
    NSString *url = @"/deleteAccount";
    
    // Server identifies user by session (included automatically by APIService)
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              if (nil != completionHandler) {
                                  NSDictionary *JSON = (NSDictionary *)result;
                                  completionHandler(JSON);
                              }
    }
                           faultCallback:^(NSError *error) {
                               if (nil != errorHandler) {
                                   errorHandler(error);
                               }
    }];
}

#pragma mark - handles

- (void)reserveHandle:(NSString *)handle
    completionHandler:(void (^)(BOOL result))completionHandler
         errorHandler:(void (^)(NSError *error))errorHandler {
    
    [APIService makeApiCallWithMethodUrl:@"/changeHandle"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{ @"handle": handle}
                          resultCallback:^(NSObject *result) {
                            NSDictionary *JSON = (NSDictionary *)result;
                              if (completionHandler) {
                                  completionHandler([JSON[@"result"] boolValue]);
                              }
                          } faultCallback:^(NSError *error) {
                              NSLog(@"/changeHandle faultCallback %@",error);
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
    
}

#pragma mark - Accessors

- (void)setCurrentUser:(User *)currentUser {
    _currentUser = currentUser;
    
    // Sync the Crashlytics user identifier
    [Crashlytics setUserIdentifier:currentUser.userToken];
}


@end
