//
//  SuggestedFriend.h
//  Spayce
//
//  Created by Arria P. Owlia on 2/9/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "Person.h"

@interface SuggestedFriend : Person

@property (strong, nonatomic) NSString *profileBannerAssetInfo;
@property (strong, nonatomic) Asset *bannerAsset;

@property (nonatomic) BOOL profileLocked;

- (instancetype)initWithAttributes:(NSDictionary *)attributes;

@end
