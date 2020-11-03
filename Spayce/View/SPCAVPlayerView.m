//
//  SPCAVPlayerView.m
//  Spayce
//
//  Created by Arria P. Owlia on 2/10/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCAVPlayerView.h"

@interface SPCAVPlayerView()

// This property determines whether we should play video if our player is ready
@property (nonatomic) BOOL shouldPlay;

// This property gives us an instant look into whether we have the ability to start the video now
@property (nonatomic, readonly) BOOL readyToPlay;


// This property determines whether we should call isReadyToPlayerWithPlayer on our delegate
@property (nonatomic) BOOL hasNotififiedOfReadyToPlayStatus;

@end

@implementation SPCAVPlayerView

#pragma mark - Lifecycle

- (void)dealloc {
    // Remove notification observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Cancel previous perform reqs
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // Remove KVO observers
    NSLog(@"try to remove KVO observers?");
    @try {
        if (nil != self.player) {
            [self.player removeObserver:self forKeyPath:@"rate"];
        }
    }
    @catch (NSException *exception) {}
    @try {
        if (nil != self.player) {
            [self.player removeObserver:self forKeyPath:@"currentItem"];
        }
    }
    @catch (NSException *exception) {}
    @try {
        if (nil != self.player) {
            [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        }
    }
    @catch (NSException *exception) {}
    @try {
        if (nil != self.player) {
            [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        }
    }
    @catch (NSException *exception) {}
    @try {
        if (nil != self.player) {
            [self.player.currentItem removeObserver:self forKeyPath:@"duration"];
        }
    }
    @catch (NSException *exception) {}
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {        
        // Set our player
        self.player = player;
        
        // This is how we are setting the viewable portion of the video
        ((AVPlayerLayer *)self.layer).videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        // This one is for a successful completion of the media
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
        // This one is for failing to play until the end
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:self.player.currentItem];
        // This notification is for stalling (i.e. buffering problem)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemStalled:) name:AVPlayerItemPlaybackStalledNotification object:self.player.currentItem];
    }
    return self;
}

#pragma mark - Actions

- (void)play {
    [self playAndWaitForBuffer:YES];
}

- (void)playNow {
    [self playAndWaitForBuffer:NO];
}

- (void)playAndWaitForBuffer:(BOOL)waitForBuffer {
    self.shouldPlay = YES;
    
    if (nil != self.player) {        
        if (waitForBuffer && !self.readyToPlay) {
            // We need to wait to become ready to play
            [self showBufferingIcon];
        } else {
            // We can or should start playing
            [self hideBufferingIcon];
            
            [self sendPlayToAVPlayer];
        }
    }
}

- (void)sendPlayToAVPlayer {
    self.player.volume = self.volume;
    
    [self.player play];
}

- (void)pause {
    self.shouldPlay = NO;
    
    if (nil != self.player) {
        [self.player pause];
        
        [self showBufferingIcon];
    }
}

- (void)stop {
    self.shouldPlay = NO;
    
    if (nil != self.player) {
        self.player.rate = 0.0f;
        [self.player seekToTime:kCMTimeZero];
    }
    
    self.hasStartedPlayback = NO;
}

- (void)showBufferingIcon {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bufferView.center = self.center;
        
        if (nil == self.bufferView.superview) {
            [self addSubview:self.bufferView];
        }
    });
}

- (void)hideBufferingIcon {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bufferView removeFromSuperview];
    });
}

-(void)resetForReplay {
    [self.player seekToTime:kCMTimeZero];
    
    self.hasStartedPlayback = NO;
}

#pragma mark - State Change

- (void)playbackItem:(AVPlayerItem *)item playbackLikelyToKeepUpChanged:(NSDictionary *)change {
    NSNumber *oldObj = change[@"old"];
    NSNumber *newObj = change[@"new"];
    if (nil != oldObj && nil != newObj) {
//        The following are not currently used/needed
//        BOOL oldLikelihood = [oldObj boolValue];
//        BOOL newLikelihood = [newObj boolValue];
        if ([self.player.currentItem isEqual:item]) {
            if (self.readyToPlay && NO == self.hasNotififiedOfReadyToPlayStatus && [self.delegate respondsToSelector:@selector(isReadyToPlayWithPlayerView:)]) {
                [self.delegate isReadyToPlayWithPlayerView:self];
                self.hasNotififiedOfReadyToPlayStatus = YES;
            }
            
            if (self.shouldPlay && self.readyToPlay) {
                [self sendPlayToAVPlayer];
            }
        }
    }
}

