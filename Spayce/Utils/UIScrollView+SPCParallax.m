//
//  UIScrollView+SPCParallax.m
//  Spayce
//
//  Created by William Santiago on 8/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UIScrollView+SPCParallax.h"
#import "UIImageView+WebCache.h"

// Objective-C
#import <objc/runtime.h>

@interface SPCParallaxView ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) CALayer *layerOverlayLayer;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat bottomFlushSpacing;
@property (nonatomic, assign) BOOL bottomFlushSpacingSet;

@end

@implementation SPCParallaxView

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame contentView:nil bottomView:nil];
}

- (id)initWithFrame:(CGRect)frame contentView:(UIView *)contentView bottomView:(UIView *)bottomView {
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self addSubview:_imageView];
        
        _overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentView.frame.size.width, contentView.frame.size.width)];
        [self addSubview:_overlayView];
        
        
        _contentView = contentView;
        _bottomView = bottomView;
        _height = CGRectGetHeight(contentView.frame);
        _bottomFlushSpacingSet = NO;
    }
    return self;
}

#pragma mark - Private

- (void)setScrollView:(UIScrollView *)scrollView {
    [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
    _scrollView = scrollView;
    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeFromSuperview {
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.contentView removeFromSuperview];
    
    [super removeFromSuperview];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!_bottomFlushSpacingSet) {
        _bottomFlushSpacing = self.height - CGRectGetMinY(_bottomView.frame);
        _bottomFlushSpacingSet = YES;
    }
    
    if (self.scrollView.contentOffset.y <= -self.scrollView.contentInset.top) {
        CGFloat inset = self.scrollView.contentInset.top;
        CGFloat offset = -self.scrollView.contentOffset.y;
        
        CGRect frame = self.frame;
        frame.origin.y = -offset;
        frame.size.height = self.height + offset - inset;
        self.frame = frame;
        
        self.contentView.frame = frame;
        
        frame.origin.x -= offset - inset;
        frame.origin.y = 0;
        frame.size.width += (offset - inset) * 2.0;
        if (self.flushWithBottomView) {
            frame.size.height -= self.bottomFlushSpacing;
        } else {
            frame.size.height -= CGRectGetHeight(self.bottomView.frame);
        }
        self.imageView.frame = frame;
        
        self.overlayView.frame = frame;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setNeedsLayout];
}

@end

static char UIScrollViewParallax;

@implementation UIScrollView (SPCParallax)

- (void)setParallaxView:(SPCParallaxView *)parallaxView {
    [self willChangeValueForKey:NSStringFromSelector(@selector(parallaxView))];
    objc_setAssociatedObject(self, &UIScrollViewParallax, parallaxView, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:NSStringFromSelector(@selector(parallaxView))];
}

- (SPCParallaxView *)parallaxView {
    return objc_getAssociatedObject(self, &UIScrollViewParallax);
}

- (void)addParallaxViewWithImage:(UIImage *)image {
    [self addParallaxViewWithImage:image contentView:nil bottomView:nil];
}

- (void)addParallaxViewWithImage:(UIImage *)image contentView:(UIView *)contentView bottomView:(UIView *)bottomView {
    [self addParallaxViewWithImage:image overlayColor:[UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:110.0f/255.0f alpha:.5f] contentView:contentView bottomView:bottomView flushWithBottom:NO];
}


- (void)addParallaxViewWithImage:(UIImage *)image overlayColor:(UIColor *)overlayColor contentView:(UIView *)contentView bottomView:(UIView *)bottomView flushWithBottom:(BOOL)flushWithBottom {
    SPCParallaxView *view = [[SPCParallaxView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(contentView.frame), CGRectGetHeight(contentView.frame)) contentView:contentView bottomView:bottomView];
    view.backgroundColor = [UIColor clearColor];
    view.imageView.image = image;
    view.scrollView = self;
    view.flushWithBottomView = flushWithBottom;
    view.overlayView.backgroundColor = overlayColor;
    [self addSubview:view];
    
    if (contentView) {
        [self addSubview:contentView];
    }
    
    self.parallaxView = view;
}

