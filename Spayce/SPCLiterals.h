//
//  SPCLiterals.h
//  Spayce
//
//  Created by Pavel Dusatko on 4/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

extern NSString *kSPCKeyGoogleAuthenticationInProgress;

extern NSString *kSPCDelayRateAppAlertDate;
extern NSString *kSPCSuppressRateAppAlert;
extern NSString *kSPCNumMemoriesPosted;

extern NSString *kSPCSpayceTeamHandle;

@interface  SPCLiterals : NSObject

+ (NSString *) literal:(NSString *)literal forUser:(User *)user;

@end