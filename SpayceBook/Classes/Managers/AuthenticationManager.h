//
//  AuthenticationManager.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;
@class UserProfile;

extern NSString * kAuthenticationDidFinishWithSuccessNotification;
extern NSString * kAuthenticationDidFailNotification;
extern NSString * kAuthenticationDidUpdateUserInfoNotification;
extern NSString * kAuthenticationDidLogoutNotification;

extern NSString * kAuthenticationDidUpdateUserInfoForceOpenKey;

@interface AuthenticationManager : NSObject

@property (nonatomic) BOOL isInitialized;
@property (nonatomic) BOOL authenticationInProgress;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) UserProfile *currentUserProfile;

+ (AuthenticationManager *)sharedInstance;

// Login
- (void)loginWithEmail:(NSString *)email password:(NSString *)password;
- (void)finishAuthenticationWithEmail:(NSString *)email firstName:(NSString *)firstName attributes:(NSDictionary *)attributes;

// Registration
- (void)registerWithEmail:(NSString *)email handle:(NSString *)handle password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName promoCode:(NSString *)promoCode completionHandler:(void (^)(BOOL codeValidated))completionHandler errorHandler:(void (^)(NSError *error))errorHandler;
- (void)isHandleAvailable:(NSString *)handle completionHandler:(void (^)(BOOL))completionHandler errorHandler:(void (^)(NSError *))errorHandler;
- (void)isEmailAddressAvailable:(NSString *)emailAddress completionHandler:(void (^)(BOOL))completionHandler errorHandler:(void (^)(NSError *))errorHandler;
// Forgot password
- (void)forgotPasswordWithEmail:(NSString *)email completionHandler:(void (^)(BOOL result))completionHandler errorHandler:(void (^)(NSError *error))errorHandler;
// Reset password
- (void)resetOldPassword:(NSString *)oldPassword forEmail:(NSString *)email passwordWithNewPassword:(NSString *)newPassword completionHandler:(void (^)(BOOL result))completionHandler errorHandler:(void (^)(NSError *error))errorHandler;
// Logout
- (void)logout;
// Delete Account
- (void)deleteAccountWithUser:(User *)user completionHandler:(void (^)(NSDictionary *result))completionHandler errorHandler:(void (^)(NSError *error))errorHandler;

//handle
- (void)reserveHandle:(NSString *)handle
    completionHandler:(void (^)(BOOL result))completionHandler
         errorHandler:(void (^)(NSError *error))errorHandler;
@end
