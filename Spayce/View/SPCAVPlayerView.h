//
//  SPCAVPlayerView.h
//  Spayce
//
//  Created by Arria P. Owlia on 2/10/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class SPCAVPlayerView;
@protocol SPCAVPlayerViewDelegate <NSObject>

@optional
- (void)didStartPlaybackWithPlayerView:(SPCAVPlayerView *)playerView;
- (void)didStopOrPausePlaybackWithPlayerView:(SPCAVPlayerView *)playerView;
- (void)didResumePlaybackWithPlayerView:(SPCAVPlayerView *)playerView;
- (void)didFailToPlayWithError:(NSError *)error withPlayerView:(SPCAVPlayerView *)playerView;
- (void)didFinishPlaybackToEndWithPlayerView:(SPCAVPlayerView *)playerView;
- (void)isReadyToPlayWithPlayerView:(SPCAVPlayerView *)playerView;

@end

@interface SPCAVPlayerView : UIView

// Delegate
@property (weak, nonatomic) id<SPCAVPlayerViewDelegate> delegate;

// The view that is displayed when buffering. It is centered onto the video screen
@property (strong, nonatomic) UIView *bufferView;

// This property controls the player's volume. It is relative to the system volume
@property (nonatomic) float volume;

// This property reflects the playable duration of the video. It should be checked against CMTimeGetSeconds(kCMTimeInvalid)
@property (nonatomic, readonly) NSTimeInterval playableDuration;

// This property reflects the total duration of the video. It should be checked againsts CMTimeGetSeconds(kCMTimeInvalid)
@property (nonatomic, readonly) NSTimeInterval duration;

// This property reflects the loaded item/track
@property (nonatomic, strong, readonly) AVPlayerItem *currentItem;

// This property determines whether we should call didStart or didResume on our delegate
@property (nonatomic) BOOL hasStartedPlayback;

// Highly recommended to init with this function
// This class is intended to be used with a single AVPlayer that is passed in at init. There is currently no other (implemented) option to set the player
- (instancetype)initWithPlayer:(AVPlayer *)player;

// Actions
- (void)play; // Playback starts as soon as the item is ready and we have enough buffer to not pause playback
- (void)playNow; // We attempt to start the video as soon as possible, regardless of how much buffer we have
- (void)pause;
- (void)stop;
- (void)resetForReplay;

@end
