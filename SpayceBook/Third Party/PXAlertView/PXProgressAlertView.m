//
//  PXProgressAlertView.m
//  PXProgressAlertViewDemo
//
//  Created by Alex Jarvis on 25/09/2013.
//  Copyright (c) 2013 Panaxiom Ltd. All rights reserved.
//

#import "PXProgressAlertView.h"
#import "PXProgressView.h"

@interface PXProgressAlertViewQueue : NSObject

@property (nonatomic) NSMutableArray *alertViews;

+ (PXProgressAlertViewQueue *)sharedInstance;

- (void)add:(PXProgressAlertView *)alertView;
- (void)remove:(PXProgressAlertView *)alertView;

@end

static const CGFloat AlertViewWidth = 270.0;
static const CGFloat AlertViewContentMargin = 9;
static const CGFloat AlertViewVerticalElementSpace = 10;
static const CGFloat AlertViewButtonHeight = 44;

@interface PXProgressAlertView ()

@property (nonatomic) UIWindow *mainWindow;
@property (nonatomic) UIWindow *alertWindow;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *contentView;
@property (nonatomic) PXProgressView *progressView;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UIButton *cancelButton;
@property (nonatomic) UIButton *otherButton;
@property (nonatomic) UITapGestureRecognizer *tap;
@property (nonatomic, strong) void (^completion)(BOOL cancelled);

@end

@implementation PXProgressAlertView

- (UIWindow *)windowWithLevel:(UIWindowLevel)windowLevel
{
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (window.windowLevel == windowLevel) {
            return window;
        }
    }
    return nil;
}

