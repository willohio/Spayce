//
//  SPCMontageView.h
//  Spayce
//
//  Created by Arria P. Owlia on 2/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum SPCMontageViewState {
  SPCMontageViewStateUnknown,
  SPCMontageViewStatePlaying,
  SPCMontageViewStatePaused,
  SPCMontageViewStateStopped,
} SPCMontageViewState;

@class Memory;

@class SPCMontageView;
@protocol SPCMontageViewDelegate <NSObject>

// Called when 'isReady' has been set to true
- (void)didLoadMemories:(NSArray *)memories OnSPCMontageView:(SPCMontageView *)montageView;
- (void)didFailToLoadMemoriesOnSPCMontageView:(SPCMontageView *)montageView;
- (void)memoriesWereClearedFromSPCMontageView:(SPCMontageView *)montageView;

- (void)tappedPlayButtonOnSPCMontageView:(SPCMontageView *)montageView;
- (void)didPlayToEndOnSPCMontageView:(SPCMontageView *)montageView;

- (void)tappedMemory:(Memory *)memory onSPCMontageView:(SPCMontageView *)montageView;
- (void)tappedAuthorForMemory:(Memory *)memory onSPCMontageView:(SPCMontageView *)montageView;
- (void)tappedDismissButtonOnSPCMontageView:(SPCMontageView *)montageView;

- (void)didTapCoachmarkToCompletionOnSPCMontageView:(SPCMontageView *)montageView;

@end

@interface SPCMontageView : UIView

// Delegate
@property (weak, nonatomic) id<SPCMontageViewDelegate> delegate;

// State
@property (nonatomic, readonly) SPCMontageViewState state;
@property (nonatomic) BOOL isReady;
@property (strong, nonatomic, readonly) NSArray *memories;
@property (weak, nonatomic, readonly) Memory *memoryCurrentlyDisplayed;

// Preview/Stitched image size - should be used for determining the size to set the montageview once it is finished
@property (nonatomic, readonly) CGSize previewImageSize;

// Configuration - memories, title (e.g. "Neighborhood Montage", "World Montage", etc.), and overlay color
- (void)configureWithMemories:(NSArray *)memories title:(NSString *)title overlayColor:(UIColor *)overlayColor useLocalLocations:(BOOL)useLocalLocations andPreviewImageSize:(CGSize)previewImageSize;

// 'memories' should be a full list of montage memories (~40). BOOL return value indicates whether the montage needs to load new memories (thus it should NOT be presented)
- (void)updateWithMemories:(NSArray *)memories withMontageNeedsLoadReturn:(BOOL *)needsLoad;

// Clears the memories, clears the background image, and puts the montage in an isReady = NO state
- (void)clear;

// Actions
- (void)play;
- (void)playWithCoachmark;
- (void)pause;
- (void)stop;

@end

@class SPCMontageCoachmarkView;
@protocol SPCMontageCoachmarkViewDelegate <NSObject>

- (void)didTapToEndOnCoachmarkView:(SPCMontageCoachmarkView *)montageCoachmarkView;

@end

@interface SPCMontageCoachmarkView : UIView

@property (weak, nonatomic) id<SPCMontageCoachmarkViewDelegate> delegate;

@end