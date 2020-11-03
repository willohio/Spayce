//
//  MemoryCommentsViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 12/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Memory.h"
#import "Comment.h"
#import "SPCTagFriendsViewController.h"
#import "SPCFriendPicker.h"
#import "SPCAdjustMemoryLocationViewController.h"
#import "SPCMapViewController.h"
#import "HMSegmentedControl.h"

@interface MemoryCommentsViewController : UIViewController <UIActionSheetDelegate, SPCTagFriendsViewControllerDelegate, SPCFriendPickerDelegate, SPCAdjustMemoryLocationViewControllerDelegate, SPCMapViewControllerDelegate> {
    int selectedSegment;
   
 }

@property (nonatomic, assign, readonly) CGFloat tableStart;
@property (assign, nonatomic) MemoryType memoryType;
@property (nonatomic, assign) BOOL viewingFromNotification;
@property (nonatomic, assign) BOOL viewingFromLightbox;
@property (nonatomic, assign) BOOL viewingFromGrid;
@property (nonatomic, assign) BOOL viewingFromVenueDetail;
@property (nonatomic, strong, readonly) UIButton *backButton;


// for transition animations...
@property (nonatomic, assign) BOOL animateTransition;
@property (nonatomic, strong) UIImage *gridCellImage;
@property (nonatomic, strong) Asset *gridCellAsset;
@property (nonatomic, assign) CGRect gridCellFrame;
@property (nonatomic, assign) CGRect gridClipFrame;

@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *exitBackgroundImage;
@property (nonatomic, assign) BOOL snapTransitionDismiss;

// init
-(id)initWithMemoryId:(NSInteger)memId;
-(id)initWithMemory:(Memory *)m;
-(void)updateForManualNav;

-(void)updateComment:(Comment *)comment;

// transitions
- (void)setNavBarAlpha:(CGFloat)alpha;
- (void)setWhiteHeaderViewAlpha:(CGFloat)alpha;
- (void)setTableHeaderViewAlpha:(CGFloat)alpha;
- (void)setTableViewAlpha:(CGFloat)alpha;
-(void)removeKeyControl;
-(void)cleanUp;

@end
