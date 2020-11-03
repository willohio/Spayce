//
//  AddFriendsCollectionViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 12/2/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "AddFriendsCollectionViewCell.h"

// Model
#import "Asset.h"
#import "Friend.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

// Utilities
#import "APIUtils.h"

@interface AddFriendsCollectionViewCell ()

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *handleLabel;
@property (nonatomic, strong) UIImageView *checkMark;
@end

@implementation AddFriendsCollectionViewCell

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.layer.cornerRadius = 2.0;
        
        
        float cornerRadius = 35;
        float topAnchorPadding = 10;
        float bottomAnchorPadding = -8;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            cornerRadius = 36;
            topAnchorPadding = 5;
            bottomAnchorPadding = -15;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            cornerRadius = 42.5;
            topAnchorPadding = 20;
            bottomAnchorPadding = -20;
        }
        
        float picWidth = cornerRadius * 2;
        
        _customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(5, topAnchorPadding, picWidth, picWidth)];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.layer.cornerRadius = cornerRadius;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
        _customImageView.layer.borderWidth = 0;
        _customImageView.textLabel.font = [UIFont spc_profileInfo_placeholderFont];
        [self.contentView addSubview:_customImageView];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(4.0, CGRectGetMaxY(self.customImageView.frame), CGRectGetWidth(frame)-8, 11)];
        self.nameLabel.textColor = [UIColor colorWithWhite:38.0f/255.0f alpha:1.0f];
        self.nameLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.adjustsFontSizeToFitWidth = YES;
        self.nameLabel.minimumScaleFactor = .7;
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.nameLabel.numberOfLines = 1;
        [self addSubview:self.nameLabel];
    
        
        self.handleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4.0, CGRectGetMaxY(self.nameLabel.frame), CGRectGetWidth(frame)-8, 10)];
        self.handleLabel.textColor = [UIColor colorWithRed:151.0f/255.0f green:150.0f/255.0f blue:150.0f/255.0f alpha:1.0f];
        self.handleLabel.font = [UIFont fontWithName:@"OpenSans" size:8];
        self.handleLabel.textAlignment = NSTextAlignmentCenter;
        self.handleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.handleLabel.numberOfLines = 1;
        [self addSubview:self.handleLabel];
        
        UIImage *checkImg = [UIImage imageNamed:@"checkmark-celeb"];
        self.checkMark = [[UIImageView alloc] initWithImage:checkImg];
        self.checkMark.center = CGPointMake(80, 25);
        self.checkMark.hidden = YES;
        [self addSubview:self.checkMark];

    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
    
    self.nameLabel.text = nil;
    self.handleLabel.text = @"";
    self.checkMark.hidden = YES;
    
    [self includeFriend:NO];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.customImageView.center = CGPointMake(CGRectGetMidX(self.contentView.frame), self.customImageView.center.y);
    self.nameLabel.frame = CGRectMake(4.0, CGRectGetMaxY(self.customImageView.frame)+10, self.nameLabel.frame.size.width, 12);
    self.nameLabel.center = CGPointMake(self.frame.size.width/2, self.nameLabel.center.y);
   
    self.handleLabel.frame = CGRectMake(4.0, CGRectGetMaxY(self.nameLabel.frame), self.nameLabel.frame.size.width, 10);
    self.handleLabel.center = CGPointMake(self.frame.size.width/2, self.handleLabel.center.y);
}

#pragma mark - Configuration

- (void)configureWithFriend:(Friend *)f {
    self.nameLabel.text = [f.displayName uppercaseString];
    self.handleLabel.text = [NSString stringWithFormat:@"@%@",f.handle];

    if (f.isCeleb) {
        self.checkMark.center = CGPointMake(self.frame.size.width/2,CGRectGetMaxY(self.customImageView.frame));
        self.checkMark.hidden = NO;
    }
    
    NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:f.imageAsset.imageUrlHalfSquare size:ImageCacheSizeSquareMedium]];
    
    if ([UIScreen mainScreen].bounds.size.width >= 375) {
        url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:f.imageAsset.imageUrlSquare size:ImageCacheSizeThumbnailXLarge]];
    }
    
    [self configureWithText:f.firstname url:url];
}

- (void)configureWithText:(NSString *)text url:(NSURL *)url {
    [self.customImageView configureWithText:[text.firstLetter capitalizedString] url:url];
}

- (void)includeFriend:(BOOL)included {
    isIncluded = included;
    
    self.customImageView.layer.borderWidth = isIncluded ? 4 : 0;
}

- (BOOL)friendIsIncluded {
    return isIncluded;
}

@end
