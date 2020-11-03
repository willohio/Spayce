//
//  SPCRankedUserTableViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 5/29/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCRankedUserTableViewCell.h"

// Model
#import "Asset.h"
#import "Friend.h"
#import "Star.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

// Utilities
#import "APIUtils.h"

@interface SPCRankedUserTableViewCell ()

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UILabel *rankPrefixLabel;
@property (nonatomic, strong) UIImageView *starImageView;
@property (nonatomic, strong) UIImageView *pinImageView;
@property (nonatomic, strong) UIImageView *trophyImageView;
@property (nonatomic, strong) UIImageView *checkMark;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic) BOOL isCeleb;

@end

@implementation SPCRankedUserTableViewCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundView = nil;
        self.backgroundColor = [UIColor whiteColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(10, 15, 46, 46)];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.layer.cornerRadius = 23;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_placeholderFont];
        [self.contentView addSubview:_customImageView];
        
        _youBadge = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 36, 15)];
        _youBadge.center = CGPointMake(33, 57);
        _youBadge.layer.cornerRadius = 7;
        _youBadge.backgroundColor = [UIColor colorWithRGBHex:0x998fcc];
        _youBadge.layer.borderColor = [UIColor whiteColor].CGColor;
        _youBadge.layer.borderWidth = 3.0f / [UIScreen mainScreen].scale;
        _youBadge.textColor = [UIColor whiteColor];
        _youBadge.text = @"You";
        _youBadge.font = [UIFont spc_boldSystemFontOfSize:8];
        _youBadge.textAlignment = NSTextAlignmentCenter;
        _youBadge.hidden = YES;
        _youBadge.clipsToBounds = YES;
        [self.contentView addSubview:_youBadge];
        
        _imageButton = [[UIButton alloc] initWithFrame:_customImageView.frame];
        _imageButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_imageButton];
        
        _rankPrefixLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _rankPrefixLabel.text = @"#";
        _rankPrefixLabel.textColor = [UIColor blackColor];
        _rankPrefixLabel.font = [UIFont spc_regularSystemFontOfSize:17];
        _rankPrefixLabel.textAlignment = NSTextAlignmentRight;
        //[self.contentView addSubview:_rankPrefixLabel];
        
        _trophyImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_trophyImageView];
        
        _rankLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _rankLabel.textColor = [UIColor blackColor];
        _rankLabel.font = [UIFont spc_regularSystemFontOfSize:17];
        _rankLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_rankLabel];
        
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.textColor = [UIColor colorWithRGBHex:0x14294b];
        _nameLabel.font = [UIFont boldSystemFontOfSize:14];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_nameLabel];
    
        _starCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _starCountLabel.textColor = [UIColor colorWithRGBHex:0xacb6c6];
        _starCountLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        _starCountLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_starCountLabel];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.textColor = [UIColor colorWithRGBHex:0xacb6c6];
        _timeLabel.font = [UIFont spc_romanSystemFontOfSize:12.0f];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_timeLabel];
    
        
        _handleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _handleLabel.textColor = [UIColor colorWithRGBHex:0x6ab1fb];
        _handleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        _handleLabel.textAlignment = NSTextAlignmentLeft;
        _handleLabel.adjustsFontSizeToFitWidth = YES;
        _handleLabel.minimumScaleFactor = .75;
        [self.contentView addSubview:_handleLabel];
        
        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _separatorView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:_separatorView];
        
        _starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-gray-xxx-small"]];
        [self.contentView addSubview:_starImageView];
        
        _checkMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark-celeb"]];
        [self.contentView addSubview:_checkMark];
        _checkMark.hidden = YES;
    }
    
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
    
    self.nameLabel.text = nil;
    self.rankLabel.text = nil;
    self.starCountLabel.text = nil;
    self.trophyImageView.image = nil;
    self.nameLabel.textColor = [UIColor blackColor];
    self.rankPrefixLabel.hidden = NO;
    self.rankLabel.textColor = [UIColor blackColor];
    self.isCeleb = NO;
    self.checkMark.hidden = YES;
    self.youBadge.hidden = YES;
    self.timeLabel.text = nil;
    
    self.imageButton.tag = 0;
    
    // Clear target action
    [self.imageButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10, 18, 220, 20);
    [self.nameLabel sizeToFit];
    
    self.handleLabel.frame =  CGRectMake(CGRectGetMinX(self.nameLabel.frame), CGRectGetMaxY(self.nameLabel.frame)+1, 50, 15);
    [self.handleLabel sizeToFit];
    
    if (self.handleLabel.frame.size.width > 175) {
        self.handleLabel.frame =  CGRectMake(CGRectGetMinX(self.nameLabel.frame), CGRectGetMaxY(self.nameLabel.frame)+3, 175, 15);
    }
    
    self.starCountLabel.frame = CGRectMake(CGRectGetMaxX(self.handleLabel.frame)+22, CGRectGetMinY(self.handleLabel.frame), 50, 15);
    [self.starCountLabel sizeToFit];
    
    self.starImageView.frame = CGRectMake(CGRectGetMinX(self.starCountLabel.frame) - 13, CGRectGetMinY(self.starCountLabel.frame)+4, self.starImageView.frame.size.width, self.starImageView.frame.size.height);
    
    self.trophyImageView.frame = CGRectMake(self.bounds.size.width - 37, 21, 30, 30);
    
    [self.rankLabel sizeToFit];
    CGSize rankLabelSize = self.rankLabel.frame.size;
    self.rankLabel.frame = CGRectMake(self.bounds.size.width - rankLabelSize.width - 10, 0, rankLabelSize.width, self.frame.size.height);
   // self.rankPrefixLabel.frame = CGRectMake(self.bounds.size.width - rankLabelSize.width - 20, 0, 8, self.frame.size.height);
    
    if (self.isCeleb) {
        self.checkMark.center = CGPointMake(CGRectGetMaxX(self.nameLabel.frame)+8, self.nameLabel.center.y);
        self.checkMark.hidden = NO;
    }
    
    CGSize timeLabelSize = [self.timeLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.timeLabel.font }];
    self.timeLabel.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - timeLabelSize.width - 10, 13, timeLabelSize.width, timeLabelSize.height);
    
    CGFloat separatorSize = 1.0f / [UIScreen mainScreen].scale;
    self.separatorView.frame = CGRectMake(0, self.contentView.frame.size.height-separatorSize, self.frame.size.width, separatorSize);
}

