//
//  UIScrollView+SPCParallax.h
//  Spayce
//
//  Created by Pavel Dusatko on 8/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCParallaxView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIView *layerOverlayView;

@property (nonatomic, assign) BOOL flushWithBottomView;

- (id)initWithFrame:(CGRect)frame contentView:(UIView*)contentView bottomView:(UIView *)bottomView;

@end

@interface UIScrollView (SPCParallax)

@property (nonatomic, weak) SPCParallaxView *parallaxView;

- (void)addParallaxViewWithImage:(UIImage *)image;
- (void)updateOverlay;
- (void)addParallaxViewWithImage:(UIImage *)image contentView:(UIView *)contentView bottomView:(UIView *)bottomView;
- (void)addParallaxViewWithImage:(UIImage *)image overlayColor:(UIColor *)overlayColor contentView:(UIView *)contentView bottomView:(UIView *)bottomView flushWithBottom:(BOOL)flushWithBottom;
- (void)updateParallaxViewWithImage:(UIImage *)image;
- (void)updateParallaxViewWithImage:(UIImage *)image overlayColor:(UIColor *)overlayColor;
- (void)addParallaxViewWithImageUrl:(NSURL *)imageUrl contentView:(UIView *)contentView bottomView:(UIView *)bottomView;
- (void)addParallaxViewWithImageUrl:(NSURL *)imageUrl overlayColor:(UIColor *)overlayColor contentView:(UIView *)contentView bottomView:(UIView *)bottomView flushWithBottom:(BOOL)flushWithBottom;
- (void)updateParallaxViewWithImageUrl:(NSURL *)imageUrl;
- (void)updateParallaxViewWithImageUrl:(NSURL *)imageUrl overlayColor:(UIColor *)overlayColor;
- (void)updateParallaxViewWithOverlayLayer:(CALayer *)overlayLayer;
- (void)removeParallaxView;;

@end
