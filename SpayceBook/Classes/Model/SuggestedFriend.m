//
//  SuggestedFriend.m
//  Spayce
//
//  Created by Arria P. Owlia on 2/9/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SuggestedFriend.h"

// Utils
#import "TranslationUtils.h"

// Model
#import "Asset.h"

@implementation SuggestedFriend

- (instancetype)initWithAttributes:(NSDictionary *)attributes
{
  self = [super initWithAttributes:attributes];
  if (self) {
    
    // Banner Asset
    _profileBannerAssetInfo = (NSString *)[TranslationUtils valueOrNil:attributes[@"profileBannerAssetInfo"]];
    _bannerAsset = [Asset assetFromDictionary:attributes withAssetKey:@"profileBannerAssetInfo" assetIdKey:nil];
    
    // Profile Locked
    _profileLocked = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"profileLocked"];
  }
  return self;
}

@end
