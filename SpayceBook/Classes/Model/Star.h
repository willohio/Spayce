//
//  Star.h
//  Spayce
//
//  Created by William Santiago on 5/21/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "Person.h"

@interface Star : Person

@property (nonatomic, strong) NSDate *dateStarred;

- (NSString *)displayDateStarred;
- (NSString *)displayDateMediumStarred;

@end
