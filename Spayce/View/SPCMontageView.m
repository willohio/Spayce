//
//  SPCMontageView.m
//  Spayce
//
//  Created by Arria P. Owlia on 2/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMontageView.h"

// View
#import "SPCInitialsImageView.h"
#import "UAProgressView.h"
#import "SPCAVPlayerView.h"

// Manager
#import "MeetManager.h"

// Model
#import "Memory.h"
#import "Asset.h"
#import "Person.h"
#import "Venue.h"

// Cache
#import "SDWebImageManager.h"
#import "UIImageView+WebCache.h"

static const CGFloat IMAGE_DISPLAY_INTERVAL = 2.0f; // seconds
//static const CGFloat VIDEO_DISPLAY_INTERVAL = 4.0f; // seconds
static const CGFloat TIMER_INTERVAL = 1.0f/60.0f; // seconds, 60Hz
static const CGFloat ANIMATION_DURATION = 0.5f; // seconds
static const NSInteger NUM_IMAGES_ON_BACKGROUND = 4 * 3;

static const NSString *kIMG = @"image";
static const NSString *kIMG_CACHED = @"imageCached";
static const NSString *kIMG_AUTHOR = @"imageAuthor";
static const NSString *kIMG_AUTHOR_CACHED = @"imageAuthorCached";
static const NSString *kVID_PLR_VIEW = @"videoPlayerView";
static const NSString *kVID_DURATION = @"videoDuration";
static const NSString *kVID_RDY = @"videoReadyToPlay";
static const NSString *kVID_LOAD_ATT = @"videoLoadAttempted";
static const NSString *kTXT = @"text";
static const NSString *kMEM_TYPE = @"type";

static const NSInteger MIN_MEMS = 12;

@interface SPCMontageView() <SPCAVPlayerViewDelegate, SPCMontageCoachmarkViewDelegate>

// Data
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) UIColor *overlayColor;
@property (strong, nonatomic) NSDictionary *dicMemoryToData;
@property (strong, atomic) NSMutableDictionary *dicTempMemoriesToData;
@property (strong, nonatomic) NSMutableDictionary *dicTempMemoryToPlayerView;
@property (nonatomic) NSTimeInterval fullMontageDuration;
@property (nonatomic) BOOL useLocalLocations;
@property (strong, nonatomic) SPCMontageCoachmarkView *viewCoachmark;

// Timer
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CGFloat secondsRemaining;

// Content view
@property (strong, nonatomic) UIView *contentView;

// Pre-montage views
// Background stitched images view
@property (strong, nonatomic) UIImageView *ivBackground;
// Overlay view
@property (strong, nonatomic) UIView *viewOverlay;
// Title
@property (strong, nonatomic) UILabel *lblTitle;
// Play button
@property (strong, nonatomic) UIButton *btnPlay;

// Intra-montage views
// Buttons (or button-looking elements)
@property (strong, nonatomic) UIButton *btnDismiss;
@property (strong, nonatomic) SPCInitialsImageView *ivAuthor;
@property (strong, nonatomic) UAProgressView *pvCountdown;
@property (strong, nonatomic) UIView *viewMontageBackground;

// Memory view
@property (strong, nonatomic) UIView *viewCurrentMemory; // Holds the memory content view as a subview
@property (weak, nonatomic) UIView *viewCurrentMemoryContent;
@property (strong, nonatomic) Memory *memoryCurrent;

// State
@property (nonatomic) SPCMontageViewState state;
@property (nonatomic) CGFloat currentMemoryDisplayDuration;
@property (nonatomic) CGFloat currentMemorySecondsRemaining;

@end

@implementation SPCMontageView

#pragma mark - Target-Actions

- (void)tappedPlayButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedPlayButtonOnSPCMontageView:)]) {
        [self.delegate tappedPlayButtonOnSPCMontageView:self];
    }
}

- (void)tappedDismissButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedDismissButtonOnSPCMontageView:)]) {
        [self.delegate tappedDismissButtonOnSPCMontageView:self];
    }
}

- (void)tappedAuthorButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedAuthorForMemory:onSPCMontageView:)]) {
        [self.delegate tappedAuthorForMemory:self.memoryCurrent onSPCMontageView:self];
    }
}

- (void)tappedMemory:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedMemory:onSPCMontageView:)]) {
        [self.delegate tappedMemory:self.memoryCurrent onSPCMontageView:self];
    }
}

- (void)swipedMemory:(id)sender {
    if ([sender isKindOfClass:[UISwipeGestureRecognizer class]]) {
        UISwipeGestureRecognizer *grSwipe = sender;
        
        if (UISwipeGestureRecognizerDirectionLeft == grSwipe.direction) {
            [self playNextMemory];
        } else if (UISwipeGestureRecognizerDirectionRight == grSwipe.direction) {
            [self playPreviousMemory];
        }
    }
}

- (void)countdownTimerFired {
    self.secondsRemaining = MAX(0.0f, self.secondsRemaining - TIMER_INTERVAL); // Display a minimum of +0
    self.currentMemorySecondsRemaining = MAX(0.0f, self.currentMemorySecondsRemaining - TIMER_INTERVAL); // Display a minimum of +0
    
    if (0.0f >= self.currentMemorySecondsRemaining) {
        [self playNextMemory];
    }
}

#pragma mark - Actions

- (void)play {
    if (nil == self.memoryCurrent) {
        self.memoryCurrent = [self.memories firstObject];
    }
    
    if (nil == self.viewCoachmark) { // Only begin montage playback if we're not displaying a coachmark
        if (MemoryTypeVideo == self.memoryCurrent.type && [self.viewCurrentMemoryContent isKindOfClass:[SPCAVPlayerView class]]) {
            SPCAVPlayerView *playerView = (SPCAVPlayerView *)self.viewCurrentMemoryContent;
            
            [playerView play];
        } else {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(countdownTimerFired) userInfo:nil repeats:YES];
        }
    }
    
    self.state = SPCMontageViewStatePlaying;
}

- (void)playWithCoachmark {
    self.viewCoachmark = [[SPCMontageCoachmarkView alloc] initWithFrame:self.frame];
    self.viewCoachmark.delegate = self;
    
    [self play];
}

- (void)pause {
    self.timer = nil;
    if (MemoryTypeVideo == self.memoryCurrent.type && [self.viewCurrentMemoryContent isKindOfClass:[SPCAVPlayerView class]]) {
        SPCAVPlayerView *playerView = (SPCAVPlayerView *)self.viewCurrentMemoryContent;
        [playerView pause];
    }
    
    self.state = SPCMontageViewStatePaused;
}

- (void)stop {
    self.timer = nil;
    self.memoryCurrent = nil;
    self.state = SPCMontageViewStateStopped;
}

- (void)playNextMemory {
    NSInteger indexOfCurrentMemory = [self.memories indexOfObject:self.memoryCurrent];
    if ((indexOfCurrentMemory + 1) < self.memories.count) {
        [self playMemoryAtIndex:(indexOfCurrentMemory + 1)];
    } else if ([self.delegate respondsToSelector:@selector(didPlayToEndOnSPCMontageView:)]) {
        [self.delegate didPlayToEndOnSPCMontageView:self]; // Delegate should call [montageView stop];
    }
}

- (void)playPreviousMemory {
    NSInteger indexOfCurrentMemory = [self.memories indexOfObject:self.memoryCurrent];
    if (0 < indexOfCurrentMemory && (indexOfCurrentMemory - 1) < self.memories.count) {
        [self playMemoryAtIndex:(indexOfCurrentMemory - 1)];
    }
}

- (void)playMemoryAtIndex:(NSInteger)index {
    [self.timer invalidate];
    
    if (index < self.memories.count) {
        self.memoryCurrent = [self.memories objectAtIndex:index];
        [self play];
    } else {
        if ([self.delegate respondsToSelector:@selector(tappedDismissButtonOnSPCMontageView:)]) {
            [self.delegate tappedDismissButtonOnSPCMontageView:self]; // Delegate should call [montageView stop];
        }
    }
}

#pragma mark - Configuration