- (void)playerItem:(AVPlayerItem *)item loadStateChanged:(NSDictionary *)change {
   // NSLog(@"movie player load state changed!");
    // Let's start playing the video if it's the current moviePlayer instance we want to play and if the video is ready to play and is not currently playing
    NSNumber *oldObj = change[@"old"];
    NSNumber *newObj = change[@"new"];
    if (nil != oldObj && nil != newObj) {
        //        AVPlayerItemStatus oldStatus = [oldObj integerValue];
        AVPlayerItemStatus newStatus = [newObj integerValue];
        if ([self.player.currentItem isEqual:item]) {
            if (self.readyToPlay && NO == self.hasNotififiedOfReadyToPlayStatus && [self.delegate respondsToSelector:@selector(isReadyToPlayWithPlayerView:)]) {
                [self.delegate isReadyToPlayWithPlayerView:self];
                self.hasNotififiedOfReadyToPlayStatus = YES;
            }
            
            if (self.shouldPlay && self.readyToPlay) {
                [self sendPlayToAVPlayer];
            } else if (AVPlayerItemStatusFailed == newStatus) {
                if ([self.delegate respondsToSelector:@selector(didFailToPlayWithError:withPlayerView:)]) {
                    [self.delegate didFailToPlayWithError:self.player.error withPlayerView:self];
                }
                self.player = nil;
            }
        }
    }
}

- (void)player:(AVPlayer *)player rateChanged:(NSDictionary *)change {
    NSLog(@"playback rate changed!");
    
    NSNumber *oldObj = change[@"old"];
    NSNumber *newObj = change[@"new"];
    if (nil != oldObj && nil != newObj) {
        //        float oldRate = [oldObj floatValue];
        float newRate = [newObj floatValue];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (nil != strongSelf.player && [strongSelf.player isEqual:player]) {
                if (0.01f >= abs(newRate)) {
                    [strongSelf showBufferingIcon]; // Show the buffering icon/view if we are stopped
                    
                    if (strongSelf.hasStartedPlayback) {
                        if ([strongSelf.delegate respondsToSelector:@selector(didStopOrPausePlaybackWithPlayerView:)]) {
                            [strongSelf.delegate didStopOrPausePlaybackWithPlayerView:strongSelf];
                        }
                    }
                } else if (0.01f <= abs(newRate)) {
                    [strongSelf hideBufferingIcon]; // Hide the buffering icon/view if we are playing
                    
                    if (!strongSelf.hasStartedPlayback) {
                        strongSelf.hasStartedPlayback = YES;
                        if ([strongSelf.delegate respondsToSelector:@selector(didStartPlaybackWithPlayerView:)]) {
                            [strongSelf.delegate didStartPlaybackWithPlayerView:strongSelf];
                        }
                    } else {
                        if ([strongSelf.delegate respondsToSelector:@selector(didResumePlaybackWithPlayerView:)]) {
                            [strongSelf.delegate didResumePlaybackWithPlayerView:strongSelf];
                        }
                    }
                }
            }
        });
    }
}

