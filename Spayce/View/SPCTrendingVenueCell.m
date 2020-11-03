//
//  SPCTrendingVenueCell.m
//  Spayce
//
//  Created by Jake Rosin on 7/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTrendingVenueCell.h"

// Model
#import "Memory.h"
#import "Venue.h"
#import "Asset.h"
#import "SPCVenueTypes.h"

// Category
#import "NSString+SPCAdditions.h"

// View
#import "UIImageView+WebCache.h"

// Utils
#import "SPCTerritory.h"


const static CGFloat IMAGE_FADE_TIME = 0.5f;

@interface SPCTrendingVenueCell()


@property (nonatomic, strong) UIView * backdropView;
@property (nonatomic, strong) UIImageView *imageLoadView;

@property (nonatomic, strong) CAGradientLayer * gradientLayer;
@property (nonatomic, strong) UILabel * captionLabel;
@property (nonatomic, strong) UILabel * memoryCountLabel;
@property (nonatomic, strong) UILabel * starCountLabel;

@property (nonatomic, strong) UIImageView * pinClockIconView;
@property (nonatomic, strong) UIImageView * memoryImageView;
@property (nonatomic, strong) UIImageView * starImageView;
@property (nonatomic, strong) UIImageView * venueTypeImageView;


@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL wasShowingText;


@end

@implementation SPCTrendingVenueCell

+(BOOL)venue:(Venue *)venue1 isEquivalentTo:(Venue *)venue2 {
    // Two venues are equivalent if they are displayed in exactly the same way.
    BOOL same = YES;
    // text
    same = same && [SPCTrendingVenueCell string:venue1.venueName isEquivalentTo:venue2.venueName];
    same = same && [SPCTrendingVenueCell string:venue1.neighborhood isEquivalentTo:venue2.neighborhood];
    same = same && [SPCTrendingVenueCell string:venue1.city isEquivalentTo:venue2.city];
    same = same && [SPCTrendingVenueCell string:venue1.state isEquivalentTo:venue2.state];
    same = same && [SPCTrendingVenueCell string:venue1.country isEquivalentTo:venue2.country];
    
    // numbers
    same = same && [[NSString stringByTruncatingInteger:venue1.totalMemories] isEqualToString:[NSString stringByTruncatingInteger:venue2.totalMemories]];
    same = same && [[NSString stringByTruncatingInteger:venue1.totalStars] isEqualToString:[NSString stringByTruncatingInteger:venue2.totalStars]];
    
    // icon
    same = same && [SPCVenueTypes typeForVenue:venue1] == [SPCVenueTypes typeForVenue:venue2];
    
    // images
    same = same && venue1.imageAsset.assetID == venue2.imageAsset.assetID;
    same = same && venue1.popularMemories.count == venue2.popularMemories.count;
    for (int i = 0; i < venue1.popularMemories.count && same; i++) {
        NSInteger asset1 = venue1.imageAsset.assetID;
        NSInteger asset2 = venue2.imageAsset.assetID;
        if ([venue1.popularMemories[i] isKindOfClass:[ImageMemory class]]) {
            ImageMemory * imem = (ImageMemory *)venue1.popularMemories[i];
            asset1 = imem.images.count > 0 ? [imem.images[0] assetID] : asset1;
        }
        if ([venue2.popularMemories[i] isKindOfClass:[ImageMemory class]]) {
            ImageMemory * imem = (ImageMemory *)venue2.popularMemories[i];
            asset2 = imem.images.count > 0 ? [imem.images[0] assetID] : asset2;
        }
        same = same && asset1 == asset2;
    }
    
    return same;
}