- (void)configureWithMemories:(NSArray *)memories title:(NSString *)title overlayColor:(UIColor *)overlayColor useLocalLocations:(BOOL)useLocalLocations andPreviewImageSize:(CGSize)previewImageSize {
    [self setMemories:memories];
    self.title = title;
    [self.lblTitle sizeToFit];
    self.overlayColor = overlayColor;
    self.isReady = NO;
    self.fullMontageDuration = 0.0f;
    self.useLocalLocations = useLocalLocations;
    _previewImageSize = previewImageSize;
    
    // Begin loading the memories if we have enough of them
    if (MIN_MEMS <= self.memories.count) {
        [self loadMemories];
    } else if ([self.delegate respondsToSelector:@selector(didFailToLoadMemoriesOnSPCMontageView:)]) {
        [self.delegate didFailToLoadMemoriesOnSPCMontageView:self];
    }
    
    // Reset the view to the stopped state
    [self stop];
}

- (void)showPreMontage:(BOOL)show animated:(BOOL)animated {
    CGFloat alpha = show ? 1.0f : 0.0f;
    
    if (animated) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.ivBackground.alpha = alpha;
            self.viewOverlay.alpha = alpha;
            self.lblTitle.alpha = alpha;
            self.btnPlay.alpha = alpha;
        }];
    } else {
        self.ivBackground.alpha = alpha;
        self.viewOverlay.alpha = alpha;
        self.lblTitle.alpha = alpha;
        self.btnPlay.alpha = alpha;
    }
}

- (void)showIntraMontage:(BOOL)show animated:(BOOL)animated {
    CGFloat alpha = show ? 1.0f : 0.0f;
    
    if (animated) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.viewMontageBackground.alpha = alpha;
            self.viewCurrentMemory.alpha = alpha;
            self.btnDismiss.alpha = alpha;
            self.ivAuthor.alpha = alpha;
            self.pvCountdown.alpha = alpha;
        }];
    } else {
        self.viewMontageBackground.alpha = alpha;
        self.viewCurrentMemory.alpha = alpha;
        self.btnDismiss.alpha = alpha;
        self.ivAuthor.alpha = alpha;
        self.pvCountdown.alpha = alpha;
    }
}

- (void)loadMemories {
    self.dicTempMemoriesToData = [[NSMutableDictionary alloc] init];
    
    Memory *memoryToBeginLoading = [self.memories firstObject];
    [self loadMemory:memoryToBeginLoading];
}

- (void)loadMemory:(Memory *)memory {
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    __weak typeof(self) weakSelf = self;
    
    Asset *asset = nil;
    if ([memory isKindOfClass:[ImageMemory class]]) {
        ImageMemory *imageMemory = (ImageMemory *)memory;
        asset = [imageMemory.images firstObject];
        
        // Download the image
        [manager downloadImageWithURL:[NSURL URLWithString:[asset imageUrlSquare]] options:SDWebImageDelayPlaceholder progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (finished) {
                __block NSMutableDictionary *dicData = [NSMutableDictionary dictionary];
                [dicData setObject:@(MemoryTypeImage) forKey:kMEM_TYPE];
                if (image && nil == error) {
                    [dicData setObject:@(YES) forKey:kIMG_CACHED];
                } else {
                    [dicData setObject:@(NO) forKey:kIMG_CACHED];
                }
                
                // Download the author image
                [manager downloadImageWithURL:[NSURL URLWithString:[memory.author.imageAsset imageUrlThumbnail]] options:SDWebImageDelayPlaceholder progress:nil completed:^(UIImage *imageAuthor, NSError *errorAuthor, SDImageCacheType cacheTypeAuthor, BOOL finishedAuthor, NSURL *imageURLAuthor) {
                    if (finishedAuthor) {
                        if (imageAuthor && nil == errorAuthor) {
                            [dicData setObject:@(YES) forKey:kIMG_AUTHOR_CACHED];
                        } else {
                            [dicData setObject:@(NO) forKey:kIMG_AUTHOR_CACHED];
                        }
                        
                        // Set the data
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        [strongSelf.dicTempMemoriesToData setObject:[NSDictionary dictionaryWithDictionary:dicData] forKey:@(memory.recordID)];
                        
                        [strongSelf finishedLoadingSingleMemory:memory];
                    }
                }];
            }
        }];
    } else if ([memory isKindOfClass:[VideoMemory class]]) {
        VideoMemory *videoMemory = (VideoMemory *)memory;
        asset = [videoMemory.previewImages firstObject];
        NSURL *videoURL = [NSURL URLWithString:[videoMemory.videoURLs firstObject]];
        
        // Grab the placeholder image
        [manager downloadImageWithURL:[NSURL URLWithString:[asset imageUrlSquare]] options:SDWebImageDelayPlaceholder progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (finished) {
                __block NSMutableDictionary *dicData = [NSMutableDictionary dictionary];
                [dicData setObject:@(MemoryTypeVideo) forKey:kMEM_TYPE];
                if (image && nil == error) {
                    [dicData setObject:@(YES) forKey:kIMG_CACHED];
                } else {
                    [dicData setObject:@(NO) forKey:kIMG_CACHED];
                }
        
                // Grab the author image
                [manager downloadImageWithURL:[NSURL URLWithString:[memory.author.imageAsset imageUrlThumbnail]] options:SDWebImageDelayPlaceholder progress:nil completed:^(UIImage *imageAuthor, NSError *errorAuthor, SDImageCacheType cacheTypeAuthor, BOOL finishedAuthor, NSURL *imageURLAuthor) {
                    if (finishedAuthor) {
                        if (imageAuthor && nil == errorAuthor) {
                            [dicData setObject:@(YES) forKey:kIMG_AUTHOR_CACHED];
                        } else {
                            [dicData setObject:@(NO) forKey:kIMG_AUTHOR_CACHED];
                        }
                        
                        // Start the video buffering
                        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
                        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
                        SPCAVPlayerView *playerView = [[SPCAVPlayerView alloc] initWithPlayer:player];
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        playerView.delegate = strongSelf;
                        [dicData setObject:playerView forKey:kVID_PLR_VIEW];
                        [dicData setObject:@(NO) forKey:kVID_RDY];
                        [dicData setObject:@(NO) forKey:kVID_LOAD_ATT];
                        
                        // Set the data
                        [strongSelf.dicTempMemoriesToData setObject:[NSDictionary dictionaryWithDictionary:dicData] forKey:@(memory.recordID)];
                        [strongSelf.dicTempMemoryToPlayerView setObject:playerView forKey:@(memory.recordID)];
                    }
                }];
            }
        }];
    } else if (MemoryTypeText == memory.type) {
        // Set the text
        __block NSMutableDictionary *dicData = [NSMutableDictionary dictionaryWithDictionary:@{ kTXT : memory.text, kMEM_TYPE : @(MemoryTypeText) }];
        
        // Grabt the author image
        [manager downloadImageWithURL:[NSURL URLWithString:[memory.author.imageAsset imageUrlThumbnail]] options:SDWebImageDelayPlaceholder progress:nil completed:^(UIImage *imageAuthor, NSError *errorAuthor, SDImageCacheType cacheTypeAuthor, BOOL finishedAuthor, NSURL *imageURLAuthor) {
            if (finishedAuthor) {
                if (imageAuthor && nil == errorAuthor) {
                    [dicData setObject:@(YES) forKey:kIMG_AUTHOR_CACHED];
                } else {
                    [dicData setObject:@(NO) forKey:kIMG_AUTHOR_CACHED];
                }
                
                // Set the data
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf.dicTempMemoriesToData setObject:[NSDictionary dictionaryWithDictionary:dicData] forKey:@(memory.recordID)];
                
                // Set the property, if we've loaded all of the memories
                [strongSelf finishedLoadingSingleMemory:memory];
            }
        }];
    }
}

