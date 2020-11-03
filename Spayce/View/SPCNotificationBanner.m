//
//  SPCNotificationBanner.m
//  Spayce
//
//  Created by Pavel Dusatko on 6/12/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCNotificationBanner.h"
#import "SAMLabel.h"

#define kNotificationViewHeight 60.0
#define kNotificationAnimationInSpeed 0.2
#define kNotificationAnimationOutSpeed 0.1

@interface SPCNotificationBanner ()

@property (nonatomic, strong) UIView *parentView;
@property (nonatomic, strong) UIView *referenceView;
@property (nonatomic, strong) UIView *segmentedControl;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *customText;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, weak) id target;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) SAMLabel *detailTextLabel;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation SPCNotificationBanner

#pragma mark - UIView - Initializing a View Object

- (instancetype)initWithParentView:(UIView *)parentView title:(NSString *)title error:(NSError *)error target:(id)target {
    self = [super init];
    if (self) {
        _parentView = parentView;
        _title = title;
        _error = error;
        _target = target;
        
        self.frame = CGRectMake(CGRectGetMinX(parentView.frame), 0.0 - kNotificationViewHeight, CGRectGetWidth(parentView.frame), kNotificationViewHeight);
        
        [self _initialize];
    }
    return self;
}

- (instancetype)initWithReferenceView:(UIView *)referenceView title:(NSString *)title error:(NSError *)error target:(id)target {
    self = [super init];
    if (self) {
        _referenceView = referenceView;
        _title = title;
        _error = error;
        _target = target;
        
        self.frame = CGRectMake(CGRectGetMinX(referenceView.frame), CGRectGetMaxY(referenceView.frame) - kNotificationViewHeight, CGRectGetWidth(referenceView.frame), kNotificationViewHeight);
        
        [self _initialize];
    }
    return self;
}

- (instancetype)initWithSegmentedControl:(UIView *)segmentedControl title:(NSString *)title error:(NSError *)error target:(id)target {
    self = [super init];
    if (self) {
        _segmentedControl = segmentedControl;
        _title = title;
        _error = error;
        _target = target;
        
        self.frame = CGRectMake(CGRectGetMinX(segmentedControl.frame), CGRectGetMaxY(segmentedControl.frame) - kNotificationViewHeight, CGRectGetWidth(segmentedControl.frame), kNotificationViewHeight);
        
        [self _initialize];
    }
    return self;
}


- (instancetype)initWithParentView:(UIView *)parentView title:(NSString *)title customText:(NSString *)customText target:(id)target {
    self = [super init];
    if (self) {
        _parentView = parentView;
        _title = title;
        _customText = customText;
        _target = target;
        
        self.frame = CGRectMake(CGRectGetMinX(parentView.frame), 0.0 - kNotificationViewHeight, CGRectGetWidth(parentView.frame), kNotificationViewHeight);
        
        [self _initialize];
    }
    return self;
}

#pragma mark - Private

- (void)_initialize {
    self.backgroundColor = [UIColor colorWithRed:0.078 green:0.094 blue:0.122 alpha:1.000];
    self.clipsToBounds = YES;
    
    _textLabel = [[UILabel alloc] init];
    _textLabel.textColor = [UIColor whiteColor];
    _textLabel.font = [UIFont spc_notificationBanner_titleFont];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.text = [self displayText];
    _textLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:_textLabel];
    
    _detailTextLabel = [[SAMLabel alloc] init];
    _detailTextLabel.font = [UIFont spc_notificationBanner_subtitleFont];
    _detailTextLabel.textColor = [UIColor whiteColor];
    _detailTextLabel.textAlignment = NSTextAlignmentCenter;
    _detailTextLabel.text = [self displayDetailText];
    _detailTextLabel.numberOfLines = 2;
    _detailTextLabel.verticalTextAlignment = SAMLabelVerticalTextAlignmentMiddle;
    [self addSubview:_detailTextLabel];
    
    _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"button-close-white"]];
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:_imageView];
    
    CGFloat detailTextHeight = [self detailTextHeight];
    CGFloat originY = (detailTextHeight > _detailTextLabel.font.lineHeight) ? CGRectGetMidY(self.bounds) - 7.0 : CGRectGetMidY(self.bounds);
    
    _imageView.frame = CGRectMake(CGRectGetWidth(self.bounds) - self.imageView.image.size.width - 10.0, CGRectGetMidY(self.bounds) - self.imageView.image.size.height / 2.0, self.imageView.image.size.width, self.imageView.image.size.height);
    _detailTextLabel.frame = CGRectMake(_imageView.image.size.width + 15.0, originY, CGRectGetWidth(self.bounds) - 2 * (self.imageView.image.size.width + 15), detailTextHeight + 5.0);
    _textLabel.frame = CGRectMake(CGRectGetMinX(_detailTextLabel.frame), CGRectGetMinY(_detailTextLabel.frame) - _textLabel.font.lineHeight, CGRectGetWidth(_detailTextLabel.frame), _textLabel.font.lineHeight);
    
    UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (NSString *)displayText {
    if (self.title) {
        return self.title;
    }
    return NSLocalizedString(@"Something's not quite right", nil);
}

