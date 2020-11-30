//
//  SPCSettingsAccountCell.h
//  Spayce
//
//  Created by William Santiago on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCGroupedCell.h"

@class SPCInitialsImageView;

@interface SPCSettingsAccountCell : SPCGroupedCell

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UILabel *customDetailTextLabel;

@end
