//
//  SPCRelationshipDetailCell/m
//  Spayce
//
//  Created by Arria P. Owlia on 3/18/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCRelationshipDetailCell.h"

NSString *SPCRelationshipDetailCellIdentifier = @"SPCRelationshipDetailCellIdentifier";

@interface SPCRelationshipDetailCell()

@property (strong, nonatomic) UIImageView *ivFollowDetailIcon;
@property (strong, nonatomic) UILabel *lblFollowDetail;

@end

@implementation SPCRelationshipDetailCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        _ivFollowDetailIcon = [[UIImageView alloc] init];
        _ivFollowDetailIcon.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_ivFollowDetailIcon];
        
        _lblFollowDetail = [[UILabel alloc] init];
        _lblFollowDetail.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10.0f];
        _lblFollowDetail.textColor = [UIColor colorWithWhite:0.0f alpha:0.2f];
        [self.contentView addSubview:_lblFollowDetail];
    }
    return self;
}

#pragma mark - Reuse

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.ivFollowDetailIcon.image = nil;
    self.lblFollowDetail.text = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    CGFloat leftRightPadding = 10.0f;
    
    // Adjust the checkmark
    self.ivFollowDetailIcon.frame = CGRectMake(0, 0, 8, 9);
    self.ivFollowDetailIcon.center = CGPointMake(leftRightPadding + self.ivFollowDetailIcon.image.size.width/2.0f, CGRectGetMidY(self.contentView.frame));
    
    // Adjust the label
    [self.lblFollowDetail sizeToFit];
    self.lblFollowDetail.center = CGPointMake(CGRectGetMaxX(self.ivFollowDetailIcon.frame) + 2.0f + CGRectGetWidth(self.lblFollowDetail.bounds)/2.0f, CGRectGetMidY(self.contentView.frame));
}

- (void)configureWithFollowingStatus:(FollowingStatus)followingStatus andFollowerStatus:(FollowingStatus)followerStatus {
    if (FollowingStatusRequested == followingStatus && FollowingStatusRequested == followerStatus) {
        self.ivFollowDetailIcon.image = [UIImage imageNamed:@"lock-gray-outline-x-small"];
        self.lblFollowDetail.text = NSLocalizedString(@"YOU REQUESTED", nil);
    } else if (FollowingStatusFollowing == followerStatus) {
        self.ivFollowDetailIcon.image = [UIImage imageNamed:@"check-gray-x-small"];
        self.lblFollowDetail.text = NSLocalizedString(@"FOLLOWS YOU", nil);
    }
}

@end
