//
//  SPCPickLocationCell.h
//  Spayce
//
//  Created by Christopher Taylor on 1/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCLocationCell.h"
#import "SPCCity.h"

@interface SPCPickLocationCell : SPCLocationCell

- (void)configureCellWithVenue:(Venue *)venue distance:(CGFloat)distance;


@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) SPCCity *territory;

-(void)activateSpinner;

-(void)configureCellWithTerritory:(SPCCity *)territory;
@end
