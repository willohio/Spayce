//
//  SPCMemoryLightboxViewController.h
//  Spayce
//
//  Created by Jake Rosin on 10/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCTagFriendsViewController.h"
#import "SPCAdjustMemoryLocationViewController.h"
#import "MemoryCommentsViewController.h"
#import "SPCMapViewController.h"

@class Memory;

@protocol SPCMemoryLightboxViewControllerDelegate <NSObject>
- (void)memoryDeletedFromLightbox:(Memory *)memory;
- (void)hideLightboxAnimated:(BOOL)animated;

@end

@interface SPCMemoryLightboxViewController : UIViewController<UIActionSheetDelegate, SPCTagFriendsViewControllerDelegate,SPCAdjustMemoryLocationViewControllerDelegate, SPCMapViewControllerDelegate>

@property (nonatomic, assign) BOOL isFromComments;
@property (nonatomic, weak) NSObject <SPCMemoryLightboxViewControllerDelegate> *delegate;

- (instancetype)initWithMemory:(Memory *)memory;
- (instancetype)initWithMemory:(Memory *)memory currentAssetIndex:(int)currentAssetIndex;

@end
