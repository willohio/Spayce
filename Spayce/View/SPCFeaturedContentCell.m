//
//  SPCFeaturedContentCell.m
//  Spayce
//
//  Created by Jake Rosin on 8/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFeaturedContent.h"
#import "SPCFeaturedContentCell.h"
#import "AFImageRequestOperation.h"
#import "Asset.h"
#import "Memory.h"
#import "Venue.h"
#import "SPCVenueTypes.h"
#import "ShadowedLabel.h"
#import "UIImage+FX.h"
#import "UIImageView+WebCache.h"
#import "SPCVenueTypes.h"

// Category
#import "NSString+SPCAdditions.h"

#define TEXT_SIZE 9


@interface SPCFeaturedContentCell()

@property (nonatomic, strong) AFImageRequestOperation *imageOperation;

@property (nonatomic, strong) SPCFeaturedContent *featuredContent;

// views
@property (nonatomic, strong) UIView *contentFrame;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *shadowOverlayView;

@property (nonatomic, strong) UIView * dropShadowView;
@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic, strong) UIImageView *pImgView;
@property (nonatomic, strong) UILabel *placeholderMsgLbl;
@property (nonatomic, strong) UILabel *placeholderTitle;
@property (nonatomic, strong) UIImageView *starPlaceholder;

@property (nonatomic, strong) UILabel *textLbl;

@property (nonatomic, strong) UIImageView *bouncingArrow;
@property (nonatomic, assign) BOOL loadedImage;
@property (nonatomic, assign) NSInteger multipleAttemptCount;

@property (nonatomic, strong) UIView *featuredOverlay;
@property (nonatomic, strong) UILabel *placeNameLabel;
@end

@implementation SPCFeaturedContentCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _dropShadowView = [[UIView alloc] initWithFrame:CGRectZero];
        _dropShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
        _dropShadowView.layer.shadowOffset = CGSizeMake(0, 1);
        _dropShadowView.layer.shadowRadius = 1;
        _dropShadowView.layer.shadowOpacity = 0.2f;
        _dropShadowView.layer.masksToBounds = NO;
        _dropShadowView.clipsToBounds = NO;
        [self addSubview:_dropShadowView];
        
        _contentFrame = [[UIView alloc] initWithFrame:CGRectZero];
        _contentFrame.backgroundColor = [UIColor colorWithWhite:1 alpha:1.0];
        _contentFrame.layer.cornerRadius = 2;
        _contentFrame.layer.masksToBounds = YES;
        _contentFrame.clipsToBounds = YES;
        [_dropShadowView addSubview:_contentFrame];
        
        _textLbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLbl.font = [UIFont spc_regularSystemFontOfSize:18];
        _textLbl.textColor = [UIColor colorWithRed:138.0f/255.0f green:142.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
        _textLbl.numberOfLines = 0;
        _textLbl.backgroundColor = [UIColor clearColor];
        _textLbl.textAlignment = NSTextAlignmentLeft;
        _textLbl.lineBreakMode = NSLineBreakByWordWrapping;
        [_contentFrame addSubview:_textLbl];
        
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [_contentFrame addSubview:_imageView];
        
        [_contentFrame addSubview:self.placeholderView];
        
        _featuredOverlay = [[UIView alloc] initWithFrame:CGRectZero];
        _featuredOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.4];
        _featuredOverlay.hidden = YES;
        [_contentFrame addSubview:_featuredOverlay];
        
        UILabel *featuredLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, 400, 15)];
        featuredLbl.text = @"Featured Memory";
        featuredLbl.font = [UIFont spc_regularSystemFontOfSize:12];
        featuredLbl.textColor = [UIColor whiteColor];
        featuredLbl.textAlignment = NSTextAlignmentLeft;
        [_featuredOverlay addSubview:featuredLbl];
        
        _placeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 22, 400, 15)];
        _placeNameLabel.text = @"";
        _placeNameLabel.font = [UIFont spc_boldSystemFontOfSize:12];
        _placeNameLabel.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _placeNameLabel.textAlignment = NSTextAlignmentLeft;
        [_featuredOverlay addSubview:_placeNameLabel];
    }
    return self;
}

-(UIImageView *)bouncingArrow {
    if (!_bouncingArrow) {
        _bouncingArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow-blue"]];
        _bouncingArrow.hidden = YES;
    }
    return _bouncingArrow;
}