- (void)updateWithMemories:(NSArray *)newMemories withMontageNeedsLoadReturn:(BOOL *)needsLoad{
    BOOL needsToLoad = NO;
    
    NSMutableArray *currentMemories = [NSMutableArray arrayWithArray:self.memories];
    NSMutableSet *setNewMemoryIds = [[NSMutableSet alloc] initWithCapacity:newMemories.count];
    NSMutableSet *setCurrentMemoryIds = [[NSMutableSet alloc] initWithCapacity:currentMemories.count];
    
    // Create sets that contain the current and new memory IDs
    for (Memory *memory in newMemories) {
        [setNewMemoryIds addObject:@(memory.recordID)];
    }
    for (Memory *memory in currentMemories) {
        [setCurrentMemoryIds addObject:@(memory.recordID)];
    }
    
    // Gather arrays of memories to remove from and add to the montage
    NSMutableArray *memoriesToRemove = [[NSMutableArray alloc] init];
    for (Memory *memory in currentMemories) {
        if (NO == [setNewMemoryIds containsObject:@(memory.recordID)]) {
            [memoriesToRemove addObject:memory];
        }
    }
    NSMutableArray *memoriesToAdd = [[NSMutableArray alloc] init];
    for (Memory *memory in newMemories) {
        if (NO == [setCurrentMemoryIds containsObject:@(memory.recordID)]) {
            [memoriesToAdd addObject:memory];
        } else {
            // This is also where we can switch in the updated memory in-place
            BOOL foundMemory = NO;
            for (NSUInteger index = 0; index < currentMemories.count && NO == foundMemory; ++index) {
                Memory *memoryToUpdate = [currentMemories objectAtIndex:index];
                if (memoryToUpdate.recordID == memory.recordID) {
                    // Go ahead and update the currentMemories array
                    [currentMemories replaceObjectAtIndex:index withObject:memory];
                }
            }
        }
    }
    
    // This will update only the memories that are the same across the current memories and the new memories that were passed in. Necessary for, e.g. a following status change
    [self setMemories:currentMemories];
    
    if (0 < memoriesToAdd.count || 0 < memoriesToRemove.count) {
        needsToLoad = YES;
        self.isReady = NO;
        
        // Remove the memories we need to remove from our memories array and data dictionary
        NSMutableDictionary *dicMemoryToData = [NSMutableDictionary dictionaryWithDictionary:self.dicMemoryToData];
        self.dicMemoryToData = nil;
        for (Memory *memory in memoriesToRemove) {
            [currentMemories removeObject:memory];
            [dicMemoryToData removeObjectForKey:@(memory.recordID)];
        }
        
        // Set our memories property - this aids us in figuring out when all mems have been loaded
        for (Memory *memory in memoriesToAdd) {
            [currentMemories insertObject:memory atIndex:0];
        }
        [self setMemories:currentMemories];
        self.dicTempMemoriesToData = dicMemoryToData; // Set this as our baseline of data objects that we have already loaded
        
        if (0 < memoriesToAdd.count) {
            // Load in the memories that we have not yet loaded
            [self loadMemory:[currentMemories firstObject]];
        } else {
            [self setDicMemoryToData:self.dicTempMemoriesToData andPrepareMontage:YES]; // Set our current memories as the new memory data
            self.dicTempMemoriesToData = nil;
            self.dicTempMemoryToPlayerView = nil;
        }
    }
    
    // Write to our ref bool
    if (*needsLoad) {
        *needsLoad = needsToLoad;
    }
}

- (void)clear {
    [self stop];
    
    self.title = nil;
    [self.lblTitle sizeToFit];
    self.overlayColor = [UIColor clearColor];
    self.isReady = NO;
    self.fullMontageDuration = 0.0f;
    self.useLocalLocations = NO;
    _previewImageSize = CGSizeZero;
    
    self.memories = nil;
    self.dicMemoryToData = nil;
    self.dicTempMemoriesToData = nil;
    self.dicTempMemoryToPlayerView = nil;
    self.viewCoachmark = nil;
    
    self.ivBackground.image = nil;
    
    if ([self.delegate respondsToSelector:@selector(memoriesWereClearedFromSPCMontageView:)]) {
        [self.delegate memoriesWereClearedFromSPCMontageView:self];
    }
}

#pragma mark - Accessors

- (void)setState:(SPCMontageViewState)state {
    SPCMontageViewState previousState = _state;
    SPCMontageViewState newState = state;
    _state = newState;
    
    switch (newState) {
        case SPCMontageViewStatePlaying:
            if (SPCMontageViewStatePaused == previousState) {
            } else if (SPCMontageViewStateStopped == previousState) {
                [self showPreMontage:NO animated:YES];
                
                [self showIntraMontage:YES animated:YES];
                self.pvCountdown.progress = 1.0f;
            }
            
            // Allow sound even when in silent mode
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            break;
        
        case SPCMontageViewStatePaused:
            // Allow other sounds
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
            break;
            
        case SPCMontageViewStateStopped:
            // Here, we want to stop anything that is playing and set the view to its original state
            // Hide intra-montage
            [self showIntraMontage:NO animated:YES];
            
            // Set to original state
            [self showPreMontage:YES animated:YES];
            
            // Allow other sounds
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
            break;
            
        default:
            break;
    }
}

