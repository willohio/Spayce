//
//  NSDate+SPCAdditions.m
//  Spayce
//
//  Created by William Santiago on 6/3/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "NSDate+SPCAdditions.h"

@implementation NSDate (SPCAdditions)

#pragma mark - Private

+ (NSString *)formattedDateStringWithTimestamp:(double)timestamp {
    NSString *adjustedTimeElapsed = @"";
    
    NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
    NSTimeInterval elapsedInterval = (nowIntervalMS - (NSTimeInterval)timestamp) / 1000;
    
    if (elapsedInterval < 60) {
        double elapsedSecs = (double)elapsedInterval;
        int secE = (int)elapsedSecs;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%is", secE];
    }
    else if (elapsedInterval < 3600) {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = floor(elapsedSecs/60);
        int minE = (int)minElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%im", minE];
    }
    else if (elapsedInterval < 86400) {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = (elapsedSecs/60);
        double hoursElapsed = floor(minElapsed/60);
        int hourE = (int)hoursElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%ih", hourE];
    }
    else if (elapsedInterval < 604800) {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = (elapsedSecs/60);
        double hoursElapsed = (minElapsed/60);
        double daysElapsed = floor(hoursElapsed/24);
        int daysE = (int)daysElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%id", daysE];
    }
    else if (elapsedInterval < 31536000) {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = (elapsedSecs/60);
        double hoursElapsed = (minElapsed/60);
        double daysElapsed = (hoursElapsed/24);
        double weeksElapsed = floor(daysElapsed/7);
        int weekE = (int)weeksElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%iw", weekE];
    }
    else {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = (elapsedSecs/60);
        double hoursElapsed = (minElapsed/60);
        double daysElapsed = (hoursElapsed/24);
        double weeksElapsed = (daysElapsed/7);
        double yearsElapsed = floor(weeksElapsed/52);
        int yearE = (int)yearsElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%iy", yearE];
    }
    
    return adjustedTimeElapsed;
}

+ (NSString *)longFormattedDateStringWithTimestamp:(double)timestamp {
    NSString *adjustedTimeElapsed = @"";
  
    NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
    NSTimeInterval elapsedInterval = (nowIntervalMS - (NSTimeInterval)timestamp) / 1000;
    
    if (elapsedInterval < 60) {
        double elapsedSecs = (double)elapsedInterval;
        int secE = (int)elapsedSecs;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%i seconds ago", secE];
        if (secE == 1) {
            adjustedTimeElapsed = [NSString stringWithFormat:@"%i second ago", secE];
        }
    }
    else if (elapsedInterval < 3600) {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = floor(elapsedSecs/60);
        int minE = (int)minElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%i minutes ago", minE];
        if (minE == 1) {
            adjustedTimeElapsed = [NSString stringWithFormat:@"%i minute ago", minE];
        }
    }
    else if (elapsedInterval < 86400) {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = (elapsedSecs/60);
        double hoursElapsed = floor(minElapsed/60);
        int hourE = (int)hoursElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%i hours ago", hourE];
        if (hourE == 1) {
            adjustedTimeElapsed = [NSString stringWithFormat:@"%i hour ago", hourE];
        }
    }
    else if (elapsedInterval < 604800) {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = (elapsedSecs/60);
        double hoursElapsed = (minElapsed/60);
        double daysElapsed = floor(hoursElapsed/24);
        int daysE = (int)daysElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%i days ago", daysE];
        if (daysE == 1) {
            adjustedTimeElapsed = [NSString stringWithFormat:@"%i day ago", daysE];
        }
    }
    else if (elapsedInterval < 31536000) {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = (elapsedSecs/60);
        double hoursElapsed = (minElapsed/60);
        double daysElapsed = (hoursElapsed/24);
        double weeksElapsed = floor(daysElapsed/7);
        int weekE = (int)weeksElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%i weeks ago", weekE];
        if (weekE == 1) {
            adjustedTimeElapsed = [NSString stringWithFormat:@"%i week ago", weekE];
        }
    }
    else {
        double elapsedSecs = (double)elapsedInterval;
        double minElapsed = (elapsedSecs/60);
        double hoursElapsed = (minElapsed/60);
        double daysElapsed = (hoursElapsed/24);
        double weeksElapsed = (daysElapsed/7);
        double yearsElapsed = floor(weeksElapsed/52);
        int yearE = (int)yearsElapsed;
        adjustedTimeElapsed = [NSString stringWithFormat:@"%i years ago", yearE];
        if (yearE == 1) {
            adjustedTimeElapsed = [NSString stringWithFormat:@"%i year ago", yearE];
        }
    }
    
    return adjustedTimeElapsed;
}


#pragma mark - Accessors

+ (NSString *)formattedDateStringWithDate:(NSDate *)date {
    double timestampComment = [date timeIntervalSince1970] * 1000;
    
    return [[self class] formattedDateStringWithTimestamp:timestampComment];
}

+ (NSString *)formattedDateStringWithString:(NSString *)string {
    double timestampComment = [string doubleValue];
    
    return [[self class] formattedDateStringWithTimestamp:timestampComment];
}


+ (NSString *)longFormattedDateStringWithString:(NSString *)string {
    double timestampComment = [string doubleValue];
    
    return [[self class] longFormattedDateStringWithTimestamp:timestampComment];
}

+ (NSString *)formattedMediumDateStringWithDate:(NSDate *)date {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *dateNow = [NSDate date];
    NSDateComponents *components = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekOfYearCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit
                                          fromDate:date
                                            toDate:dateNow
                                           options:0];
    
    NSString *strRet = @"0sec"; // Default case - the input date precedes or is equal to the current date
    
    if (0 < components.year) {
        strRet = [NSString stringWithFormat:@"%@yr", @(components.year)];
    }
    else if (0 < components.month) {
        strRet = [NSString stringWithFormat:@"%@m", @(components.month)];
    }
    else if (0 < components.weekOfYear) {
        strRet = [NSString stringWithFormat:@"%@w", @(components.weekOfYear)];
    }
    else if (0 < components.day) {
        strRet = [NSString stringWithFormat:@"%@d", @(components.day)];
    }
    else if (0 < components.hour) {
        strRet = [NSString stringWithFormat:@"%@hr", @(components.hour)];
    }
    else if (0 < components.minute) {
        strRet = [NSString stringWithFormat:@"%@min", @(components.minute)];
    }
    else if (0 < components.second) {
        strRet = [NSString stringWithFormat:@"%@sec", @(components.second)];
    }
    
    return strRet;
}

@end