+(BOOL)memory:(Memory *)memory1 isEquivalentTo:(Memory *)memory2 {
    // Two venues are equivalent if they are displayed in exactly the same way.
    BOOL same = YES;
    // text
    Venue *venue1 = memory1.venue;
    Venue *venue2 = memory2.venue;
    same = same && [SPCTrendingVenueCell string:venue1.venueName isEquivalentTo:venue2.venueName];
    same = same && [SPCTrendingVenueCell string:venue1.neighborhood isEquivalentTo:venue2.neighborhood];
    same = same && [SPCTrendingVenueCell string:venue1.city isEquivalentTo:venue2.city];
    same = same && [SPCTrendingVenueCell string:venue1.state isEquivalentTo:venue2.state];
    same = same && [SPCTrendingVenueCell string:venue1.country isEquivalentTo:venue2.country];
    
    // numbers
    same = same && [[NSString stringByTruncatingInteger:venue1.totalMemories] isEqualToString:[NSString stringByTruncatingInteger:venue2.totalMemories]];
    same = same && [[NSString stringByTruncatingInteger:venue1.totalStars] isEqualToString:[NSString stringByTruncatingInteger:venue2.totalStars]];
    
    // icon
    same = same && [SPCVenueTypes typeForVenue:venue1] == [SPCVenueTypes typeForVenue:venue2];
    
    // images
    same = same && [memory1.key isEqualToString:memory2.key];
    
    return same;
}

+(BOOL)string:(NSString *)string1 isEquivalentTo:(NSString *)string2 {
    if (!string1 && !string2) {
        return YES;
    }
    return [string1 isEqualToString:string2];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
        
        
        self.backdropView = [[UIView alloc] init];
        self.backdropView.backgroundColor = [UIColor colorWithRGBHex:0x2d3747];
        
        self.imageView = [[UIImageView alloc] init];
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        
        self.imageLoadView = [[UIImageView alloc] init];
        self.imageLoadView.backgroundColor = [UIColor clearColor];
        self.imageLoadView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageLoadView.clipsToBounds = YES;
        
        self.textMemView = [[UIView alloc] init];
        self.textMemView.backgroundColor = [UIColor colorWithRed:138.0f/255.0f green:192.0f/255.0f blue:249.0f/255.0f alpha:1.0f];
        self.textMemView.alpha = 0;
        
        self.textMemLbl = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textMemLbl.textColor = [UIColor whiteColor];
        self.textMemLbl.backgroundColor = [UIColor clearColor];
        self.textMemLbl.font = [UIFont spc_regularSystemFontOfSize:14];
        self.textMemLbl.numberOfLines = 0;
        self.textMemLbl.lineBreakMode = NSLineBreakByWordWrapping;
        self.textMemLbl.textAlignment = NSTextAlignmentLeft;
        
        self.gradientOverlayView = [[UIView alloc] init];
        self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.35f];
        
        self.captionLabel = [[UILabel alloc] init];
        self.captionLabel.textAlignment = NSTextAlignmentCenter;
        self.captionLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:12];
        self.captionLabel.textColor = [UIColor whiteColor];
        self.captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.captionLabel.numberOfLines = 0;
        
        self.timeDistanceDetailLabel = [[UILabel alloc] init];
        self.timeDistanceDetailLabel.textAlignment = NSTextAlignmentCenter;
        self.timeDistanceDetailLabel.textColor = [UIColor whiteColor];
        self.timeDistanceDetailLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:.3];
        self.timeDistanceDetailLabel.layer.cornerRadius = 6;
        
        self.memoryCountLabel = [[UILabel alloc] init];
        self.memoryCountLabel.textAlignment = NSTextAlignmentLeft;
        self.memoryCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
        self.memoryCountLabel.textColor = [UIColor colorWithRGBHex:0xaeb5c0];
        self.memoryCountLabel.text = @"0";
        
        self.starCountLabel = [[UILabel alloc] init];
        self.starCountLabel.textAlignment = NSTextAlignmentLeft;
        self.starCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
        self.starCountLabel.textColor = [UIColor colorWithRGBHex:0xaeb5c0];
        self.starCountLabel.text = @"0";
        
        self.anonBadgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"anon-badge"]];
        self.anonBadgeView.frame = CGRectMake(10.0f, 10.0f, 30.0f, 30.0f);
        self.anonBadgeView.alpha = 0.0f;
        
        // load the memory and star images
        self.pinClockIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin-clock"]];
        self.pinClockIconView.contentMode = UIViewContentModeCenter;
        self.memoryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-solid-memory"]];
        self.starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-solid-star"]];
        self.venueTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 19.0, 15.0)];
        
        // Add to the view
        [self addSubview:self.backdropView];
        [self addSubview:self.imageView];
        [self addSubview:self.textMemView];
        [self.textMemView addSubview:self.textMemLbl];
        
        [self addSubview:self.gradientOverlayView];
        [self addSubview:self.captionLabel];
        [self addSubview:self.timeDistanceDetailLabel];
        //[self addSubview:self.pinClockIconView];
        [self addSubview:self.anonBadgeView];
        //[self addSubview:self.memoryCountLabel];
        //[self addSubview:self.starCountLabel];
        //[self addSubview:self.memoryImageView];
        //[self addSubview:self.starImageView];
        //[self addSubview:self.venueTypeImageView];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    const CGFloat GRADIENT_OPAQUE_HEIGHT_PX = 45.0f / 315.0f * CGRectGetHeight(self.bounds);
    
    // Image and gradient
    self.backdropView.frame = self.bounds;
    self.imageView.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
    self.textMemView.frame = self.imageView.frame;
    self.textMemLbl.frame = CGRectMake(8, 9, self.bounds.size.width - 16, self.bounds.size.height - 18 - GRADIENT_OPAQUE_HEIGHT_PX);
    self.gradientOverlayView.frame = CGRectMake(0.0, self.bounds.size.height - GRADIENT_OPAQUE_HEIGHT_PX, self.bounds.size.width, GRADIENT_OPAQUE_HEIGHT_PX);
    
    // Text (initial position for those whose widths we adjust)

    
  
    self.captionLabel.center = CGPointMake(self.gradientOverlayView.center.x, self.gradientOverlayView.center.y);
    
    // for crisp text:
    [self.captionLabel setFrame:CGRectIntegral(self.captionLabel.frame)];
    
    [self layoutDetailRow];
}

