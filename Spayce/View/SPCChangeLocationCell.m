//
//  SPCChangeLocationCell.m
//  Spayce
//
//  Created by Christopher Taylor on 10/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCChangeLocationCell.h"

@interface SPCChangeLocationCell()

@end

@implementation SPCChangeLocationCell

#pragma mark - Configuration

- (void)configureCellWithVenue:(Venue *)venue distance:(CGFloat)distance {
    self.venue = venue;
    
    if (venue.specificity == SPCVenueIsReal) {
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.image = [SPCVenueTypes imageForVenue:venue withIconType:VenueIconTypeIconNewColor];
        self.imageView.hidden = NO;
        self.textLabel.text = venue.displayNameTitle;
        self.detailTextLabel.text = [NSString detailedStringFromDistance:distance];
        self.starsLabel.text = venue.displayStarsCountString;
        self.memoriesLabel.text = venue.displayMemoriesCountString;
        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        self.topGrayPadding.hidden = YES;
        self.bottomGrayPadding.hidden = YES;
    }
    if (venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
        self.textLabel.text = [NSString stringWithFormat:@"%@, %@",venue.neighborhood,venue.city];
        self.imageView.image = [UIImage imageNamed:@"fuzzed-neigh-thumb"];
        self.detailTextLabel.text = @"Neighborhood Level";
        self.starsLabel.text = @"(for private places like home)";
        self.topGrayPadding.hidden = NO;
        self.bottomGrayPadding.hidden = NO;
    }
    if (venue.specificity == SPCVenueIsFuzzedToCity) {
        self.textLabel.text = [NSString stringWithFormat:@"%@, %@",venue.city,venue.country];
        self.imageView.image = [UIImage imageNamed:@"fuzzed-neigh-thumb"];
        self.detailTextLabel.text = @"City Level";
        self.starsLabel.text = @"(for private places like home)";
        self.topGrayPadding.hidden = NO;
        self.bottomGrayPadding.hidden = NO;
    }

    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    //image view
    float imgSize = 35;
    CGFloat topBottomGrayPaddingHeight = (self.topGrayPadding.hidden ? 0.0f : 10.0f) + (self.bottomGrayPadding.hidden ? 0.0f : 10.0f);
    float heightPadding = (self.contentView.frame.size.height - imgSize) / 2;
    float widthPadding = (self.contentView.frame.size.height - topBottomGrayPaddingHeight - imgSize) / 2;
    self.imageView.frame = CGRectMake(widthPadding + 5, heightPadding, imgSize, imgSize);

    // separator
    self.separator.frame = CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), 1.0f / [UIScreen mainScreen].scale);
    
    float specAdj = 0;
    
    if (self.venue.specificity > SPCVenueIsReal) {
        specAdj = 10;
         self.imageView.center = CGPointMake(40, CGRectGetHeight(self.contentView.bounds)/2);
    }
    
    self.textLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 25.0, 11 + specAdj, CGRectGetWidth(self.contentView.frame) - CGRectGetMaxX(self.imageView.frame) - 65, self.textLabel.font.lineHeight);
    
    // text
    self.detailTextLabel.frame = CGRectMake(CGRectGetMinX(self.textLabel.frame),
                                                CGRectGetMaxY(self.textLabel.frame),
                                                CGRectGetWidth(self.textLabel.frame),
                                                self.detailTextLabel.font.lineHeight);
    
    float starLabelWidth = [self widthForStarsLabel];
    if (SPCVenueIsReal < self.venue.specificity) {
        starLabelWidth = [self.starsLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.starsLabel.font }].width;
    }

    self.starsLabel.frame = CGRectMake(CGRectGetMinX(self.detailTextLabel.frame), CGRectGetMaxY(self.detailTextLabel.frame), starLabelWidth, self.starsLabel.font.lineHeight);
    CGFloat horizontalOffset = 12;

    self.memoriesLabel.frame = CGRectMake(CGRectGetMinX(self.detailTextLabel.frame) + CGRectGetWidth(self.starsLabel.frame) + horizontalOffset, CGRectGetMinY(self.starsLabel.frame), [self widthForMemoriesLabel], self.memoriesLabel.font.lineHeight);
    
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
                view.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - 21, top + 2, 16, 16);
                view.layer.cornerRadius = 8;
            }
            top += height;
        }
    }
}


@end
