//
//  SPCVenueDetailsCollectionViewCell.h
//  Spayce
//
//  Created by Christopher Taylor on 11/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCFeaturedContent.h"

@interface SPCVenueDetailsCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *venueImageView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UILabel *distanceLabel;
@property (nonatomic, strong) UIImageView *distanceImageView;
@property (nonatomic, strong) UILabel * memoryCountLabel;
@property (nonatomic, strong) UILabel * starCountLabel;
@property (nonatomic, strong) UIImageView * memoryImageView;
@property (nonatomic, strong) UIImageView * starImageView;
@property (nonatomic, strong) UILabel *venueLabel;
@property (nonatomic, strong) UIButton *venueActionButton;
@property (nonatomic, strong) UIButton *refreshLocationButton;


-(void)configureWithFeaturedContent:(SPCFeaturedContent *)featuredContent;
- (void)updateOffsetAdjustment:(float)offsetAdj;

@end