-(void)layoutDetailRow {
    
    // Get the Time/Distance Label size, we need its size for ensuring the place information text is within bounds
    CGSize timeDistanceSize = [self.timeDistanceDetailLabel.attributedText size];
    
    // Now, set the Time/Distance's frame
    self.timeDistanceDetailLabel.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - (timeDistanceSize.width + 5), 0, timeDistanceSize.width + 5, timeDistanceSize.height + 5);
    
    const CGFloat GRADIENT_OPAQUE_HEIGHT_PX = 45.0f / 315.0f * CGRectGetHeight(self.bounds);
    
    if (self.captionLabel.frame.size.height > self.captionLabel.font.lineHeight * 2) {
        self.gradientOverlayView.frame = CGRectMake(0.0, self.bounds.size.height - (GRADIENT_OPAQUE_HEIGHT_PX + 20), self.bounds.size.width, GRADIENT_OPAQUE_HEIGHT_PX + 20);
        self.captionLabel.center = CGPointMake(self.gradientOverlayView.center.x, self.gradientOverlayView.center.y);
    }
    
    // These next lines ensure the frames have integral values, making the text look crisp
    [self.timeDistanceDetailLabel setFrame:CGRectIntegral(self.timeDistanceDetailLabel.frame)];
}


#pragma mark - Accessors

- (Memory *)memoryDisplayed {
    if (self.memory) {
        return self.memory;
    }
    NSInteger index = self.venueImageDisplayedMemoryIndex >= 0 ? self.venueImageDisplayedMemoryIndex : self.venueImageMemoryIndex;
    return [self memoryAtIndex:index];
}

- (Memory *)memoryAtIndex:(NSInteger)index {
    if (self.venue && index >= 0 && index < self.venue.popularMemories.count) {
        return self.venue.popularMemories[index];
    }
    return nil;
}


#pragma mark - UICollectionViewCell - Managing the Cell’s State

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.backgroundColor = (selected) ? [UIColor colorWithWhite:0.9 alpha:1.0] : [UIColor whiteColor];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    self.backgroundColor = (highlighted) ? [UIColor colorWithWhite:0.9 alpha:1.0] : [UIColor whiteColor];
}