- (void)setMemoryCurrent:(Memory *)memoryCurrent {
    // Cleanup the current memory
    if (MemoryTypeVideo == self.memoryCurrent.type && [self.viewCurrentMemoryContent isKindOfClass:[SPCAVPlayerView class]]) {
        SPCAVPlayerView *playerView = (SPCAVPlayerView *)self.viewCurrentMemoryContent;
        [playerView stop];
    }
    
    _memoryCurrent = memoryCurrent; // Set property
    
    // Update the current memory view
    // Remove any memories occupying the current memory view
    NSArray *subviews = self.viewCurrentMemory.subviews;
    UIView *subview = (UIView *)[subviews firstObject];
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        subview.alpha = 0.0f;
    } completion:^(BOOL finished) {
        for (UIView *subview in subviews) {
            [subview removeFromSuperview];
        }
    }];
    
    if (nil != memoryCurrent) {
        // Add the current memory to the current memory view
        self.viewCurrentMemoryContent = nil;
        UIView *viewNewMemoryContent;
        NSDictionary *memData = [self.dicMemoryToData objectForKey:@(memoryCurrent.recordID)];
        if ([memoryCurrent isKindOfClass:[VideoMemory class]]) {
            SPCAVPlayerView *playerView = [memData objectForKey:kVID_PLR_VIEW];
            
            // Video-specific setup
            [self.timer invalidate]; // Wait for our video to begin playback before starting the timer
            self.currentMemoryDisplayDuration = playerView.duration + ANIMATION_DURATION/2.0f;
            //        self.lblCountdown.text = @""; // Hide the countdown duration
            //        self.pvCountdown.progress = 1.0f; // Set the progress value to full
            
            playerView.volume = 1.0f;
            
            viewNewMemoryContent = playerView;
        } else if ([memoryCurrent isKindOfClass:[ImageMemory class]]) {
            UIImageView *ivImage = [[UIImageView alloc] init];
            ivImage.contentMode = UIViewContentModeScaleAspectFill;
            
            ImageMemory *memoryImage = (ImageMemory *)memoryCurrent;
            Asset *asset = [memoryImage.images firstObject];
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:[asset imageUrlSquare]] options:SDWebImageDelayPlaceholder progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                if (finished) {
                    if (image) {
                        ivImage.image = image;
                    }
                }
            }];
            
            viewNewMemoryContent = ivImage;
            self.currentMemoryDisplayDuration = IMAGE_DISPLAY_INTERVAL + ANIMATION_DURATION/2.0f;
        } else if (MemoryTypeText == memoryCurrent.type) {
            NSString *text = [memData objectForKey:kTXT];
            
            UILabel *lblText = [[UILabel alloc] init];
            lblText.text = text;
            lblText.backgroundColor = [UIColor clearColor];
            lblText.textColor = [UIColor whiteColor];
            lblText.textAlignment = NSTextAlignmentCenter;
            lblText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:30.0f];
            lblText.numberOfLines = 0;
            lblText.autoresizesSubviews = YES;
            lblText.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            UIView *viewBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
            viewBackground.backgroundColor = [UIColor colorWithRed:138.0f/255.0f green:192.0f/255.0f blue:249.0f/255.0f alpha:1.0f];
            [viewBackground addSubview:lblText];
            CGSize sizeThatFitsLabel = [lblText sizeThatFits:CGRectInset(viewBackground.frame, 5, 5).size];
            lblText.frame = CGRectMake(0, 0, sizeThatFitsLabel.width, sizeThatFitsLabel.height);
            lblText.center = viewBackground.center;
            
            viewNewMemoryContent = viewBackground;
            self.currentMemoryDisplayDuration = IMAGE_DISPLAY_INTERVAL + ANIMATION_DURATION/2.0f;
        }
        // Current mem seconds remaining
        self.currentMemorySecondsRemaining = self.currentMemoryDisplayDuration;
        self.secondsRemaining = [self secondsRemainingFromMemory:self.memoryCurrent];
        
        // Set resizing properties
        viewNewMemoryContent.autoresizesSubviews = YES;
        viewNewMemoryContent.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // Animate in the new memory
        viewNewMemoryContent.alpha = 0.0f;
        viewNewMemoryContent.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)); // Setting this to self.viewCurrentMemory.bounds may result in an undesired frame, since viewCurrentMemory changes its bound shortly after a users touches the play button
        [self.viewCurrentMemory addSubview:viewNewMemoryContent];
        self.viewCurrentMemoryContent = viewNewMemoryContent; // Set this for future reference (this is a weak pointer, so we can only set it once there is an owner who holds a strong pointer to it (i.e. self.viewCurrentMemory)
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            viewNewMemoryContent.alpha = 1.0f;
        }];
        
        // Update the author button
        [self.ivAuthor prepareForReuse];
        self.ivAuthor.alpha = 0.0f;
        UIImage *imageAuthor = [memData objectForKey:kIMG_AUTHOR];
        if (nil != imageAuthor) {
            self.ivAuthor.textLabel.hidden = YES;
            self.ivAuthor.image = imageAuthor;
        } else {
            NSString *authorFirstInitial = 0 < memoryCurrent.author.firstname.length ? [memoryCurrent.author.firstname substringWithRange:NSMakeRange(0, 1)] : @"";
            [self.ivAuthor configureWithText:authorFirstInitial url:[NSURL URLWithString:memoryCurrent.author.imageAsset.imageUrlThumbnail]];
        }
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.ivAuthor.alpha = 1.0f;
        }];
        
        // Add in the pin/location - only if there is text to be shown
        NSString *strLocation = [self getLocationFromMemory:memoryCurrent];
        if (0 < strLocation.length)
        {
            // Alloc the pin imageview and text label
            UIImageView *ivPin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin-white-x-small"]];
            UILabel *lblLocation = [[UILabel alloc] init];
            
            // Configure text label
            lblLocation.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12.0f];
            lblLocation.textColor = [UIColor whiteColor];
            lblLocation.text = strLocation;
            lblLocation.textAlignment = NSTextAlignmentRight;
            [lblLocation sizeToFit];
            
            // Alloc & configure gradient background view
            UIView *gradientBackground = [[UIView alloc] initWithFrame:CGRectMake(10.0f, CGRectGetHeight(self.contentView.bounds) - lblLocation.font.lineHeight - 10.0f, CGRectGetWidth(lblLocation.frame) + 16.0f, lblLocation.font.lineHeight)];
            gradientBackground.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
            gradientBackground.layer.cornerRadius = 2.0f;
            gradientBackground.layer.masksToBounds = YES;
            
            // Update the label's frame
            CGRect lblLocationFrame = lblLocation.frame;
            lblLocationFrame.origin = CGPointMake(12.0f, -0.5f);
            lblLocation.frame = lblLocationFrame;
            
            // Update the pin's center
            ivPin.center = CGPointMake(6.5f, CGRectGetHeight(gradientBackground.frame)/2.0f);
            
            // Insert the pin/label into the gradient background's view
            [gradientBackground addSubview:lblLocation];
            [gradientBackground addSubview:ivPin];
            
            // Add the gradient into the memory content view
            [viewNewMemoryContent addSubview:gradientBackground];
        }
        
        // Coachmark - show it if we have a valid object
        if (nil != self.viewCoachmark) {
            [self insertSubview:self.viewCoachmark aboveSubview:self.viewCurrentMemory];
        }
    } else {
        // Setting memory current to nil
        // Make sure we remove the coachmark view if we are still maintaining it
        if (nil != self.viewCoachmark) {
            [self removeCoachmarkViewAndPlay:NO];
        }
    }
}

- (void)setTimer:(NSTimer *)timer {
    if (nil != _timer) {
        [_timer invalidate];
    }
    
    _timer = timer;
}

- (void)setCurrentMemorySecondsRemaining:(CGFloat)currentMemorySecondsRemaining {
    _currentMemorySecondsRemaining = currentMemorySecondsRemaining;
    
    self.pvCountdown.progress = currentMemorySecondsRemaining / self.currentMemoryDisplayDuration;
}

- (void)setImageBackground:(UIImage *)imageBackground {
    self.ivBackground.image = imageBackground;
    [self sendSubviewToBack:self.ivBackground];
}

- (void)setMemories:(NSArray *)memories {
    // Let's filter our memories to contain only image/video/text mems,
    // and to omit anything by a blocked user.
    NSMutableArray *filteredMemories = [[NSMutableArray alloc] init];
    NSArray *blockedIds = [MeetManager getBlockedIds];
    for (Memory *mem in memories) {
        BOOL typeOk = MemoryTypeImage == mem.type || MemoryTypeVideo == mem.type || MemoryTypeText == mem.type;
        BOOL blocked = [blockedIds containsObject:@(mem.author.recordID)];
        if (typeOk && !blocked) {
            [filteredMemories addObject:mem];
        }
    }
    
    _memories = filteredMemories;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.lblTitle.text = title;
}

- (void)setOverlayColor:(UIColor *)overlayColor {
    _overlayColor = overlayColor;
    self.viewOverlay.backgroundColor = overlayColor;
}

- (void)setIsReady:(BOOL)isReady {
    _isReady = isReady;
    
    if (isReady) { // Notify our delegate
        if ([self.delegate respondsToSelector:@selector(didLoadMemories:OnSPCMontageView:)]) {
            [self.delegate didLoadMemories:self.memories OnSPCMontageView:self];
        }
    }
}

- (void)setDicMemoryToData:(NSDictionary *)dicMemoryToData andPrepareMontage:(BOOL)prepareMontage {
    _dicMemoryToData = dicMemoryToData;
    
    if (prepareMontage) {
        // Go ahead and create the stitched preview image with the loaded data, or alert the delegate that we did not get enough memories loaded
        if (MIN_MEMS <= dicMemoryToData.count) {
            // Get our full montage duration
            NSTimeInterval duration = 0.0f + ANIMATION_DURATION/2.0f;
            for (NSDictionary *dicData in dicMemoryToData.allValues) {
                NSNumber *typeNum = [dicData objectForKey:kMEM_TYPE];
                MemoryType type = (MemoryType)[typeNum integerValue];
                
                if (MemoryTypeText == type || MemoryTypeImage == type) {
                    duration = duration + IMAGE_DISPLAY_INTERVAL + ANIMATION_DURATION/2.0f;
                } else if (MemoryTypeVideo == type) {
                    NSNumber *durationNumber = [dicData objectForKey:kVID_DURATION];
                    duration = duration + [durationNumber doubleValue] + ANIMATION_DURATION/2.0f;
                }
            }
            
            self.fullMontageDuration = duration + ANIMATION_DURATION/2.0f;
            self.secondsRemaining = self.fullMontageDuration;
            
            if (0.0f < self.fullMontageDuration) {
                // Create our background image and let 'er rip
                __weak typeof(self) weakSelf = self;
                [self loadBackgroundImageWithCompletionBlock:^(BOOL succeeded, UIImage *image) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (succeeded) {
                        // Set the background image on the main thread and wait until it's finished
                        [strongSelf performSelectorOnMainThread:@selector(setImageBackground:) withObject:image waitUntilDone:YES];
                        strongSelf.isReady = YES;
                    } else if ([strongSelf.delegate respondsToSelector:@selector(didFailToLoadMemoriesOnSPCMontageView:)]) {
                        [strongSelf.delegate didFailToLoadMemoriesOnSPCMontageView:strongSelf];
                    }
                }];
            }
        } else if ([self.delegate respondsToSelector:@selector(didFailToLoadMemoriesOnSPCMontageView:)]) {
            [self.delegate didFailToLoadMemoriesOnSPCMontageView:self];
        }
    }
}

