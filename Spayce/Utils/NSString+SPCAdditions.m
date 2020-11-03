//
//  NSString+SPCAdditions.m
//  Spayce
//
//  Created by Pavel Dusatko on 8/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "NSString+SPCAdditions.h"

@implementation NSString (SPCAdditions)

#pragma mark - General

- (NSString *)firstLetter {
    return (self.length > 0) ? [self substringToIndex:1] : nil;
}

#pragma mark - Image naming

- (NSString *)stringBetweenString:(NSString *)start andString:(NSString *)ending {
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    
    if ([scanner scanString:start intoString:NULL]) {
        NSString *result = nil;
        if ([scanner scanUpToString:ending intoString:&result]) {
            return result;
        }
    }
    return nil;
}

#pragma mark - Distance

+ (NSString *)stringFromDistance:(CGFloat)distance {
    if (distance < 0) {
        return @"";
    }
    
    CGFloat miles = distance * 0.000621371;
    NSInteger milesInt = (NSInteger)miles;
    NSInteger milesTenth = ((int)(miles * 10) % 10);
    if (miles < 2) {
        return [NSString stringWithFormat:@"%@.%@mi", @(milesInt), @(milesTenth)];
    } else if (miles < 1000) {
        return [NSString stringWithFormat:@"%@mi", @(milesInt)];
    } else if (miles >= 1000) {
        return [NSString stringWithFormat:@"1k+ mi"];
    }
    return @"";
}

+ (NSString *)detailedStringFromDistance:(CGFloat)distance {
    if (distance < 0) {
        return @"";
    }
    
    CGFloat miles = distance * 0.000621371;
    NSInteger milesInt = (NSInteger)miles;
    NSInteger milesTenths = ((int)(miles * 10) % 10);
    NSInteger milesHundredths = ((int)(miles * 100) % 100);
    if (milesInt == 0) {
        return [NSString stringWithFormat:@"%@.%02ldmi", @(milesInt), (long)milesHundredths];
    } else {
        return [NSString stringWithFormat:@"%@.%@mi", @(milesInt), @(milesTenths)];
    }
}

+ (NSString *)stringInFeetFromDistance:(CGFloat)distance {
    if (distance < 0) {
        return @"";
    }
    
    CGFloat feet = distance * 3.2808399;
    NSInteger feetInt = (NSInteger)feet;
    if (999 >= feetInt) {
        return [NSString stringWithFormat:@"%@ft", @(feetInt)];
    }
    else {
        return [NSString stringWithFormat:@"1k+ ft"];
    }
}

+ (NSString *)stringInFeetOrMilesFromDistance:(CGFloat)distance {
    NSString *distanceToReturn = @""; // Default value - return nothing if distance is not greater than 0
    
    if (0 <= distance)
    {
        CGFloat feet = distance * 3.2808399;
        NSInteger feetInt = (NSInteger)feet;
        if (5280 >= feetInt) { // If we're less than one mile away
            distanceToReturn = [NSString stringWithFormat:@"%@ft", @(feetInt)];
        }
        else {
            CGFloat miles = distance * 0.000621371;
            NSInteger milesInt = (NSInteger)miles;
            if (milesInt == 0) { // We're at 0 miles away, i.e. probably at 5280 feet exactly
                distanceToReturn = [NSString stringWithFormat:@"1mi"];
            } else if (1000 > milesInt) { // We're at [1,1000) miles away
                distanceToReturn = [NSString stringWithFormat:@"%@mi", @(milesInt)];
            } else { // We're > 1000 miles away
                distanceToReturn = [NSString stringWithFormat:@"1k+ mi"];
            }
        }
    }
    
    return distanceToReturn;
}

+ (NSString *)stringInFeetOrMilesFromDistanceWithRounding:(CGFloat)distance {
    NSString *distanceToReturn = @""; // Default value - return nothing if distance is not greater than 0
    
    if (0 <= distance)
    {
        CGFloat feet = distance * 3.2808399;
        NSInteger feetInt = (NSInteger)feet;
        if (5280 >= feetInt) { // If we're less than one mile away
            if (1000 > feetInt) { // Less than 1000ft, round to the 10s place
                distanceToReturn = [NSString stringWithFormat:@"%@ft", @(round(feetInt / 10) * 10)];
            } else { // [1000, 5280], round to the 100s place
                distanceToReturn = [NSString stringWithFormat:@"%@ft", @(round(feetInt / 100) * 100)];
            }
        }
        else {
            CGFloat miles = distance * 0.000621371;
            NSInteger milesInt = (NSInteger)miles;
            if (milesInt == 0) { // We're at 0 miles away, i.e. probably at 5280 feet exactly
                distanceToReturn = [NSString stringWithFormat:@"1.0mi"];
            } else if (1000 > milesInt) { // We're at [1,1000) miles away
                distanceToReturn = [NSString stringWithFormat:@"%.1fmi", round(miles * 10.0f) / 10.0f];
            } else { // We're > 1000 miles away
                distanceToReturn = [NSString stringWithFormat:@"1k+ mi"];
            }
        }
    }
    
    return distanceToReturn;
}

