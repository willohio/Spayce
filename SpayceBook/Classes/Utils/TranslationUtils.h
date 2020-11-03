//
//  ParseUtils.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/24/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TranslationUtils : NSObject

+(NSObject *) valueOrNil:(NSObject *) parseValue;
+(NSNumber *) numberFromDictionary:(NSDictionary *) dictionary withKey:(NSString *) key;
+(NSInteger)  integerValueFromDictionary:(NSDictionary *) dictionary withKey:(NSString *) key;
+(BOOL)  booleanValueFromDictionary:(NSDictionary *) dictionary withKey:(NSString *) key;

@end
