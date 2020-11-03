//
//  Friend.h
//  Spayce
//
//  Created by Pavel Dušátko on 11/28/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "Person.h"

@interface Friend : Person

@property (strong, nonatomic) NSString *status;
@property (strong, nonatomic) NSDate *dateAcquainted;
@property (strong, nonatomic) NSArray *memories;
@property (strong, nonatomic) NSString *distance;

- (id)initWithAttributes:(NSDictionary *)attributes;

- (NSString *)displayName;

@end
