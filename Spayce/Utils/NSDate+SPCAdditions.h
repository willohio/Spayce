//
//  NSDate+SPCAdditions.h
//  Spayce
//
//  Created by William Santiago on 6/3/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (SPCAdditions)

+ (NSString *)formattedDateStringWithDate:(NSDate *)date;
+ (NSString *)formattedMediumDateStringWithDate:(NSDate *)date;
+ (NSString *)formattedDateStringWithString:(NSString *)string;
+ (NSString *)longFormattedDateStringWithString:(NSString *)string;
@end
