//
//  NSArray+SPCAdditions.h
//  Spayce
//
//  Created by Pavel Dusatko on 9/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (SPCAdditions)

- (NSArray *)sortArrayDescending:(NSArray *)anArray basedOnField:(NSString *)field;

@end
