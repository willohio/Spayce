//
//  SPCTerritoryCell.m
//  Spayce
//
//  Created by Jake Rosin on 11/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTerritoryCell.h"

// Model
#import "SPCCity.h"
#import "SPCNeighborhood.h"

@interface SPCTerritoryCell()

@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *starCountLabel;
@property (nonatomic, strong) UIImageView *mapImageView;
@property (nonatomic, strong) UIView *tintView;

@property (nonatomic, strong) UIView *separator;
@property (nonatomic, strong) UIImageView *expandCaret;

@end


@implementation SPCTerritoryCell



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor colorWithWhite:241.0/255.0 alpha:1.0];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _customContentView.layer.masksToBounds = YES;
        [self.contentView addSubview:_customContentView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        _mapImageView = [[UIImageView alloc] init];
        _mapImageView.contentMode = UIViewContentModeScaleAspectFill;
        _mapImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _mapImageView.layer.masksToBounds = YES;
        [_customContentView addSubview:_mapImageView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_mapImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_mapImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_mapImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_mapImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        
        _tintView = [[UIView alloc] init];
        _tintView.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_tintView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_tintView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_tintView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_tintView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_tintView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        
        
        _separator = [[UIView alloc] init];
        _separator.backgroundColor = [UIColor whiteColor];
        _separator.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_separator];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_separator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_separator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_separator attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(1.0 / [UIScreen mainScreen].scale)]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_separator attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-120]];
        
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.adjustsFontSizeToFitWidth = YES;
        _nameLabel.minimumScaleFactor = 0.75;
        _nameLabel.font = [UIFont fontWithName:@"AvenirNext-Bold" size:16];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_nameLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_nameLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_nameLabel.font.lineHeight]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_nameLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_nameLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_nameLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-6]];
        
        
        _typeLabel = [[UILabel alloc] init];
        _typeLabel.adjustsFontSizeToFitWidth = YES;
        _typeLabel.minimumScaleFactor = 0.75;
        _typeLabel.font = [UIFont spc_boldSystemFontOfSize:10];
        _typeLabel.textAlignment = NSTextAlignmentCenter;
        _typeLabel.textColor = [UIColor whiteColor];
        _typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_typeLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_typeLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_typeLabel.font.lineHeight]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_typeLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_typeLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_typeLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_nameLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-4]];
        
        
        _starCountLabel = [[UILabel alloc] init];
        _starCountLabel.adjustsFontSizeToFitWidth = YES;
        _starCountLabel.minimumScaleFactor = 0.75;
        _starCountLabel.font = [UIFont spc_boldSystemFontOfSize:10];
        _starCountLabel.textAlignment = NSTextAlignmentCenter;
        _starCountLabel.textColor = [UIColor whiteColor];
        _starCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_starCountLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starCountLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_starCountLabel.font.lineHeight]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starCountLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starCountLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starCountLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:7]];
        
        _expandCaret = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"territory-caret-down"]];
        _expandCaret.translatesAutoresizingMaskIntoConstraints = NO;
        _expandCaret.alpha = 0.7;
        [_customContentView addSubview:_expandCaret];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_expandCaret attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_expandCaret attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_starCountLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:7]];
        
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.typeLabel.text = nil;
    self.nameLabel.text = nil;
    self.starCountLabel.text = nil;
    
    self.imageView.image = nil;
}


# pragma mark - Configuration


