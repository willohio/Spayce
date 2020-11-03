//
//  SPCFriendsListCell.m
//  Spayce
//
//  Created by Jake Rosin on 10/20/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFriendsListCell.h"
#import "SPCInitialsImageView.h"
#import "Person.h"

// Category
#import "NSString+SPCAdditions.h"


@interface SPCFriendsListCell()

@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) UIButton *imageButton;

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *userIsYouLabel;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UILabel *customDetailTextLabel;
@property (nonatomic, strong) UILabel *starCountLabel;
@property (nonatomic, strong) UIImageView *starImageView;
@property (nonatomic, strong) UIImageView *isCelebBadge;
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation SPCFriendsListCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        _customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(10, 15, 46, 46)];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.layer.cornerRadius = 23;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_placeholderFont];
        [self.contentView addSubview:_customImageView];
        
        _userIsYouLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 36, 15)];
        _userIsYouLabel.center = CGPointMake(33, 57);
        _userIsYouLabel.layer.cornerRadius = 7;
        _userIsYouLabel.backgroundColor = [UIColor colorWithRGBHex:0x998fcc];
        _userIsYouLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        _userIsYouLabel.layer.borderWidth = 3.0f / [UIScreen mainScreen].scale;
        _userIsYouLabel.textColor = [UIColor whiteColor];
        _userIsYouLabel.text = @"You";
        _userIsYouLabel.font = [UIFont spc_boldSystemFontOfSize:8];
        _userIsYouLabel.textAlignment = NSTextAlignmentCenter;
        _userIsYouLabel.hidden = YES;
        _userIsYouLabel.clipsToBounds = YES;
        [self.contentView addSubview:_userIsYouLabel];
        
        _imageButton = [[UIButton alloc] initWithFrame:_customImageView.frame];
        _imageButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_imageButton];
        
        _customTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _customTextLabel.textColor = [UIColor colorWithRGBHex:0x14294b];
        _customTextLabel.font = [UIFont boldSystemFontOfSize:14];
        _customTextLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_customTextLabel];
        
        _customDetailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _customDetailTextLabel.textColor = [UIColor colorWithRGBHex:0x6ab1fb];
        _customDetailTextLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        _customDetailTextLabel.textAlignment = NSTextAlignmentLeft;
        _customDetailTextLabel.adjustsFontSizeToFitWidth = YES;
        _customDetailTextLabel.minimumScaleFactor = .75;
        [self.contentView addSubview:_customDetailTextLabel];
        
        _starCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _starCountLabel.textColor = [UIColor colorWithRGBHex:0xacb6c6];
        _starCountLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        _starCountLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_starCountLabel];
        
        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _separatorView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:_separatorView];
        
        _starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-gray-xxx-small"]];
        [self.contentView addSubview:_starImageView];
        
        _isCelebBadge = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"celebrity-check"]];
        _isCelebBadge.hidden = YES;
        [self.contentView addSubview:_isCelebBadge];
    }
    return self;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
    
    // clear text
    self.customTextLabel.text = nil;
    self.customDetailTextLabel.text = nil;
    self.starCountLabel.text = nil;
    self.userIsYouLabel.hidden = YES;
    self.isCelebBadge.hidden = YES;
    
    self.imageButton.tag = 0;
    
    // Clear target action
    [self.imageButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.customTextLabel.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10, 18, self.bounds.size.width - 100, 20);
    [self.customTextLabel sizeToFit];
    
    self.customDetailTextLabel.frame =  CGRectMake(CGRectGetMinX(self.customTextLabel.frame), CGRectGetMaxY(self.customTextLabel.frame)+1, 50, 15);
    [self.customDetailTextLabel sizeToFit];
    
    if (self.customDetailTextLabel.frame.size.width > 175) {
        self.customDetailTextLabel.frame =  CGRectMake(CGRectGetMinX(self.customDetailTextLabel.frame), CGRectGetMaxY(self.customDetailTextLabel.frame)+3, 175, 15);
    }
    
    self.starCountLabel.frame = CGRectMake(CGRectGetMaxX(self.customDetailTextLabel.frame)+22, CGRectGetMinY(self.customDetailTextLabel.frame), 50, 15);
    [self.starCountLabel sizeToFit];
    
    self.starImageView.frame = CGRectMake(CGRectGetMinX(self.starCountLabel.frame) - 13, CGRectGetMinY(self.starCountLabel.frame)+4, self.starImageView.frame.size.width, self.starImageView.frame.size.height);
    
    self.isCelebBadge.center = CGPointMake(CGRectGetMaxX(self.customTextLabel.frame)+8, self.customTextLabel.center.y);
    
    CGFloat separatorHeight = 1.0f / [UIScreen mainScreen].scale;
    self.separatorView.frame = CGRectMake(0, CGRectGetHeight(self.contentView.frame) - separatorHeight, CGRectGetWidth(self.contentView.frame), separatorHeight);
}

#pragma mark - Configuration

- (void)setUserName:(NSString *)name isCeleb:(BOOL)isCeleb {
    self.customTextLabel.text = name;
    self.isCelebBadge.hidden = !isCeleb;
    
    // set left position of isCeleb badge field
    //NSDictionary *attributes = @{NSFontAttributeName: self.customTextLabel.font};
    //CGRect rect = [self.customTextLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    //self.isCelebLeftConstraint.constant = rect.size.width + 17;
    
    [self setNeedsLayout];
}

- (void)configureWithCurrentUser:(Person *)person url:(NSURL *)url {
    [self configureWithPerson:person url:url];
    self.userIsYouLabel.hidden = NO;
}

- (void)configureWithPerson:(Person *)person url:(NSURL *)url {
    // Handle the name
    NSString *nameToDisplay = person.displayName;
    if (person.firstname && person.lastname) {
        nameToDisplay = [NSString stringWithFormat:@"%@ %@",person.firstname,person.lastname];
    }
    // Setting attributes here, because we need kern
    NSDictionary *nameAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:14.0f],
                                      NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x14294b],
                                      NSKernAttributeName : @(0.5) };
    self.customTextLabel.attributedText = [[NSAttributedString alloc] initWithString:nameToDisplay attributes:nameAttributes];
    
    // Handle the handle
    self.detailTextLabel.text = @"";
    if (person.handle.length > 0) {
        NSDictionary *handleAttributes = @{ NSFontAttributeName : [UIFont spc_mediumSystemFontOfSize:14.0f],
                                            NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x6ab1fb],
                                            NSKernAttributeName : @(0.5) };
        self.customDetailTextLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@",person.handle] attributes:handleAttributes];
    }
    
    // Handle the star count
    NSString *starCountText = @"Infinite";
    if (-1 != person.recordID) {
        starCountText = [NSString stringWithFormat:@"%i",(int)person.starCount];
    }
    NSDictionary *starCountAttributes = @{ NSFontAttributeName : [UIFont spc_mediumSystemFontOfSize:14.0f],
                                           NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0xacb6c6],
                                           NSKernAttributeName : @(0.5) };
    self.starCountLabel.attributedText = [[NSAttributedString alloc] initWithString:starCountText attributes:starCountAttributes];
    
    [self.customImageView configureWithText:[person.firstname firstLetter] url:url];
    
    [self setNeedsLayout];
}

@end
