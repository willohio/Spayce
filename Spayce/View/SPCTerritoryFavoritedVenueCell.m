//
//  SPCTerritoryFavoritedVenueCell.m
//  Spayce
//
//  Created by Jake Rosin on 11/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTerritoryFavoritedVenueCell.h"

// Model
#import "Venue.h"
#import "Asset.h"
#import "SPCVenueTypes.h"

// View
#import "UIImageView+WebCache.h"

NSString * SPCTerritoryFavoritedVenueTappedNotification = @"SPCTerritoryFavoritedVenueTappedNotification";

@implementation SPCTerritoryFavoritedVenueCellVenueTapped

@end

@interface SPCTerritoryFavoritedVenueCell()

@property (nonatomic, strong) UIView *favoritedVenueView1;
@property (nonatomic, strong) UIView *favoritedVenueView2;
@property (nonatomic, strong) UIView *favoritedVenueView3;

// content of these
@property (nonatomic, strong) UILabel *favoritedVenueLabel1;
@property (nonatomic, strong) UILabel *favoritedVenueLabel2;
@property (nonatomic, strong) UILabel *favoritedVenueLabel3;

@property (nonatomic, strong) UIImageView *favoritedVenueImage1;
@property (nonatomic, strong) UIImageView *favoritedVenueImage2;
@property (nonatomic, strong) UIImageView *favoritedVenueImage3;

@property (nonatomic, strong) UIView *favoritedVenueIconHolder1;
@property (nonatomic, strong) UIView *favoritedVenueIconHolder2;
@property (nonatomic, strong) UIView *favoritedVenueIconHolder3;

@property (nonatomic, strong) UIImageView *favoritedVenueIcon1;
@property (nonatomic, strong) UIImageView *favoritedVenueIcon2;
@property (nonatomic, strong) UIImageView *favoritedVenueIcon3;


@property (nonatomic, strong) NSArray *venues;

@end

@implementation SPCTerritoryFavoritedVenueCell

- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.frame = frame;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.favoritedVenueView1];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-15]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView1 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:(1.0/3.0) constant:-12]];
        
        
        [self.contentView addSubview:self.favoritedVenueView2];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView2 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView2 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-15]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView2 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:(1.0/3.0) constant:-12]];
    
        
        
        [self.contentView addSubview:self.favoritedVenueView3];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView3 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView3 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-15]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView3 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.favoritedVenueView3 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:(1.0/3.0) constant:-12]];
        
        
        // make sure subviews are available here
        [self favoritedVenueLabel1];
        [self favoritedVenueLabel2];
        [self favoritedVenueLabel3];
        
        [self favoritedVenueImage1];
        [self favoritedVenueImage2];
        [self favoritedVenueImage3];
        
        [self favoritedVenueIcon1];
        [self favoritedVenueIcon2];
        [self favoritedVenueIcon3];
    }
    return self;
}


#pragma mark - Accessors

- (UIView *)favoritedVenueView1 {
    if (!_favoritedVenueView1) {
        _favoritedVenueView1 = [self makeFavoritedVenueView];
        _favoritedVenueView1.tag = 1;
    }
    return _favoritedVenueView1;
}

- (UIView *)favoritedVenueView2 {
    if (!_favoritedVenueView2) {
        _favoritedVenueView2 = [self makeFavoritedVenueView];
        _favoritedVenueView2.tag = 2;
    }
    return _favoritedVenueView2;
}

- (UIView *)favoritedVenueView3 {
    if (!_favoritedVenueView3) {
        _favoritedVenueView3 = [self makeFavoritedVenueView];
        _favoritedVenueView3.tag = 3;
    }
    return _favoritedVenueView3;
}

- (UIView *)makeFavoritedVenueView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor whiteColor];
    view.layer.borderColor = [UIColor colorWithRGBHex:0xd9dee5].CGColor;
    view.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapVenue:)]];
    view.userInteractionEnabled = YES;
    
    return view;
}


- (UILabel *)favoritedVenueLabel1 {
    if (!_favoritedVenueLabel1) {
        _favoritedVenueLabel1 = [self makeFavoriteVenueLabelWithSuperview:self.favoritedVenueView1];
    }
    return _favoritedVenueLabel1;
}

