//
//  SPCVenueDetailGridTransitionViewController.h
//  Spayce
//
//  Created by Jake Rosin on 1/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Memory;
@class Venue;
@class Asset;

@interface SPCVenueDetailGridTransitionViewController : UIViewController

@property (nonatomic, strong) Memory *memory;
@property (nonatomic, strong) Venue *venue;

@property (nonatomic, strong) UIImage *gridCellImage;
@property (nonatomic, strong) Asset *gridCellAsset;
@property (nonatomic, assign) CGRect gridCellFrame;
@property (nonatomic, assign) CGRect gridClipFrame;

@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *exitBackgroundImage;
@property (nonatomic, assign) BOOL snapTransitionDismiss;

@end
