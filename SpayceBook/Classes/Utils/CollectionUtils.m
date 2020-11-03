//
//  CollectionUtils.m
//  SpayceBook
//
//  Created by Dmitry Miller on 7/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "CollectionUtils.h"

@implementation CollectionUtils

+(NSString *) listFromCollection:(NSArray *)collection withSeparator:(NSString *) separator
{
    NSMutableString * res = [[NSMutableString alloc] init];
    
    BOOL isFirstItem = YES;
    for(NSObject * item in collection)
    {
        if(isFirstItem)
        {
            isFirstItem = NO;
        }
        else
        {
            [res appendString:separator];
        }
        
        if([item isKindOfClass:[NSString class]])
        {
            [res appendString:(NSString *)item];
        }
        else
        {
            [res appendString:[item description]];
        }
    }
    
    return res;
}

@end
