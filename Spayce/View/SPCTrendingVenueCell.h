//
//  SPCTrendingVenueCell.h
//  Spayce
//
//  Created by Jake Rosin on 7/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Venue;
@class Memory;


@protocol SPCTrendingVenueCellDelegate <NSObject>
@optional
- (void)removeCellFromCycledListWithTag:(NSInteger)cellTag;
@end


@interface SPCTrendingVenueCell : UICollectionViewCell

@property (nonatomic, readonly) BOOL isConfigured;
@property (nonatomic, readonly) BOOL isMemory;
@property (nonatomic, readonly) Memory *memoryDisplayed;
@property (nonatomic, strong) Memory *memory;
@property (nonatomic, strong) Venue * venue;
@property (nonatomic, assign) NSInteger venueImageMemoryIndex;
@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, strong) UIView * gradientOverlayView;
@property (nonatomic, strong) UILabel * timeDistanceDetailLabel;
@property (nonatomic, strong) UIView *textMemView;
@property (nonatomic, strong) UIImageView *anonBadgeView;
@property (nonatomic, strong) UILabel *textMemLbl;
@property (nonatomic, assign) BOOL isHashMem;
@property (nonatomic, assign) NSInteger venueImageDisplayedMemoryIndex;
@property (nonatomic, weak) id<SPCTrendingVenueCellDelegate> delegate;

+(BOOL)venue:(Venue *)venue1 isEquivalentTo:(Venue *)venue2;
+(BOOL)memory:(Memory *)memory1 isEquivalentTo:(Memory *)memory2;

-(void)configureWithMemory:(Memory *)memory isLocal:(BOOL)isLocal;
-(void)configureWithVenue:(Venue *)venue isLocal:(BOOL)isLocal;

-(BOOL)cycleImageAnimated:(BOOL)animated;

-(BOOL)canAnimateCell;
-(void)resetCycleImage;
-(void)setImage:(UIImage *)image animated:(BOOL)animated displayedMemoryIndex:(NSInteger)displayedMemoryIndex;
-(void)layoutDetailRow;
-(void)cancelImageOperation;
-(void)loadImageWithUrl:(NSURL *)url
         resultCallback:(void (^)(UIImage *image))resultCallback
          faultCallback:(void (^)(NSError *fault))faultCallback;
@end
