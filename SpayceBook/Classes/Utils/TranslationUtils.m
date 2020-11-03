//
//  ParseUtils.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/24/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "TranslationUtils.h"

@implementation TranslationUtils

+(NSObject *) valueOrNil:(NSObject *) parseValue
{
    return [parseValue isKindOfClass:[NSNull class]] ? nil : parseValue;
}

+(NSNumber *) numberFromDictionary:(NSDictionary *) dictionary withKey:(NSString *) key {
    NSNumber * n = (NSNumber *) dictionary[key];
    return  ![n isKindOfClass:[NSNull class]] ? n : @0;
}

+(NSInteger)  integerValueFromDictionary:(NSDictionary *) dictionary withKey:(NSString *) key
{
    NSNumber * n = (NSNumber *)dictionary[key];
    return  ![n isKindOfClass:[NSNull class]] ? [n integerValue] : 0;
}

+(BOOL)  booleanValueFromDictionary:(NSDictionary *)dictionary withKey:(NSString *)key
{
    NSNumber * n = (NSNumber *)dictionary[key];
    return [n boolValue];
}



@end
