//
//  SPCLocationCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 5/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCLocationCell.h"

// Model
#import "ProfileDetail.h"
#import "UserProfile.h"
#import "AFImageRequestOperation.h"

// Manager
#import "ContactAndProfileManager.h"

const NSInteger spc_LOCATION_CELL_BADGE_CURRENT = 0x1;
const NSInteger spc_LOCATION_CELL_BADGE_DEVICE = 0x2;
const NSInteger spc_LOCATION_CELL_BADGE_FAVORITED = 0x4;
const NSInteger spc_LOCATION_CELL_BADGE_GOLD_STAR = 0x8;
const NSInteger spc_LOCATION_CELL_BADGE_SILVER_STAR = 0x10;
const NSInteger spc_LOCATION_CELL_BADGE_BRONZE_STAR = 0x20;

@interface SPCLocationCell ()

@property (nonatomic, strong) AFImageRequestOperation * profileImageOperation;

@end

@implementation SPCLocationCell

#pragma mark - NSObject - Responding to Being Loaded from a Nib File

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.imageView setContentMode:UIViewContentModeCenter];
        
        self.textLabel.textColor = [UIColor colorWithRed:96.0f/255.0f green:115.0f/255.0f blue:145.0f/255.0f alpha:1.0f];
        self.textLabel.font = [UIFont spc_boldSystemFontOfSize:14];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = 0.75;
        
        self.detailTextLabel.textColor = [UIColor colorWithRGBHex:0x8b99af];
        self.detailTextLabel.font = [UIFont spc_mediumSystemFontOfSize:12];
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.detailTextLabel.minimumScaleFactor = 0.75;
        
        self.separator = [[UIView alloc] init];
        self.separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        [self.contentView addSubview:self.separator];
        
        self.starsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.starsLabel.textColor =  [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        self.starsLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        [self.contentView addSubview:self.starsLabel];
        
        self.memoriesLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.memoriesLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        self.memoriesLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        [self.contentView addSubview:self.memoriesLabel];
        
        self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.distanceLabel.textColor = [UIColor colorWithRed:96.0f/255.0f green:115.0f/255.0f blue:145.0f/255.0f alpha:1.0f];
        self.distanceLabel.font = [UIFont spc_mediumSystemFontOfSize:12];
        self.distanceLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.distanceLabel];
        
        // Up to 3 badge views...
        NSMutableArray * badgeViewsMut = [[NSMutableArray alloc] initWithCapacity:3];
        for (int i = 0; i < 3; i++) {
            UIImageView * view = [[UIImageView alloc] init];
            view.contentMode = UIViewContentModeCenter;
            view.clipsToBounds = YES;
            [self.contentView addSubview:view];
            [badgeViewsMut addObject:view];
        }
        self.badgeViews = [NSArray arrayWithArray:badgeViewsMut];
        
        self.topGrayPadding = [[UIView alloc] init];
        self.topGrayPadding.backgroundColor = [UIColor colorWithRGBHex:0xf8f8f8];
        [self.contentView addSubview:self.topGrayPadding];
        
        self.bottomGrayPadding = [[UIView alloc] init];
        self.bottomGrayPadding.backgroundColor = [UIColor colorWithRGBHex:0xf8f8f8];
        [self.contentView addSubview:self.bottomGrayPadding];
    }
    return self;
}

#pragma mark - UITableViewCell - Reusing Cells

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.imageView.image = nil;
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    self.separator.hidden = YES;
    self.starsLabel.text = nil;
    self.memoriesLabel.text = nil;
    self.distanceLabel.text = nil;
    for (UIImageView * view in self.badgeViews) {
        view.image = nil;
    }
    
    self.topGrayPadding.hidden = YES;
    self.bottomGrayPadding.hidden = YES;
    
    [self.profileImageOperation cancel];
    self.profileImageOperation = nil;
}

#pragma mark - Layout

- (CGFloat)widthForStarsLabel {
    CGFloat maxWidth = CGRectGetWidth(self.detailTextLabel.frame) / 2.0 - 6.0;
    CGRect boundingRect = [self.starsLabel.text boundingRectWithSize:CGSizeMake(320.0, self.starsLabel.font.lineHeight) options:NSStringDrawingTruncatesLastVisibleLine attributes:@{ NSFontAttributeName: self.starsLabel.font } context:nil];
    return MIN(maxWidth, boundingRect.size.width);
}