- (UILabel *)favoritedVenueLabel2 {
    if (!_favoritedVenueLabel2) {
        _favoritedVenueLabel2 = [self makeFavoriteVenueLabelWithSuperview:self.favoritedVenueView2];
    }
    return _favoritedVenueLabel2;
}

- (UILabel *)favoritedVenueLabel3 {
    if (!_favoritedVenueLabel3) {
        _favoritedVenueLabel3 = [self makeFavoriteVenueLabelWithSuperview:self.favoritedVenueView3];
    }
    return _favoritedVenueLabel3;
}

- (UILabel *)makeFavoriteVenueLabelWithSuperview:(UIView *)superview {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = [UIColor colorWithRGBHex:0xacb6c7];
    label.font = [UIFont spc_mediumSystemFontOfSize:8];
    label.numberOfLines = 2;
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.75;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [superview addSubview:label];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-18]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-40]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(label.font.lineHeight * 2)]];
    
    return label;
}


- (UIImageView *)favoritedVenueImage1 {
    if (!_favoritedVenueImage1) {
        _favoritedVenueImage1 = [self makeFavoriteVenueImageViewWithSuperview:self.favoritedVenueView1];
    }
    return _favoritedVenueImage1;
}

- (UIImageView *)favoritedVenueImage2 {
    if (!_favoritedVenueImage2) {
        _favoritedVenueImage2 = [self makeFavoriteVenueImageViewWithSuperview:self.favoritedVenueView2];
    }
    return _favoritedVenueImage2;
}

- (UIImageView *)favoritedVenueImage3 {
    if (!_favoritedVenueImage3) {
        _favoritedVenueImage3 = [self makeFavoriteVenueImageViewWithSuperview:self.favoritedVenueView3];
    }
    return _favoritedVenueImage3;
}

- (UIImageView *)makeFavoriteVenueImageViewWithSuperview:(UIView *)superview {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.backgroundColor = [UIColor colorWithRGBHex:0xd9dee5];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [superview addSubview:imageView];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:3]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-6]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    
    return imageView;
}


- (UIView *)favoritedVenueIconHolder1 {
    if (!_favoritedVenueIconHolder1) {
        _favoritedVenueIconHolder1 = [self makeFavoriteVenueIconHolderViewWithSuperview:self.favoritedVenueView1 imageView:self.favoritedVenueImage1];
    }
    return _favoritedVenueIconHolder1;
}

- (UIView *)favoritedVenueIconHolder2 {
    if (!_favoritedVenueIconHolder2) {
        _favoritedVenueIconHolder2 = [self makeFavoriteVenueIconHolderViewWithSuperview:self.favoritedVenueView2 imageView:self.favoritedVenueImage2];
    }
    return _favoritedVenueIconHolder2;
}

- (UIView *)favoritedVenueIconHolder3 {
    if (!_favoritedVenueIconHolder3) {
        _favoritedVenueIconHolder3 = [self makeFavoriteVenueIconHolderViewWithSuperview:self.favoritedVenueView3 imageView:self.favoritedVenueImage3];
    }
    return _favoritedVenueIconHolder3;
}

- (UIView *)makeFavoriteVenueIconHolderViewWithSuperview:(UIView *)superview imageView:(UIImageView *)imageView {
    UIView *iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.backgroundColor = [UIColor whiteColor];
    iconView.layer.cornerRadius = 15;
    
    [superview addSubview:iconView];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:iconView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:iconView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:iconView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:iconView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30]];
    
    return iconView;
}


- (UIImageView *)favoritedVenueIcon1 {
    if (!_favoritedVenueIcon1) {
        _favoritedVenueIcon1 = [self makeFavoriteVenueIconViewWithSuperview:self.favoritedVenueIconHolder1];
    }
    return _favoritedVenueIcon1;
}

- (UIImageView *)favoritedVenueIcon2 {
    if (!_favoritedVenueIcon2) {
        _favoritedVenueIcon2 = [self makeFavoriteVenueIconViewWithSuperview:self.favoritedVenueIconHolder2];
    }
    return _favoritedVenueIcon2;
}

- (UIImageView *)favoritedVenueIcon3 {
    if (!_favoritedVenueIcon3) {
        _favoritedVenueIcon3 = [self makeFavoriteVenueIconViewWithSuperview:self.favoritedVenueIconHolder3];
    }
    return _favoritedVenueIcon3;
}