- (void)configureWithCity:(SPCCity *)city cityNumber:(NSInteger)cityNumber expanded:(BOOL)expanded {
    NSString *typeText = [NSString stringWithFormat:@"CITY %i", (int)cityNumber+1];
    NSString *name = [NSString stringWithFormat:@"%@, %@", city.cityFullName,
                      (city.stateAbbr.length > 0 ? city.stateAbbr : city.countryAbbr)];
    NSString *starText = [NSString stringWithFormat:@"%i stars", (int)city.personalStarsInCity];
    
    NSString *locationSearchText = city.cityName;
    if (city.stateAbbr) {
        locationSearchText = [locationSearchText stringByAppendingString:[NSString stringWithFormat:@",%@", city.stateAbbr]];
    }
    if (city.countryAbbr) {
        locationSearchText = [locationSearchText stringByAppendingString:[NSString stringWithFormat:@",%@", city.countryAbbr]];
    }
    locationSearchText = [[[locationSearchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@"+"];
    
    UIColor *tintColor = [self tintColorForCityNumber:cityNumber];
    
    [self configureWithTypeText:typeText name:name starCountText:starText imageName:@"Territory_map_city" tintColor:tintColor expanded:expanded];
}

- (void)configureWithNeighborhood:(SPCNeighborhood *)neighborhood neighborhoodNumber:(NSInteger)neighborhoodNumber expanded:(BOOL)expanded {
    NSString *typeText = [NSString stringWithFormat:@"NEIGHBORHOOD %i", (int)neighborhoodNumber+1];
    NSString *name = [NSString stringWithFormat:@"%@", neighborhood.neighborhoodName];
    NSString *starText = [NSString stringWithFormat:@"%i stars", (int)neighborhood.personalStarsInNeighborhood];
    
    NSString *locationSearchText = neighborhood.neighborhood;
    if (neighborhood.cityName) {
        locationSearchText = [locationSearchText stringByAppendingString:[NSString stringWithFormat:@",%@", neighborhood.cityName]];
    }
    if (neighborhood.stateAbbr) {
        locationSearchText = [locationSearchText stringByAppendingString:[NSString stringWithFormat:@",%@", neighborhood.stateAbbr]];
    }
    if (neighborhood.countryAbbr) {
        locationSearchText = [locationSearchText stringByAppendingString:[NSString stringWithFormat:@",%@", neighborhood.countryAbbr]];
    }
    locationSearchText = [[[locationSearchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@"+"];
    
    UIColor *tintColor = [self tintColorForNeighborhoodNumber:neighborhoodNumber];
    
    [self configureWithTypeText:typeText name:name starCountText:starText imageName:@"Territory_map_neighborhood" tintColor:tintColor expanded:expanded];
}

- (void)configureWithTypeText:(NSString *)typeText name:(NSString *)name starCountText:(NSString *)starCountText imageName:(NSString *)imageName tintColor:(UIColor *)tintColor expanded:(BOOL)expanded {
    
    self.typeLabel.text = typeText;
    self.nameLabel.text = name;
    self.starCountLabel.text = starCountText;
    
    // tint color
    self.tintView.backgroundColor = tintColor;
    
    // Fetch map image
    self.mapImageView.image = [UIImage imageNamed:imageName];
    
    self.expandCaret.image = [UIImage imageNamed:(expanded ? @"territory-caret-up" : @"territory-caret-down")];
}


- (UIColor *)tintColorForCityNumber:(NSInteger)cityNumber {
    switch(cityNumber % 4) {
        case 0:
            return [UIColor colorWithRGBHex:0x7ab3ef alpha:0.8];
        case 1:
            return [UIColor colorWithRGBHex:0x4f9def alpha:0.8];
        case 2:
            return [UIColor colorWithRGBHex:0x084b90 alpha:0.8];
        case 3:
            return [UIColor colorWithRGBHex:0x1879de alpha:0.8];
    }
    return nil;
}

- (UIColor *)tintColorForNeighborhoodNumber:(NSInteger)neighborhoodNumber {
    switch(neighborhoodNumber % 5) {
        case 0:
            return [UIColor colorWithRGBHex:0x7f79d1 alpha:0.8];
        case 1:
            return [UIColor colorWithRGBHex:0x6259d1 alpha:0.8];
        case 2:
            return [UIColor colorWithRGBHex:0x130c6a alpha:0.8];
        case 3:
            return [UIColor colorWithRGBHex:0x39347a alpha:0.8];
        case 4:
            return [UIColor colorWithRGBHex:0x2f26a3 alpha:0.8];
    }
    return nil;
}


@end
