//
//  ProfileManager.h
//  Spayce
//
//  Created by Jake Rosin on 4/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserProfile;

@interface ProfileManager : NSObject

+ (void)fetchProfileWithUserToken:(NSString *)userToken
                   resultCallback:(void (^)(UserProfile *profile))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)updateProfileBannerAssetId:(NSInteger)bannerAssetId
                    resultCallback:(void (^)(void))resultCallback
                     faultCallback:(void (^)(NSError *))faultCallback;

@end