- (void)player:(AVPlayer *)player currentItemChanged:(NSDictionary *)change {
    NSLog(@"player currentItem changed!");
    
    if ([player isEqual:self.player]) {
        NSObject *objOld = change[@"old"];
        NSObject *objNew = change[@"new"];
        
        // Remove old observers
        if ([objOld isKindOfClass:[AVPlayerItem class]]) {
            AVPlayerItem *itemOld = (AVPlayerItem *)objOld;
            
            [itemOld removeObserver:self forKeyPath:@"status"];
            [itemOld removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [itemOld removeObserver:self forKeyPath:@"duration"];
        }
        
        // Add new observers
        if ([objNew isKindOfClass:[AVPlayerItem class]]) {
            AVPlayerItem *itemNew = (AVPlayerItem *)objNew;
            
            [itemNew addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
            [itemNew addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
            [itemNew addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        } else {
            // If the item is nil, alert our delegate that we've failed to load
            if ([self.delegate respondsToSelector:@selector(didFailToPlayWithError:withPlayerView:)]) {
                [self.delegate didFailToPlayWithError:[NSError errorWithDomain:@"" code:-1 userInfo:[NSDictionary dictionary]] withPlayerView:self];
            }
            
            // And set the player to nil
            self.player = nil;
        }
    }
}

- (void)playerItem:(AVPlayerItem *)item durationStateChanged:(NSDictionary *)change {
    NSLog(@"duration status changed!");
    
    _duration = CMTimeGetSeconds(self.player.currentItem.duration);
}

#pragma mark - Accessors

- (UIView *)bufferView {
    if (nil == _bufferView) {
        UIButton *clockIcon = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
        clockIcon.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        clockIcon.layer.cornerRadius = 32;
        UIImage *clockIconImg = [UIImage imageNamed:@"clock-4pm"];
        [clockIcon setImage:clockIconImg forState:UIControlStateNormal];
        [clockIcon setImageEdgeInsets:UIEdgeInsetsMake(0.0, 3.0, 0.0, 0.0)];
        
        _bufferView = clockIcon;
    }
    
    return _bufferView;
}

- (NSTimeInterval)playableDuration {
    // Taken from: http://stackoverflow.com/questions/6815316/how-can-i-get-the-playable-duration-of-avplayer
    //  use loadedTimeRanges to compute playableDuration.
    AVPlayerItem *playeritem = self.player.currentItem;
    
    if (playeritem.status == AVPlayerItemStatusReadyToPlay) {
        NSArray *timeRangeArray = playeritem.loadedTimeRanges;
        
        CMTime currentTime = self.player.currentTime;
        
        __block CMTimeRange aTimeRange;
        
        [timeRangeArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            aTimeRange = [[timeRangeArray objectAtIndex:0] CMTimeRangeValue];
            
            if(CMTimeRangeContainsTime(aTimeRange, currentTime))
                *stop = YES;
            
        }];
        
        CMTime maxTime = CMTimeRangeGetEnd(aTimeRange);
        
        return CMTimeGetSeconds(maxTime);
    } else {
        return(CMTimeGetSeconds(kCMTimeInvalid));
    }
}

- (AVPlayerItem *)currentItem {
    return [self player].currentItem;
}

- (void)setVolume:(float)volume {
    if (0.0f > volume) {
        volume = 0.0f;
    } else if (1.0f < volume) {
        volume = 1.0f;
    }
    
    _volume = volume; // Set our volume property, so others may access it if they need
    self.player.volume = volume; // Set the video player's volume
}

- (BOOL)readyToPlay {
    // We're ready to play if the player is ready to play and we have enough buffer so that playback will not cut out
    return AVPlayerStatusReadyToPlay == self.player.status && self.player.currentItem.isPlaybackLikelyToKeepUp;
}

- (void)setDelegate:(id<SPCAVPlayerViewDelegate>)delegate {
    _delegate = delegate;
    
    self.hasNotififiedOfReadyToPlayStatus = NO;
    if (self.readyToPlay && [self.delegate respondsToSelector:@selector(isReadyToPlayWithPlayerView:)]) {
        [self.delegate isReadyToPlayWithPlayerView:self];
        self.hasNotififiedOfReadyToPlayStatus = YES;
    }
}

#pragma mark - Notifications

- (void)playerItemStalled:(NSNotification *)notification {
    // Here, we've run out of buffer. What we need to do is show the loading/waiting image and wait for the playbackLikelyToKeepUp KVO update
    // Show the image
    [self showBufferingIcon];
}

- (void)playerPlaybackDidFinish:(NSNotification*)notification {
    NSLog(@"playback did finish!");
    
    if ([self.player.currentItem isEqual:notification.object]) {
        if ([self.delegate respondsToSelector:@selector(didFinishPlaybackToEndWithPlayerView:)]) {
            [self.delegate didFinishPlaybackToEndWithPlayerView:self];
        }
    }
    
    self.hasStartedPlayback = NO;
}

// This almost never gets called
- (void)playerItemFailedToPlayToEndTime:(NSNotification*)notification {
    NSLog(@"playback did fail to play to end time!");
    
    if ([self.player.currentItem isEqual:notification.object]) {
        if ([self.delegate respondsToSelector:@selector(didFailToPlayWithError:withPlayerView:)]) {
            [self.delegate didFailToPlayWithError:self.player.error withPlayerView:self];
        }
    }
    
    self.hasStartedPlayback = NO;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    //NSLog(@"observe value!");
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        [self playbackItem:item playbackLikelyToKeepUpChanged:change];
    } else if ([keyPath isEqualToString:@"rate"]) {
        AVPlayer *player = (AVPlayer *)object;
        [self player:player rateChanged:change];
    } else if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        [self playerItem:item loadStateChanged:change];
    } else if ([keyPath isEqualToString:@"duration"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        [self playerItem:item durationStateChanged:change];
    } else if ([keyPath isEqualToString:@"currentItem"]) {
        AVPlayer *player = (AVPlayer *)object;
        [self player:player currentItemChanged:change];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}

#pragma mark - AVPlayerLayer

+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    if (nil != self.player) {
        [self.player removeObserver:self forKeyPath:@"rate"];
        [self.player removeObserver:self forKeyPath:@"currentItem"];
        
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.player.currentItem removeObserver:self forKeyPath:@"duration"];
    }
    
    self.hasStartedPlayback = NO;
    _duration = CMTimeGetSeconds(kCMTimeInvalid);
    [(AVPlayerLayer *)[self layer] setPlayer:player];
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    [self.player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
}

@end
