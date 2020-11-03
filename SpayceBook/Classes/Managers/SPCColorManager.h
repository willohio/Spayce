//
//  SPCColorManager.h
//  Spayce
//
//  Created by Howard Cantrell on 7/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCColorManager : NSObject

@property (nonatomic,readonly) UIColor *nameNormalColor;

@property (nonatomic,readonly) UIColor *buttonDisabledColor;
@property (nonatomic,readonly) UIColor *buttonEnabledColor;
@property (nonatomic,readonly) UIColor *buttonEnabledFadedColor;



+ (SPCColorManager *)sharedInstance;

@end
