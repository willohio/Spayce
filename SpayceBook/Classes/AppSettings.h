//
//  AppSettings.h
//  Spayce
//
//  Created by Howard Cantrell on 11/8/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppSettings : NSObject

@property (nonatomic, strong) NSDictionary *settings;

+ (AppSettings *)sharedInstance;

- (void)loadAndCheckForUpdate;

@end