- (CGFloat)widthForMemoriesLabel {
    CGFloat maxWidth = CGRectGetWidth(self.detailTextLabel.frame) / 2.0 - 6.0;
    CGRect boundingRect = [self.memoriesLabel.text boundingRectWithSize:CGSizeMake(320.0, self.memoriesLabel.font.lineHeight) options:NSStringDrawingTruncatesLastVisibleLine attributes:@{ NSFontAttributeName: self.memoriesLabel.font } context:nil];
    return MIN(maxWidth, boundingRect.size.width);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL tall = (self.contentView.frame.size.height > 60);
    
    if (self.venue && self.venue.specificity == SPCVenueIsReal) {
        self.imageView.image = [SPCVenueTypes largeImageForVenue:self.venue withIconType:VenueIconTypeIconNewColor];
    }
    if (self.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
        self.imageView.image = [UIImage imageNamed:@"fuzzed-neigh-thumb"];
    }
    if (self.venue.specificity == SPCVenueIsFuzzedToCity) {
        NSLog(@"fuzzed city, set imagE!");
        self.imageView.image = [UIImage imageNamed:@"fuzzed-neigh-thumb"];
    }
    
    self.imageView.frame = CGRectMake(0.0, 0.0, self.imageView.image.size.width, self.imageView.image.size.height);
    self.imageView.center = CGPointMake(40, CGRectGetHeight(self.contentView.bounds)/2);

    
    // separator
    self.separator.frame = CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), 0.5);
    
    // text views
    if (self.venue.specificity > 0) { // If the specificity is fuzzed city/neighborhood
        self.textLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 25.0, 26, CGRectGetWidth(self.contentView.frame) - CGRectGetMaxX(self.imageView.frame) - 65, self.textLabel.font.lineHeight);
        // text
        self.detailTextLabel.frame = CGRectMake( CGRectGetMinX(self.textLabel.frame),
                                                CGRectGetMaxY(self.textLabel.frame),
                                                CGRectGetWidth(self.textLabel.frame),
                                                self.detailTextLabel.font.lineHeight);
        self.starsLabel.frame = CGRectZero;
        self.memoriesLabel.frame = CGRectZero;
    }
    else {
        BOOL showsStars = self.starsLabel.text.length > 0 && tall;
        BOOL showsMemories = self.memoriesLabel.text.length > 0 && tall;
        BOOL showsDistance = self.distanceLabel.text.length > 0 && self.badgeCount == 0;
        
        self.textLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 30.0, 11, CGRectGetWidth(self.contentView.frame) - CGRectGetMaxX(self.imageView.frame) - 65, self.textLabel.font.lineHeight);
        
        self.detailTextLabel.frame = CGRectMake(
                                                CGRectGetMaxX(self.imageView.frame) + 30.0,
                                                CGRectGetMaxY(self.textLabel.frame) - 1.5,
                                                CGRectGetWidth(self.contentView.frame) - CGRectGetMaxX(self.imageView.frame) - 65.0,
                                                self.detailTextLabel.font.lineHeight);
        
        if (showsStars) {
            self.starsLabel.frame = CGRectMake(CGRectGetMinX(self.detailTextLabel.frame), CGRectGetMaxY(self.detailTextLabel.frame) + 1.5, [self widthForStarsLabel], self.starsLabel.font.lineHeight);
        }
        if (showsMemories) {
            CGFloat horizontalOffset = (showsStars) ? 12.0 : 0.0;
            self.memoriesLabel.frame = CGRectMake(CGRectGetMinX(self.detailTextLabel.frame) + CGRectGetWidth(self.starsLabel.frame) + horizontalOffset, CGRectGetMaxY(self.detailTextLabel.frame) + 1.5, [self widthForMemoriesLabel], self.memoriesLabel.font.lineHeight);
        }
        if (showsDistance) {
            self.distanceLabel.center = CGPointMake(CGRectGetWidth(self.contentView.frame) - CGRectGetWidth(self.distanceLabel.frame)/2 - 10, CGRectGetHeight(self.contentView.frame)/2);
        }
    }
    
    // badge views
    if (self.badgeCount > 0) {
        CGFloat height = 20;
        CGFloat totalHeight = height * self.badgeCount;
        CGFloat top = CGRectGetMidY(self.contentView.bounds) - totalHeight / 2;
        for (int i = 0; i < self.badgeCount; i++) {
            UIImageView * view = self.badgeViews[i];
            if (view.contentMode == UIViewContentModeCenter) {
                view.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - 30, top, height, height);
            } else {
                // make exactly 12 by 12
                view.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - 21, top + 4, 12, 12);
                view.layer.cornerRadius = 6;
            }
            top += height;
        }
    }
    
    // Top and bottom gray padding
    CGFloat paddingHeight = 10.0f / [UIScreen mainScreen].scale;
    self.topGrayPadding.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), paddingHeight);
    self.bottomGrayPadding.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - paddingHeight, CGRectGetWidth(self.bounds), paddingHeight);
}

