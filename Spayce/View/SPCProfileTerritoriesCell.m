//
//  SPCProfileTerritoriesCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 8/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileTerritoriesCell.h"

// Model
#import "SPCCity.h"
#import "SPCNeighborhood.h"

@interface SPCProfileTerritoriesCell ()

// Data
@property (nonatomic, strong) NSArray *cities;
@property (nonatomic, strong) NSArray *neighborhoods;

// UI
@property (nonatomic, strong) UIView *customBackgroundView;
@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *titleSeparatorView;
@property (nonatomic, strong) UIView *cityView1;
@property (nonatomic, strong) UIView *cityView2;
@property (nonatomic, strong) UIView *neighborhoodView1;
@property (nonatomic, strong) UIView *neighborhoodView2;
@property (nonatomic, strong) UILabel *cityLabel1;
@property (nonatomic, strong) UILabel *cityLabel2;
@property (nonatomic, strong) UILabel *neighborhoodLabel1;
@property (nonatomic, strong) UILabel *neighborhoodLabel2;

@end

@implementation SPCProfileTerritoriesCell

#pragma mark - Object lifecycle

- (void)dealloc
{
    [self.cities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        @try {
            [obj removeObserver:self forKeyPath:@"thumbnailImage"];
        } @catch (NSException *exception) {}
    }];
    
    [self.neighborhoods enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        @try {
            [obj removeObserver:self forKeyPath:@"thumbnailImage"];
        } @catch (NSException *exception) {}
    }];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:230.0/255.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _customBackgroundView = [[UIView alloc] init];
        _customBackgroundView.backgroundColor = [UIColor whiteColor];
        _customBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _customBackgroundView.layer.masksToBounds = NO;
        _customBackgroundView.layer.cornerRadius = 2;
        _customBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
        _customBackgroundView.layer.shadowOpacity = 0.2;
        _customBackgroundView.layer.shadowRadius = 0.5;
        _customBackgroundView.layer.shadowOffset = CGSizeMake(0, 1);
        _customBackgroundView.layer.shouldRasterize = YES;
        _customBackgroundView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [self.contentView addSubview:_customBackgroundView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.clipsToBounds = YES;
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _customContentView.layer.cornerRadius = 2;
        [self.contentView addSubview:_customContentView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = NSLocalizedString(@"Territories", nil);
        _titleLabel.font = [UIFont spc_profileInfo_boldSectionFont];
        _titleLabel.textColor = [UIColor colorWithWhite:159.0/255.0 alpha:1.0];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_titleLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_titleLabel.font.lineHeight]];
        
        _titleSeparatorView = [[UIView alloc] init];
        _titleSeparatorView.backgroundColor = [UIColor colorWithWhite:231.0/255.0 alpha:1.0];
        _titleSeparatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_titleSeparatorView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleSeparatorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:35]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleSeparatorView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleSeparatorView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleSeparatorView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.5]];
        
        UILabel *citiesLabel = [[UILabel alloc] init];
        citiesLabel.font = [UIFont spc_lightFont];
        citiesLabel.text = NSLocalizedString(@"Cities", nil);
        citiesLabel.textAlignment = NSTextAlignmentCenter;
        citiesLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        citiesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:citiesLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:citiesLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_titleSeparatorView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:citiesLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:citiesLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:citiesLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:citiesLabel.font.lineHeight]];
        
        UILabel *neighborhoodsLabel = [[UILabel alloc] init];
        neighborhoodsLabel.font = [UIFont spc_lightFont];
        neighborhoodsLabel.text = NSLocalizedString(@"Neighborhoods", nil);
        neighborhoodsLabel.textAlignment = NSTextAlignmentCenter;
        neighborhoodsLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        neighborhoodsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:neighborhoodsLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:neighborhoodsLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_titleSeparatorView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:neighborhoodsLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:citiesLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:neighborhoodsLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:neighborhoodsLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:neighborhoodsLabel.font.lineHeight]];
        
        _cityView1 = [[UIView alloc] init];
        _cityView1.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_cityView1];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cityView1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:citiesLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cityView1 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cityView1 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cityView1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:65]];
        
        _cityLabel1 = [[UILabel alloc] init];
        _cityLabel1.font = [UIFont spc_regularFont];
        _cityLabel1.textAlignment = NSTextAlignmentCenter;
        _cityLabel1.textColor = [UIColor whiteColor];
        _cityLabel1.backgroundColor = [UIColor colorWithRed:136.0/255.0 green:146.0/255.0 blue:156.0/255.0 alpha:1.0];
        _cityLabel1.numberOfLines = 2;
        _cityLabel1.translatesAutoresizingMaskIntoConstraints = NO;
        [_cityView1 addSubview:_cityLabel1];
        [_cityView1 addConstraint:[NSLayoutConstraint constraintWithItem:_cityLabel1 attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_cityView1 attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_cityView1 addConstraint:[NSLayoutConstraint constraintWithItem:_cityLabel1 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_cityView1 attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_cityView1 addConstraint:[NSLayoutConstraint constraintWithItem:_cityLabel1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_cityView1 attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [_cityView1 addConstraint:[NSLayoutConstraint constraintWithItem:_cityLabel1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_cityView1 attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        
        _cityView2 = [[UIView alloc] init];
        _cityView2.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_cityView2];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cityView2 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_cityView1 attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cityView2 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_cityView1 attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cityView2 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_cityView1 attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cityView2 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_cityView1 attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        
        _cityLabel2 = [[UILabel alloc] init];
        _cityLabel2.font = [UIFont spc_regularFont];
        _cityLabel2.textAlignment = NSTextAlignmentCenter;
        _cityLabel2.textColor = [UIColor whiteColor];
        _cityLabel2.backgroundColor = [UIColor colorWithRed:161.0/255.0 green:178.0/255.0 blue:197.0/255.0 alpha:1.0];
        _cityLabel2.numberOfLines = 2;
        _cityLabel2.translatesAutoresizingMaskIntoConstraints = NO;
        [_cityView2 addSubview:_cityLabel2];
        [_cityView2 addConstraint:[NSLayoutConstraint constraintWithItem:_cityLabel2 attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_cityView2 attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_cityView2 addConstraint:[NSLayoutConstraint constraintWithItem:_cityLabel2 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_cityView2 attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_cityView2 addConstraint:[NSLayoutConstraint constraintWithItem:_cityLabel2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_cityView2 attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [_cityView2 addConstraint:[NSLayoutConstraint constraintWithItem:_cityLabel2 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_cityView2 attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        
        _neighborhoodView1 = [[UIView alloc] init];
        _neighborhoodView1.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_neighborhoodView1];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodView1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:neighborhoodsLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodView1 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodView1 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodView1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:65]];
        
        _neighborhoodLabel1 = [[UILabel alloc] init];
        _neighborhoodLabel1.font = [UIFont spc_regularFont];
        _neighborhoodLabel1.textAlignment = NSTextAlignmentCenter;
        _neighborhoodLabel1.textColor = [UIColor whiteColor];
        _neighborhoodLabel1.backgroundColor = [UIColor colorWithRed:224.0/255.0 green:220.0/255.0 blue:188.0/255.0 alpha:1.0];
        _neighborhoodLabel1.numberOfLines = 2;
        _neighborhoodLabel1.translatesAutoresizingMaskIntoConstraints = NO;
        [_neighborhoodView1 addSubview:_neighborhoodLabel1];
        [_neighborhoodView1 addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodLabel1 attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView1 attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_neighborhoodView1 addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodLabel1 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView1 attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_neighborhoodView1 addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodLabel1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView1 attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [_neighborhoodView1 addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodLabel1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView1 attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        
        _neighborhoodView2 = [[UIView alloc] init];
        _neighborhoodView2.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_neighborhoodView2];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodView2 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView1 attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodView2 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView1 attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodView2 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView1 attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodView2 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView1 attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        
        _neighborhoodLabel2 = [[UILabel alloc] init];
        _neighborhoodLabel2.font = [UIFont spc_regularFont];
        _neighborhoodLabel2.textColor = [UIColor whiteColor];
        _neighborhoodLabel2.textAlignment = NSTextAlignmentCenter;
        _neighborhoodLabel2.backgroundColor = [UIColor colorWithRed:218.0/255.0 green:207.0/255.0 blue:164.0/255.0 alpha:1.0];
        _neighborhoodLabel2.numberOfLines = 2;
        _neighborhoodLabel2.translatesAutoresizingMaskIntoConstraints = NO;
        [_neighborhoodView2 addSubview:_neighborhoodLabel2];
        [_neighborhoodView2 addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodLabel2 attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView2 attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_neighborhoodView2 addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodLabel2 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView2 attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_neighborhoodView2 addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodLabel2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView2 attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [_neighborhoodView2 addConstraint:[NSLayoutConstraint constraintWithItem:_neighborhoodLabel2 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_neighborhoodView2 attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    
    self.cityLabel1.text = nil;
    self.cityLabel2.text = nil;
    self.neighborhoodLabel1.text = nil;
    self.neighborhoodLabel2.text = nil;
}

#pragma mark - Configuration

- (void)configureWithCities:(NSArray *)cities neighborhoods:(NSArray *)neighborhoods {
    _cities = cities;
    _neighborhoods = neighborhoods;
    
    if (cities.count > 0) {
        SPCCity *city = cities[0];
        
        // Configure label
        self.cityLabel1.text = [city.cityFullName stringByAppendingFormat:@"\n\U00002605 %@", @(city.personalStarsInCity)];
    }
    if (cities.count > 1) {
        SPCCity *city = cities[1];
        
        // Configure label
        self.cityLabel2.text = [city.cityFullName stringByAppendingFormat:@"\n\U00002605 %@", @(city.personalStarsInCity)];
    }
    if (neighborhoods.count > 0) {
        SPCNeighborhood *neighborhood = neighborhoods[0];
        
        // Configure label
        self.neighborhoodLabel1.text = [neighborhood.neighborhood stringByAppendingFormat:@"\n\U00002605 %@", @(neighborhood.personalStarsInNeighborhood)];
    }
    if (neighborhoods.count > 1) {
        SPCNeighborhood *neighborhood = neighborhoods[1];
        
        // Configure label
        self.neighborhoodLabel2.text = [neighborhood.neighborhood stringByAppendingFormat:@"\n\U00002605 %@", @(neighborhood.personalStarsInNeighborhood)];
    }
}

@end
