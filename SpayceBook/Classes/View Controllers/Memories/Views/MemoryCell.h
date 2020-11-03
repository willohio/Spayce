//
//  MemoryCell.h
//  Spayce
//
//  Created by Jake Rosin on 5/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Memory.h"
#import "SPCFeedPhotoScroller.h"
#import "SPCFeedVideoScroller.h"
#import "Venue.h"
#import "STTweetLabel.h"

@interface MemoryCell : UITableViewCell<SPCFeedPhotoScrollerDelegate, SPCFeedVideoScrollerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIButton *commentsButton;
@property (strong, nonatomic) UIButton *starsButton;
@property (strong, nonatomic) UIButton *usersToStarButton;
@property (strong, nonatomic) UIButton *authorButton;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *followButton;
@property (strong, nonatomic) UILabel *locationLabel;
@property (nonatomic, assign) BOOL lighterBg;
@property (nonatomic, assign) BOOL viewingInComments;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
@property (assign, nonatomic) NSInteger lastIndexShown;
@property (strong, nonatomic) STTweetLabel *memoryTextLabel;

@property (nonatomic, readonly) CGRect mediaContentScreenRect;
@property (nonatomic, readonly) UIImage *mediaContentImage;

@property (nonatomic, copy) void (^taggedUserTappedBlock)(NSString *userToken);
@property (nonatomic, copy) void (^hashTagTappedBlock)(NSString *hashTag, Memory *mem);
@property (nonatomic, copy) void (^locationTappedBlock)(Memory *memory);
@property (nonatomic, copy) void (^imageTappedBlock)(Memory *memory, NSArray *assets, int index);
@property (nonatomic, copy) void (^videoTappedBlock)(Memory *memory, NSArray *thumbnailAssetIds, NSArray *videoURLs, int index);

- (id)initWithMemoryType:(MemoryType)type style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)configureWithMemory:(Memory *)memory tag:(NSInteger)tag dateFormatter:(NSDateFormatter *)dateFormatter placeholder:(UIImage *)placeholder;
- (void)configureWithMemory:(Memory *)memory tag:(NSInteger)tag dateFormatter:(NSDateFormatter *)dateFormatter canShowAnonLabel:(BOOL)canShowAnonLabel;
- (void)configureWithMemory:(Memory *)memory tag:(NSInteger)tag dateFormatter:(NSDateFormatter *)dateFormatter;
- (void)configureStarsWithMemory:(Memory *)memory;

- (void)clearContent;

- (void)updateForCommentDisplay;
- (void)updateTimestamp;

// FIXME: Deprecated
- (void)updateToPublic;
- (void)updateToPrivate;

+ (CGFloat)measureMainContentOffsetWithMemory:(Memory *)memory constrainedToSize:(CGSize)size;
+ (CGFloat)measureHeightWithMemory:(Memory *)memory constrainedToSize:(CGSize)size;
+ (NSAttributedString *)getMemoryTextWithMemory:(Memory *)memory;

@end
