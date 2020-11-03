//
//  ContactAndProfileManager.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/15/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserProfile;

// TODO: Remove
extern NSString * ContactAndProfileManagerUserProfileDidUpdateNotification;
extern NSString * ContactAndProfileManagerUserProfilePhotoDidUpdateNotification;
extern NSString * ContactAndProfileManagerContactsDidUpdateNotification;
extern NSString * ContactAndProfileManagerPersonalCardDidUpdateNotification;
extern NSString * ContactAndProfileManagerBusinessCardDidUpdateNotification;
extern NSString * ContactAndProfileManagerPersonalProfileDidUpdateNotification;
extern NSString * ContactAndProfileManagerProfessionalProfileDidUpdateNotification;
extern NSString * ContactAndProfileManagerVipProfileDidUpdateNotification;
extern NSString * ContactAndProfileManagerContactsChangedNotification;
extern NSString * ContactAndProfileManagerDidUpdateStatusNotification;

@interface ContactAndProfileManager : NSObject

@property (strong, nonatomic) UserProfile *profile;

+ (ContactAndProfileManager *)sharedInstance;

- (void)updateProfile:(UserProfile *)profile
         profileImage:(UIImage *)profileImage
       resultCallback:(void (^)(void))resultCallback
        faultCallback:(void (^) (NSError * fault))faultCallback;

- (void)updateProfileImage:(UIImage *)image
            isProfilePhoto:(BOOL)isProfilePhoto;

- (void)updateProfileBanner:(UserProfile *)profile
                bannerImage:(UIImage *)bannerImage
             resultCallback:(void (^)(NSInteger bannerAssetId))resultCallback
              faultCallback:(void (^)(NSError * fault))faultCallback;

@end
