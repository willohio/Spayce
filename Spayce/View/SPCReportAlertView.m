//
//  SPCReportAlertView.m
//  Spayce
//
//  Created by Arria P. Owlia on 2/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCReportAlertView.h"

@interface SPCReportAlertView()

// Contains the content
@property (strong, nonatomic) UIScrollView *contentView;
@property (strong, nonatomic) NSMutableArray *separatorViews;

// Title button
@property (strong, nonatomic) UIButton *titleButton;

// Options buttons
@property (strong, nonatomic) NSMutableArray *buttonOptions;

// Cancel button
@property (strong, nonatomic) NSMutableArray *buttonDismisses;

@end

@implementation SPCReportAlertView

#pragma mark - Lifecycle

static const CGFloat ANIMATION_DURATION = 0.3f;
static const CGFloat MIN_LEFTRIGHT_SCREEN_PADDING = 35.0f;
static const CGFloat MIN_TOPBOTTOM_SCREEN_PADDING = 70.0f;

- (void)dealloc {
    [self hideAnimated:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        self.frame = [UIScreen mainScreen].bounds;
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

- (instancetype)initWithTitle:(NSString *)title stringOptions:(NSArray *)stringOptions dismissTitles:(NSArray *)dismissTitles andDelegate:(id<SPCReportAlertViewDelegate>)delegate {
    if (self = [self init]) { // Init'ing with [self init] on purpose (simply to get the frame that is set in that method)
        [self commonInit];
        
        self.title = title;
        self.stringOptions = stringOptions;
        self.stringDismissTitles = dismissTitles;
        
        self.delegate = delegate;
    }
    
    return self;
}

- (void)commonInit {
    // Background Color
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3f];
    // Add a tap gesture recognizer to our background, so we can dismiss when a user taps outside the alert view as well
    UITapGestureRecognizer *backgroundTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedDismissButton:)];
    self.gestureRecognizers = @[backgroundTapGR];
    
    // Content View
    self.contentView = [[UIScrollView alloc] init];
    self.contentView.scrollEnabled = YES;
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 6.0f;
    self.contentView.layer.masksToBounds = YES;
    [self addSubview:self.contentView];
    
    // Title button/font
    self.titleButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    [self.titleButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.titleButton.titleLabel.numberOfLines = 0;
    [self.contentView addSubview:self.titleButton];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat numberOfItems = 1 + [self.buttonOptions count] + 1; // Title + #options + Cancel
    CGFloat contentHeight = 60.0f * numberOfItems;
    CGFloat finalViewWidth = MIN([UIScreen mainScreen].bounds.size.width - MIN_LEFTRIGHT_SCREEN_PADDING, CGRectGetWidth(self.bounds));
    CGFloat finalViewHeight = MIN([UIScreen mainScreen].bounds.size.height - MIN_TOPBOTTOM_SCREEN_PADDING, contentHeight);
    
    // Set the content view's properties
    self.contentView.contentSize = CGSizeMake(finalViewWidth, contentHeight);
    self.contentView.frame = CGRectMake((CGRectGetWidth(self.bounds) - finalViewWidth) / 2.0f, (CGRectGetHeight(self.bounds) - finalViewHeight) / 2.0f, finalViewWidth, finalViewHeight);
    
    // For ease
    CGFloat viewWidth = finalViewWidth;
    CGFloat viewHeight = contentHeight;
    CGFloat itemOffset = viewHeight / numberOfItems / 2.0f;
    CGFloat itemSpacing = viewHeight / numberOfItems;
    CGFloat separatorOffset = itemSpacing;
    CGFloat separatorSize = 1.0f / [UIScreen mainScreen].scale;
    
    // Title
    self.titleButton.frame = CGRectMake(0.0f, 0.0f, viewWidth, itemSpacing);
    self.titleButton.center = CGPointMake(viewWidth / 2.0f, itemOffset);
    itemOffset = itemOffset + itemSpacing;
    
    // Separator init
    for (UIView *view in self.separatorViews) {
        [view removeFromSuperview];
    }
    self.separatorViews = [[NSMutableArray alloc] init];
    
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, separatorOffset - separatorSize, viewWidth, separatorSize)];
    separatorView.backgroundColor = [UIColor colorWithRGBHex:0xe7e7e7];
    [self.contentView addSubview:separatorView];
    separatorOffset = separatorOffset + itemSpacing;
    
    for (UIButton *option in self.buttonOptions) {
        // Configure option
        option.frame = CGRectMake(0.0f, 0.0f, viewWidth, itemSpacing);
        option.center = CGPointMake(viewWidth / 2.0f, itemOffset);
        itemOffset = itemOffset + itemSpacing;
        
        // Configure separator
        UIView *separatorViewOption = [[UIView alloc] initWithFrame:CGRectMake(0, separatorOffset - separatorSize, viewWidth, separatorSize)];
        separatorViewOption.backgroundColor = [UIColor colorWithRGBHex:0xe7e7e7];
        [self.contentView addSubview:separatorViewOption];
        separatorOffset = separatorOffset + itemSpacing;
    }
    
    separatorOffset = viewWidth / [self.buttonDismisses count];
    CGFloat dismissButtonWidth = viewWidth / [self.buttonDismisses count];
    CGFloat dismissButtonOffset = dismissButtonWidth / 2.0f;
    for (UIButton *dismiss in self.buttonDismisses) {
        dismiss.frame = CGRectMake(0, 0, dismissButtonWidth, itemSpacing);
        dismiss.center = CGPointMake(dismissButtonOffset, itemOffset);
        dismissButtonOffset = dismissButtonOffset + dismissButtonWidth;
        
        // Configure separator
        if (![[self.buttonDismisses lastObject] isEqual:dismiss]) { // Add a separator if this is not the last object
            UIView *separatorViewDismiss = [[UIView alloc] initWithFrame:CGRectMake(separatorOffset, itemOffset - (itemSpacing / 2.0f), separatorSize, itemSpacing)];
            separatorViewDismiss.backgroundColor = [UIColor colorWithRGBHex:0xe7e7e7];
            [self.contentView addSubview:separatorViewDismiss];
            separatorOffset = separatorOffset + dismissButtonWidth;
        }
    }
}

