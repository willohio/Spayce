//
//  SPCMemoryGridCell.m
//  Spayce
//
//  Created by Arria P. Owlia on 3/20/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMemoryGridCell.h"

// View
#import "UIImageView+WebCache.h"
#import "SPCAVPlayerView.h"

// Model
#import "Memory.h"
#import "Asset.h"

// Manager
#import "SDWebImageManager.h"

NSString *SPCMemoryGridCellIdentifier = @"SPCMemoryGridCellIdentifier";

@interface SPCMemoryGridCell() <SPCAVPlayerViewDelegate>

@property (nonatomic, strong) UIView *viewMemoryContent;
@property (nonatomic, weak) SPCAVPlayerView *currentAVPlayerView;

@end

@implementation SPCMemoryGridCell

- (void)dealloc {
    [self clearMemoryContent];
}

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    // Content view
    self.contentView.autoresizesSubviews = YES;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Memory content view
    _viewMemoryContent = [[UIView alloc] init];
    _viewMemoryContent.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0f];
    _viewMemoryContent.autoresizesSubviews = YES;
    _viewMemoryContent.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _viewMemoryContent.clipsToBounds = YES;
    _viewMemoryContent.userInteractionEnabled = NO;
    [self.contentView addSubview:_viewMemoryContent];
}

#pragma mark - Reuse

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self clearMemoryContent];
}

- (void)clearMemoryContent {
    for (UIView *subview in self.viewMemoryContent.subviews) {
        [subview removeFromSuperview];
    }
    
    self.currentAVPlayerView = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    self.viewMemoryContent.frame = self.contentView.bounds;
    
    for (UIView *subview in self.viewMemoryContent.subviews) {
        subview.frame = self.viewMemoryContent.bounds;
    }
}

#pragma mark - Actions

- (void)playIfVideo {
    [self.currentAVPlayerView play];
}

- (void)pauseIfVideo {
    [self.currentAVPlayerView pause];
}

#pragma mark - Configuration

- (void)configureWithMemory:(Memory *)memory andQuality:(MemoryGridCellQuality)quality {
    [self clearMemoryContent];
    
    _memory = memory;
    
    if ([memory isKindOfClass:[ImageMemory class]]) {
        UIImageView *ivImage = [[UIImageView alloc] init];
        Asset *assetImage = [((ImageMemory *)memory).images firstObject];
        [self setImageView:ivImage withAsset:assetImage andQuality:quality];
        
        // Add the image to the view
        [self.viewMemoryContent addSubview:ivImage];
    } else if ([memory isKindOfClass:[VideoMemory class]]) {
        UIImageView *ivImage = [[UIImageView alloc] init];
        Asset *assetImage = [((VideoMemory *)memory).previewImages firstObject];
        [self setImageView:ivImage withAsset:assetImage andQuality:MemoryGridCellQualityLow];
        
        // Add the image to the view
        [self.viewMemoryContent addSubview:ivImage];
        
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:[((VideoMemory *)memory).videoURLs firstObject]]];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
        SPCAVPlayerView *playerView = [[SPCAVPlayerView alloc] initWithPlayer:player];
        playerView.volume = 0.0f;
        playerView.delegate = self;
        
        // Add the playerview below the image, until it starts playing
        [self.viewMemoryContent insertSubview:playerView belowSubview:ivImage];
        [playerView play];
        self.currentAVPlayerView = playerView;
    } else {
        NSString *text = memory.text;
        
        UILabel *lblText = [[UILabel alloc] init];
        lblText.text = text;
        lblText.backgroundColor = [UIColor clearColor];
        lblText.textColor = [UIColor whiteColor];
        lblText.textAlignment = NSTextAlignmentCenter;
        CGFloat fontSize = MemoryGridCellQualityHigh == quality ? 20.0f : MemoryGridCellQualityMedium == quality ? 16.0f : 12.0f;
        lblText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:fontSize];
        lblText.numberOfLines = 0;
        lblText.autoresizesSubviews = YES;
        lblText.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UIView *viewBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
        viewBackground.backgroundColor = [UIColor colorWithRed:138.0f/255.0f green:192.0f/255.0f blue:249.0f/255.0f alpha:1.0f];
        [viewBackground addSubview:lblText];
        CGSize sizeThatFitsLabel = [lblText sizeThatFits:CGRectInset(viewBackground.frame, 5, 5).size];
        lblText.frame = CGRectMake(0, 0, sizeThatFitsLabel.width, sizeThatFitsLabel.height);
        lblText.center = viewBackground.center;
        
        [self.viewMemoryContent addSubview:viewBackground];
    }
    
    for (UIView *subview in self.viewMemoryContent.subviews) {
        subview.autoresizesSubviews = YES;
        subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth;
    }
    
    [self layoutSubviews];
}

#pragma mark - SPCAVPlayerViewDelegate

- (void)didStartPlaybackWithPlayerView:(SPCAVPlayerView *)playerView {
    if ([self.currentAVPlayerView isEqual:playerView]) {
        [self.viewMemoryContent bringSubviewToFront:playerView];
        [playerView play];
    }
}

- (void)didFinishPlaybackToEndWithPlayerView:(SPCAVPlayerView *)playerView {
    if ([self.currentAVPlayerView isEqual:playerView]) {
        [playerView stop];
        [playerView play];
    }
}

#pragma mark - Helpers

- (void)setImageView:(UIImageView *)imageView withAsset:(Asset *)asset andQuality:(MemoryGridCellQuality)quality {
    NSString *strUrl = [asset imageUrlStringWithSize:ImageCacheSizeThumbnailLarge];
    if (MemoryGridCellQualityHigh == quality) {
        strUrl = [asset imageUrlSquare];
    } else if (MemoryGridCellQualityMedium == quality) {
        strUrl = [asset imageUrlStringWithSize:ImageCacheSizeSquareMedium];
    }
    
    [imageView sd_setImageWithURL:[NSURL URLWithString:strUrl]];
}

@end
