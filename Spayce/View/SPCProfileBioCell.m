//
//  SPCProfileBioCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-23.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileBioCell.h"

static const CGFloat leftRightPadding = 10;

@interface SPCProfileBioCell ()

// UI
@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UITextView *customTextLabel;

@property (nonatomic, weak) id dataSource;
@property (nonatomic) BOOL canEditProfile;

@end

@implementation SPCProfileBioCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:241.0/255.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:backgroundView];
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:_customContentView];
        
        _customTextLabel = [[self class] createCustomTextView];
        [_customContentView addSubview:_customTextLabel];
        
        _btnBioEdit = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [_btnBioEdit setImage:[UIImage imageNamed:@"pencil-bio-icon"] forState:UIControlStateNormal];
        [_btnBioEdit setImageEdgeInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
        [_customContentView addSubview:_btnBioEdit];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.dataSource = nil;
    self.customTextLabel.text = nil;
    self.canEditProfile = NO;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.customContentView.frame = self.bounds;
    if (self.canEditProfile) {
        self.btnBioEdit.hidden = NO;
        self.btnBioEdit.center = CGPointMake(CGRectGetWidth(self.bounds) - leftRightPadding + self.btnBioEdit.imageEdgeInsets.right - CGRectGetWidth(self.btnBioEdit.frame)/2.0f, CGRectGetHeight(self.bounds)/2.0f);
        
        self.customTextLabel.frame = CGRectMake(leftRightPadding, 0, CGRectGetMinX(self.btnBioEdit.frame) - leftRightPadding + self.btnBioEdit.imageEdgeInsets.left, CGRectGetHeight(self.bounds));
    } else {
        self.customTextLabel.frame = CGRectInset(self.customContentView.bounds, leftRightPadding, 0);
        self.btnBioEdit.hidden = YES;
    }
}

#pragma mark - Configuration

- (void)configureWithDataSource:(id)dataSource text:(NSString *)text andCanEditProfile:(BOOL)canEditProfile {
    self.dataSource = dataSource;
    self.canEditProfile = canEditProfile;
    self.customTextLabel.text = text;
    
    [self setNeedsLayout];
}

#pragma mark - Cell Size

+ (CGFloat)heightOfCellWithText:(NSString *)text andTableWidth:(CGFloat)tableWidth {
    CGFloat heightRet = 0;
    
    if (0 < [text length]) {
        CGRect textRect = [[self class] rectForText:text withWidth:tableWidth];
        heightRet += CGRectGetHeight(textRect);
    }
    
    return heightRet;
}

+ (CGRect)rectForText:(NSString *)text withWidth:(CGFloat)width {
    CGRect frameRet = CGRectZero;
    UITextView *textViewSample = [self createCustomTextView];
    textViewSample.text = text;
    frameRet.size = [textViewSample sizeThatFits:CGSizeMake(width - 2 * leftRightPadding, CGFLOAT_MAX)];
    return frameRet;
}

+ (UIFont *)fontForBioText {
    return [UIFont fontWithName:@"OpenSans" size:11.0f];
}

+ (UITextView *)createCustomTextView {
    UITextView *textView;
    textView = [[UITextView alloc] init];
    textView.font = [[self class] fontForBioText];
    textView.textColor = [UIColor colorWithRGBHex:0x3d3d3d];
    textView.textAlignment = NSTextAlignmentLeft;
    textView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
    textView.editable = NO;
    textView.selectable = YES;
    textView.textContainer.lineFragmentPadding = 0;
    textView.contentInset = UIEdgeInsetsZero;
    textView.scrollEnabled = NO;
    
    return textView;
}

@end