#pragma mark - UICollectionReusableView - Reusing Cells

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.layer removeAllAnimations];
    if (self.delegate && [self.delegate respondsToSelector:@selector(removeCellFromCycledListWithTag:)]){
        [self.delegate removeCellFromCycledListWithTag:self.tag];
    }
    
    // Cancel image operation
    [self cancelImageOperation];
    
    // Clear venue etc.
    self.venue = nil;
    self.venueImageMemoryIndex = -1;
    self.venueImageDisplayedMemoryIndex = -1;
    self.textMemView.alpha = 0;
    
    // Clear display values
    self.imageView.image = nil;
    self.imageLoadView.image = nil;
    self.captionLabel.text = nil;
    self.memoryCountLabel.text = @"0";
    self.starCountLabel.text = @"0";
    if (!self.isHashMem) {
        self.timeDistanceDetailLabel.attributedText = nil;
    }
    self.wasShowingText = NO;
    self.venueTypeImageView.image = nil;
    self.pinClockIconView.hidden = NO;
    self.anonBadgeView.alpha = 0.0f;
}


#pragma mark - configure

-(BOOL)isConfigured {
    return self.venue != nil || self.memory != nil;
}

-(BOOL)isMemory {
    return self.memory != nil;
}

-(void)configureWithMemory:(Memory *)memory isLocal:(BOOL)isLocal {
    self.venue = nil;
    self.memory = memory;
    
    
    NSDictionary *timeDistanceAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor],
                                              NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:10.0f] };
    NSString *timeDistanceText = memory.timeElapsedSinceFeatured;
    
    if (!self.isHashMem) {
        self.timeDistanceDetailLabel.attributedText = [[NSAttributedString alloc] initWithString:timeDistanceText attributes:timeDistanceAttributes];
    }
    
    self.captionLabel.text = memory.text;
    self.captionLabel.frame = CGRectMake(10, self.bounds.size.height - CGRectGetHeight(self.gradientOverlayView.frame) + 4.0f, self.bounds.size.width - 20.0f, self.captionLabel.font.lineHeight * 2.1);
    [self.captionLabel sizeToFit];

    if (self.captionLabel.frame.size.height > self.captionLabel.font.lineHeight * 2) {
        self.captionLabel.frame = CGRectMake(10, self.bounds.size.height - (self.captionLabel.font.lineHeight * 2.1) - 30.0f, self.bounds.size.width - 20.0f, self.captionLabel.font.lineHeight * 2.1);
    }
    
    self.gradientOverlayView.hidden = NO;
    self.captionLabel.hidden = NO;
    
    if (memory.text.length == 0) {
        self.gradientOverlayView.hidden = YES;
    }
    if (self.memory.type == MemoryTypeText) {
        self.gradientOverlayView.hidden = YES;
        self.captionLabel.hidden = YES;
    }
    
    // Set the initial image.
    [self setImageForMemory:memory animated:YES];
    
   
    [self setNeedsLayout];
}


