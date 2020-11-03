//
//  SPCVenueDetailsCollectionViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 11/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//


#import "SPCVenueDetailsCollectionViewCell.h"
#import "SPCFeaturedContent.h"
#import "Memory.h"
#import "Venue.h"
#import "SPCVenueTypes.h"
#import "NSString+SPCAdditions.h"


@interface SPCVenueDetailsCollectionViewCell()


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
@end


@implementation SPCVenueDetailsCollectionViewCell

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
        _contentFrame.layer.cornerRadius = 1;
        _contentFrame.layer.masksToBounds = YES;
        _contentFrame.clipsToBounds = YES;
        [_dropShadowView addSubview:_contentFrame];
        

        UIImageView *venueImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        venueImageView.backgroundColor = [UIColor clearColor];
        venueImageView.contentMode = UIViewContentModeScaleAspectFill;
        [_contentFrame addSubview:venueImageView];

        
        UILabel *distanceCountLabel = [[UILabel alloc] init];
        distanceCountLabel.textAlignment = NSTextAlignmentCenter;
        distanceCountLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        distanceCountLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        distanceCountLabel.text = @"0";
        distanceCountLabel.clipsToBounds = NO;
        distanceCountLabel.layer.masksToBounds = NO;
        
        UILabel *memoryCountLabel = [[UILabel alloc] init];
        memoryCountLabel.textAlignment = NSTextAlignmentCenter;
        memoryCountLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        memoryCountLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        memoryCountLabel.text = @"0";
        memoryCountLabel.clipsToBounds = NO;
        memoryCountLabel.layer.masksToBounds = NO;
        
        UILabel *starCountLabel = [[UILabel alloc] init];
        starCountLabel.textAlignment = NSTextAlignmentCenter;
        starCountLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        starCountLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        starCountLabel.text = @"0";
        starCountLabel.clipsToBounds = NO;
        starCountLabel.layer.masksToBounds = NO;
        
        // load the memory and star images
        UIImageView *distanceImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"venue-bar-loc-icon"]];
        UIImageView *memoryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"venue-bar-mem-icon"]];
        UIImageView *starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"venue-bar-star-icon"]];
        
        //[_contentFrame addSubview:distanceCountLabel];
        [_contentFrame addSubview:memoryCountLabel];
        [_contentFrame addSubview:starCountLabel];
        //[_contentFrame addSubview:distanceImageView];
        [_contentFrame addSubview:memoryImageView];
        [_contentFrame addSubview:starImageView];
        
        UILabel *venueLabel = [[UILabel alloc] init];
        venueLabel.font = [UIFont spc_boldSystemFontOfSize:16];
        venueLabel.frame = CGRectMake(62, 3+CGRectGetMidY(self.bounds) - venueLabel.font.lineHeight, CGRectGetWidth(self.bounds)-142, venueLabel.font.lineHeight +2);
        venueLabel.textAlignment = NSTextAlignmentLeft;
        venueLabel.textColor = [UIColor colorWithRed:96.0f/255.0f green:115.0f/255.0f blue:145.0f/255.0f alpha:1.0f];
        venueLabel.clipsToBounds = NO;
        venueLabel.layer.masksToBounds = NO;
        venueLabel.adjustsFontSizeToFitWidth = YES;
        venueLabel.minimumScaleFactor = .75;
        [_contentFrame addSubview:venueLabel];
        
        self.refreshLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(self.contentFrame.frame.size.width - 47, 5, 45, 45)];
        [self.refreshLocationButton setBackgroundImage:[UIImage imageNamed:@"button-refresh-location"] forState:UIControlStateNormal];
        [_contentFrame addSubview:self.refreshLocationButton];
    

        
        self.venueImageView = venueImageView;
        self.distanceLabel = distanceCountLabel;
        self.distanceImageView = distanceImageView;
        self.memoryCountLabel = memoryCountLabel;
        self.memoryImageView = memoryImageView;
        self.starCountLabel = starCountLabel;
        self.starImageView = starImageView;
        self.venueLabel = venueLabel;        

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _dropShadowView.frame = self.bounds;
    _contentFrame.frame = self.bounds;
    
    
    _venueImageView.center = CGPointMake(15 + _venueImageView.image.size.width/2,  self.contentFrame.frame.size.height/2);
    
    _refreshLocationButton.frame = CGRectMake(self.contentFrame.frame.size.width - 47, (self.contentFrame.frame.size.height - 45)/2, 45, 45);
}

