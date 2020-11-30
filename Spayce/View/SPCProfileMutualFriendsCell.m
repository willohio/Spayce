//
//  SPCProfileMutualFriendsCell.m
//  Spayce
//
//  Created by William Santiago on 2014-10-22.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileMutualFriendsCell.h"

static CGFloat leftRightPadding = 20;

// Model
#import "Asset.h"
#import "Person.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

// Utils
#import "APIUtils.h"

// Literals
#import "SPCLiterals.h"

@interface SPCProfileMutualFriendsCell ()

// Data
@property (nonatomic) SPCCellStyle cellStyle;

// UI
@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) NSLayoutConstraint *backgroundViewTopConstraint;
@property (nonatomic, strong) SPCInitialsImageView *customImageViewOne;
@property (nonatomic, strong) SPCInitialsImageView *customImageViewTwo;
@property (nonatomic, strong) SPCInitialsImageView *customImageViewThree;
@property (nonatomic, strong) UILabel *customTextLabel;

- (UIRectCorner)cornerForStyle:(SPCCellStyle)style;

@end

@implementation SPCProfileMutualFriendsCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
      
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:backgroundView];
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:_customContentView];
        
        _customImageViewOne = [[SPCInitialsImageView alloc] init];
        _customImageViewOne.backgroundColor = [UIColor whiteColor];
        _customImageViewOne.contentMode = UIViewContentModeScaleAspectFill;
        _customImageViewOne.layer.cornerRadius = 22.5;
        _customImageViewOne.layer.masksToBounds = YES;
        _customImageViewOne.textLabel.font = [UIFont spc_profileInfo_placeholderFont];
        [_customContentView addSubview:_customImageViewOne];
        
        _customImageViewTwo = [[SPCInitialsImageView alloc] init];
        _customImageViewTwo.backgroundColor = [UIColor whiteColor];
        _customImageViewTwo.contentMode = UIViewContentModeScaleAspectFill;
        _customImageViewTwo.layer.cornerRadius = 22.5;
        _customImageViewTwo.layer.masksToBounds = YES;
        _customImageViewTwo.hidden = YES;
        _customImageViewTwo.textLabel.font = [UIFont spc_profileInfo_placeholderFont];
        [_customContentView addSubview:_customImageViewTwo];
        
        _customImageViewThree = [[SPCInitialsImageView alloc] init];
        _customImageViewThree.backgroundColor = [UIColor whiteColor];
        _customImageViewThree.contentMode = UIViewContentModeScaleAspectFill;
        _customImageViewThree.layer.cornerRadius = 22.5;
        _customImageViewThree.layer.masksToBounds = YES;
        _customImageViewThree.hidden = YES;
        _customImageViewThree.textLabel.font = [UIFont spc_profileInfo_placeholderFont];
        [_customContentView addSubview:_customImageViewThree];
        
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.numberOfLines = 2;
        _customTextLabel.lineBreakMode = NSLineBreakByTruncatingTail; // This is the default anyway
        [_customContentView addSubview:_customTextLabel];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    self.customTextLabel.attributedText = nil;
    
    // Clear friend badges
    [self.customImageViewOne prepareForReuse];
    [self.customImageViewTwo prepareForReuse];
    self.customImageViewTwo.hidden = YES;
    [self.customImageViewThree prepareForReuse];
    self.customImageViewThree.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    self.customContentView.backgroundColor = selected ? [UIColor colorWithWhite:0.98 alpha:1.0] : [UIColor whiteColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    self.customContentView.backgroundColor = highlighted ? [UIColor colorWithWhite:0.98 alpha:1.0] : [UIColor whiteColor];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.customContentView layoutIfNeeded];
    
    self.backgroundView.frame = self.bounds;
    self.customContentView.frame = self.bounds;
    
    // Update customImageView frames
    // 1 friend = _ * _
    // 2 friends = _*_*_
    // 3 friends = *_*_*
    // 45x45pt cells, 10pt spacing, 25pt from top of frame
    // Calculate the first cell's X offset, then space the others 10pt to the right of the previous one
    NSInteger numberOfCells = self.customImageViewThree.hidden ? (self.customImageViewTwo.hidden ? 1 : 2) : 3;
    CGFloat imageViewDimension = 45.0;
    CGFloat imageViewOneX = CGRectGetMidX(self.frame) - imageViewDimension / 2 - ( (numberOfCells - 1) * ( imageViewDimension / 2 + 5 ) ); // Add 5pt of spacing
    self.customImageViewOne.frame = CGRectMake(imageViewOneX, 25, 45, 45);
    self.customImageViewTwo.frame = CGRectMake(CGRectGetMaxX(self.customImageViewOne.frame) + 10, 25, 45, 45);
    self.customImageViewThree.frame = CGRectMake(CGRectGetMaxX(self.customImageViewTwo.frame) + 10, 25, 45, 45);
    
    self.customTextLabel.frame = CGRectMake(leftRightPadding, CGRectGetHeight(self.frame) - 10 - 2 * self.customTextLabel.font.lineHeight, CGRectGetWidth(self.frame) - (2*leftRightPadding), 2 * self.customTextLabel.font.lineHeight);
    self.customTextLabel.textAlignment = NSTextAlignmentCenter;
}

