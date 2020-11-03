//
//  Friend.m
//  Spayce
//
//  Created by Pavel Dušátko on 11/28/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "Friend.h"

// Utility
#import "TranslationUtils.h"

@implementation Friend

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super initWithAttributes:attributes];
    if (self) {
        _status = (NSString *)[TranslationUtils valueOrNil:attributes[@"status"]];
        _distance = (NSString *)[TranslationUtils valueOrNil:attributes[@"distance"]];
        
        self.mutualFriendsCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"mutualFriendsCount"];

        [self initializeDateAcquaintedWithAttributes:attributes];
    }
    return self;
}

- (void)initializeDateAcquaintedWithAttributes:(NSDictionary *)attributes
{
    NSNumber *dateAcquainted = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"dateAcquainted"]];
    
    if (dateAcquainted) {
        NSTimeInterval seconds = [dateAcquainted doubleValue];
        NSTimeInterval miliseconds = seconds/1000;
        _dateAcquainted = [NSDate dateWithTimeIntervalSince1970:miliseconds];
    }
}

#pragma mark - Accessors

- (NSString *)displayName {
    if (self.recordID == -1) {
        // Spayce Te...
        return @"Spayce";
    }
    NSMutableString *mutableString = [NSMutableString string];
        
    if (self.firstname.length > 0) {
        [mutableString appendString:self.firstname];
    }
    if (self.lastname.length > 0) {
        if (mutableString.length > 0) {
            [mutableString appendString:@" "];
        }
        [mutableString appendString:self.lastname];
    }
    return [NSString stringWithString:mutableString];

}

@end