- (Memory *)memoryCurrentlyDisplayed {
    return self.memoryCurrent;
}

- (NSTimeInterval)secondsRemainingFromMemory:(Memory *)memory {
    CGFloat secondsRemaining = 0.0f; // Default
    
    NSInteger indexOfMemory = [self.memories indexOfObject:memory];
    if (NSNotFound != indexOfMemory) {
        secondsRemaining = 0.0f + ANIMATION_DURATION/2.0f;
        for (NSInteger i = self.memories.count - 1; i >= indexOfMemory; --i) {
            Memory *memAtIndex = [self.memories objectAtIndex:i];
            if (MemoryTypeText == memAtIndex.type || MemoryTypeImage == memAtIndex.type) {
                secondsRemaining = secondsRemaining + IMAGE_DISPLAY_INTERVAL + ANIMATION_DURATION/2.0f;
            } else if (MemoryTypeVideo == memAtIndex.type) {
                NSDictionary *dicData = [self.dicMemoryToData objectForKey:@(memAtIndex.recordID)];
                if (nil != dicData) {
                    NSNumber *durationNum = [dicData objectForKey:kVID_DURATION];
                    secondsRemaining = secondsRemaining + [durationNum doubleValue] + ANIMATION_DURATION/2.0f;
                } else {
                    // Don't add any time for this item - we have no data for it.
                }
            }
        }
    }
    
    return secondsRemaining;
}

#pragma mark - SPCMontageCoachmarkViewDelegate

- (void)didTapToEndOnCoachmarkView:(SPCMontageCoachmarkView *)montageCoachmarkView {
    if ([self.viewCoachmark isEqual:montageCoachmarkView]) {
        [self removeCoachmarkViewAndPlay:YES];
    }
    
    if ([self.delegate respondsToSelector:@selector(didTapCoachmarkToCompletionOnSPCMontageView:)]) {
        [self.delegate didTapCoachmarkToCompletionOnSPCMontageView:self];
    }
}

- (void)removeCoachmarkViewAndPlay:(BOOL)play {
    [UIView animateWithDuration:0.3f animations:^{
        self.viewCoachmark.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.viewCoachmark removeFromSuperview];
        self.viewCoachmark = nil;
        if (play) {
            [self play];
        }
    }];
}

#pragma mark - SPCAVPlayerViewDelegate

- (void)didStartPlaybackWithPlayerView:(SPCAVPlayerView *)playerView {
    NSLog(@"MONTAGE: STARTED PLAYBACK");
    if (MemoryTypeVideo == self.memoryCurrent.type && [self.viewCurrentMemoryContent isEqual:playerView] && nil == self.viewCoachmark) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(countdownTimerFired) userInfo:nil repeats:YES];
    }
}

- (void)didStopOrPausePlaybackWithPlayerView:(SPCAVPlayerView *)playerView {
    NSLog(@"MONTAGE: stopOrPaused Playback");
    if (MemoryTypeVideo == self.memoryCurrent.type && [self.viewCurrentMemoryContent isEqual:playerView]) {
        [self.timer invalidate]; // Pause/invalidate the timer if we stopped/pause the current displayed memory's playback
    }
}

- (void)didResumePlaybackWithPlayerView:(SPCAVPlayerView *)playerView {
    NSLog(@"MONTAGE: didRESUMEPlayback");
    if (MemoryTypeVideo == self.memoryCurrent.type && [self.viewCurrentMemoryContent isEqual:playerView]) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(countdownTimerFired) userInfo:nil repeats:YES];
    }
}

- (void)didFinishPlaybackToEndWithPlayerView:(SPCAVPlayerView *)playerView {
    // Use this as a failsafe in case the video player gets in a funky state where it comes back from applicationdidbecomeactive
    if (MemoryTypeVideo == self.memoryCurrent.type && [self.viewCurrentMemoryContent isEqual:playerView] && NO == [self.timer isValid]) {
        [self playNextMemory];
    }
    
    [playerView stop];
}

- (void)isReadyToPlayWithPlayerView:(SPCAVPlayerView *)playerView {
    [self setVideoDuration:playerView.duration andReadyStatus:YES forPlayerView:playerView];
}

- (void)didFailToPlayWithError:(NSError *)error withPlayerView:(SPCAVPlayerView *)playerView {
    if ([playerView isEqual:self.viewCurrentMemoryContent]) {
        // This is the video that is currently playing
        [self.timer invalidate]; // Stop the timer, and go on to the next memory. Something went wrong.
        
        [self playNextMemory];
    } else {
        [self setVideoDuration:playerView.duration andReadyStatus:NO forPlayerView:playerView];
        playerView.delegate = nil;
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Private properties
    // Content view
    self.contentView.frame = self.bounds;
    
    // Pre-montage views
    // Background stitched images view
    self.ivBackground.frame = self.contentView.bounds;
    
    // Overlay
    self.viewOverlay.frame = self.contentView.bounds;
    
    // Title label
    self.lblTitle.center = CGPointMake(CGRectGetWidth(self.contentView.bounds)/2.0f, CGRectGetHeight(self.contentView.bounds)*356.0f/540.0f);
    
    // Play button
    self.btnPlay.center = CGPointMake(CGRectGetWidth(self.contentView.bounds)/2.0f, CGRectGetHeight(self.contentView.bounds)*239.0f/540.0f);
    
    // Intra-montage views
    // Background
    self.viewMontageBackground.frame = self.contentView.bounds;
    
    // Current memory
    self.viewCurrentMemory.frame = self.contentView.bounds;
    
    // Dismiss button
    self.btnDismiss.frame = CGRectMake(0, 0, 40, 40);
    self.btnDismiss.center = CGPointMake(30, 30);
    self.btnDismiss.layer.cornerRadius = CGRectGetHeight(self.btnDismiss.frame)/2.0f;
    
    // Author image
    self.ivAuthor.frame = CGRectMake(0, 0, 40 - self.pvCountdown.lineWidth, 40 - self.pvCountdown.lineWidth);
    self.ivAuthor.layer.cornerRadius = CGRectGetHeight(self.ivAuthor.frame)/2.0f;
    [self.pvCountdown setNeedsLayout];
    
    // Countdown progress view
    self.pvCountdown.frame = CGRectMake(0, 0, 40, 40);
    self.pvCountdown.center = CGPointMake(CGRectGetWidth(self.contentView.frame) - 30, 30);
    self.pvCountdown.layer.cornerRadius = CGRectGetHeight(self.pvCountdown.frame)/2.0f;
}

#pragma mark - dealloc
- (void)dealloc {
    if (nil != self.timer) {
        [self.timer invalidate];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Init
- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    // Public properties
    _memories = nil;
    _title = @"";
    _overlayColor = [UIColor colorWithWhite:0.0 alpha:0.3f];
    
    // Private properties
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.autoresizesSubviews = YES;
    self.backgroundColor = [UIColor clearColor];
    _secondsRemaining = IMAGE_DISPLAY_INTERVAL;
    
    // Content view
    _contentView = [[UIView alloc] init];
    _contentView.autoresizesSubviews = YES;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:_contentView];
    
    // Background stitched images view
    _ivBackground = [[UIImageView alloc] init];
    _ivBackground.contentMode = UIViewContentModeScaleAspectFill;
    _ivBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _ivBackground.image = nil;
    [self addSubview:_ivBackground];
    
    // Pre-montage views
    // Overlay
    _viewOverlay = [[UIView alloc] init];
    _viewOverlay.backgroundColor = self.overlayColor;
    _viewOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView insertSubview:_viewOverlay aboveSubview:_ivBackground];
    
    // Title label
    _lblTitle = [[UILabel alloc] init];
    _lblTitle.numberOfLines = 0;
    _lblTitle.textAlignment = NSTextAlignmentCenter;
    _lblTitle.textColor = [UIColor whiteColor];
    _lblTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0f];
    _lblTitle.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView insertSubview:_lblTitle aboveSubview:_viewOverlay];
    
    // Play button
    _btnPlay = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
    [_btnPlay setBackgroundImage:[UIImage imageNamed:@"montage-play"] forState:UIControlStateNormal];
    [_btnPlay addTarget:self action:@selector(tappedPlayButton:) forControlEvents:UIControlEventTouchUpInside];
    _btnPlay.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView insertSubview:_btnPlay aboveSubview:_viewOverlay];
    
    // Intra-montage views
    // Background
    _viewMontageBackground = [[UIView alloc] init];
    _viewMontageBackground.backgroundColor = [UIColor blackColor];
    _viewMontageBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:_viewMontageBackground];
    
    // Current mem holder
    _viewCurrentMemory = [[UIView alloc] init];
    _viewCurrentMemory.backgroundColor = [UIColor clearColor];
    // Gesture Recognizers
    UITapGestureRecognizer *grTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMemory:)];
    UISwipeGestureRecognizer *grForward = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedMemory:)];
    grForward.direction = UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *grBack = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedMemory:)];
    grBack.direction = UISwipeGestureRecognizerDirectionRight;
    _viewCurrentMemory.gestureRecognizers = @[grTap, grForward, grBack];
    _viewCurrentMemory.autoresizesSubviews = YES;
    _viewCurrentMemory.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _viewCurrentMemory.clipsToBounds = YES;
    [self.contentView insertSubview:_viewCurrentMemory aboveSubview:_viewMontageBackground];
    
    // Dismiss button
    _btnDismiss = [[UIButton alloc] init];
    [_btnDismiss setImage:[UIImage imageNamed:@"montage-dismiss"] forState:UIControlStateNormal];
    [_btnDismiss addTarget:self action:@selector(tappedDismissButton:) forControlEvents:UIControlEventTouchUpInside];
    _btnDismiss.layer.masksToBounds = YES;
    _btnDismiss.autoresizingMask = UIViewAutoresizingNone;
    [self.contentView addSubview:_btnDismiss];
    
    // Author image
    _ivAuthor = [[SPCInitialsImageView alloc] init];
    _ivAuthor.layer.masksToBounds = YES;
    _ivAuthor.layer.shadowColor = [UIColor blackColor].CGColor;
    _ivAuthor.layer.shadowOpacity = 0.3f;
    _ivAuthor.layer.shadowRadius = 2.0f;
    _ivAuthor.autoresizingMask = UIViewAutoresizingNone;
    
    // Countdown progress view
    _pvCountdown = [[UAProgressView alloc] init];
    _pvCountdown.borderWidth = 0.0f;
    _pvCountdown.lineWidth = 6.0f/[UIScreen mainScreen].scale;
    _pvCountdown.tintColor = [UIColor whiteColor];
    _pvCountdown.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    _pvCountdown.autoresizingMask = UIViewAutoresizingNone;
    _pvCountdown.gestureRecognizers = @[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAuthorButton:)]];
    [self.contentView addSubview:_pvCountdown];
    [_pvCountdown setCentralView:_ivAuthor];
    
    // Set default, initial audiosessioncategory, until playback starts
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    [self stop];
}

