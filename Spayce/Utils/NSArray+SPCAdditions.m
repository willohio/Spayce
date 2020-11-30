//
//  NSArray+SPCAdditions.m
//  Spayce
//
//  Created by William Santiago on 9/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "NSArray+SPCAdditions.h"

@implementation NSArray (SPCAdditions)

- (NSArray *)sortArrayDescending:(NSArray *)anArray basedOnField:(NSString *)field {
    return [self sortArrayBasedOnField:field withAscending:NO];
}

- (NSArray *)sortArrayBasedOnField:(NSString *)field withAscending:(bool)ascending {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:field ascending:ascending];
    NSArray *sortDescriptors = @[sortDescriptor];
    return [self sortedArrayUsingDescriptors:sortDescriptors];
}

@end