- (UIImageView *)makeFavoriteVenueIconViewWithSuperview:(UIView *)superview {
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    
    [superview addSubview:iconView];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:iconView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:iconView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:iconView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:16]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:iconView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:16]];
    
    return iconView;
}


#pragma mark - Configuration

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.favoritedVenueIcon1.image = nil;
    self.favoritedVenueIcon2.image = nil;
    self.favoritedVenueIcon3.image = nil;
    
    [self.favoritedVenueImage1 sd_cancelCurrentImageLoad];
    [self.favoritedVenueImage2 sd_cancelCurrentImageLoad];
    [self.favoritedVenueImage3 sd_cancelCurrentImageLoad];
    
    self.favoritedVenueImage1.image = nil;
    self.favoritedVenueImage2.image = nil;
    self.favoritedVenueImage3.image = nil;
}

- (void)configureWithVenues:(NSArray *)venues {
    self.venues = venues;
    
    for (int i = 0; i < 3 && i < venues.count; i++) {
        Venue *venue = venues[i];
        
        switch(i) {
            case 0:
                self.favoritedVenueView1.hidden = NO;
                self.favoritedVenueView1.userInteractionEnabled = YES;
                [self configureWithVenue:venue label:self.favoritedVenueLabel1 image:self.favoritedVenueImage1 icon:self.favoritedVenueIcon1];
                break;
            case 1:
                self.favoritedVenueView2.hidden = NO;
                self.favoritedVenueView2.userInteractionEnabled = YES;
                [self configureWithVenue:venue label:self.favoritedVenueLabel2 image:self.favoritedVenueImage2 icon:self.favoritedVenueIcon2];
                break;
            case 2:
                self.favoritedVenueView3.hidden = NO;
                self.favoritedVenueView3.userInteractionEnabled = YES;
                [self configureWithVenue:venue label:self.favoritedVenueLabel3 image:self.favoritedVenueImage3 icon:self.favoritedVenueIcon3];
                break;
        }
    }
    
    for (int i = (int)venues.count; i < 3; i++) {
        switch(i) {
            case 0:
                self.favoritedVenueView1.hidden = YES;
                self.favoritedVenueView1.userInteractionEnabled = NO;
                break;
            case 1:
                self.favoritedVenueView2.hidden = YES;
                self.favoritedVenueView2.userInteractionEnabled = NO;
                break;
            case 2:
                self.favoritedVenueView3.hidden = YES;
                self.favoritedVenueView3.userInteractionEnabled = NO;
                break;
        }
    }
}


- (void)configureWithVenue:(Venue *)venue label:(UILabel *)label image:(UIImageView *)image icon:(UIImageView *)icon {
    label.text = venue.displayNameTitle;
    Asset *asset = venue.bestImageAsset;
    if (asset) {
        [image sd_setImageWithURL:[NSURL URLWithString:asset.imageUrlThumbnail]];
    }
    image.image = [SPCVenueTypes headerImageForVenue:venue];
    icon.image = [SPCVenueTypes imageForVenue:venue withIconType:VenueIconTypeIconNewColor];
}


# pragma mark - Actions

- (void)didTapVenue:(id)sender {
    NSInteger index = ((UIGestureRecognizer *)sender).view.tag - 1;
    Venue *venue = self.venues[index];
    Memory *memory = venue.bestImageAssetMemory;
    UIImage *image = nil;
    CGRect rect;
    if (memory) {
        switch (index) {
            case 0:
                image = self.favoritedVenueImage1.image;
                rect = [self.favoritedVenueView1 convertRect:self.favoritedVenueImage1.frame toView:nil];
                break;
            case 1:
                image = self.favoritedVenueImage2.image;
                rect = [self.favoritedVenueView2 convertRect:self.favoritedVenueImage2.frame toView:nil];
                break;
            case 2:
                image = self.favoritedVenueImage3.image;
                rect = [self.favoritedVenueView3 convertRect:self.favoritedVenueImage3.frame toView:nil];
                break;
        }
    }
    SPCTerritoryFavoritedVenueCellVenueTapped *venueTapped = [[SPCTerritoryFavoritedVenueCellVenueTapped alloc] init];
    venueTapped.venue = venue;
    venueTapped.memoryDisplayed = memory;
    venueTapped.imageDisplayed = image;
    venueTapped.gridRect = rect;
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCTerritoryFavoritedVenueTappedNotification object:venueTapped];
}

@end
