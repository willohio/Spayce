//
//  ContactAndProfileManager.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/15/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "ContactAndProfileManager.h"

// Model
#import "ProfileDetail.h"
#import "User.h"
#import "UserProfile.h"

// General
#import "Singleton.h"

// Manager
#import "AuthenticationManager.h"
#import "ProfileManager.h"

// Utility
#import "APIService.h"

NSString * ContactAndProfileManagerUserProfileDidUpdateNotification = @"UserProfileDidUpdate";
NSString * ContactAndProfileManagerUserProfilePhotoDidUpdateNotification = @"UserProfilePhotoDidUpdate";
NSString * ContactAndProfileManagerContactsDidUpdateNotification = @"ContactsDidUpdate";
NSString * ContactAndProfileManagerPersonalCardDidUpdateNotification = @"PersonalCardDidUpdate";
NSString * ContactAndProfileManagerBusinessCardDidUpdateNotification = @"BusinessCardDidUpdate";
NSString * ContactAndProfileManagerPersonalProfileDidUpdateNotification = @"PersonalProfileDidUpdate";
NSString * ContactAndProfileManagerProfessionalProfileDidUpdateNotification = @"ProfessionalProfileDidUpdate";
NSString * ContactAndProfileManagerVipProfileDidUpdateNotification = @"VipProfileDidUpdate";
NSString * ContactAndProfileManagerContactsChangedNotification = @"ContactsChanged";
NSString * ContactAndProfileManagerDidUpdateStatusNotification = @"UserStatusUpdate";

@interface ContactAndProfileManager() {
    NSMutableDictionary *userIdToContact;
}

@end

@implementation ContactAndProfileManager

SINGLETON_GCD(ContactAndProfileManager);

#pragma mark - Object lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    if (self = [super init]) {
        userIdToContact = [[NSMutableDictionary alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fetchUserProfile)
                                                     name:kAuthenticationDidFinishWithSuccessNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLogout:)
                                                     name:kAuthenticationDidLogoutNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fetchUserProfile)
                                                     name:kAuthenticationDidUpdateUserInfoNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fetchUserProfile)
                                                     name:@"profileNeedsRefresh"
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Accessors

- (void)fetchUserProfile {
    NSString *url = [NSString stringWithFormat:@"/meet/getUserProfile/%@", [AuthenticationManager sharedInstance].currentUser.userToken];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              NSDictionary *src = (NSDictionary *)result;
                              //NSLog(@"url %@ result %@",url,result);
                              
                              self.profile = [[UserProfile alloc] initWithAttributes:src];
                              [self.profile updateWithFriendCount:[src[@"totalFriendCount"] integerValue]];
                              
                              [[NSUserDefaults standardUserDefaults] setObject:self.profile.profileDetail.firstname forKey:@"userHandle"];
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:ContactAndProfileManagerUserProfileDidUpdateNotification object:nil];
                          } faultCallback:nil];
}

#pragma mark - SpayceMeet profiles