-(void)configureWithVenue:(Venue *)venue isLocal:(BOOL)isLocal {
    self.memory = nil;
    self.venue = venue;
    self.venueImageMemoryIndex = venue.popularMemories.count > 0 ? 0 : -1;
    self.venueImageDisplayedMemoryIndex = self.venueImageMemoryIndex;
    
    self.memoryCountLabel.text = [NSString stringByTruncatingInteger:venue.totalMemories];
    self.starCountLabel.text = [NSString stringByTruncatingInteger:venue.totalStars];
    self.venueTypeImageView.image = [SPCVenueTypes imageForVenue:venue withIconType:VenueIconTypeIconSmallColor];
    
    if (venue.recentHashtagMemories.count > 0) {
        
        int index = self.venueImageMemoryIndex;
        if (index < 0){
            index = 0;
        }
        
        Memory *mem = venue.recentHashtagMemories[index];
        self.captionLabel.text = mem.text;
        self.captionLabel.frame = CGRectMake(10, self.bounds.size.height - CGRectGetHeight(self.gradientOverlayView.frame) + 4.0f, self.bounds.size.width - 20.0f, self.captionLabel.font.lineHeight * 2.1);
        [self.captionLabel sizeToFit];
        
        if (self.captionLabel.frame.size.height > self.captionLabel.font.lineHeight * 2) {
            self.captionLabel.frame = CGRectMake(10, self.bounds.size.height - (self.captionLabel.font.lineHeight * 2.1) - 30.0f, self.bounds.size.width - 20.0f, self.captionLabel.font.lineHeight * 2.1);
        }
        
        self.gradientOverlayView.hidden = NO;
        self.captionLabel.hidden = NO;
        
        if (mem.text.length == 0) {
            self.gradientOverlayView.hidden = YES;
        }
        if (mem.type == MemoryTypeText) {
            self.gradientOverlayView.hidden = YES;
            self.captionLabel.hidden = YES;
        }
    }
    
    // Set the initial image.
    [self setImageForVenue:venue memoryIndex:self.venueImageMemoryIndex animated:YES];
    
    [self setNeedsLayout];
}


-(BOOL)cycleImageAnimated:(BOOL)animated {
    if (self.venue && self.venueImageMemoryIndex >= 0 && self.venue.popularMemories.count > 1) {
        self.venueImageMemoryIndex = (self.venueImageMemoryIndex + 1) % self.venue.popularMemories.count;
        [self setImageForVenue:self.venue memoryIndex:self.venueImageMemoryIndex animated:animated];
        return YES;
    }
    return NO;
}

-(void)resetCycleImage {
    if (self.isAnimating) {
        if (self.venue && self.venueImageMemoryIndex >= 0 && self.venue.popularMemories.count > 1) {
            [self setImageForVenue:self.venue memoryIndex:self.venueImageMemoryIndex animated:YES];
        }
    }
}

-(BOOL)canAnimateCell{
    if (self.venue && self.venueImageMemoryIndex >= 0 && self.venue.popularMemories.count > 1) {
        return YES;
    }
    return NO;
}

- (void)cancelImageOperation {
    [self.imageLoadView sd_cancelCurrentImageLoad];
    self.imageLoadView.image = nil;
}

-(void)loadImageWithUrl:(NSURL *)url
         resultCallback:(void (^)(UIImage *))resultCallback
          faultCallback:(void (^)(NSError *fault))faultCallback {
    [self.imageLoadView sd_cancelCurrentImageLoad];
    [self.imageLoadView sd_setImageWithURL:url placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (image) {
            if (resultCallback) {
                resultCallback(image);
            }
        } else {
            if (faultCallback) {
                faultCallback(error);
            }
        }
    }];
}


#pragma mark - Private



