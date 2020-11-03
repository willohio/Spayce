//
//  SPCPickLocationCell.m
//  Spayce
//
//  Created by Christopher Taylor on 1/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCPickLocationCell.h"

@implementation SPCPickLocationCell


#pragma mark - Configuration


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.imageView setContentMode:UIViewContentModeCenter];
        self.tintColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        
        self.textLabel.textColor = [UIColor colorWithRed:96.0f/255.0f green:115.0f/255.0f blue:145.0f/255.0f alpha:1.0f];
        self.textLabel.font = [UIFont spc_boldSystemFontOfSize:14];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.autoresizingMask = UIViewAutoresizingNone;
        self.textLabel.minimumScaleFactor = 0.75;
        
        self.separator = [[UIView alloc] init];
        self.separator.backgroundColor = [UIColor colorWithWhite:232.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:self.separator];
        
        self.spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(self.contentView.frame.size.width - 40, (self.contentView.frame.size.height - 25) / 2, 25, 25)];
        self.spinner.color = [UIColor darkGrayColor];
        self.spinner.hidden = YES;
        [self.contentView addSubview:self.spinner];
        
        self.autoresizesSubviews = NO;
        self.contentView.autoresizesSubviews = NO;
        self.topGrayPadding.hidden = YES;
        self.bottomGrayPadding.hidden = YES;
     
    }
    return self;
}

- (void)configureCellWithVenue:(Venue *)venue distance:(CGFloat)distance {
    self.venue = venue;
    
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.image = [SPCVenueTypes imageForVenue:venue withIconType:VenueIconTypeIconNewColor];
    self.imageView.hidden = NO;
    self.textLabel.text = venue.displayNameTitle;
    self.detailTextLabel.text = [NSString stringInFeetOrMilesFromDistanceWithRounding:venue.distanceAway];
    self.textLabel.textColor = [UIColor blackColor];
    self.textLabel.font = [UIFont spc_boldSystemFontOfSize:14];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
    
    [self setNeedsLayout];
}

-(void)configureCellWithTerritory:(SPCCity *)territory {
    self.territory = territory;
    
    if (territory.neighborhoodName) {
        self.textLabel.text = territory.neighborhoodName;
    }
    else {
        self.textLabel.text = territory.cityFullName;
    }
    
    
    if (territory.neighborhoodName.length > 0) {
        self.textLabel.text = [NSString stringWithFormat:@"%@, %@",territory.neighborhoodName,territory.cityFullName];
        
        if (territory.stateAbbr.length > 0 && [territory.countryAbbr isEqualToString:@"US"]) {
            self.textLabel.text = [NSString stringWithFormat:@"%@, %@  (%@)",territory.neighborhoodName,territory.cityFullName,territory.stateAbbr];
            
        }
    }
    else {
        self.textLabel.text = [NSString stringWithFormat:@"%@, %@",territory.cityFullName,territory.countryAbbr];
        
        if (territory.stateAbbr.length > 0 && [territory.countryAbbr isEqualToString:@"US"]) {
            self.textLabel.text = [NSString stringWithFormat:@"%@, %@",territory.cityFullName,territory.stateAbbr];
            
        }
    }
    
    self.imageView.image = nil;
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.image = [UIImage imageNamed:@"pickLocFuzzIcon"];
    self.imageView.hidden = NO;
    self.detailTextLabel.hidden = YES;
    self.textLabel.textColor = [UIColor blackColor];
    self.textLabel.font = [UIFont spc_boldSystemFontOfSize:14];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
    
    [self setNeedsLayout];
    
}


- (void)prepareForReuse {   
    [super prepareForReuse];
    self.imageView.image = nil;
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    self.separator.hidden = NO;
    if (!self.spinner.hidden) {
        [self.spinner stopAnimating];
        self.spinner.hidden = YES;
    }
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    //image view
    float imgSize = 16;
    
    // separator
    self.separator.frame = CGRectMake(0, CGRectGetHeight(self.contentView.frame)- 1.0f / [UIScreen mainScreen].scale, CGRectGetWidth(self.contentView.frame), 1.0f / [UIScreen mainScreen].scale);

    float heightPadding = (self.contentView.frame.size.height - imgSize) / 2;
    float widthPadding = 15;
    self.imageView.frame = CGRectMake(widthPadding, heightPadding, imgSize, imgSize);
    
    if (self.detailTextLabel.hidden) {
        self.textLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 15.0, (self.contentView.frame.size.height - self.textLabel.frame.size.height)/2, self.frame.size.width-85, self.textLabel.frame.size.height);
        
    }
    else {
        self.textLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 15.0, self.textLabel.frame.origin.y, self.frame.size.width-85, self.textLabel.frame.size.height);
        self.detailTextLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 15.0, self.detailTextLabel.frame.origin.y, self.detailTextLabel.frame.size.width, self.detailTextLabel.frame.size.height);
    }
    self.spinner.frame = CGRectMake(self.contentView.frame.size.width - 40, (self.contentView.frame.size.height - 25) / 2, 25, 25);;
    
    if (self.territory) {
        self.imageView.image = [UIImage imageNamed:@"pickLocFuzzIcon"];
    }
}

-(void)activateSpinner {
    [self.spinner startAnimating];
    self.spinner.hidden = NO;
}

@end
