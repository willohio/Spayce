//
//  SPCAccountImageCell.h
//  Spayce
//
//  Created by William Santiago on 2014-11-06.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCInitialsImageView;

@interface SPCAccountImageCell : UITableViewCell

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *customTextLabel;

@end