-(UIView *)placeholderView   {
    if (!_placeholderView) {
        _placeholderView = [[UIView alloc] initWithFrame:self.bounds];
        _placeholderView.backgroundColor = [UIColor whiteColor];
        
        self.starPlaceholder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"big-gold-star"]];
        self.starPlaceholder.center = CGPointMake(_placeholderView.frame.size.width/2, _placeholderView.frame.size.height/3);
        
        self.placeholderTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.starPlaceholder.frame)+10, self.bounds.size.width, 20)];
        self.placeholderTitle.text = NSLocalizedString(@"Earn 2 Stars", nil);
        self.placeholderTitle.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14];
        self.placeholderTitle.textColor = [UIColor whiteColor];  //[UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        self.placeholderTitle.textAlignment = NSTextAlignmentCenter;
        
        self.placeholderMsgLbl.frame = CGRectMake(0, CGRectGetMaxY(self.placeholderTitle.frame), self.bounds.size.width, 40);
        
        
        self.pImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        self.pImgView.contentMode = UIViewContentModeScaleAspectFill;
        [_placeholderView addSubview:self.pImgView];
        
        UIView *overlay = [[UIView alloc] initWithFrame:self.pImgView.frame];
        overlay.backgroundColor= [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:.7];
        //[_placeholderView addSubview:overlay];
        
        
        float starOriginHeight = (_placeholderView.frame.size.height - 85) / 2;
        
        _starPlaceholder.center = CGPointMake(_placeholderView.frame.size.width/2, starOriginHeight);
        _placeholderTitle.frame = CGRectMake(0, CGRectGetMaxY(self.starPlaceholder.frame)+10, self.bounds.size.width, 20);
        _placeholderMsgLbl.frame = CGRectMake(0, CGRectGetMaxY(self.placeholderTitle.frame), self.bounds.size.width, 40);
        

        
        [_placeholderView addSubview:self.starPlaceholder];
        [_placeholderView addSubview:self.placeholderTitle];
        [_placeholderView addSubview:self.placeholderMsgLbl];
        
        [_placeholderView addSubview:self.bouncingArrow];
        
        _placeholderView.hidden = YES;
    }
    return _placeholderView;
}

-(UILabel *)placeholderMsgLbl {
    if (!_placeholderMsgLbl) {
        _placeholderMsgLbl = [[UILabel alloc] init];
        _placeholderMsgLbl.text = NSLocalizedString(@"Make the first memory here\nand leave your mark.", nil);
        _placeholderMsgLbl.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
        _placeholderMsgLbl.textColor = [UIColor whiteColor];//[UIColor colorWithRed:194.0f/255.0f green:200.0f/255.0f blue:208.0f/255.0f alpha:1.0f];
        _placeholderMsgLbl.textAlignment = NSTextAlignmentCenter;
        _placeholderMsgLbl.numberOfLines = 0;
        _placeholderMsgLbl.lineBreakMode = NSLineBreakByWordWrapping;

    }
    return _placeholderMsgLbl;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _dropShadowView.frame = self.bounds;    
    _contentFrame.frame = self.bounds;
    _imageView.frame = self.bounds;
    _textLbl.frame = CGRectMake(15, 5, self.bounds.size.width-30, self.bounds.size.height-10);
    
    _featuredOverlay.frame = CGRectMake(0, self.bounds.size.height - 45, self.bounds.size.width, 45);
   
}

#pragma mark - UICollectionReusableView - Reusing Cells

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear venue etc.
    self.featuredContent = nil;
    
    // TODO: clear view content
    _imageView.image = nil;
    _loadedImage = NO;
    _multipleAttemptCount = 0;
    
    // HIDE VIEWS
    _placeholderView.hidden = YES;
    _placeholderMsgLbl.text = NSLocalizedString(@"Make the first memory here\nand leave your mark.", nil);
    _bouncingArrow.hidden = YES;
    _textLbl.hidden = YES;
    _textLbl.textAlignment = NSTextAlignmentLeft;
    _textLbl.font = [UIFont spc_regularSystemFontOfSize:18];
    
    if ([UIScreen mainScreen].bounds.size.width >= 375) {
        _textLbl.font = [UIFont spc_regularSystemFontOfSize:24];
    }
    
    float starOriginHeight = (_placeholderView.frame.size.height - 85) / 2;
    
    _starPlaceholder.center = CGPointMake(_placeholderView.frame.size.width/2, starOriginHeight);
    _placeholderTitle.frame = CGRectMake(0, CGRectGetMaxY(self.starPlaceholder.frame)+10, self.bounds.size.width, 20);
    _placeholderMsgLbl.frame = CGRectMake(0, CGRectGetMaxY(self.placeholderTitle.frame), self.bounds.size.width, 40);
    _featuredOverlay.hidden = YES;
}