- (void)setImageForVenue:(Venue *)venue memoryIndex:(NSInteger)memoryIndex animated:(BOOL)animated {
    Asset * asset = nil;
    //NSLog(@"set image for venue %@ %li",venue.displayName,venue.addressId);
    
    if (venue.popularMemories.count == 0 || memoryIndex >= venue.popularMemories.count) {
        //NSLog(@"no popular memories! or the index is greater than the pop mem count!");
        //NSLog(@"venue.popularMems %@",venue.popularMemories);
        
        asset = venue.imageAsset;
    }
    if ([venue.popularMemories[memoryIndex] isKindOfClass:[ImageMemory class]] && ((ImageMemory *)venue.popularMemories[memoryIndex]).images.count > 0) {
        //NSLog(@"we should have an asset!");
        asset = ((ImageMemory *)venue.popularMemories[memoryIndex]).images[0];
    }
    
    if ([venue.popularMemories[memoryIndex] isKindOfClass:[VideoMemory class]] && ((VideoMemory *)venue.popularMemories[memoryIndex]).previewImages.count > 0) {
        //NSLog(@"handling vid mem in the grid!");
        asset = ((VideoMemory *)venue.popularMemories[memoryIndex]).previewImages[0];
    }
    
    if (asset) {
        //NSLog(@"loading asset %d", asset.assetID);
        [self loadImageWithUrl:[NSURL URLWithString:asset.imageUrlHalfSquare] resultCallback:^(UIImage *image) {
            //NSLog(@"asset is loaded!");
            if (venue == self.venue) {
                [self setImage:image animated:animated displayedMemoryIndex:memoryIndex];
            }
        } faultCallback:^(NSError *fault) {
            [self setImage:nil animated:animated displayedMemoryIndex:memoryIndex];
        }];
    }
    
    //handle text mems
    
    if ([venue.popularMemories[memoryIndex] isKindOfClass:[Memory class]] && ((Memory *)venue.popularMemories[memoryIndex]).type == MemoryTypeText) {
        //NSLog(@"handling text mem in the grid!");
        Memory *mem = (Memory *)venue.popularMemories[memoryIndex];
        self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.05f];
        CGFloat anonBadgeFinalAlpha = mem.isAnonMem ? 1.0f : 0.0f;
        
        if (self.imageView.image) {
            //NSLog(@"animating from an image mem to a text mem!");
            [self.imageView.layer removeAllAnimations];
            self.imageView.alpha = 1.0f;
            UIImage * oldImage = self.imageView.image;
            
            [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                self.imageView.alpha = 0.0f;
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished && self.imageView.image == oldImage) {
                    [self updateTextStyling:mem.text];
                    [UIView animateWithDuration:.5 animations:^{
                        self.textMemView.alpha = 1;
                        self.wasShowingText = YES;
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                    } completion:^(BOOL finished) {
                        self.imageView.image = nil;
                        self.venueImageDisplayedMemoryIndex = memoryIndex;
                    }];
                }
            }];
        } else {
            //NSLog(@"animating from a text mem to a text mem!");
            [self.imageView.layer removeAllAnimations];
            self.imageView.alpha = 0.0f;
            [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished) {
                    [self updateTextStyling:mem.text];
                    [UIView animateWithDuration:.5 animations:^{
                        self.textMemView.alpha = 1;
                        self.wasShowingText = YES;
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                    }completion:^(BOOL finished) {
                        self.imageView.image = nil;
                        self.venueImageDisplayedMemoryIndex = memoryIndex;
                    }];
                }
            }];
        }
    }
    
}


- (void)setImageForMemory:(Memory *)memory animated:(BOOL)animated {
    Asset * asset = nil;
    //NSLog(@"set image for venue %@ %li",venue.displayName,venue.addressId);
    if ([memory isKindOfClass:[ImageMemory class]] && ((ImageMemory *)memory).images.count > 0) {
        //NSLog(@"we should have an asset!");
        asset = ((ImageMemory *)memory).images[0];
    }
    
    if ([memory isKindOfClass:[VideoMemory class]] && ((VideoMemory *)memory).previewImages.count > 0) {
        //NSLog(@"handling vid mem in the grid!");
        asset = ((VideoMemory *)memory).previewImages[0];
    }
    
    if (asset) {
        //NSLog(@"loading asset %d", asset.assetID);
        [self loadImageWithUrl:[NSURL URLWithString:asset.imageUrlHalfSquare] resultCallback:^(UIImage *image) {
            //NSLog(@"asset is loaded!");
            if (memory == self.memory) {
                [self setImage:image animated:animated displayedMemoryIndex:-1];
            }
        } faultCallback:^(NSError *fault) {
            [self setImage:nil animated:animated displayedMemoryIndex:-1];
        }];
    }
    
    //handle text mems
    
    if ([memory isKindOfClass:[Memory class]] && ((Memory *)memory).type == MemoryTypeText) {
        //NSLog(@"handling text mem in the grid!");
        self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.05f];
        CGFloat anonBadgeFinalAlpha = memory.isAnonMem ? 1.0f : 0.0f;
        
        if (self.imageView.image) {
            //NSLog(@"animating from an image mem to a text mem!");
            [self.imageView.layer removeAllAnimations];
            self.imageView.alpha = 1.0f;
            UIImage * oldImage = self.imageView.image;
            
            [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                self.imageView.alpha = 0.0f;
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished && self.imageView.image == oldImage) {
                    [self updateTextStyling:memory.text];
                    [UIView animateWithDuration:.5 animations:^{
                        self.textMemView.alpha = 1;
                        self.wasShowingText = YES;
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                    } completion:^(BOOL finished) {
                        self.imageView.image = nil;
                        self.venueImageDisplayedMemoryIndex = 0;
                    }];
                }
            }];
        } else {
            //NSLog(@"animating from a text mem to a text mem!");
            [self.imageView.layer removeAllAnimations];
            self.imageView.alpha = 0.0f;
            [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished) {
                    [self updateTextStyling:memory.text];
                    [UIView animateWithDuration:.5 animations:^{
                        self.textMemView.alpha = 1;
                        self.wasShowingText = YES;
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                    }completion:^(BOOL finished) {
                        self.imageView.image = nil;
                        self.venueImageDisplayedMemoryIndex = 0;
                    }];
                }
            }];
        }
    }
    
}




