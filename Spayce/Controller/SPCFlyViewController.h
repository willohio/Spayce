//
//  SPCFlyViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 12/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"
#import "SPCGrid.h"


@protocol SPCFlyViewControllerDelegate <NSObject>

@optional
- (void)flyComplete;
@end

typedef NS_ENUM(NSInteger, FlyState) {
    FlyStateSearch,
    FlyStateSearchTeleport,
    FlyStateExplore
};


@interface SPCFlyViewController : UIViewController <SPCGridDelegate>
@property (nonatomic, weak) NSObject <SPCFlyViewControllerDelegate> *delegate;

@end