#pragma mark - Private

- (UIRectCorner)cornerForStyle:(SPCCellStyle)style {
    UIRectCorner corner = 0;
    if (style == SPCCellStyleTop) {
        corner = UIRectCornerTopLeft | UIRectCornerTopRight;
    }
    else if (style == SPCCellStyleBottom) {
        corner = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }
    else if (style == SPCCellStyleSingle) {
        corner = UIRectCornerAllCorners;
    }
    return corner;
}

#pragma mark - Configuration
- (void)configureWithMutualFriends:(NSArray *)mutualFriends cellStyle:(SPCCellStyle)cellStyle {
    [self configureWithMutualFriendCount:mutualFriends.count mutualFriends:mutualFriends cellStyle:cellStyle];
}


- (void)configureWithMutualFriendCount:(NSInteger)mutualFriendCount mutualFriends:(NSArray *)mutualFriends cellStyle:(SPCCellStyle)cellStyle {
    if (mutualFriends.count > 0) {
        // Populate the friends that we will display
        Person *firstPerson = nil;
        Person *secondPerson = nil;
        Person *thirdPerson = nil;
        NSInteger numFriends = 0;
        
        NSArray *filteredFriends = [[self class] filterSpayceTeamFromFriends:mutualFriends];
        
        if (3 <= filteredFriends.count) {
            NSArray *arrayThreeFriends = [self pullNumberOfFriends:3 fromFriends:filteredFriends];
            firstPerson = arrayThreeFriends[0];
            secondPerson = arrayThreeFriends[1];
            thirdPerson = arrayThreeFriends[2];
            
            numFriends = 3;
        } else if (2 == filteredFriends.count) {
            firstPerson = filteredFriends[0];
            secondPerson = filteredFriends[1];
            
            numFriends = 2;
        } else if (1 == filteredFriends.count) {
            firstPerson = filteredFriends[0];
            
            numFriends = 1;
        }
        
        // Update profile images
        if (1 <= numFriends) {
            NSURL *url = [NSURL URLWithString: [APIUtils imageUrlStringForUrlString:firstPerson.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
            [self.customImageViewOne configureWithText:firstPerson.displayName.firstLetter url:url];
            self.customImageViewOne.hidden = NO;
        }
        if (2 <= numFriends) {
            NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:secondPerson.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
            [self.customImageViewTwo configureWithText:secondPerson.displayName.firstLetter url:url];
            self.customImageViewTwo.hidden = NO;
        }
        if (3 <= numFriends) {
            NSURL *url = [NSURL URLWithString: [APIUtils imageUrlStringForUrlString:thirdPerson.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
            [self.customImageViewThree configureWithText:thirdPerson.displayName.firstLetter url:url];
            self.customImageViewThree.hidden = NO;
        }
        
        NSMutableString *mutableText = [[NSMutableString alloc] init];
        [mutableText appendFormat:@"%ld ", (long)mutualFriendCount];
        if (1 != filteredFriends.count) {
            [mutableText appendFormat:NSLocalizedString(@"mutual friends", nil)];
        } else if (0 < filteredFriends.count) {
            [mutableText appendFormat:NSLocalizedString(@"mutual friend", nil)];
        }
        
        NSRange boldRange = NSMakeRange(0, mutableText.length);
        
        if (1 == numFriends) {
            [mutableText appendFormat:@" including\n%@.", firstPerson.displayName];
        } else if (2 == numFriends) {
            [mutableText appendFormat:@" including %@ and %@.", firstPerson.displayName, secondPerson.displayName];
        } else if (3 == numFriends) {
            [mutableText appendFormat:@" including %@, %@, and %@.", firstPerson.displayName, secondPerson.displayName, thirdPerson.displayName];
        }
        
        // Font
        UIColor *foregroundColor = [UIColor colorWithRGBHex:0x14294b];
        
        UIFont *normalFont = [UIFont spc_regularSystemFontOfSize:14];
        UIFont *highlightedFont = [UIFont spc_mediumSystemFontOfSize:14];
        
        // Attributed text
        NSDictionary *normalAttributes = @{
                                           NSFontAttributeName: normalFont,
                                           NSForegroundColorAttributeName: foregroundColor,
                                           };
        NSDictionary *highlightedAttributes = @{
                                                NSFontAttributeName: highlightedFont,
                                                NSForegroundColorAttributeName: foregroundColor
                                                };
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:mutableText attributes:nil];
        [attributedText addAttributes:normalAttributes range:NSMakeRange(0, mutableText.length)];
        [attributedText addAttributes:highlightedAttributes range:boldRange];
        
        self.customTextLabel.attributedText = attributedText;
    }
    
    [self setNeedsLayout];
    [self configureWithCellStyle:cellStyle];
}

- (void)configureWithCellStyle:(SPCCellStyle)cellStyle {
    self.cellStyle = cellStyle;
    
    // Update top constraint
    self.backgroundViewTopConstraint.constant = (cellStyle != SPCCellStyleTop && cellStyle != SPCCellStyleSingle) ? 0.5 : 4;
}

#pragma mark - Private

+ (NSArray *)filterSpayceTeamFromFriends:(NSArray *)friends {
    NSMutableArray *filteredArray = [[NSMutableArray alloc] initWithArray:friends];
    
    // Loop through the array of friends until we find SpayceTeam
    Person *spayceTeam = nil;
    BOOL found = NO;
    for (NSUInteger index = 0; index < [friends count] && NO == found; ++index) {
        Person *person = [filteredArray objectAtIndex:index];
        if (NSOrderedSame == [person.handle caseInsensitiveCompare:kSPCSpayceTeamHandle]) {
            spayceTeam = person;
            found = YES;
        }
    }
    
    // If we set the spayceTeam variable, remove it from the array
    if (nil != spayceTeam) {
        [filteredArray removeObject:spayceTeam];
    }
    
    return [NSArray arrayWithArray:filteredArray];
}

- (NSArray *)pullNumberOfFriends:(u_int32_t)numberOfFriends fromFriends:(NSArray *)friends {
    NSArray *arrayFriendsRet = [[NSArray alloc] init];
    if (numberOfFriends >= friends.count) {
        arrayFriendsRet = friends;
    } else {
        NSMutableArray *arrayIndexes = [[NSMutableArray alloc] init];
        do
        {
            u_int32_t index = arc4random_uniform(numberOfFriends);
            if (![arrayIndexes containsObject:@(index)]) {
                [arrayIndexes addObject:@(index)];
            }
            
        } while (arrayIndexes.count < numberOfFriends);
        
        NSMutableArray *arrayFriends = [[NSMutableArray alloc] init];
        for (NSNumber *numberVal in arrayIndexes) {
            [arrayFriends addObject:[friends objectAtIndex:[numberVal unsignedIntValue]]];
        }
        
        arrayFriendsRet = arrayFriends;
    }
    return arrayFriendsRet;
}

@end
