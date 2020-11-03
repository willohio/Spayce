//
//  SPCVenueDetailDataSource.h
//  Spayce
//
//  Created by Pavel Dusatko on 9/30/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTileSupportingDataSource.h"
@class Memory;




@interface SPCVenueDetailDataSource : SPCTileSupportingDataSource

@property (nonatomic, strong) Venue *venue;

- (BOOL)isMemoryAtIndexPath:(NSIndexPath *)indexPath;

@end
