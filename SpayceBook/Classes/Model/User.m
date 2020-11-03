//
//  User.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/15/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "User.h"
#import "TranslationUtils.h"
#import "Asset.h"

NSInteger UserMinRequiredIdentityImages = 10;

@implementation User

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        _userId = [TranslationUtils integerValueFromDictionary:attributes withKey:@"id"];
        _username = (NSString *)[TranslationUtils valueOrNil:attributes[@"email"]];
        _userToken = (NSString *)[TranslationUtils valueOrNil:attributes[@"userToken"]];
        _imageAsset = [Asset assetFromDictionary:attributes withAssetKey:@"userPhotoAssetId" assetIdKey:@"userPhotoAssetInfo"];
        _isCeleb = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"isCeleb"];
        _isAdmin = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"isAdmin"];
    }
    return self;
}

@end