- (void)updateProfile:(UserProfile *)profile
         profileImage:(UIImage *)profileImage
       resultCallback:(void (^)(void))resultCallback
        faultCallback:(void (^) (NSError * fault))faultCallback {
    __block BOOL didUploadProfileImage = profileImage == nil;
    
    __block Asset *firstPhotoAsset = nil;
    __block Asset *secondPhotoAsset = nil;
    __block Asset *thirdPhotoAsset = nil;

    void (^doUpdateProfile)(void) = ^{

        NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];

        if (profile.profileDetail.firstname && ![profile.profileDetail.firstname isEqualToString:@""]) {
            queryParams[@"firstName"] = profile.profileDetail.firstname;
        }

        if (profile.profileDetail.lastname && ![profile.profileDetail.lastname isEqualToString:@""]) {
            queryParams[@"lastName"] = profile.profileDetail.lastname;
        }

        NSString *maritalStatusEnum = profile.profileDetail.maritalStatus;
        if (maritalStatusEnum && ![maritalStatusEnum isEqualToString:@""]) {
            queryParams[@"maritalStatus"] = maritalStatusEnum;
        }

        if (profile.profileDetail.birthday) {
            long long interval = (long long)(NSTimeInterval)([profile.profileDetail.birthday timeIntervalSince1970] * 1000);
            queryParams[@"birthDay"] = @(interval);
        }

        NSString *genderEnum = [profile.profileDetail genderEnumForString:profile.profileDetail.gender];
        if (genderEnum && ![genderEnum isEqualToString:@""]) {
            queryParams[@"gender"] = genderEnum;
        }

        if (profile.profileDetail.statusMessage && ![profile.profileDetail.statusMessage isEqualToString:@""]) {
            queryParams[@"statusMessage"] = profile.profileDetail.statusMessage;
        }

        if (profile.profileDetail.aboutMe && ![profile.profileDetail.aboutMe isEqualToString:@""]) {
            queryParams[@"aboutMe"] = profile.profileDetail.aboutMe;
        }

        if (profile.profileDetail.imageAsset != nil) {
            queryParams[@"profilePhotoAssetId"] = @(profile.profileDetail.imageAsset.assetID);
        }

        NSMutableArray *photosAssets = [NSMutableArray arrayWithArray:profile.profileDetail.photosAssets];

        if (firstPhotoAsset) {
            if (photosAssets.count > 0) {
                photosAssets[0] = firstPhotoAsset;
            } else {
                [photosAssets addObject:firstPhotoAsset];
            }
        }
        if (secondPhotoAsset) {
            if (photosAssets.count > 1) {
                photosAssets[1] = secondPhotoAsset;
            } else {
                [photosAssets addObject:secondPhotoAsset];
            }
        }
        if (thirdPhotoAsset) {
            if (photosAssets.count > 2) {
                photosAssets[2] = thirdPhotoAsset;
            } else {
                [photosAssets addObject:thirdPhotoAsset];
            }
        }

        if (photosAssets && photosAssets.count > 0) {
            NSMutableArray *photosAssetIds = [[NSMutableArray alloc] initWithCapacity:photosAssets.count];
            for (Asset *asset in photosAssets) {
                [photosAssetIds addObject:[NSString stringWithFormat:@"%@", @(asset.assetID)]];
            }
            queryParams[@"photosAssetIds"] = [photosAssetIds componentsJoinedByString:@","];
        }
        NSLog(@"update profile, queryParams %@",queryParams);
        __weak typeof(self)weakSelf = self;

        [APIService makeApiCallWithMethodUrl:@"/meet/updatePersonalProfile"
                              andRequestType:RequestTypePost
                               andPathParams:nil
                              andQueryParams:queryParams
                              resultCallback:^(NSObject *result) {
                                  __strong typeof(weakSelf)strongSelf = weakSelf;

                                  NSDictionary *src = (NSDictionary *)result;

                                  if (!strongSelf.profile.profileDetail) {
                                      strongSelf.profile.profileDetail = [[ProfileDetail alloc] initWithAttributes:src];
                                  } else {
                                      [strongSelf.profile.profileDetail updateWithAttributes:src];
                                  }

                                  [[NSNotificationCenter defaultCenter] postNotificationName:ContactAndProfileManagerPersonalProfileDidUpdateNotification
                                                                                      object:nil];

                                  if (resultCallback) {
                                      resultCallback();
                                  }
                              } faultCallback:^(NSError *fault) {
                                  if (faultCallback) {
                                      faultCallback(fault);
                                  }
                              }];
    };
    
    if (!profileImage) {
        doUpdateProfile();
    }
    
    void (^didFinishUploadingImage)(void) = ^{
        if (didUploadProfileImage) {
            doUpdateProfile();
        }
    };
    
    if (profileImage) {
        [APIService uploadAssetToSpayceVaultWithData:UIImageJPEGRepresentation(profileImage, 0.75)
                                      andQueryParams:nil
                                    progressCallback:nil
                                      resultCallback:^(Asset *asset) {
                                          profile.profileDetail.imageAsset = asset;
                                          
                                          didUploadProfileImage = YES;
                                          
                                          if (didFinishUploadingImage) {
                                              didFinishUploadingImage();
                                              
                                              [[NSNotificationCenter defaultCenter] postNotificationName:ContactAndProfileManagerUserProfilePhotoDidUpdateNotification object:nil];
                                              
                                          }
                                    } faultCallback:^(NSError *fault) {
                                        if (faultCallback) {
                                            faultCallback(fault);
                                        }
                                    }];
    }
}

- (void)updateProfileBanner:(UserProfile *)profile
                bannerImage:(UIImage *)bannerImage
             resultCallback:(void (^)(NSInteger bannerAssetId))resultCallback
              faultCallback:(void (^)(NSError * fault))faultCallback {
    __block BOOL didUploadBannerImage = bannerImage == nil;
    
    void (^doUpdateProfile)(void) = ^{
        if (profile.profileDetail.bannerAsset != nil) {
            [ProfileManager updateProfileBannerAssetId:profile.profileDetail.bannerAsset.assetID resultCallback:^{
                if (resultCallback) {
                    resultCallback(profile.profileDetail.bannerAsset.assetID);
                }
            } faultCallback:^(NSError *fault){
                if (faultCallback) {
                    faultCallback(fault);
                }
            }];
        }
    };
    
    void (^didFinishUploadingImage)(void) = ^{
        if (didUploadBannerImage) {
            doUpdateProfile();
        }
    };
    
    if (bannerImage) {
        [APIService uploadAssetToSpayceVaultWithData:UIImageJPEGRepresentation(bannerImage, 0.75)
                                      andQueryParams:nil
                                    progressCallback:nil
                                      resultCallback:^(Asset *asset) {
                                          profile.profileDetail.bannerAsset = asset;
                                          
                                          didUploadBannerImage = YES;
                                          
                                          if (didFinishUploadingImage) {
                                              didFinishUploadingImage();
                                          }
                                      } faultCallback:^(NSError *fault) {
                                          if (faultCallback) {
                                              faultCallback(fault);
                                          }
                                      }];
    }
}

- (void)updateProfileImage:(UIImage *)image isProfilePhoto:(BOOL)isProfilePhoto {
    if (image) {
        [APIService uploadAssetToSpayceVaultWithData:UIImageJPEGRepresentation(image, 0.75)
                                      andQueryParams:nil
                                    progressCallback:nil
                                      resultCallback:^(Asset *asset) {
                                          
                                          self.profile.profileDetail.imageAsset = asset;
                                          
                                          [self updateProfile:self.profile profileImage:image resultCallback:^{
                                              [[NSNotificationCenter defaultCenter] postNotificationName:ContactAndProfileManagerUserProfileDidUpdateNotification object:nil];
                                          } faultCallback:nil];
                                          
                                          if (isProfilePhoto) {
                                              [[NSNotificationCenter defaultCenter] postNotificationName:ContactAndProfileManagerUserProfilePhotoDidUpdateNotification object:nil];
                                          }
                                      } faultCallback:nil];
    }
}

#pragma mark - Handle notifications

- (void)handleLogout:(NSNotification *)notification {
    self.profile.profileDetail = nil;
    self.profile = nil;
    
    [userIdToContact removeAllObjects];
}

@end
