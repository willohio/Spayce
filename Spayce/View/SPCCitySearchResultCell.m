//
//  SPCCitySearchResultCell.m
//  Spayce
//
//  Created by Christopher Taylor on 6/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCCitySearchResultCell.h"

#import "SPCTerritory.h"

@interface SPCCitySearchResultCell ()

@property (nonatomic, strong) UIView *clippingView;
@property (nonatomic,strong) UIView *separatorView;
@property (nonatomic, strong) UIImageView *thumbImgView;


@end

@implementation SPCCitySearchResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // use an extra clipping view and create an oversized map because otherwise only "legal" is visible in each thumbnail :/
        self.clippingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
        self.clippingView.layer.cornerRadius = self.clippingView.frame.size.height/2;
        self.clippingView.clipsToBounds = YES;
        self.clippingView.backgroundColor = [UIColor colorWithWhite:245.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:self.clippingView];
        
        self.thumbImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
        self.imageView.userInteractionEnabled = NO;
        self.thumbImgView.image = [UIImage imageNamed:@"placeholder-map"];
        [self.clippingView addSubview:self.thumbImgView];
        
        self.placeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 0, 250, 60)];
        self.placeNameLabel.font = [UIFont spc_boldSystemFontOfSize:14];
        self.placeNameLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:self.placeNameLabel];
        
        
        self.placeNameSubtitle = [[UILabel alloc] initWithFrame:CGRectMake(65, 0, 250, 60)];
        self.placeNameSubtitle.font = [UIFont spc_mediumSystemFontOfSize:14];
        self.placeNameSubtitle.textColor = [UIColor colorWithRed:172.0f/255.0f  green:182.0f/255.0f  blue:198.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:self.placeNameSubtitle];
    
        _separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-1, self.frame.size.width, 1)];
        _separatorView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:_separatorView];

    }
    return self;
}

-(void)prepareForReuse {
    self.placeNameLabel.text = @"";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.clippingView.frame = CGRectMake(10,
                                               CGRectGetMidY(self.contentView.frame) - CGRectGetHeight(self.clippingView.frame)/2,
                                               CGRectGetWidth(self.clippingView.frame),
                                               CGRectGetHeight(self.clippingView.frame));
  
    self.placeNameLabel.frame = CGRectMake(CGRectGetMaxX(self.clippingView.frame)+10, 10, 220, 20);
    [self.placeNameLabel sizeToFit];
    
    self.placeNameSubtitle.frame =  CGRectMake(CGRectGetMinX(self.placeNameLabel.frame), CGRectGetMaxY(self.placeNameLabel.frame)+3, 200, 15);
    
    self.separatorView.frame = CGRectMake(0, self.contentView.frame.size.height-1, self.frame.size.width, 1);
}

-(void)configureWithCity:(SPCCity *)city {
    
    self.thumbImgView.image = [UIImage imageNamed:@"city-result-thumb"];
    
    if ([city.countryAbbr isEqualToString:@"US"]) {
        self.placeNameLabel.text = [NSString stringWithFormat:@"%@, %@",city.cityFullName,city.stateAbbr];
        self.placeNameSubtitle.text = [NSString stringWithFormat:@"United States"];
    }
    else {
      
        self.placeNameLabel.text = [NSString stringWithFormat:@"%@",city.cityFullName];
        
        if (city.countryAbbr.length > 0) {
            NSString *tempCountry = [self countryNameForAbr:city.countryAbbr];
            self.placeNameSubtitle.text = [NSString stringWithFormat:@"%@",tempCountry];
        }
        
        if (city.countryAbbr.length > 0 && city.stateAbbr.length > 0) {
            NSString *tempCountry = [self countryNameForAbr:city.countryAbbr];
            self.placeNameSubtitle.text = [NSString stringWithFormat:@"%@, %@",city.stateAbbr,tempCountry];
        }
    }
}

-(void)updateForNeighborhood:(SPCCity *)city  {
    self.thumbImgView.image = [UIImage imageNamed:@"neighborhood-result-thumb"];
    
    self.placeNameLabel.text = [NSString stringWithFormat:@"%@",city.neighborhoodName];
    
    if (city.stateAbbr.length > 0 && city.cityName.length > 0 && city.countryAbbr) {
        self.placeNameSubtitle.text = [NSString stringWithFormat:@"%@, %@",city.cityFullName, city.countryAbbr];
          if ([city.countryAbbr isEqualToString:@"US"]) {
              self.placeNameSubtitle.text = [NSString stringWithFormat:@"%@, %@",city.cityFullName,city.stateAbbr];
          }
    }
    else if (city.cityName.length > 0 && city.countryAbbr) {
        self.placeNameSubtitle.text = [NSString stringWithFormat:@"%@, %@",city.cityFullName, city.countryAbbr];
    }
    else if (city.cityName.length > 0) {
        self.placeNameSubtitle.text = [NSString stringWithFormat:@"%@",city.cityFullName];
    }
}

-(NSString *)countryNameForAbr:(NSString *)abbr {
    return [SPCTerritory countryNameForCountryCode:abbr];
}

@end
