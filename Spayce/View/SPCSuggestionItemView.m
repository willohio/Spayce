//
//  SPCSuggestionItemView.m
//  Spayce
//
//  Created by Christopher Taylor on 10/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSuggestionItemView.h"
#import "Venue.h"
#import "Memory.h"
#import "UIImageView+WebCache.h"
#import "Asset.h"


@implementation SPCSuggestionItemView 


- (id)initWithVenue:(Venue *)v andFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor clearColor];
        
        float imgWidth = 60;
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            imgWidth =  70;
        }
                
        float imgOriginX = (self.frame.size.width - imgWidth)/2;
        self.picImageView = [[UIImageView alloc] initWithFrame:CGRectMake(imgOriginX, 0, imgWidth, imgWidth)];
        self.picImageView.backgroundColor = [UIColor lightGrayColor];
        self.picImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.picImageView.layer.borderWidth = 2;
        self.picImageView.layer.cornerRadius = self.picImageView.frame.size.height/2;
        self.picImageView.clipsToBounds = YES;
        self.picImageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.picImageView];
        
        self.cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, CGRectGetMaxY(self.picImageView.frame)+5, self.frame.size.width-4, 30)];
        self.cityLabel.text = @"";
        self.cityLabel.textAlignment = NSTextAlignmentCenter;
        self.cityLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        self.cityLabel.textColor = [UIColor colorWithRed:139.0f/255.0f  green:153.0f/255.0f  blue:175.0f/255.0f alpha:1.0f];
        self.cityLabel.numberOfLines = 0;
        self.cityLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.cityLabel];
        
        if (v.city) {
            self.cityLabel.text = v.city;
            [self.cityLabel sizeToFit];
            self.cityLabel.center = CGPointMake(self.picImageView.center.x, CGRectGetMaxY(self.picImageView.frame)+self.cityLabel.frame.size.height/2 + 6);
        }
        else {
            if (v.county) {
                self.cityLabel.text = v.county;
                [self.cityLabel sizeToFit];
                self.cityLabel.center = CGPointMake(self.picImageView.center.x, CGRectGetMaxY(self.picImageView.frame)+self.cityLabel.frame.size.height/2 + 6);
            }
            else {
                self.cityLabel.text = v.country;
                [self.cityLabel sizeToFit];
                self.cityLabel.center = CGPointMake(self.picImageView.center.x, CGRectGetMaxY(self.picImageView.frame)+self.cityLabel.frame.size.height/2 + 6);

            }
        }
   
        if (v) {
            self.venue = v;
            [self setImageForVenue:v];
        }
 }
    return self;
}


- (void)setImageForVenue:(Venue *)venue {
    Asset * asset = nil;
    //NSLog(@"setImageForVenue %@",venue.displayNameTitle);
    //NSLog(@"pop mems %@",venue.popularMemories);
    
    for (int i = 0; i < venue.popularMemories.count; i++) {
        if ([venue.popularMemories[i] isKindOfClass:[ImageMemory class]] && ((ImageMemory *)venue.popularMemories[i]).images.count > 0) {
            asset = ((ImageMemory *)venue.popularMemories[i]).images[0];
            //NSLog(@"got an asset!");
            break;
        }
    }
    
    if (asset) {
        //NSLog(@"load asset for venue %@.",venue.displayNameTitle);
        NSURL *assetURL = [NSURL URLWithString:[asset imageUrlThumbnail]];
        //NSLog(@"assetURL %@.",assetURL);
        [self.picImageView sd_setImageWithURL:assetURL
                                           placeholderImage:nil
                                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                      self.picImageView.image = image;
                                                      //NSLog(@"got image for venue %@.",venue.displayNameTitle);
                                                     
                                                  }];
    }
}

@end