#pragma mark - Configuration

- (void)configureWithPerson:(Person *)f peopleState:(NSInteger)peopleState {
    self.nameLabel.text = f.displayName;

    if (f.firstname && f.lastname) {
        self.nameLabel.text = [NSString stringWithFormat:@"%@ %@",f.firstname,f.lastname];
    }
    
    self.starCountLabel.text = [NSString stringWithFormat:@"%i",(int)f.starCount];
    self.handleLabel.text = @"";
    self.territoryNameLabel.text = @"Spayce";
    
    if (f.handle.length > 0) {
        self.handleLabel.text = [NSString stringWithFormat:@"@%@",f.handle];
    }
    if (f.isCeleb) {
        self.isCeleb = YES;
    }
    if (self.rank <= 3) {
        self.rankPrefixLabel.hidden = YES;
        
        NSString *imgName = [NSString stringWithFormat:@"trophy-%@", @(self.rank)];
        UIImage *image = [UIImage imageNamed:imgName];
        
        self.trophyImageView.image = image;
        self.rankLabel.text = @"";
    }
    
    if (f.recordID == -1) {
     self.starCountLabel.text = @"Infinite";
    }
    
    NSURL *url = [NSURL URLWithString:[f.imageAsset imageUrlThumbnail]];
    
    [self configureWithText:f.firstname url:url];
    
    [self setNeedsLayout];
}

