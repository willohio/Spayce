//
//  Star.m
//  Spayce
//
//  Created by Pavel Dusatko on 5/21/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "Star.h"
#import "TranslationUtils.h"
#import "NSDate+SPCAdditions.h"

@implementation Star

- (instancetype)initWithAttributes:(NSDictionary *)attributes {
    self = [super initWithAttributes:attributes];
    if (self) {
        [self initializeDateStarredWithAttributes:attributes];
    }
    return self;
}

- (void)initializeDateStarredWithAttributes:(NSDictionary *)attributes {
    NSNumber *dateStarred = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"dateStarred"]];
    
    if (dateStarred) {
        NSTimeInterval seconds = [dateStarred doubleValue];
        NSTimeInterval miliseconds = seconds/1000;
        _dateStarred = [NSDate dateWithTimeIntervalSince1970:miliseconds];
    }
}

#pragma mark - Accessors

- (NSString *)displayDateStarred {
    return [NSDate formattedDateStringWithDate:self.dateStarred];
}

- (NSString *)displayDateMediumStarred {
    return [NSDate formattedMediumDateStringWithDate:self.dateStarred];
}

@end
