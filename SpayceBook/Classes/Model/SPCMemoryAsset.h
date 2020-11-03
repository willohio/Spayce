//
//  SPCMemoryAsset.h
//  Spayce
//
//  Created by Christopher Taylor on 7/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Memory.h"

@class Asset;

@interface SPCMemoryAsset : NSObject

@property (nonatomic, strong) Asset *asset;
@property (nonatomic, assign) NSInteger memoryID;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) NSString *memText;


// Custom initializer
- (id)initWithAttributes:(NSDictionary *)attributes;

@end
