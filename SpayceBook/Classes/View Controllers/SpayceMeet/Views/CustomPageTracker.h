//
//  CustomPageTracker.h
//  Spayce
//
//  Created by Christopher Taylor on 11/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomPageTracker : UIView

@property (nonatomic,strong) UIView *pillView;
@property (nonatomic, strong) UIColor *trackerColor;
@property (nonatomic, strong) UIColor *highlightColor;

-(void)totalPics:(int)totalPics currPic:(int)currPic;
-(void)highlightPic:(int)currPic;
- (void)configureWithTotal:(int)totalAssets curr:(int)currAsset;
- (void)totalAssets:(int)totalAssets currAsset:(int)currAsset;
-(void)adjustForAudioTracker;
@end
