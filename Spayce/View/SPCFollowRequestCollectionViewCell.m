//
//  SPCFollowRequestCollectionViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 4/7/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCFollowRequestCollectionViewCell.h"

// Model
#import "Asset.h"
#import "Person.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

// Utilities
#import "APIUtils.h"


@interface SPCFollowRequestCollectionViewCell ()

@property (nonatomic, strong) Person *requestingPerson;

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *nameLabel;


@property (nonatomic, strong) UIImageView *checkMark;

@property (nonatomic, strong) UIView *starContainerView;
@property (nonatomic, strong) UIImageView *starImageView;
@property (nonatomic, strong) UILabel *starLabel;

@property (nonatomic, strong) UILabel *followLabel;


@property (nonatomic, strong) UIView *buttonsContainerView;

@property (nonatomic, strong) UILabel *followingLabel;
@property (nonatomic, strong) UIImageView *checkImgView;

@end


@implementation SPCFollowRequestCollectionViewCell

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.layer.cornerRadius = 2.0;
        
        
        float cornerRadius = 36;
        float topAnchorPadding = 10;
        
        float picWidth = cornerRadius * 2;
        
        _customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(5, topAnchorPadding, picWidth, picWidth)];
        _customImageView.backgroundColor = [UIColor colorWithWhite:247.0f/255.0f alpha:1.0f];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.layer.cornerRadius = cornerRadius;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
        _customImageView.layer.borderWidth = 0;
        _customImageView.textLabel.font = [UIFont spc_profileInfo_placeholderFont];
        [self.contentView addSubview:_customImageView];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(4.0, CGRectGetMaxY(self.customImageView.frame)+10, CGRectGetWidth(frame)-8, 15)];
        self.nameLabel.textColor = [UIColor colorWithRed:38.0f/255.0f green:38.0f/255.0f blue:38.0f/255.0f alpha:1.0f];
        self.nameLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.nameLabel.numberOfLines = 1;
        [self.contentView addSubview:self.nameLabel];
        
        
        self.starContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        self.starContainerView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.starContainerView];
        
        self.starLabel = [[UILabel alloc] initWithFrame:CGRectMake(4.0, CGRectGetMaxY(self.nameLabel.frame)+5, CGRectGetWidth(frame)-8, 15)];
        self.starLabel.textColor = [UIColor colorWithRed:187.0f/255.0f green:189.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
        self.starLabel.font = [UIFont fontWithName:@"OpenSans" size:8];
        self.starLabel.textAlignment = NSTextAlignmentLeft;
        self.starLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.starLabel.numberOfLines = 1;
        [self.starContainerView addSubview:self.starLabel];
        
        self.starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-gray-xxx-small"]];
        [self.starContainerView addSubview:self.starImageView];
        
        self.followLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.followLabel.textColor = [UIColor colorWithRed:187.0f/255.0f green:189.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
        self.followLabel.backgroundColor = [UIColor clearColor];
        self.followLabel.text = [NSLocalizedString(@"You follow", nil) uppercaseString];
        self.followLabel.font = [UIFont fontWithName:@"OpenSans" size:8];
        [self.contentView addSubview:self.followLabel];
        
        UIImage *checkImg = [UIImage imageNamed:@"checkmark-celeb"];
        self.checkMark = [[UIImageView alloc] initWithImage:checkImg];
        self.checkMark.center = CGPointMake(80, 25);
        self.checkMark.hidden = YES;
        [self.contentView addSubview:self.checkMark];
        
        self.buttonsContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        self.buttonsContainerView.backgroundColor = [UIColor clearColor];
        self.buttonsContainerView.userInteractionEnabled = YES;
        [self.contentView addSubview:self.buttonsContainerView];
        
        self.acceptBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.acceptBtn.backgroundColor = [UIColor colorWithRed:76.0f/255.0f  green:176.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        self.acceptBtn.layer.cornerRadius = 6;
        [self.acceptBtn setImage:[UIImage imageNamed:@"followAcceptIcon"] forState:UIControlStateNormal];
        [self.buttonsContainerView addSubview:self.acceptBtn];
        
        self.declineBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.declineBtn.backgroundColor = [UIColor whiteColor];
        self.declineBtn.layer.borderColor = [UIColor colorWithWhite:214.0f/255.0f alpha:1.0f].CGColor;
        self.declineBtn.layer.borderWidth = 1;
        [self.declineBtn setImage:[UIImage imageNamed:@"followDeclineIcon"] forState:UIControlStateNormal];
        self.declineBtn.layer.cornerRadius = 6;
        [self.buttonsContainerView addSubview:self.declineBtn];
        
        self.followingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.followingLabel.text = [NSLocalizedString(@"     Following", nil) uppercaseString];
        self.followingLabel.backgroundColor = [UIColor colorWithRed:76.0f/255.0f  green:176.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        self.followingLabel.layer.cornerRadius = 4;
        self.followingLabel.clipsToBounds = YES;
        
        self.followingLabel.textColor = [UIColor whiteColor];
        self.followingLabel.textAlignment = NSTextAlignmentCenter;
        self.followingLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
        
        self.followingLabel.hidden = YES;
        
        self.checkImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"followAcceptIcon"]];
        [self.followingLabel addSubview:self.checkImgView];
        
        [self.contentView addSubview:self.followingLabel];
        
        self.authorBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.authorBtn];
        
        
    }
    return self;
}

