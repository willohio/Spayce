//
//  SPCAdjustMemoryLocationViewController.h
//  Spayce
//
//  Created by Jake Rosin on 6/20/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Memory.h"
#import "SPCGoogleMapInfoView.h"
#import "SPCMapDataSource.h"

extern NSString * SPCMemoryMovedFromVenueToVenue;


@protocol SPCAdjustMemoryLocationViewControllerDelegate <NSObject>

-(void)didAdjustLocationForMemory:(Memory *)memory withViewController:(UIViewController *)viewController;
-(void)dismissAdjustMemoryLocationViewController:(UIViewController *)viewController;

@end

@interface SPCAdjustMemoryLocationViewController : UIViewController<SPCGoogleMapInfoViewSupportDelegateDelegate, SPCMapDataSourceDelegate>

@property (nonatomic, weak) NSObject <SPCAdjustMemoryLocationViewControllerDelegate> *delegate;

-(instancetype)initWithMemory:(Memory *)memory;

@end