- (void)addParallaxViewWithImage:(UIImage *)image placeholderColor:(UIColor *)placeholderColor overlayColor:(UIColor *)overlayColor contentView:(UIView *)contentView bottomView:(UIView *)bottomView flushWithBottom:(BOOL)flushWithBottom {
    
}

- (void)addParallaxViewWithImageUrl:(NSURL *)imageUrl {
    [self addParallaxViewWithImageUrl:imageUrl contentView:nil bottomView:nil];
}

- (void)addParallaxViewWithImageUrl:(NSURL *)imageUrl contentView:(UIView *)contentView bottomView:(UIView *)bottomView {
    [self addParallaxViewWithImageUrl:imageUrl overlayColor:[UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:110.0f/255.0f alpha:.5f] contentView:contentView bottomView:bottomView flushWithBottom:NO];
}

- (void)addParallaxViewWithImageUrl:(NSURL *)imageUrl overlayColor:(UIColor *)overlayColor contentView:(UIView *)contentView bottomView:(UIView *)bottomView flushWithBottom:(BOOL)flushWithBottom {
    SPCParallaxView *view = [[SPCParallaxView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(contentView.frame), CGRectGetHeight(contentView.frame)) contentView:contentView bottomView:bottomView];
    view.backgroundColor = [UIColor clearColor];
    [view.imageView sd_setImageWithURL:imageUrl
                      placeholderImage:[UIImage imageNamed:@"placeholder-stars"]
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 //[self.tableView updateParallaxViewWithImage:image];
                             }];
    view.scrollView = self;
    view.flushWithBottomView = flushWithBottom;
    view.overlayView.backgroundColor = overlayColor;
    [self addSubview:view];
    
    if (contentView) {
        [self addSubview:contentView];
    }
    
    self.parallaxView = view;
}



- (void)updateParallaxViewWithImage:(UIImage *)image {
    self.parallaxView.imageView.image = image;
    [self.parallaxView.imageView setNeedsUpdateConstraints];
}

- (void)updateParallaxViewWithImageUrl:(NSURL *)url {
    [self.parallaxView.imageView sd_setImageWithURL:url
                 placeholderImage:[UIImage imageNamed:@"fuzzy-banner"]
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                            
                            if (error) {
                                //NSLog(@"error %@",error);
                            }
                            if (image) {
                                //NSLog(@"got image!");
                                self.parallaxView.imageView.image = image;
                            }
                        }];
}

- (void)updateParallaxViewWithImage:(UIImage *)image overlayColor:(UIColor *)overlayColor {
    self.parallaxView.imageView.image = image;
    self.parallaxView.overlayView.backgroundColor = overlayColor;
    [self.parallaxView.imageView setNeedsUpdateConstraints];
}

- (void)updateParallaxViewWithImageUrl:(NSURL *)url overlayColor:(UIColor *)overlayColor {
    [self.parallaxView.imageView sd_setImageWithURL:url
                                   placeholderImage:[UIImage imageNamed:@"fuzzy-banner"]
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                              
                                              if (error) {
                                                  //NSLog(@"error %@",error);
                                              }
                                              if (image) {
                                                  //NSLog(@"got image!");
                                                  self.parallaxView.imageView.image = image;
                                                  self.parallaxView.overlayView.backgroundColor = overlayColor;
                                              }
                                          }];
}


- (void)updateParallaxViewWithOverlayLayer:(CALayer *)overlayLayer {
    if (self.parallaxView.layerOverlayView) {
        [self.parallaxView.layerOverlayView removeFromSuperview];
        self.parallaxView.layerOverlayView = nil;
        self.parallaxView.layerOverlayLayer = nil;
    }
    
    if (overlayLayer) {
        self.parallaxView.layerOverlayView = [[UIView alloc] initWithFrame:overlayLayer.frame];
        [self.parallaxView addSubview:self.parallaxView.layerOverlayView];
        [self.parallaxView.layerOverlayView.layer insertSublayer:overlayLayer atIndex:0];
        self.parallaxView.layerOverlayLayer = overlayLayer;
    }
}

- (void)removeParallaxView {
    [self.parallaxView removeFromSuperview];
    self.parallaxView = nil;
}

- (void)updateOverlay {
    self.parallaxView.overlayView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.15];
}

@end