- (NSString *)displayDetailText {
    NSError *error = self.error;
    if (error) {
        NSMutableString *detailText = [NSMutableString string];
        
        if (error.code > 0) {
            [detailText appendFormat:@"%@", @(error.code)];
        }
        if ([error.userInfo objectForKey:@"description"]) {
            if (detailText.length > 0) {
                [detailText appendFormat:@" - "];
            }
            [detailText appendFormat:@"%@", [error.userInfo objectForKey:@"description"]];
        }
        return detailText;
    }
    if (self.customText) {
        return self.customText;
    }
    return NSLocalizedString(@"No details available.\nPlease try again later!", nil);
}

- (CGFloat)detailTextHeight {
    CGSize constraint = CGSizeMake(CGRectGetWidth(self.bounds) - 2 * (self.imageView.image.size.width + 15.0), self.detailTextLabel.font.lineHeight * 2.0);
    NSDictionary *attributes = @{ NSFontAttributeName: self.detailTextLabel.font };
    
    CGRect frame = [self.detailTextLabel.text boundingRectWithSize:constraint
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:attributes
                                                           context:NULL];
    return MIN(frame.size.height, constraint.height);
}

- (void)showInParentView {
    // Add to view hierarchy
    [self.parentView addSubview:self];
    
    // Show animated
    [UIView animateWithDuration:kNotificationAnimationInSpeed animations:^{
        CGRect frame = self.frame;
        frame.origin.y += CGRectGetHeight(frame);
        self.frame = frame;
    }];
}

- (void)showInReferenceView {
    UIView *superview = self.referenceView.superview;
    
    [superview insertSubview:self belowSubview:self.referenceView];
    
    [UIView animateWithDuration:kNotificationAnimationInSpeed animations:^{
        CGRect frame = self.frame;
        frame.origin.y += CGRectGetHeight(frame);
        self.frame = frame;
    }];
}

- (void)showInSegmentedControl {
    UIView *superview = self.segmentedControl.superview;
    [superview insertSubview:self atIndex:0];
    
    [UIView animateWithDuration:kNotificationAnimationInSpeed animations:^{
        CGRect superviewFrame = superview.frame;
        superviewFrame.size.height += kNotificationViewHeight - CGRectGetHeight(superviewFrame);
        superview.frame = superviewFrame;
        superview.tag = 1;
        
        CGRect frame = self.frame;
        frame.origin.y += CGRectGetHeight(frame);
        self.frame = frame;
    }];
}

#pragma mark - Actions

- (void)show {
    if (self.parentView) {
        [self showInParentView];
    }
    else if (self.referenceView) {
        [self showInReferenceView];
    }
    else if (self.segmentedControl) {
        [self showInSegmentedControl];
    }
}

- (void)hide {
    [self hideWithCompletionHandler:nil];
}

- (void)hideWithCompletionHandler:(void (^)())completionHandler {
    [UIView animateWithDuration:kNotificationAnimationOutSpeed animations:^{
        if (self.segmentedControl) {
            UIView *superview = self.segmentedControl.superview;
            CGRect superviewFrame = superview.frame;
            superviewFrame.size.height -= kNotificationViewHeight;
            superview.frame = superviewFrame;
            superview.tag = 0;
        }
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:kNotificationAnimationOutSpeed animations:^{
                CGRect frame = self.frame;
                frame.origin.y -= CGRectGetHeight(frame);
                self.frame = frame;
            } completion:^(BOOL finished) {
                [self removeFromSuperview];
                
                if (completionHandler) {
                    completionHandler();
                }
            }];
        }
    }];
}

#pragma mark - Gesture recognizers

- (void)tapGestureRecognized:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.target respondsToSelector:@selector(spc_hideNotificationBanner:)]) {
            [self.target performSelector:@selector(spc_hideNotificationBanner:) withObject:self];
        }
    }
}

@end
