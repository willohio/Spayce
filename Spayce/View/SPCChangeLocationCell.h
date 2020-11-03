//
//  SPCChangeLocationCell.h
//  Spayce
//
//  Created by Christopher Taylor on 10/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCLocationCell.h"

@interface SPCChangeLocationCell : SPCLocationCell

- (void)configureCellWithVenue:(Venue *)venue distance:(CGFloat)distance;

@end
