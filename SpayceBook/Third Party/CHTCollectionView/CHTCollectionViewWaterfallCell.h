//
//  UICollectionViewWaterfallCell.h
//  Demo
//
//  Created by Nelson on 12/11/27.
//  Copyright (c) 2012年 Nelson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCMemoryAsset.h"

@interface CHTCollectionViewWaterfallCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *vidBtn;
@property (nonatomic, copy) NSString *displayString;
@property (nonatomic, strong) IBOutlet UILabel *displayLabel;
@property (nonatomic, assign) BOOL cacheInProgress;

-(void)configureWithAsset:(SPCMemoryAsset *)asset;
@end