#pragma mark - configure

-(void)configureWithFeaturedContent:(SPCFeaturedContent *)featuredContent {
    // TODO: configure err'thing
    //NSLog(@"configitall for venue %@ and type %li",featuredContent.venue.displayNameTitle,featuredContent.contentType);
    
    self.featuredContent = featuredContent;
    _placeholderView.hidden = YES;
    
    // set placeholder content
    switch (featuredContent.contentType) {
        case FeaturedContentPlaceholder:
            
            self.pImgView.image = [UIImage imageNamed:@"placeholder-featured-content"];//[SPCVenueTypes headerImageForVenue:featuredContent.venue];

            if (featuredContent.venue.totalMemories > 0) {
                
                float starOriginHeight = (_placeholderView.frame.size.height - 105) / 2;
                
                _starPlaceholder.center = CGPointMake(_placeholderView.frame.size.width/2, starOriginHeight);
                _placeholderTitle.frame = CGRectMake(0, CGRectGetMaxY(self.starPlaceholder.frame)+10, self.bounds.size.width, 20);
                _placeholderMsgLbl.frame = CGRectMake(0, CGRectGetMaxY(self.placeholderTitle.frame), self.bounds.size.width, 40);

                self.placeholderMsgLbl.text = NSLocalizedString(@"Be the first to leave\na public memory.", nil);
            }
            
            
            
            
            _placeholderView.hidden = NO;
            break;
        case FeaturedContentText: {
            _textLbl.hidden = NO;
            if (self.featuredContent.memory.text.length > 0) {
                _textLbl.text = self.featuredContent.memory.text;
               
                if (_textLbl.text.length < 40) {
                    _textLbl.font = [UIFont spc_regularSystemFontOfSize:25];
                    
                    if ([UIScreen mainScreen].bounds.size.width >= 375) {
                        _textLbl.font = [UIFont spc_regularSystemFontOfSize:36];
                    }
                }
                if (_textLbl.text.length < 20) {
                    _textLbl.textAlignment = NSTextAlignmentCenter;
                }
            
                if (_textLbl.text.length < 8) {
                    _textLbl.font = [UIFont spc_regularSystemFontOfSize:30];
                    
                    if ([UIScreen mainScreen].bounds.size.width >= 375) {
                        _textLbl.font = [UIFont spc_regularSystemFontOfSize:40];
                    }
                }
                
            }
            break;
        }
        default:
            break;
    }

    Asset *asset = [self assetForFeaturedContent:featuredContent];
    if (asset) {
        [self getimageForAsset:asset];
    }
    
    if ((featuredContent.contentType == FeaturedContentFeaturedMemory) && featuredContent.venue.distanceAway > 300) {
        
        //show overlay treatment
        _featuredOverlay.hidden = NO;
        
        if (featuredContent.venue.city.length > 0 && featuredContent.venue.state.length > 0){
            self.placeNameLabel.text = [NSString stringWithFormat:@"%@, %@",featuredContent.venue.city,featuredContent.venue.state];
        }
        else if (featuredContent.venue.city.length > 0 ) {
            self.placeNameLabel.text = featuredContent.venue.city;
        } else {
            self.placeNameLabel.text = @"Spayce";
        }
    }
}

- (void)updatOffsetAdjustment:(float)offsetAdj {
    _dropShadowView.center = CGPointMake(self.bounds.size.width/2 + offsetAdj, self.bounds.size.height/2);
}

-(void)getimageForAsset:(Asset *)asset {
    
    NSString *imageUrlStr = [asset imageUrlSquare];
    [self.imageView sd_cancelCurrentImageLoad];
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                      placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 
                                 //NSLog(@"sd cache callback complete...");
                                 
                                 if (image) {
                                     //NSLog(@"got featured image from %@",imageURL);
                                     if (asset.assetID == [self assetForFeaturedContent:self.featuredContent].assetID) {
                                         //NSLog(@"setting featured image - cell still matches image");
                                         self.imageView.image = image;
                                         self.loadedImage = YES;
                                         
                                         if (self.delegate && [self.delegate respondsToSelector:@selector(imageLoadComplete)]) {
                                             [self.delegate imageLoadComplete];
                                         }
                                     }
                                 }
                                 else {
                                     //NSLog(@"uh oh, try again..");
                                     if (self.multipleAttemptCount < 5) {
                                         self.multipleAttemptCount++;
                                         [self getimageForAsset:asset];
                                     }
                                 }
                             }];
}

