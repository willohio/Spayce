//
//  SPCMemoryAsset.m
//  Spayce
//
//  Created by Christopher Taylor on 7/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCMemoryAsset.h"
#import "TranslationUtils.h"
#import "Asset.h"

@implementation SPCMemoryAsset

-(id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        _asset = [Asset assetFromDictionary:attributes withAssetKey:@"assetInfo" assetIdKey:@"assetID"];
        _memoryID = [TranslationUtils integerValueFromDictionary:attributes withKey:@"memoryID"];
        
        _type = [TranslationUtils integerValueFromDictionary:attributes withKey:@"type"];
        _memText = (NSString *)[TranslationUtils valueOrNil:attributes[@"memText"]];
        _height = 154;
        
        if (_type == MemoryTypeText) {
            _height = [self getHeightForText:_memText];
        }
    }
    
    return self;
}

-(CGFloat)getHeightForText:(NSString *)memText {
    
        CGSize constraint = CGSizeMake(144, FLT_MAX);
    
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:2];
        NSDictionary *attributes = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:14], NSParagraphStyleAttributeName: paragraphStyle };
        CGRect frame = [memText boundingRectWithSize:constraint
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:attributes
                                                   context:NULL];
    
        return  frame.size.height + 20;
    
}

@end