#pragma mark - Helpers

- (UIImage *)createStitchedImageFromData:(NSDictionary *)dicMemoryToData {
    UIImage *imageToReturn = nil;
    
    if (NO == CGRectEqualToRect(CGRectZero, self.frame)) {
        CGFloat viewHeight = self.previewImageSize.height;
        CGFloat viewWidth = self.previewImageSize.width;
        CGSize singleImageSize = CGSizeMake(viewWidth/4.0f, viewHeight/3.0f);
        UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0f);
        
        NSArray *keys = dicMemoryToData.allKeys;
        int keyIndex = 0;
        for (int row = 0; row < 3; ++row) {
            for (int column = 0; column < 4; ++column, ++keyIndex) {
                // Determine if we should draw an image (from an image/vid mem)
                // or if we should draw a text mem
                
                id key = [keys objectAtIndex:keyIndex];
                NSDictionary *dicData = [dicMemoryToData objectForKey:key];
                CGRect rectToDraw = CGRectMake(column * singleImageSize.width, row * singleImageSize.height, singleImageSize.width, singleImageSize.height);
                
                UIImage *image = [dicData objectForKey:kIMG];
                if (nil != image) {
                    [image drawInRect:rectToDraw];
                } else {
                    NSString *text = [dicData objectForKey:kTXT];
                    if (nil != text) {
                        [[UIColor colorWithRed:138.0f/255.0f green:192.0f/255.0f blue:249.0f/255.0f alpha:1.0f] setFill];
                        UIRectFill(rectToDraw);
                        
                        UILabel *lblText = [[UILabel alloc] init];
                        lblText.text = text;
                        lblText.backgroundColor = [UIColor clearColor];
                        lblText.textColor = [UIColor whiteColor];
                        lblText.textAlignment = NSTextAlignmentLeft;
                        lblText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10.0f];
                        lblText.numberOfLines = 0;
                        
                        CGSize sizeThatFitsLabel = [lblText sizeThatFits:CGRectInset(rectToDraw, 5, 5).size];
                        lblText.frame = CGRectMake(0, 0, sizeThatFitsLabel.width, sizeThatFitsLabel.height);
                        lblText.center = CGPointMake(CGRectGetMaxX(rectToDraw) - (rectToDraw.size.width)/2.0f, CGRectGetMaxY(rectToDraw) - (rectToDraw.size.height)/2.0f);
                        
                        [text drawInRect:lblText.frame withAttributes:@{ NSFontAttributeName : lblText.font, NSForegroundColorAttributeName : lblText.textColor }];
                    }
                }
            }
        }
        
        imageToReturn = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return imageToReturn;
}

- (void)finishedLoadingSingleMemory:(Memory *)memoryLoaded {
    if (self.dicTempMemoriesToData.count == self.memories.count) {
        BOOL allMemoriesAttemptedLoad = YES;
        for (NSNumber *memRecordId in self.dicTempMemoriesToData.allKeys) {
            // Get the data - constant time
            NSDictionary *dicData = [self.dicTempMemoriesToData objectForKey:memRecordId];
            
            NSNumber *typeNum = [dicData objectForKey:kMEM_TYPE];
            MemoryType type = (MemoryType)[typeNum integerValue];
            
            // Image and text mems will only be present in the self.dicTempMemoriesToData dictionary if they have already attempted to load
            // Must check video mems
            if (MemoryTypeVideo == type) {
                if (NO == [[dicData objectForKey:kVID_LOAD_ATT] boolValue]) {
                    allMemoriesAttemptedLoad = NO;
                }
            }
        }
        
        if (allMemoriesAttemptedLoad) {
            BOOL allMemoriesLoaded = YES;
            NSMutableArray *arrayMemoriesNotLoaded = [[NSMutableArray alloc] init]; // In order to remove the mems that did not load
            for (NSNumber *memRecordId in self.dicTempMemoriesToData.allKeys) {
                // Get the data - constant time
                NSDictionary *dicData = [self.dicTempMemoriesToData objectForKey:memRecordId];
                
                NSNumber *typeNum = [dicData objectForKey:kMEM_TYPE];
                MemoryType type = (MemoryType)[typeNum integerValue];
                
                if (MemoryTypeText == type) {
                    // Text is here already. Ensure the author image is also here
                    BOOL loadedAuthorImage = [[dicData objectForKey:kIMG_AUTHOR_CACHED] boolValue];
                    if (NO == loadedAuthorImage) {
                        allMemoriesLoaded = NO;
                        [arrayMemoriesNotLoaded addObject:memRecordId];
                    }
                } else if (MemoryTypeImage == type) {
                    // Check for author and memory images
                    BOOL loadedAuthorImage = [[dicData objectForKey:kIMG_AUTHOR_CACHED] boolValue];
                    BOOL loadedImage = [[dicData objectForKey:kIMG_CACHED] boolValue];
                    if (NO == loadedAuthorImage || NO == loadedImage) {
                        allMemoriesLoaded = NO;
                        [arrayMemoriesNotLoaded addObject:memRecordId];
                    }
                } else if (MemoryTypeVideo == type) {
                    // Check for author, preview, and the video/isReady status
                    BOOL loadedAuthorImage = [[dicData objectForKey:kIMG_AUTHOR_CACHED] boolValue];
                    UIView *viewPlayer = [dicData objectForKey:kVID_PLR_VIEW];
                    NSNumber *readyNum = [dicData objectForKey:kVID_RDY];
                    BOOL ready = [readyNum boolValue];
                    if (NO == loadedAuthorImage || nil == viewPlayer || NO == ready) {
                        allMemoriesLoaded = NO;
                        [arrayMemoriesNotLoaded addObject:memRecordId];
                    }
                }
            }
            
            if (allMemoriesLoaded) {
                // Prepare the montage
                [self setDicMemoryToData:self.dicTempMemoriesToData andPrepareMontage:YES];
                self.dicTempMemoriesToData = nil;
                self.dicTempMemoryToPlayerView = nil;
            } else {
                // Remove the bad memories - do NOT prepare the montage
                for (NSNumber *memRecordId in arrayMemoriesNotLoaded) {
                    [self.dicTempMemoriesToData removeObjectForKey:memRecordId];
                }
                
                [self setDicMemoryToData:self.dicTempMemoriesToData andPrepareMontage:NO];
                self.dicTempMemoriesToData = nil;
                self.dicTempMemoryToPlayerView = nil;
            }
        }
    } else {
        NSInteger indexOfMemoryToLoadNext = [self.memories indexOfObject:memoryLoaded] + 1;
        if (indexOfMemoryToLoadNext < self.memories.count) {
            Memory* memoryNext = [self.memories objectAtIndex:indexOfMemoryToLoadNext];
            
            // Load the next memory only if we have not yet loaded it in
            if (nil == [self.dicTempMemoriesToData objectForKey:@(memoryNext.recordID)]) {
                [self loadMemory:memoryNext];
            }
        }
    }
}

- (void)loadBackgroundImageWithCompletionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock {
    NSAssert(nil != completionBlock, @"Must use this method with a completion handler");
    
    if (NUM_IMAGES_ON_BACKGROUND <= self.dicMemoryToData.count) {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        __block NSMutableArray *arrayImagesAndTextLoaded = [[NSMutableArray alloc] init];
        
        for (NSInteger i = 0; i < NUM_IMAGES_ON_BACKGROUND; ++i) {
            Memory *memory = [self.memories objectAtIndex:i];
            
            if ([memory isKindOfClass:[ImageMemory class]]) {
                ImageMemory *memImage = (ImageMemory *)memory;
                Asset *asset = [memImage.images firstObject];
                NSURL *assetUrl = [NSURL URLWithString:[asset imageUrlSquare]];
                
                [manager downloadImageWithURL:assetUrl options:SDWebImageDelayPlaceholder progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    if (finished) {
                        [arrayImagesAndTextLoaded addObject:image];
                        
                        if (NUM_IMAGES_ON_BACKGROUND == arrayImagesAndTextLoaded.count) {
                            UIImage *imageToReturn = [self stitchedImageFromImagesAndText:arrayImagesAndTextLoaded];
                            
                            completionBlock(YES, imageToReturn);
                        }
                    }
                }];
            } else if ([memory isKindOfClass:[VideoMemory class]]) {
                VideoMemory *memVideo = (VideoMemory *)memory;
                Asset *asset = [memVideo.previewImages firstObject];
                NSURL *assetUrl = [NSURL URLWithString:[asset imageUrlSquare]];
                
                [manager downloadImageWithURL:assetUrl options:SDWebImageDelayPlaceholder progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    if (finished) {
                        [arrayImagesAndTextLoaded addObject:image];
                        
                        if (NUM_IMAGES_ON_BACKGROUND == arrayImagesAndTextLoaded.count) {
                            UIImage *imageToReturn = [self stitchedImageFromImagesAndText:arrayImagesAndTextLoaded];
                            
                            completionBlock(YES, imageToReturn);
                        }
                    }
                }];
            } else {
                [arrayImagesAndTextLoaded addObject:memory.text];
                
                if (NUM_IMAGES_ON_BACKGROUND == arrayImagesAndTextLoaded.count) {
                    UIImage *imageToReturn = [self stitchedImageFromImagesAndText:arrayImagesAndTextLoaded];
                    
                    completionBlock(YES, imageToReturn);
                }
            }
        }
    } else {
        completionBlock(NO, nil);
    }
}

- (UIImage *)stitchedImageFromImagesAndText:(NSArray *)arrayImagesAndText {
    CGFloat viewHeight = self.previewImageSize.height;
    CGFloat viewWidth = self.previewImageSize.width;
    CGSize singleImageSize = CGSizeMake(viewWidth/4.0f, viewHeight/3.0f);
    UIGraphicsBeginImageContextWithOptions(self.previewImageSize, NO, 0.0f);
    
    NSInteger imageIndex = 0; // Easy way of referencing the next image
    for (NSInteger row = 0; row < 3; ++row) {
        for (NSInteger column = 0; column < 4; ++column) {
            // Get our rect and image
            CGRect rectToDraw = CGRectMake(column * singleImageSize.width, row * singleImageSize.height, singleImageSize.width, singleImageSize.height);
            
            NSObject *objImageOrText = [arrayImagesAndText objectAtIndex:imageIndex++];
            if ([objImageOrText isKindOfClass:[UIImage class]]) {
                UIImage *imageToDraw = (UIImage *)objImageOrText;
                
                // Draw the image in the rect
                [imageToDraw drawInRect:rectToDraw];
            } else if ([objImageOrText isKindOfClass:[NSString class]]) {
                NSString *text = (NSString *)objImageOrText;
                [[UIColor colorWithRed:138.0f/255.0f green:192.0f/255.0f blue:249.0f/255.0f alpha:1.0f] setFill];
                UIRectFill(rectToDraw);
                
                UILabel *lblText = [[UILabel alloc] init];
                lblText.text = text;
                lblText.backgroundColor = [UIColor clearColor];
                lblText.textColor = [UIColor whiteColor];
                lblText.textAlignment = NSTextAlignmentLeft;
                lblText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10.0f];
                lblText.numberOfLines = 0;
                
                CGSize sizeThatFitsLabel = [lblText sizeThatFits:CGRectInset(rectToDraw, 5, 5).size];
                lblText.frame = CGRectMake(0, 0, sizeThatFitsLabel.width, sizeThatFitsLabel.height);
                lblText.center = CGPointMake(CGRectGetMaxX(rectToDraw) - (rectToDraw.size.width)/2.0f, CGRectGetMaxY(rectToDraw) - (rectToDraw.size.height)/2.0f);
                
                [text drawInRect:rectToDraw withAttributes:@{ NSFontAttributeName : lblText.font, NSForegroundColorAttributeName : lblText.textColor }];
            }
        }
    }
    
    UIImage *imageToReturn = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageToReturn;
}

- (void)setVideoDuration:(NSTimeInterval)duration andReadyStatus:(BOOL)readyStatus forPlayerView:(SPCAVPlayerView *)playerView {
    // This will be called as the videos are being loaded in
    // Find the memory with which this playerView is associated
    if (nil != self.dicTempMemoriesToData) {
        for (Memory *memory in self.memories) { // O(N) time
            if (MemoryTypeVideo == memory.type) { // Only browse into video mems
                NSDictionary *dicData = [self.dicTempMemoriesToData objectForKey:@(memory.recordID)];
                if (nil != dicData) { // If we have temp data for this particular memId
                    SPCAVPlayerView *player = [dicData objectForKey:kVID_PLR_VIEW];
                    if (nil != player && [player isEqual:playerView]) { // If the players are the same
                        // Update the info
                        NSMutableDictionary *dicDataNew = [NSMutableDictionary dictionaryWithDictionary:dicData];
                        [dicDataNew setObject:@(readyStatus) forKey:kVID_RDY];
                        [dicDataNew setObject:@(duration) forKey:kVID_DURATION];
                        [dicDataNew setObject:@(YES) forKey:kVID_LOAD_ATT];
                        [self.dicTempMemoriesToData setObject:dicDataNew forKey:@(memory.recordID)];
                        
                        // Process
                        [self finishedLoadingSingleMemory:memory];
                        
                        break;
                    }
                }
            }
        }
    }
}

