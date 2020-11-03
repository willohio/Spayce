//
//  SPCMapViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 5/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Venue;
@class Memory;

@protocol SPCMapViewControllerDelegate <NSObject>

@optional

- (void)cancelMap;
- (void)updateLocation:(Venue *)venue;
- (void)updateLocation:(Venue *)venue dismissViewController:(BOOL)dismiss;
- (void)didAdjustLocationForMemory:(Memory *)memory;
@end

@interface SPCMapViewController : UIViewController
@property (nonatomic, weak) NSObject <SPCMapViewControllerDelegate> *delegate;
@property (nonatomic, strong) Venue *selectedVenue;

- (instancetype)initForNewMemoryWithSelectedVenue:(Venue *)selectedVenue;
- (instancetype)initForExistingMemory:(Memory *)memory;

- (void)refreshVenues;

@end
