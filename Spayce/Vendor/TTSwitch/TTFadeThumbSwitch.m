//
//  TTFadeThumbSwitch.m
//  Spayce
//
//  Created by Jake Rosin on 8/11/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "TTFadeThumbSwitch.h"
#import "TTSwitchSubclass.h"

@interface TTFadeThumbSwitch ()

@property (nonatomic, strong) UIImageView *thumbImageOffView;

@end

@implementation TTFadeThumbSwitch

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self fadeSwitchCommonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self fadeSwitchCommonInit];
    }
    return self;
}

- (void)fadeSwitchCommonInit
{
    _thumbImageOffView = [[UIImageView alloc] init];
    
    // insert above self.thumbImageView because we fade out the alpha of it
    [self.maskedThumbView insertSubview:_thumbImageOffView aboveSubview:self.thumbImageView];
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    _thumbImageOffView.frame = self.thumbImageView.frame;
}

#pragma mark - Public Interface

- (void)setThumbImageOff:(UIImage *)thumbImageOff
{
    if (_thumbImageOff != thumbImageOff) {
        _thumbImageOff = thumbImageOff;
        [_thumbImageOffView setImage:_thumbImageOff];
        [_thumbImageOffView setFrame:(CGRect){ { 0.0f, self.thumbOffsetY }, _thumbImageOff.size }];
    }
}

#pragma mark - TTSwitch

- (void)moveThumbCenterToX:(CGFloat)newThumbCenterX
{
    [super moveThumbCenterToX:newThumbCenterX];
    [self.thumbImageOffView setCenter:(CGPoint){ newThumbCenterX, self.thumbImageOffView.center.y }];
    [self.thumbImageOffView setAlpha:(self.on ? 0.0f : 1.0f)];
}


#pragma mark - UIGestureRecognizer

- (void)handleThumbPanGesture:(UIPanGestureRecognizer *)gesture
{
    [super handleThumbPanGesture:gesture];
    
    if ([gesture state] == UIGestureRecognizerStateBegan || [gesture state] == UIGestureRecognizerStateChanged) {
        CGFloat minBoundary = self.thumbInsetX + (self.thumbImageOffView.bounds.size.width / 2.0f);
        CGFloat maxBoundary = self.bounds.size.width - (self.thumbImageOffView.bounds.size.width / 2.0f) - self.thumbInsetX;
        self.thumbImageOffView.alpha = (1.0f - ((self.thumbImageOffView.center.x - minBoundary)/(maxBoundary - minBoundary)));
        self.thumbImageOffView.frame = self.thumbImageView.frame;
    }
}

@end
