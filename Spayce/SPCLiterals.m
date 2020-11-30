//
//  SPCLiterals.m
//  Spayce
//
//  Created by William Santiago on 4/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCLiterals.h"
#import "User.h"

NSString *kSPCKeyGoogleAuthenticationInProgress = @"SPCKeyGoogleAuthenticationInProgress";

NSString *kSPCDelayRateAppAlertDate = @"SPCDelayRateAppAlertDate";
NSString *kSPCSuppressRateAppAlert = @"kSPCSuppressRateAppAlert";
NSString *kSPCNumMemoriesPosted = @"kSPCNumMemoriesPosted";

NSString *kSPCSpayceTeamHandle = @"SpayceTeam";

@implementation SPCLiterals

+ (NSString *) literal:(NSString *)literal forUser:(User *)user  {
    return [literal stringByAppendingString:[@"_user_" stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)user.userId]]];
}

@end