- (void)configureWithPerson:(Person *)person {
    
    self.nameLabel.text = [person.displayName uppercaseString];
    float maxWidth = CGRectGetWidth(self.frame)-8;

    self.starLabel.text = [NSString stringWithFormat:@"%li",person.starCount];
    [self.starLabel sizeToFit];
    
    float starContainerWidth = self.starImageView.image.size.width + 5 + self.starLabel.frame.size.width;
    self.starLabel.frame = CGRectMake(self.starImageView.image.size.width + 5, 0, self.starLabel.frame.size.width, 10);
    
    self.starContainerView.frame = CGRectMake(0, CGRectGetMaxY(self.nameLabel.frame), starContainerWidth, 10);
    self.starContainerView.center = CGPointMake(self.contentView.frame.size.width/2, self.starContainerView.center.y);
    
    float centerY = self.nameLabel.center.y;
    
    CGSize constraint = CGSizeMake(maxWidth, self.nameLabel.frame.size.height);
    NSDictionary *attributes = @{ NSFontAttributeName: self.nameLabel.font };
    CGRect frame = [self.nameLabel.text boundingRectWithSize:constraint
                                                     options:NSStringDrawingTruncatesLastVisibleLine
                                                  attributes:attributes
                                                     context:NULL];
    
    if (frame.size.width > maxWidth) {
        frame.size.width = maxWidth;
    }
    
    self.nameLabel.frame = frame;
    self.nameLabel.center = CGPointMake(self.contentView.frame.size.width/2, centerY);
    self.customImageView.center = CGPointMake(self.contentView.frame.size.width/2, self.customImageView.center.y);
    self.authorBtn.frame = self.customImageView.frame;
    
    
    float btnWidth = 40;
    float btnHeight = 25;
    
    self.acceptBtn.frame = CGRectMake(0, 0, btnWidth, btnHeight);
    self.declineBtn.frame = CGRectMake(btnWidth + 10, 0, btnWidth, btnHeight);
    self.buttonsContainerView.frame = CGRectMake(0, CGRectGetMaxY(self.starContainerView.frame)+5, (btnWidth * 2)+10, btnHeight);
    self.buttonsContainerView.center = CGPointMake(self.contentView.frame.size.width/2, self.buttonsContainerView.center.y);
    
    NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:person.imageAsset.imageUrlHalfSquare size:ImageCacheSizeSquareMedium]];
    
    [self configureWithText:person.firstname url:url];
    
    if (person.followingStatus == FollowingStatusFollowing) {
        self.starContainerView.hidden = YES;
        self.followLabel.frame = CGRectMake((self.bounds.size.width - 50)/2, self.starContainerView.frame.origin.y, self.bounds.size.width - 50, self.starContainerView.frame.size.height);
        self.followLabel.hidden = NO;
    }
    else {
        self.starContainerView.hidden = NO;
        self.followLabel.hidden = YES;
    }
    
    
    if (person.followerStatus == FollowingStatusFollowing) {
        self.acceptBtn.hidden = YES;
        self.declineBtn.hidden = YES;
        
        self.followingLabel.frame = self.buttonsContainerView.frame;
        self.checkImgView.center = CGPointMake(6 + self.checkImgView.image.size.width/2, self.followingLabel.frame.size.height/2);
        self.followingLabel.hidden = NO;
    }
    else {
        self.followingLabel.hidden = YES;
        self.acceptBtn.hidden = NO;
        self.declineBtn.hidden = NO;
    }
    
}

- (void)configureWithText:(NSString *)text url:(NSURL *)url {
    [self.customImageView configureWithText:[text.firstLetter capitalizedString] url:url];
}
@end