// This method's implementation was mostly ripped out of SPCTrendingVenueCell.m
- (NSString *)getLocationFromMemory:(Memory *)memory {
    Venue *venue = memory.venue;
    
    NSString * specific;
    //USA
    if ([venue.country isEqualToString:@"US"]) {
        if (venue.city) {
            specific = [NSString stringWithFormat:@"%@, USA", venue.city];
        }
        else {
            if (venue.county) {
                specific = [NSString stringWithFormat:@"%@, USA",venue.county];
                
            }
            else {
                specific = NSLocalizedString(@"USA", nil);
            }
        }
    }
    //INTL
    else {
        if (venue.city) {
            specific = [NSString stringWithFormat:@"%@, %@", venue.city, venue.country];
        }
        else {
            if (venue.county) {
                specific = [NSString stringWithFormat:@"%@, %@", venue.county, venue.country];
                
            }
            else {
                specific = [NSString stringWithFormat:@"%@",venue.country];
            }
        }
    }
    
    NSString * venueName = venue.venueName ? venue.venueName : venue.streetAddress;
    
    if (venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
        specific = [NSString stringWithFormat:@"%@, %@",venue.city, venue.country];
        
        if ([venue.country isEqualToString:@"US"]) {
            specific = [NSString stringWithFormat:@"%@, USA",venue.city];
        }
        
        venueName = venue.neighborhood;
        
    }
    if (venue.specificity == SPCVenueIsFuzzedToCity) {
        specific = [NSString stringWithFormat:@"%@, %@",venue.city, venue.country];
        
        if ([venue.country isEqualToString:@"US"]) {
            specific = [NSString stringWithFormat:@"%@, USA",venue.city];
        }
        
        venueName = nil;
    }
    
    NSString *finalString = nil;
    if (nil != venueName && self.useLocalLocations) {
        finalString = [NSString stringWithFormat:@"%@, %@", venueName, specific];
    } else {
        finalString = specific;
    }
    
    return finalString;
}

@end

@interface SPCMontageCoachmarkView()

@property (strong, nonatomic) UIView *contentView;

// Icon and message
@property (strong, nonatomic) UIImageView *ivSwipe;
@property (strong, nonatomic) UIImageView *ivTap;
@property (strong, nonatomic) UILabel *lblMessage;

// Button
@property (strong, nonatomic) UIButton *btn;

// Tap count / simple state variable
@property (nonatomic) NSInteger numberOfTaps;

@end

@implementation SPCMontageCoachmarkView

#pragma mark - Target-Action

- (void)tappedButton:(id)sender {
    // Check our state. We can improve this check to be more robust in the future if we expand on this coachmark
    if (0 == self.numberOfTaps++) {
        [self showTapCoachmarkAnimated:YES];
    } else {
        self.numberOfTaps = 0;
        
        if ([self.delegate respondsToSelector:@selector(didTapToEndOnCoachmarkView:)]) {
            [self.delegate didTapToEndOnCoachmarkView:self];
        } else {
            [UIView animateWithDuration:0.3f animations:^{
                self.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [self removeFromSuperview];
                [self showSwipeCoachmarkAnimated:NO];
                self.alpha = 1.0f;
            }];
        }
    }
}

#pragma mark - Configuration

- (void)showSwipeCoachmarkAnimated:(BOOL)animated {
    // Icons
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.ivTap.alpha = 0.0f;
            self.ivSwipe.alpha = 1.0f;
        }];
    } else {
        self.ivTap.alpha = 0.0f;
        self.ivSwipe.alpha = 1.0f;
    }
    
    // Message
    NSString *strMessage = @"Swipe left and right for\nnext and previous memories";
    NSMutableAttributedString *strAttributedMessage = [[NSMutableAttributedString alloc] initWithString:strMessage attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14.0f] }];
    [strAttributedMessage addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Bold" size:14.0f] range:[strMessage rangeOfString:@"left"]];
    [strAttributedMessage addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Bold" size:14.0f] range:[strMessage rangeOfString:@"right"]];
    self.lblMessage.attributedText = strAttributedMessage;
    
    // Button
    [self.btn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"NEXT" attributes:nil] forState:UIControlStateNormal];
    
    [self setNeedsLayout];
}

- (void)showTapCoachmarkAnimated:(BOOL)animated {
    // Icons
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.ivTap.alpha = 1.0f;
            self.ivSwipe.alpha = 0.0f;
        }];
    } else {
        self.ivTap.alpha = 1.0f;
        self.ivSwipe.alpha = 0.0f;
    }
    
    // Message
    NSString *strMessage = @"Tap memory to see comments";
    NSMutableAttributedString *strAttributedMessage = [[NSMutableAttributedString alloc] initWithString:strMessage attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14.0f] }];
    self.lblMessage.attributedText = strAttributedMessage;
    
    // Button
    [self.btn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"GOT IT!" attributes:nil] forState:UIControlStateNormal];
    
    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    CGFloat PSD_WIDTH = 750.0f;
    CGFloat PSD_HEIGHT = 750.0f;
    
    // Content view
    self.contentView.frame = self.bounds;
    
    // Icons
    self.ivSwipe.frame = CGRectMake(0, 0, 119.0f/PSD_WIDTH * viewWidth, 136.0f/PSD_HEIGHT * viewHeight);
    self.ivSwipe.center = CGPointMake(self.center.x, 322.0f/PSD_HEIGHT * viewHeight);
    self.ivTap.frame = CGRectMake(0, 0, 112.0f/PSD_WIDTH * viewWidth, 159.0f/PSD_HEIGHT * viewHeight);
    self.ivTap.center = CGPointMake(self.center.x, 322.0f/PSD_HEIGHT * viewHeight);
    
    // Message
    // Update its font size
    CGFloat fontSize = 28.0f/PSD_HEIGHT * viewHeight;
    NSMutableAttributedString *strAttr = [[NSMutableAttributedString alloc] initWithAttributedString:self.lblMessage.attributedText];
    [self.lblMessage.attributedText enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, strAttr.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *oldFont = (UIFont *)value;
        UIFont *newFont = [oldFont fontWithSize:fontSize];
        
        [strAttr addAttribute:NSFontAttributeName value:newFont range:range];
    }];
    self.lblMessage.attributedText = strAttr;
    
    // And its frame
    CGSize sizeMessage = [strAttr size];
    self.lblMessage.bounds = CGRectMake(0, 0, sizeMessage.width, sizeMessage.height);
    // The top of its frame should be ~14pt below the icon, centered
    CGRect frameVisibleImage = 0 == self.numberOfTaps ? self.ivSwipe.frame : self.ivTap.frame;
    self.lblMessage.center = CGPointMake(self.center.x, CGRectGetMaxY(frameVisibleImage) + 14.0f + CGRectGetHeight(self.lblMessage.frame)/2.0f);
    
    // Button
    NSDictionary *btnAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:24.0f/PSD_HEIGHT * viewHeight],
                                     NSForegroundColorAttributeName : [UIColor whiteColor] };
    [self.btn setAttributedTitle:[[NSAttributedString alloc] initWithString:self.btn.titleLabel.text attributes:btnAttributes] forState:UIControlStateNormal];
    self.btn.frame = CGRectMake(0, 0, 200.0f/PSD_WIDTH * viewWidth, 60.0f/PSD_HEIGHT * viewHeight);
    self.btn.center = CGPointMake(self.center.x, 624.0f/PSD_HEIGHT * viewHeight);
}

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // Content view
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
    _contentView.autoresizesSubviews = YES;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_contentView];
    
    // Icons
    _ivSwipe = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coachmark-swipe"]];
    _ivSwipe.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:_ivSwipe];
    _ivTap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coachmark-tap"]];
    _ivTap.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:_ivTap];
    
    // Label
    _lblMessage = [[UILabel alloc] init];
    _lblMessage.numberOfLines = 0;
    _lblMessage.font = [UIFont fontWithName:@"OpenSans" size:14.0f];
    _lblMessage.textAlignment = NSTextAlignmentCenter;
    _lblMessage.textColor = [UIColor whiteColor];
    _lblMessage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:_lblMessage];
    
    // Button
    _btn = [[UIButton alloc] init];
    _btn.layer.cornerRadius = 2.0f;
    _btn.layer.borderColor = [UIColor whiteColor].CGColor;
    _btn.layer.borderWidth = 1.0f;
    _btn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_btn addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_btn];
    
    [self showSwipeCoachmarkAnimated:NO];
}

@end