+ (NSString *)stringInTruncatedFeetOrMilesFromDistance:(CGFloat)distance {
    NSString *distanceToReturn = @""; // Default value - return nothing if distance is not greater than 0
    
    if (0 <= distance)
    {
        CGFloat feet = distance * 3.2808399;
        NSInteger feetInt = (NSInteger)feet;
        if (5280 >= feetInt) { // If we're less than one mile away
            distanceToReturn = [NSString stringWithFormat:@"%@ft", @(feetInt)];
        }
        else {
            CGFloat miles = distance * 0.000621371;
            NSInteger milesInt = (NSInteger)miles;
            if (milesInt == 0) { // We're at 0 miles away, i.e. probably at 5280 feet exactly
                distanceToReturn = [NSString stringWithFormat:@"1mi"];
            } else if (1000 > milesInt) { // We're at [1,1000) miles away
                distanceToReturn = [NSString stringWithFormat:@"%@mi", @(milesInt)];
            } else { // We're > 1000 miles away
                distanceToReturn = [NSString stringWithFormat:@"1k+ mi"];
            }
        }
    }
    
    return distanceToReturn;
}

#pragma mark - Truncated integer

+ (NSString *)stringByTruncatingInteger:(NSInteger)integer {
    if (integer < 1000) {
        return [NSString stringWithFormat:@"%@", @(integer)];
    } else if (integer < 10000) {
        return [NSString stringWithFormat:@"%@.%@k", @(integer / 1000), @(((long)integer % 1000) / 100)];
    } else if (integer < 1000000) {
        return [NSString stringWithFormat:@"%@k", @(integer / 1000)];
    } else if (integer < 10000000) {
        return [NSString stringWithFormat:@"%@.%@M", @(integer / 1000000), @(((long)integer % 1000000) / 100)];
    } else {
        return [NSString stringWithFormat:@"%@M", @(integer / 1000000)];
    }
}

+ (NSString *)stringByFormattingInteger:(NSInteger)integer {
    BOOL neg = integer < 0;
    NSInteger val = neg ? -integer : integer;
    NSString *str = nil;
    while (val != 0) {
        NSString *header;
        if (val >= 1000) {
            header = [NSString stringWithFormat:@"%03d", val % 1000];
        } else {
            header = [NSString stringWithFormat:@"%d", val % 1000];
        }
        
        if (str) {
            str = [NSString stringWithFormat:@"%@,%@", header, str];
        } else {
            str = header;
        }
        
        val /= 1000;
    }
    
    return str;
}

#pragma mark - Ellipsizing string

// Ellipsizing / Truncating string
- (NSString *)stringByEllipsizingWithSize:(CGSize)size attributes:(NSDictionary *)attributes {
    return [self stringByEllipsizingWithSize:size attributes:attributes ellipsis:@"..."];
}

- (NSString *)stringByEllipsizingWithSize:(CGSize)size attributes:(NSDictionary *)attributes ellipsis:(NSString *)ellipsis {
    // Divide the string into parts separated by whitespace.  Build the string
    // back up piece-by-piece until we find the maximum size that, including the ellipsis
    // text, will fit within the space provided.
    
    CGSize sizeTaller = CGSizeMake(size.width, size.height * 2 + 1000000);
    
    // First, though, measure the full text.
    NSString *source = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    CGRect fullSize = [source boundingRectWithSize:sizeTaller options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    if (fullSize.size.height <= size.height) {
        // the whole thing will fit!
        return source;
    }
    
    // Otherwise, we need to truncate.  Our preferences:
    // 1. include as many words (non-whitespace) on each line as possible.
    // 2. do not include whitespace immediately before the ellipsis text on the same line
    // 3. maintain whitespace strings if included (e.g. three spaces are still three spaces, not one).
    // 4. only leading / trailing whitespace is an exception to 3.
    
    NSArray *words = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    int nextWord = 0;
    int nextCharacter = 0;
    NSString *result = @"";
    while (true) {
        NSString *previousResult = result;
        
        // extend the result by all whitespace included, followed by the next word.
        // then test adding the ellipsis.  If the whole thing does not fit, restore
        // the previous 'result' and break.
        while(true) {
            if (nextWord >= words.count) {
                // we've used all available text
                break;
            }
            NSString *word = words[nextWord];
            BOOL shouldBreak = NO;
            
            //make sure our 'word' is long enough before we try to use it!
            if (word.length > 0 && ([word characterAtIndex:0] != [source characterAtIndex:nextCharacter])) {
                // there is whitespace before we reach this word.
            
                //make sure our source is long enough before we try to create a substring with it!
                if (source.length > nextCharacter + 1) {
                    word = [source substringWithRange:NSMakeRange(nextCharacter, 1)];
                    nextCharacter++;
                }
                else {
                    nextWord++;
                    nextCharacter += word.length;
                    shouldBreak = YES;
                }
            } else {
                nextWord++;
                nextCharacter += word.length;
                shouldBreak = YES;
            }
            result = [result stringByAppendingString:word];
            if (shouldBreak) {
                break;
            }
        }
        
        // try including the ellipsis: does that exceed our size?
        CGRect ellipsizedBounds = [[result stringByAppendingString:ellipsis] boundingRectWithSize:sizeTaller options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
        if (ellipsizedBounds.size.height > size.height) {
            // just went over.  Result result and break.
            result = previousResult;
            break;
        }
    }
    
    return [result stringByAppendingString:ellipsis];
}

@end
