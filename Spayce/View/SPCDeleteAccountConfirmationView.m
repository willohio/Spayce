//
//  SPCDeleteAccountConfirmationView.m
//  Spayce
//
//  Created by Arria P. Owlia on 2/21/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCDeleteAccountConfirmationView.h"

@interface SPCDeleteAccountConfirmationView()

// UI
@property (strong, nonatomic) UIView *viewContent;

@property (strong, nonatomic) UIImageView *ivSpayceMan;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblMessage;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation SPCDeleteAccountConfirmationView

static const CGFloat ANIMATION_DURATION = 0.3f;

#pragma mark - Lifecycle

- (void)dealloc {
    [self hideAnimated:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    // Background
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    
    // Content view
    _viewContent = [[UIView alloc] init];
    _viewContent.backgroundColor = [UIColor whiteColor];
    _viewContent.layer.cornerRadius = 6.0f;
    _viewContent.layer.masksToBounds = YES;
    [self addSubview:_viewContent];
    
    // Spayce Man image
    _ivSpayceMan = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spayce-man-sad"]];
    _ivSpayceMan.contentMode = UIViewContentModeScaleAspectFit;
    [self.viewContent addSubview:_ivSpayceMan];
    
    // Title label
    _lblTitle = [[UILabel alloc] init];
    _lblTitle.text = @"ARE YOU SURE?";
    _lblTitle.numberOfLines = 1;
    _lblTitle.textAlignment = NSTextAlignmentCenter;
    _lblTitle.textColor = [UIColor colorWithRGBHex:0x4cb0fb];
    [self.viewContent addSubview:_lblTitle];
    
    // Message label
    _lblMessage = [[UILabel alloc] init];
    _lblMessage.text = @"We'll be sad to see you go!";
    _lblMessage.numberOfLines = 1;
    _lblMessage.textAlignment = NSTextAlignmentCenter;
    _lblMessage.textColor = [UIColor colorWithRGBHex:0x979797];
    [self.viewContent addSubview:_lblMessage];
    
    // Delete button
    _btnDelete = [[UIButton alloc] init];
    [_btnDelete setTitle:@"Delete" forState:UIControlStateNormal];
    [_btnDelete setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_btnDelete.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:14.0f]];
    [_btnDelete setBackgroundColor:[UIColor colorWithRGBHex:0xd4d4d4]];
    [_btnDelete.layer setCornerRadius:3.0f];
    [self.viewContent addSubview:_btnDelete];
    
    // Cancel button
    _btnCancel = [[UIButton alloc] init];
    [_btnCancel setTitle:@"Cancel" forState:UIControlStateNormal];
    [_btnCancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_btnCancel.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:14.0f]];
    [_btnCancel setBackgroundColor:[UIColor colorWithRGBHex:0x4cb0fb]];
    [_btnCancel.layer setCornerRadius:3.0f];
    [self.viewContent addSubview:_btnCancel];
    
    // Activity Indicator
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.color = [UIColor grayColor];
    _activityIndicator.hidden = YES;
    [self.viewContent addSubview:_activityIndicator];
}

#pragma mark - Layout
- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Content view
    const CGFloat PSD_WIDTH = 560.0f;
    const CGFloat PSD_HEIGHT = 600.0f;
    self.frame = [UIScreen mainScreen].bounds;
    
    // Let's stretch the view to fit the width of the screen minus 20pt on each side
    CGFloat viewWidthAfterPadding = CGRectGetWidth(self.frame) - 40.0f;
    CGFloat stretchScale = viewWidthAfterPadding / PSD_WIDTH;
    CGFloat viewHeightAfterScale = stretchScale * PSD_HEIGHT;
    
    self.viewContent.frame = CGRectMake(0, 0, viewWidthAfterPadding, viewHeightAfterScale);
    self.viewContent.center = self.center;
    CGFloat centerOffsetForSubviews = (CGRectGetWidth(self.frame) - CGRectGetWidth(self.viewContent.frame)) / 2.0f;
    
    CGFloat viewWidth = CGRectGetWidth(self.viewContent.frame);
    CGFloat viewHeight = CGRectGetHeight(self.viewContent.frame);
    
    // Spayce Man image
    self.ivSpayceMan.frame = CGRectMake(0, 0, 271.0f/PSD_WIDTH * viewWidth, 215.0f/PSD_HEIGHT * viewHeight);
    self.ivSpayceMan.center = CGPointMake(self.viewContent.center.x - centerOffsetForSubviews, 166.5f/PSD_HEIGHT * viewHeight);
    
    // Title label
    self.lblTitle.font = [UIFont fontWithName:@"OpenSans-Bold" size:32.0f/PSD_WIDTH * viewWidth];
    [self.lblTitle sizeToFit];
    self.lblTitle.center = CGPointMake(self.viewContent.center.x - centerOffsetForSubviews, 334.0f/PSD_HEIGHT * viewHeight);
    
    // Message label
    self.lblMessage.font = [UIFont fontWithName:@"OpenSans" size:26.0f/PSD_WIDTH * viewWidth];
    [self.lblMessage sizeToFit];
    self.lblMessage.center = CGPointMake(self.viewContent.center.x - centerOffsetForSubviews, 384.0f/PSD_HEIGHT * viewHeight);
    
    // Delete button
    self.btnDelete.frame = CGRectMake(0, 0, 200.0f/PSD_WIDTH * viewWidth, 80.0f/PSD_HEIGHT * viewHeight);
    self.btnDelete.center = CGPointMake(self.center.x - 10.0f - CGRectGetWidth(self.btnDelete.frame)/2.0f - centerOffsetForSubviews, 496.0f/PSD_HEIGHT * viewHeight);
    
    // Cancel button
    self.btnCancel.frame = CGRectMake(0, 0, 200.0f/PSD_WIDTH * viewWidth, 80.0f/PSD_HEIGHT * viewHeight);
    self.btnCancel.center = CGPointMake(self.center.x + 10.0f + CGRectGetWidth(self.btnCancel.frame)/2.0f - centerOffsetForSubviews, 496.0f/PSD_HEIGHT * viewHeight);
    
    // Activity Indicator
    self.activityIndicator.frame = self.btnDelete.frame;
}

#pragma mark - Actions

- (void)showAnimated:(BOOL)animated {
    UIView *view = [[UIApplication sharedApplication] keyWindow];
    
    [self showInView:view animated:animated];
}

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    [self showActivityIndicatorOnDelete:NO];
    
    if (nil == view) {
        view = [[UIApplication sharedApplication] keyWindow];
    }
    
    self.alpha = 0.0f;
    [view addSubview:self];
    
    if (animated) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.alpha = 1.0f;
        }];
    } else {
        self.alpha = 1.0f;
    }
}

- (void)showActivityIndicatorOnDelete:(BOOL)show {
    if (show) {
        [self.activityIndicator startAnimating];
        [self.activityIndicator setHidden:NO];
        [self.btnDelete setHidden:YES];
    } else {
        [self.activityIndicator setHidden:YES];
        [self.activityIndicator stopAnimating];
        [self.btnDelete setHidden:NO];
    }
}

- (void)hideAnimated:(BOOL)animated {
    [self showActivityIndicatorOnDelete:NO];
    
    self.alpha = 1.0f;
    
    if (animated) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.alpha = 0.0f;
        } completion:^(BOOL finished) {
            if (finished) {
                //                [self removeFromSuperview];
            }
            [self removeFromSuperview]; // Remove from the superview regardless
        }];
    } else {
        [self removeFromSuperview];
    }
}

@end