- (void)updateOffsetAdjustment:(float)offsetAdj {
    _dropShadowView.center = CGPointMake(self.bounds.size.width/2 + offsetAdj, self.bounds.size.height/2);
}

#pragma mark - UICollectionReusableView - Reusing Cells

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear venue etc.
    self.featuredContent = nil;
    
    
}

#pragma mark - configure

-(void)configureWithFeaturedContent:(SPCFeaturedContent *)featuredContent {
    // TODO: configure err'thing
    //NSLog(@"configitall for venue %@ and type %li",featuredContent.venue.displayNameTitle,featuredContent.contentType);
    
    self.featuredContent = featuredContent;

    self.venueLabel.text = self.featuredContent.venue.displayNameTitle;
    self.distanceLabel.text = [NSString detailedStringFromDistance:self.featuredContent.venue.distanceAway];
    self.starCountLabel.text =  [NSString stringByTruncatingInteger:self.featuredContent.venue.totalStars];
    self.memoryCountLabel.text = [NSString stringByTruncatingInteger:self.featuredContent.venue.totalMemories];
    self.venueImageView.image = [SPCVenueTypes largeImageForVenue:self.featuredContent.venue withIconType:VenueIconTypeIconNewColor];
    self.venueImageView.frame = CGRectMake(0, 0, self.venueImageView.image.size.width, self.venueImageView.image.size.height);
    self.venueImageView.center = CGPointMake(15 + self.venueImageView.image.size.width/2, self.contentFrame.frame.size.height/2);
    
    
    // Memory / Star / Venue icons and counts.
    // Determine text sizes...
    CGSize distTextSize = [self.distanceLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.distanceLabel.font }];
    CGSize memTextSize = [self.memoryCountLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.memoryCountLabel.font }];
    CGSize strTextSize = [self.starCountLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.starCountLabel.font }];
    
    // align the bottoms of things
    CGRect frame = self.distanceLabel.frame;
    frame.size = distTextSize;
    self.distanceLabel.frame = frame;
    
    frame = self.memoryCountLabel.frame;
    frame.size = memTextSize;
    self.memoryCountLabel.frame = frame;
    
    frame = self.starCountLabel.frame;
    frame.size = strTextSize;
    self.starCountLabel.frame = frame;
    
    // Place everything in a row...
    CGFloat bottomY = CGRectGetHeight(self.frame) - 9.0;
    // Revision to make the purpose of this more clear, and remove the static analysis warning.
    // placeView will position the provided view with its bottom-left corner at (x, bottomY)
    // and return the right-edge x position of the view.
    CGFloat widthUsed = 60;
   // widthUsed = [self placeView:self.distanceImageView atLeftX:widthUsed bottomY:bottomY-1];
   // widthUsed = [self placeView:self.distanceLabel atLeftX:widthUsed bottomY:bottomY];
    widthUsed = [self placeView:self.memoryImageView atLeftX:widthUsed bottomY:bottomY-1];
    widthUsed = [self placeView:self.memoryCountLabel atLeftX:widthUsed+2.0 bottomY:bottomY];
    widthUsed = [self placeView:self.starImageView atLeftX:widthUsed+8.0 bottomY:bottomY-1];
    [self placeView:self.starCountLabel atLeftX:widthUsed+1.0 bottomY:bottomY];
    
}

-(CGFloat)placeView:(UIView *)view atLeftX:(CGFloat)x bottomY:(CGFloat)bottomY {
    CGFloat height = view.frame.size.height;
    CGFloat width = view.frame.size.width;
    view.frame = CGRectMake(x, bottomY - height, width, height);
    return width + x;
}

@end
