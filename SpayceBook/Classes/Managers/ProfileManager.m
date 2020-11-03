//
//  ProfileManager.m
//  Spayce
//
//  Created by Jake Rosin on 4/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "ProfileManager.h"
#import "Flurry.h"
#import "APIService.h"
#import "UserProfile.h"
#import "ContactAndProfileManager.h"
#import "AuthenticationManager.h"
#import "User.h"

@implementation ProfileManager

+ (void)fetchProfileWithUserToken:(NSString *)userToken
                   resultCallback:(void (^)(UserProfile *profile))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/meet/getUserProfile/%@", userToken];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              NSDictionary *src = (NSDictionary *)result;
                              
                              UserProfile *profile = [[UserProfile alloc] initWithAttributes:src];
                              profile.userToken = userToken;
                              
                              if ([userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
                                  [ContactAndProfileManager sharedInstance].profile = profile;
                              }
                              
                              if (resultCallback) {
                                  resultCallback(profile);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)updateProfileBannerAssetId:(NSInteger)bannerAssetId
                    resultCallback:(void (^)(void))resultCallback
                     faultCallback:(void (^)(NSError *))faultCallback {
    NSDictionary *params = @{ @"bannerAssetId": @(bannerAssetId) };
    [Flurry logEvent:@"UPDATE_PROFILE_BANNER" withParameters:params];

    NSString *url = @"/meet/banner";

    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject *result) {
                              if (resultCallback) {
                                  resultCallback();
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

@end