#pragma mark - Actions

- (void)showAnimated:(BOOL)animated {
    UIView *view = [[UIApplication sharedApplication] keyWindow];
    
    [self showInView:view animated:animated];
}

- (void)showInView:(UIView *)view animated:(BOOL)animated {
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

- (void)hideAnimated:(BOOL)animated {
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

- (void)tappedOptionButton:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *btnOption = (UIButton *)sender;
        NSInteger tag = btnOption.tag;
        
        if ([self.delegate respondsToSelector:@selector(tappedOption:onSPCReportAlertView:)] && tag < [self.stringOptions count]) {
            [self.delegate tappedOption:[self.stringOptions objectAtIndex:tag] onSPCReportAlertView:self];
        }
    }
}

- (void)tappedDismissButton:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *btnOption = (UIButton *)sender;
        NSInteger tag = btnOption.tag;
        
        if ([self.delegate respondsToSelector:@selector(tappedDismissTitle:onSPCReportAlertView:)] && tag < [self.stringDismissTitles count]) {
            [self.delegate tappedDismissTitle:[self.stringDismissTitles objectAtIndex:tag] onSPCReportAlertView:self];
        } else {
            [self hideAnimated:YES];
        }
    } else if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        [self hideAnimated:YES];
    }
}

#pragma mark - Accessors

- (UIButton *)titleButton {
    if (nil == _titleButton) {
        _titleButton = [[UIButton alloc] init];
    }
    
    return _titleButton;
}

- (void)setTitle:(NSString *)title {
    [self.titleButton setTitle:title forState:UIControlStateNormal];
    [self.titleButton setNeedsDisplay];
    
    _title = title;
}

- (void)setStringDismissTitles:(NSArray *)stringDismissTitles {
    for (UIButton *btnDismissCurrent in self.buttonDismisses) {
        [btnDismissCurrent removeFromSuperview];
    }
    self.buttonDismisses = [[NSMutableArray alloc] init];
    
    NSInteger tag = 0;
    for (NSObject *dismissObj in stringDismissTitles) {
        if ([dismissObj isKindOfClass:[NSString class]]) {
            NSString *strDismiss = (NSString *)dismissObj;
            
            UIButton *btnDismiss = [[UIButton alloc] init];
            btnDismiss.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0f];
            [btnDismiss setTitle:strDismiss forState:UIControlStateNormal];
            if ([dismissObj isEqual:[stringDismissTitles lastObject]]) {
                [btnDismiss setTitleColor:[UIColor colorWithRGBHex:0xf14c0a] forState:UIControlStateNormal];
            } else {
                [btnDismiss setTitleColor:[UIColor colorWithRGBHex:0x6ab1fb] forState:UIControlStateNormal];
            }
            btnDismiss.titleLabel.numberOfLines = 0;
            btnDismiss.tag = tag++;
            [btnDismiss addTarget:self action:@selector(tappedDismissButton:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:btnDismiss];
            
            [self.buttonDismisses addObject:btnDismiss];
        }
    }
    
    _stringDismissTitles = stringDismissTitles;
    
    [self setNeedsLayout];
}

- (void)setStringOptions:(NSArray *)stringOptions {
    for (UIButton *btnOptionCurrent in self.buttonOptions) {
        [btnOptionCurrent removeFromSuperview];
    }
    self.buttonOptions = [[NSMutableArray alloc] init];
    
    NSInteger tag = 0;
    for (NSObject *optionObj in stringOptions) {
        if ([optionObj isKindOfClass:[NSString class]]) {
            NSString *strOption = (NSString *)optionObj;
            
            UIButton *btnOption = [[UIButton alloc] init];
            btnOption.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0f];
            [btnOption setTitle:strOption forState:UIControlStateNormal];
            [btnOption setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btnOption.titleLabel.numberOfLines = 0;
            btnOption.tag = tag++;
            [btnOption addTarget:self action:@selector(tappedOptionButton:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:btnOption];
            
            [self.buttonOptions addObject:btnOption];
        }
    }
    
    _stringOptions = stringOptions;
    
    [self setNeedsLayout];
}

@end