- (void)configureWithStar:(Star *)s {
    // Handle the name
    NSString *nameToDisplay = s.displayName;
    if (s.firstname && s.lastname) {
        nameToDisplay = [NSString stringWithFormat:@"%@ %@",s.firstname,s.lastname];
    }
    // Setting attributes here, because we need kern
    NSDictionary *nameAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:14.0f],
                                      NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x14294b],
                                      NSKernAttributeName : @(0.5) };
    self.nameLabel.attributedText = [[NSAttributedString alloc] initWithString:nameToDisplay attributes:nameAttributes];
    
    self.territoryNameLabel.text = @"Spayce";
    
    // Handle the handle
    self.handleLabel.text = @"";
    if (s.handle.length > 0) {
        NSDictionary *handleAttributes = @{ NSFontAttributeName : [UIFont spc_mediumSystemFontOfSize:14.0f],
                                          NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x6ab1fb],
                                          NSKernAttributeName : @(0.5) };
        self.handleLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@",s.handle] attributes:handleAttributes];
    }
    
    
    if (s.isCeleb) {
        self.isCeleb = YES;
    }
    
    // Handle the star count
    NSString *starCountText = @"Infinite";
    if (-1 != s.recordID) {
        starCountText = [NSString stringWithFormat:@"%i",(int)s.starCount];
    }
    NSDictionary *starCountAttributes = @{ NSFontAttributeName : [UIFont spc_mediumSystemFontOfSize:14.0f],
                                       NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0xacb6c6],
                                       NSKernAttributeName : @(0.5) };
    self.starCountLabel.attributedText = [[NSAttributedString alloc] initWithString:starCountText attributes:starCountAttributes];
    
    NSURL *url = [NSURL URLWithString:[s.imageAsset imageUrlThumbnail]];
    [self configureWithText:s.firstname url:url];
    
    self.timeLabel.text = s.displayDateMediumStarred;
    
    self.rankPrefixLabel.hidden = YES;
    
    [self setNeedsLayout];
}

- (void)configureWithText:(NSString *)text url:(NSURL *)url {
    [self.customImageView configureWithText:[text.firstLetter capitalizedString] url:url];
}

- (NSString *) findSuperscript:(NSInteger)rank {
    NSString *numericString = [NSString stringWithFormat:@"%li",rank];
    NSInteger numericStringLength = [numericString length];
    NSString *superScriptText = [[NSString alloc] init];
    
    if (numericStringLength == 1) {
        if ([numericString isEqualToString:@"1"]) { superScriptText = @"st"; }
        else if ([numericString isEqualToString:@"2"]) { superScriptText = @"nd"; }
        else if ([numericString isEqualToString:@"3"]) { superScriptText = @"rd"; }
        else { superScriptText = @"th"; }
    }
    
    //handle special cases 11, 12, 13

    else if (rank == 11) {
        superScriptText = @"th";
    }
    else if (rank == 12) {
        superScriptText = @"th";
    }
    else if (rank == 13) {
        superScriptText = @"th";
    }
    
    //handle special cases for longer numbers ending in 11, 12 or 13
    else if (numericStringLength > 2) {
        NSString* numericStringCharacterAtIndex = [numericString substringWithRange:NSMakeRange(numericStringLength-2, 2)];
        int numericStringCharacter = [numericStringCharacterAtIndex intValue];
        switch (numericStringCharacter) {
            case 11:
                superScriptText = @"th";
                break;
            case 12:
                superScriptText = @"th";
                break;
            case 13:
                superScriptText = @"th";
                break;
            default:
                break;
        }
    }
    
    //handle everything else
    if (superScriptText.length == 0 && numericStringLength > 1) {
        NSString* numericStringCharacterAtIndex = [numericString substringWithRange:NSMakeRange(numericStringLength-1, 1)];
        int numericStringCharacterInOnesPlace = [numericStringCharacterAtIndex intValue];
        switch (numericStringCharacterInOnesPlace) {
            case 1:
                superScriptText = @"st";
                break;
            case 2:
                superScriptText = @"nd";
                break;
            case 3:
                superScriptText = @"rd";
                break;
            default:
                superScriptText = @"th";
                break;
        }
    }
    
    return superScriptText;
}

@end