- (void)setHasSeparator:(BOOL)hasSeparator {
    _separator.hidden = !hasSeparator;
}

- (BOOL)hasSeparator {
    return !_separator.hidden;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    UIColor *backgroundColor = self.imageView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    self.imageView.backgroundColor = backgroundColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    UIColor *backgroundColor = self.imageView.backgroundColor;
    [super setSelected:selected animated:animated];
    self.imageView.backgroundColor = backgroundColor;
}

#pragma mark - Configuration

- (void)configureCellWithVenue:(Venue *)venue badges:(NSInteger)badges {
    self.venue = venue;
    
    if (venue.specificity == SPCVenueIsReal) {
        self.imageView.backgroundColor = [SPCVenueTypes colorForVenue:venue];
        self.imageView.image = [SPCVenueTypes largeImageForVenue:venue withIconType:VenueIconTypeIconNewColor];
        self.imageView.hidden = NO;
        self.textLabel.text = venue.displayNameTitle;
        self.detailTextLabel.text = [NSString stringInFeetFromDistance:venue.distanceAway];
        self.starsLabel.text = venue.displayStarsCountString;
        self.memoriesLabel.text = venue.displayMemoriesCountString;
        self.topGrayPadding.hidden = YES;
        self.bottomGrayPadding.hidden = YES;
    }
    if (venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
        self.textLabel.text = [NSString stringWithFormat:@"%@, %@",venue.neighborhood,venue.city];
        self.imageView.image = [UIImage imageNamed:@"fuzzed-neigh-thumb"];
        self.detailTextLabel.text = @"Neighborhood Level";
        self.topGrayPadding.hidden = NO;
        self.bottomGrayPadding.hidden = NO;
    }
    if (venue.specificity == SPCVenueIsFuzzedToCity) {
        self.textLabel.text = [NSString stringWithFormat:@"%@, %@",venue.city,venue.country];
        self.imageView.image = [UIImage imageNamed:@"fuzzed-neigh-thumb"];
        self.detailTextLabel.text = @"City Level";
        self.topGrayPadding.hidden = NO;
        self.bottomGrayPadding.hidden = NO;
    }
    
    
    [self setBadges:badges];
    [self setNeedsLayout];
}

- (void)setBadges:(NSInteger)badges {
    for (UIImageView * view in self.badgeViews) {
        view.image = nil;
        view.hidden = YES;
        view.layer.masksToBounds = NO;
        view.layer.cornerRadius = 0.0;
        view.contentMode = UIViewContentModeCenter;
    }
    [self.profileImageOperation cancel];
    
    int count = 0;
    while (count < 2 && badges) {
        
        if (badges && self.venue.favorited) {
            UIImageView * view = self.badgeViews[count];
            view.image = [UIImage imageNamed:@"badge-heart"];
            view.hidden = NO;
            badges ^= spc_LOCATION_CELL_BADGE_FAVORITED;
            count++;
        }
        
        if (badges & spc_LOCATION_CELL_BADGE_GOLD_STAR) {
            UIImageView * view = self.badgeViews[count];
            view.image = [UIImage imageNamed:@"badge-location-gold-star"];
            view.hidden = NO;
            badges ^= spc_LOCATION_CELL_BADGE_GOLD_STAR;
            count++;
        } else if (badges & spc_LOCATION_CELL_BADGE_SILVER_STAR) {
            UIImageView * view = self.badgeViews[count];
            view.image = [UIImage imageNamed:@"badge-location-silver-star"];
            view.hidden = NO;
            badges ^= spc_LOCATION_CELL_BADGE_SILVER_STAR;
            count++;
        } else if (badges & spc_LOCATION_CELL_BADGE_BRONZE_STAR) {
            UIImageView * view = self.badgeViews[count];
            view.image = [UIImage imageNamed:@"badge-location-bronze-star"];
            view.hidden = NO;
            badges ^= spc_LOCATION_CELL_BADGE_BRONZE_STAR;
            count++;
        }
    }
    self.badgeCount = count;
}

@end
