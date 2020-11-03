//
//  SPCFeaturedContentCell.h
//  Spayce
//
//  Created by Jake Rosin on 8/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCFeaturedContent;

@protocol SPCFeaturedContentCellDelegate <NSObject>
- (void)imageLoadComplete;
@end

@interface SPCFeaturedContentCell : UICollectionViewCell

@property (nonatomic, weak) NSObject <SPCFeaturedContentCellDelegate> *delegate;

-(void)configureWithFeaturedContent:(SPCFeaturedContent *)featuredContent;
-(void)displayAndAnimateArrow;
-(void)hideBouncingArrow;
-(void)fallbackImageLoad;
- (void)updatOffsetAdjustment:(float)offsetAdj;
-(void)forceFeature;
@end
