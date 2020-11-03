//
//  SPCNearbyVenuesViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 12/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"

@protocol SPCNearbyVenuesViewDelegate <NSObject>

@required
- (void)showCreateVenueViewControllerWithVenues:(NSArray *)venues;

@optional
- (void)hideNearbyVenues;
- (void)showVenueDetail:(Venue *)v;

@end

@interface SPCNearbyVenuesView : UIView <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, weak) NSObject <SPCNearbyVenuesViewDelegate> *delegate;
@property (nonatomic, strong) UIView *mapContainerView;

-(void)skipToMap;
-(void)updateVenues:(NSArray *)venues;
@end