-(void)setImage:(UIImage *)image animated:(BOOL)animated displayedMemoryIndex:(NSInteger)displayedMemoryIndex {
    Memory *memToDisplay = displayedMemoryIndex >= 0 ? [self memoryAtIndex:displayedMemoryIndex] : self.memory;
    CGFloat anonBadgeFinalAlpha = memToDisplay.isAnonMem ? 1.0f : 0.0f;
    if (!animated) {
        [self.imageView.layer removeAllAnimations];
        self.textMemView.alpha = 0.0f;
        self.imageView.image = image;
        self.imageView.alpha = 1.0f;
        self.venueImageDisplayedMemoryIndex = displayedMemoryIndex;
        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
    }
    else if (self.imageView.image) {
        //NSLog(@"animating to a an img mem from an image mem?");
        [self.imageView.layer removeAllAnimations];
        self.imageView.alpha = 1.0f;
        UIImage * oldImage = self.imageView.image;
        self.isAnimating = YES;
        [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
            self.textMemView.alpha = 0.0f;
            self.imageView.alpha = 0.0f;
            self.anonBadgeView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            if (finished && self.imageView.image == oldImage) {
                // still the same image... complete the animation.
                self.venueImageDisplayedMemoryIndex = displayedMemoryIndex;
                self.imageView.image = image;
                [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                    self.imageView.alpha = 1.0f;
                    self.isAnimating = NO;
                    self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                }];
            }
        }];
    }
    else {
        [self.imageView.layer removeAllAnimations];
        self.imageView.alpha = 0.0f;
        self.imageView.image = image;
        self.isAnimating = YES;
        self.venueImageDisplayedMemoryIndex = displayedMemoryIndex;
        
        if (self.wasShowingText) {
            //NSLog(@"animating to an img mem from a text mem");
            [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                self.textMemView.alpha = 0.0f;
                self.anonBadgeView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                if (finished) {
                    [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                        self.imageView.alpha = 1.0f;
                        self.isAnimating = NO;
                        self.wasShowingText = NO;
                        self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.35f];
                        self.anonBadgeView.alpha = anonBadgeFinalAlpha;
                        
                    }];
                }
            }];
            
        }
        else {
            //NSLog(@"animating to a an img mem");
            [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                self.imageView.alpha = 1.0f;
                self.isAnimating = NO;
                self.wasShowingText = NO;
                self.gradientOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.35f];
                self.anonBadgeView.alpha = anonBadgeFinalAlpha;
            }];
        }
    }
}


-(void)updateTextStyling:(NSString *)newText; {
    
    self.textMemLbl.font = [UIFont spc_regularSystemFontOfSize:16];
    self.textMemLbl.textAlignment = NSTextAlignmentLeft;
    self.textMemLbl.text = newText;
    
    if (newText.length < 30) {
        self.textMemLbl.textAlignment = NSTextAlignmentCenter;
        self.textMemLbl.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16];
    }
    
    if (newText.length < 12) {
        self.textMemLbl.font = [UIFont fontWithName:@"AvenirNext-Bold" size:16];
    }
}

@end