#pragma mark - Actions
-(void)displayAndAnimateArrow {
    //self.bouncingArrow.hidden = NO;
    //[self animateArrow];
    

}
-(void)hideBouncingArrow {
    //self.bouncingArrow.hidden = YES;
}

-(void)forceFeature {
    //show overlay treatment
    _featuredOverlay.hidden = NO;
    
    if (self.featuredContent.venue.city.length > 0 && self.featuredContent.venue.state.length > 0){
        self.placeNameLabel.text = [NSString stringWithFormat:@"%@, %@",self.featuredContent.venue.city,self.featuredContent.venue.state];
    }
    else if (self.featuredContent.venue.city.length > 0 ) {
        self.placeNameLabel.text = self.featuredContent.venue.city;
    } else {
        self.placeNameLabel.text = @"Spayce";
    }
}

#pragma mark - Private

-(void)fallbackImageLoad {
    
    if (!self.loadedImage) {
        //NSLog(@"fallback..");
        Asset *asset = [self assetForFeaturedContent:self.featuredContent];
        if (asset) {
            //NSLog(@"asset exists..get the image!");
            [self getimageForAsset:asset];
        }
    }
    else {
        //NSLog(@"already has image..");
    }
}



- (Asset *)assetForFeaturedContent:(SPCFeaturedContent *)featuredContent {
    switch (featuredContent.contentType) {
        case FeaturedContentFeaturedMemory:
        case FeaturedContentPopularMemoryHere:
            return [self assetForMemory:featuredContent.memory];
        case FeaturedContentVenueNearby:
            return [self assetForVenue:featuredContent.venue];
        case FeaturedContentPlaceholder:
            return nil;
        case FeaturedContentText:
            return nil;
    }
    return nil;
}

- (Asset *)assetForMemory:(Memory *)memory {
    if ([memory isKindOfClass:[ImageMemory class]]) {
        ImageMemory *imageMemory = (ImageMemory *)memory;
        if (imageMemory.images.count > 0) {
            return imageMemory.images[0];
        }
    } else if ([memory isKindOfClass:[VideoMemory class]]) {
        VideoMemory *videoMemory = (VideoMemory *)memory;
        if (videoMemory.previewImages.count > 0) {
            return videoMemory.previewImages[0];
        }
    }
    return memory.locationMainPhotoAsset;
}

- (Asset *)assetForVenue:(Venue *)venue {
    // attempt a memory first...
    if (venue.popularMemories.count > 0) {
        for (Memory *memory in venue.popularMemories) {
            if ([memory isKindOfClass:[ImageMemory class]]) {
                ImageMemory *imageMemory = (ImageMemory *)memory;
                if (imageMemory.images.count > 0) {
                    return imageMemory.images[0];
                }
            } else if ([memory isKindOfClass:[VideoMemory class]]) {
                VideoMemory *videoMemory = (VideoMemory *)memory;
                if (videoMemory.previewImages.count > 0) {
                    return videoMemory.previewImages[0];
                }
            }
        }
    }
    
    return venue.imageAsset;
}

-(NSString *)textForCount:(NSInteger)count {
    if (count < 1000) {
        return [NSString stringWithFormat:@"%ld", (long)count];
    } else if (count < 10000) {
        return [NSString stringWithFormat:@"%ld.%ldk", (long)count / 1000, ((long)count % 1000)/100];
    } else if (count < 1000000) {
        return [NSString stringWithFormat:@"%ldk", (long)count / 1000];
    } else if (count < 10000000) {
        return [NSString stringWithFormat:@"%ld.%ldM", (long)count / 1000000, ((long)count % 1000000)/100];
    } else {
        return [NSString stringWithFormat:@"%ldM", (long)count / 1000000];
    }
}

- (void)animateArrow {
    if (_bouncingArrow) {
        
        _bouncingArrow.center = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)-30);
        [UIView animateWithDuration:1.2
                              delay:0.0
                            options: UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                         animations:^{
                             _bouncingArrow.center = CGPointMake(_bouncingArrow.center.x, _bouncingArrow.center.y+10);
                         }
                         completion:NULL];
    }
}

@end