- (id)initAlertWithTitle:(NSString *)title
                 message:(NSString *)message
             cancelTitle:(NSString *)cancelTitle
              otherTitle:(NSString *)otherTitle
             contentView:(UIView *)contentView
                   ticks:(NSInteger)ticks
                progress:(NSInteger)progress
              completion:(void(^) (BOOL cancelled))completion
{
    self = [super init];
    if (self) {
        _mainWindow = [self windowWithLevel:UIWindowLevelNormal];
        _alertWindow = [self windowWithLevel:UIWindowLevelAlert];
        if (!_alertWindow) {
            _alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            _alertWindow.windowLevel = UIWindowLevelAlert;
        }
        self.frame = _alertWindow.bounds;
        
        _backgroundView = [[UIView alloc] initWithFrame:_alertWindow.bounds];
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _backgroundView.alpha = 1;
        [self addSubview:_backgroundView];
        
        _alertView = [[UIView alloc] init];
        _alertView.backgroundColor = [UIColor whiteColor];
        _alertView.layer.cornerRadius = 4.0;
        _alertView.layer.opacity = 1.0;
        _alertView.clipsToBounds = YES;
        [self addSubview:_alertView];
        
        // Title
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(AlertViewContentMargin,
                                                                AlertViewVerticalElementSpace,
                                                                AlertViewWidth - AlertViewContentMargin*2,
                                                                44)];
        _titleLabel.text = title;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor colorWithRed:72.0/255.0 green:85.0/255.0 blue:102.0/255.0 alpha:1.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.frame = [self adjustLabelFrameHeight:self.titleLabel];
        [_alertView addSubview:_titleLabel];
        
        CGFloat messageLabelY = _titleLabel.frame.origin.y + _titleLabel.frame.size.height + AlertViewVerticalElementSpace;
        
        // Optional Content View
        if (contentView) {
            _contentView = contentView;
            _contentView.frame = CGRectMake(0,
                                            messageLabelY,
                                            _contentView.frame.size.width,
                                            _contentView.frame.size.height);
            _contentView.center = CGPointMake(AlertViewWidth/2, _contentView.center.y);
            [_alertView addSubview:_contentView];
            messageLabelY += contentView.frame.size.height + AlertViewVerticalElementSpace;
        }
        
        // Message
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(AlertViewContentMargin,
                                                                  messageLabelY,
                                                                  AlertViewWidth - AlertViewContentMargin*2,
                                                                  44)];
        _messageLabel.text = message;
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.textColor = [UIColor colorWithRed:103.0/255.0 green:120.0/255.0 blue:140.0/255.0 alpha:1.0];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.font = [UIFont systemFontOfSize:15];
        _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _messageLabel.numberOfLines = 0;
        _messageLabel.frame = [self adjustLabelFrameHeight:self.messageLabel];
        [_alertView addSubview:_messageLabel];
        
        // Line
        CALayer *lineLayer = [CALayer layer];
        lineLayer.backgroundColor = [[UIColor colorWithWhite:0.90 alpha:0.3] CGColor];
        lineLayer.frame = CGRectMake(0, _messageLabel.frame.origin.y + _messageLabel.frame.size.height + AlertViewVerticalElementSpace, AlertViewWidth, 0.5);
        [_alertView.layer addSublayer:lineLayer];
        
        // Buttons
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (cancelTitle) {
            [_cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
        } else {
            [_cancelButton setTitle:NSLocalizedString(@"Ok", nil) forState:UIControlStateNormal];
        }
        _cancelButton.backgroundColor = [UIColor colorWithRed:103.0/255.0 green:120.0/255.0 blue:140.0/255.0 alpha:1.0];
        
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor colorWithWhite:0.25 alpha:1] forState:UIControlStateHighlighted];
        [_cancelButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton addTarget:self action:@selector(setBackgroundColorForButton:) forControlEvents:UIControlEventTouchDown];
        [_cancelButton addTarget:self action:@selector(clearBackgroundColorForButton:) forControlEvents:UIControlEventTouchDragExit];

        CGFloat buttonsY = lineLayer.frame.origin.y + lineLayer.frame.size.height;
        
        _progressView = [[PXProgressView alloc] init];
        _progressView.backgroundColor = [UIColor colorWithRed:28.0/255.0 green:26.0/255.0 blue:33.0/255.0 alpha:1.0];
        _progressView.ticks = ticks;
        _progressView.progressTicks = progress;
        _progressView.frame = CGRectMake(0, buttonsY, AlertViewWidth/3*2, AlertViewButtonHeight);
        [_alertView addSubview:_progressView];
        
        if (otherTitle) {
            _cancelButton.titleLabel.font = [UIFont systemFontOfSize:17];
            _cancelButton.frame = CGRectMake(0, buttonsY, AlertViewWidth/2, AlertViewButtonHeight);
            
            _otherButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_otherButton setTitle:otherTitle forState:UIControlStateNormal];
            _otherButton.backgroundColor = [UIColor clearColor];
            _otherButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
            [_otherButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_otherButton setTitleColor:[UIColor colorWithWhite:0.25 alpha:1] forState:UIControlStateHighlighted];
            [_otherButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
            [_otherButton addTarget:self action:@selector(setBackgroundColorForButton:) forControlEvents:UIControlEventTouchDown];
            [_otherButton addTarget:self action:@selector(clearBackgroundColorForButton:) forControlEvents:UIControlEventTouchDragExit];
            _otherButton.frame = CGRectMake(_cancelButton.frame.size.width, buttonsY, AlertViewWidth/2, 44);
            [self.alertView addSubview:_otherButton];
            
            CALayer *lineLayer = [CALayer layer];
            lineLayer.backgroundColor = [[UIColor colorWithWhite:0.90 alpha:0.3] CGColor];
            lineLayer.frame = CGRectMake(_otherButton.frame.origin.x, _otherButton.frame.origin.y, 0.5, AlertViewButtonHeight);
            [_alertView.layer addSublayer:lineLayer];
            
        } else {
            _cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
            _cancelButton.frame = CGRectMake(AlertViewWidth-AlertViewWidth/3, buttonsY, AlertViewWidth/3, AlertViewButtonHeight);
        }
        
        [_alertView addSubview:_cancelButton];
        
        _alertView.bounds = CGRectMake(0, 0, AlertViewWidth, 150);
        
        if (completion) {
            _completion = completion;
        }
        
        [self setupGestures];
        [self resizeViews];
        
        float adjX=80;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenHeight = screenRect.size.height;
        if (screenHeight<500){
            adjX=40;
        }
        if (screenHeight>600){
            NSLog(@"ipad alert placement adjustment");
            adjX=300;
        }
        
        //hack to reposition on tour steps 10 & 11
        if ([title isEqualToString:@"Make A Memory"]) {
            adjX = adjX + 70;
        }
        if ([title isEqualToString:@"Viewing Memories"]){
            adjX = -30;
        }
        
        
        _alertView.center = CGPointMake(CGRectGetMidX(_alertWindow.bounds), CGRectGetMidY(_alertWindow.bounds)-adjX);
    }
    return self;
}

