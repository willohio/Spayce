//
//  SPCHighSpeedVenueCell.m
//  Spayce
//
//  Created by Christopher Taylor on 9/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHighSpeedVenueCell.h"
#import "Asset.h"
#import "UIImageView+WebCache.h"
#import "SPCVenueTypes.h"
#import "Memory.h"

@interface SPCHighSpeedVenueCell ()

@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *venueNameLabel;
@property (nonatomic, strong) UILabel *starCountLabel;
@property (nonatomic, strong) UILabel *memCountLabel;
@property (nonatomic, strong) UIImageView *venueIconImgView;
@property (nonatomic, strong) UIImageView *starIconImgView;
@property (nonatomic, strong) UIImageView *memoryIconImgView;
@end

@implementation SPCHighSpeedVenueCell


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 154, 154)];
        self.imageView.backgroundColor = [UIColor colorWithWhite:152.0f/255.0f alpha:1.0f];
        [self addSubview:self.imageView];
        
        UIView *bgLayer = [[UIView alloc] initWithFrame:CGRectMake(0, 110, 154, 44)];
        bgLayer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.2];
        [self addSubview:bgLayer];
        
        self.venueNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(41, 112, 100, 30)];
        self.venueNameLabel.text = @"Nearby Hotspot";
        self.venueNameLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
        self.venueNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12];
        [self addSubview:self.venueNameLabel];

        self.venueIconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        self.venueIconImgView.center = CGPointMake(20, 133);
        self.venueIconImgView.layer.cornerRadius = self.venueIconImgView.frame.size.width/2;
        self.venueIconImgView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.venueIconImgView.layer.borderWidth = 1;
        self.venueIconImgView.contentMode = UIViewContentModeCenter;
        [self addSubview:self.venueIconImgView];
        
        UIImage *memIconImg = [UIImage imageNamed:@"icon-solid-memory"];
        self.memoryIconImgView = [[UIImageView alloc] initWithImage:memIconImg];
        self.memoryIconImgView.center = CGPointMake(48, 143);
        [self addSubview:self.memoryIconImgView];

        self.memCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(59, 133, 100, 20)];
        self.memCountLabel.text = @"";
        self.memCountLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
        self.memCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        [self addSubview:self.memCountLabel];
        
        UIImage *starIconImg = [UIImage imageNamed:@"icon-solid-star"];
        self.starIconImgView = [[UIImageView alloc] initWithImage:starIconImg];
        self.starIconImgView.center = CGPointMake(100, 143);
        
        [self addSubview:self.starIconImgView];
        
        self.starCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(109, 133, 100, 20)];
        self.starCountLabel.text = @"";
        self.starCountLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
        self.starCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        [self addSubview:self.starCountLabel];
        
    }
    return self;
}

- (void)configureWithVenue:(Venue *)venue {
    
    if (venue.imageAsset) {
        NSString *imageUrlStr = [venue.imageAsset imageUrlHalfSquare];
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                     placeholderImage:nil
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                if (image){
                                    self.imageView.image = image;
                                }
                            }];
    } else if (venue.popularMemories.count > 0) {
        
        ImageMemory *imgMem = (ImageMemory *)venue.popularMemories[0];
        
        if (imgMem.images.count > 0){
            Asset *assImg = imgMem.images[0];
            NSString *imageUrlStr = [assImg imageUrlHalfSquare];
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                              placeholderImage:nil
                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                         if (image){
                                             self.imageView.image = image;
                                         }
                                     }];
        }
    }
    
    NSString *iconStr = [SPCVenueTypes imageNameForVenue:venue withIconType:VenueIconTypeIconWhite];
    self.venueIconImgView.image = [UIImage imageNamed:iconStr];
    self.venueIconImgView.backgroundColor = [SPCVenueTypes colorForVenue:venue];
    self.venueIconImgView.layer.borderColor = [SPCVenueTypes colorSecondaryForVenue:venue].CGColor;
    self.venueNameLabel.text = venue.displayName;
    self.memCountLabel.text = [NSString stringWithFormat:@"%@", @(venue.totalMemories)];
    self.starCountLabel.text = [NSString stringWithFormat:@"%@", @(venue.totalStars)];

}

@end
