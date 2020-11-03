//
//  SPCNeighborhood.h
//  Spayce
//
//  Created by Howard Cantrell on 6/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCCity.h"

@interface SPCNeighborhood : SPCCity

@property (assign, nonatomic) NSInteger personalStarsInNeighborhood;
@property (strong, nonatomic) NSString *neighborhood;

@end
