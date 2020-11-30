//
//  NSString+SPCAdditions.h
//  Spayce
//
//  Created by William Santiago on 8/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SPCAdditions)

// General
- (NSString *)firstLetter;

// Image naming
- (NSString *)stringBetweenString:(NSString *)start andString:(NSString *)ending;

// Distance
+ (NSString *)stringFromDistance:(CGFloat)distance;
+ (NSString *)detailedStringFromDistance:(CGFloat)distance;
+ (NSString *)stringInFeetFromDistance:(CGFloat)distance;
+ (NSString *)stringInFeetOrMilesFromDistance:(CGFloat)distance;
+ (NSString *)stringInFeetOrMilesFromDistanceWithRounding:(CGFloat)distance;
+ (NSString *)stringInTruncatedFeetOrMilesFromDistance:(CGFloat)distance;

// Truncated integer
+ (NSString *)stringByTruncatingInteger:(NSInteger)integer;
// Formatting with commas
+ (NSString *)stringByFormattingInteger:(NSInteger)integer;

// Ellipsizing / Truncating string
- (NSString *)stringByEllipsizingWithSize:(CGSize)size attributes:(NSDictionary *)attributes;
- (NSString *)stringByEllipsizingWithSize:(CGSize)size attributes:(NSDictionary *)attributes ellipsis:(NSString *)ellipsis;


@end