- (void)show
{
    [[PXProgressAlertViewQueue sharedInstance] add:self];
}

- (void)_show
{
    [self.alertWindow addSubview:self];
    [self.alertWindow makeKeyAndVisible];
    self.visible = YES;
    [self showBackgroundView];
    [self showAlertAnimation];
}

- (void)showBackgroundView
{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        self.mainWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        [self.mainWindow tintColorDidChange];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundView.alpha = 1;
    }];
}

- (void)hide
{
    [self removeFromSuperview];
}

- (void)dismiss:(id)sender
{
    self.visible = NO;
    
    if ([[[PXProgressAlertViewQueue sharedInstance] alertViews] count] == 1) {
        [self dismissAlertAnimation];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            self.mainWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [self.mainWindow tintColorDidChange];
        }
        [UIView animateWithDuration:0.2 animations:^{
            self.backgroundView.alpha = 0;
            [self.mainWindow makeKeyAndVisible];
        }];
    }
    
    
    
    [UIView animateWithDuration:0.2 animations:^{
        self.alertView.alpha = 0;
    } completion:^(BOOL finished) {
        [[PXProgressAlertViewQueue sharedInstance] remove:self];
        [self removeFromSuperview];
    }];
    
    BOOL cancelled;
    if (sender == self.cancelButton || sender == self.tap) {
        cancelled = YES;
    } else {
        cancelled = NO;
    }
    if (self.completion) {
        self.completion(cancelled);
    }
}

- (void)setBackgroundColorForButton:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:94/255.0 green:196/255.0 blue:221/255.0 alpha:1.0]];
}

- (void)clearBackgroundColorForButton:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:103.0/255.0 green:120.0/255.0 blue:140.0/255.0 alpha:1.0]];
}

#pragma mark - public

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
{
    return [PXProgressAlertView showAlertWithTitle:title message:nil cancelTitle:NSLocalizedString(@"Ok", nil) ticks:ticks progress:progress completion:nil];
}

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
{
    return [PXProgressAlertView showAlertWithTitle:title message:message cancelTitle:NSLocalizedString(@"Ok", nil) ticks:ticks progress:progress completion:nil];
}

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
                                 completion:(void(^) (BOOL cancelled))completion
{
    return [PXProgressAlertView showAlertWithTitle:title message:message cancelTitle:NSLocalizedString(@"Ok", nil) ticks:ticks progress:progress completion:completion];
}

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                cancelTitle:(NSString *)cancelTitle
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
                                 completion:(void(^) (BOOL cancelled))completion
{
    PXProgressAlertView *alertView = [[PXProgressAlertView alloc] initAlertWithTitle:title
                                                                             message:message
                                                                         cancelTitle:cancelTitle
                                                                          otherTitle:nil
                                                                         contentView:nil
                                                                               ticks:ticks
                                                                            progress:progress
                                                                          completion:completion];
    [alertView show];
    return alertView;
}

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                cancelTitle:(NSString *)cancelTitle
                                 otherTitle:(NSString *)otherTitle
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
                                 completion:(void(^) (BOOL cancelled))completion
{
    PXProgressAlertView *alertView = [[PXProgressAlertView alloc] initAlertWithTitle:title
                                                                             message:message
                                                                         cancelTitle:cancelTitle
                                                                          otherTitle:otherTitle
                                                                         contentView:nil
                                                                               ticks:ticks
                                                                            progress:progress
                                                                          completion:completion];
    [alertView show];
    return alertView;
}

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                cancelTitle:(NSString *)cancelTitle
                                 otherTitle:(NSString *)otherTitle
                                contentView:(UIView *)view
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
                                 completion:(void(^) (BOOL cancelled))completion
{
    PXProgressAlertView *alertView = [[PXProgressAlertView alloc] initAlertWithTitle:title
                                                                             message:message
                                                                         cancelTitle:cancelTitle
                                                                          otherTitle:otherTitle
                                                                         contentView:view
                                                                               ticks:ticks
                                                                            progress:progress
                                                                          completion:completion];
    [alertView show];
    return alertView;
}

