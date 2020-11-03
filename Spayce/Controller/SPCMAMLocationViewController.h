//
//  SPCMAMLocationViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 2/27/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"

@protocol SPCMAMLocationViewControllerDelegate <NSObject>

@optional

- (void)spcPickLocationViewControllerDidFinish:(id)sender withSelectedVenue:(Venue *)venue;

@end

@interface SPCMAMLocationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UITextFieldDelegate>

@property (nonatomic, weak) NSObject <SPCMAMLocationViewControllerDelegate> *delegate;

- (id) initWithNearbyVenues:(NSArray *)nearbyVenues selectedVenue:(Venue *)selectedVenue;
@end
