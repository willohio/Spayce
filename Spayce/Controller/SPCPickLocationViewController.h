//
//  SPCPickLocationViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 1/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"
#import "SPCImageToCrop.h"
#import "SPCCity.h"

@protocol SPCPickLocationViewControllerDelegate <NSObject>

@optional


- (void)spcPickLocationViewControllerDidFinish:(id)sender withSelectedVenue:(Venue *)venue;
- (void)spcPickLocationViewControllerDidFinish:(id)sender withSelectedTerritory:(SPCCity *)territory;
- (void)spcPickLocationViewControllerDidCancel:(id)sender;
- (void)prepForVenueReset;
- (void)updateSelectedVenue:(Venue *)venue;
@end



@interface SPCPickLocationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UITextFieldDelegate>


@property (nonatomic, weak) NSObject <SPCPickLocationViewControllerDelegate> *delegate;
@property (nonatomic, assign) BOOL fuzzedVenuesOnly;

-(void)configureWithLatitude:(double)latitude longitude:(double)longitude image:(SPCImageToCrop *)imageToPreview;
-(void)showLocationOptions;
-(void)reset;


@end