#pragma mark - gestures

- (void)setupGestures
{
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.tap setNumberOfTapsRequired:1];
    [self.backgroundView setUserInteractionEnabled:YES];
    [self.backgroundView setMultipleTouchEnabled:NO];
    [self.backgroundView addGestureRecognizer:self.tap];
}

#pragma mark -

- (CGRect)adjustLabelFrameHeight:(UILabel *)label
{
    CGFloat height;
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGSize size = [label.text sizeWithFont:label.font
                             constrainedToSize:CGSizeMake(label.frame.size.width, FLT_MAX)
                                 lineBreakMode:NSLineBreakByWordWrapping];
        
        height = size.height;
        #pragma clang diagnostic pop
    } else {
        NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
        context.minimumScaleFactor = 1.0;
        CGRect bounds = [label.text boundingRectWithSize:CGSizeMake(label.frame.size.width, FLT_MAX)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName:label.font}
                                        context:context];
        height = bounds.size.height;
    }
    
    return CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, height);
}

- (void)resizeViews
{
    CGFloat totalHeight = 0;
    for (UIView *view in [self.alertView subviews]) {
        if ([view class] != [UIButton class] &&
            [view class] != [PXProgressView class]) {
            totalHeight += view.frame.size.height + AlertViewVerticalElementSpace;
        }
    }
    totalHeight += AlertViewButtonHeight;
    totalHeight += AlertViewVerticalElementSpace;
    
    self.alertView.frame = CGRectMake(self.alertView.frame.origin.x,
                                      self.alertView.frame.origin.y,
                                      self.alertView.frame.size.width,
                                      totalHeight);
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        CGAffineTransform transform = CGAffineTransformIdentity;
        self.alertView.transform = transform;
    }
    else {
        if (orientation ==UIInterfaceOrientationLandscapeLeft) {
            CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
            self.alertView.transform = transform;
        }
        if (orientation ==UIInterfaceOrientationLandscapeRight) {
            CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
            self.alertView.transform = transform;
        }
    }
}

- (void)showAlertAnimation
{
    self.alertView.alpha = 0.0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alertView.alpha = 1.0;
    }];
    
    return;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05, 1.05, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)]];
    animation.keyTimes = @[ @0, @0.5, @1 ];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .3;
    
    [self.alertView.layer addAnimation:animation forKey:@"showAlert"];
}

- (void)dismissAlertAnimation
{
    [UIView animateWithDuration:0.2 animations:^{
        self.alertView.alpha = 0.0;
    }];
    
    return;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1)]];
    animation.keyTimes = @[ @0, @0.5, @1 ];
    animation.fillMode = kCAFillModeRemoved;
    animation.duration = .2;
    
    [self.alertView.layer addAnimation:animation forKey:@"dismissAlert"];
}

@end

@implementation PXProgressAlertViewQueue

+ (instancetype)sharedInstance
{
    static PXProgressAlertViewQueue *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[PXProgressAlertViewQueue alloc] init];
        _sharedInstance.alertViews = [NSMutableArray array];
    });
    
    return _sharedInstance;
}

- (void)add:(PXProgressAlertView *)alertView
{
    [self.alertViews addObject:alertView];
    [alertView _show];
    for (PXProgressAlertView *av in self.alertViews) {
        if (av != alertView) {
            [av hide];
        }
    }
}

- (void)remove:(PXProgressAlertView *)alertView
{
    [self.alertViews removeObject:alertView];
    PXProgressAlertView *last = [self.alertViews lastObject];
    if (last) {
        [last _show];
    }
}

@end
