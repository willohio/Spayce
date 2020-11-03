//
//  SPCCreateVenuePostViewController.h
//  Spayce
//
//  Created by Jake Rosin on 6/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"


extern NSString * kSPCDidPostVenue;
extern NSString * kSPCDidUpdateVenue;
extern NSString * kSPCDidDeleteVenue;

@protocol SPCCreateVenuePostViewControllerDelegate

-(void) spcCreateVenuePostViewControllerDidFinish:(UIViewController *)viewController;

@end

@interface SPCCreateVenuePostViewController : UIViewController

-(id) initWithVenue:(Venue *)venue;
-(id) initWithLocation:(CLLocationCoordinate2D)location;

@property (nonatomic, weak) NSObject<SPCCreateVenuePostViewControllerDelegate> *delegate;

@end
