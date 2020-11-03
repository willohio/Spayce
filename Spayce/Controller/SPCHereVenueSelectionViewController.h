//
//  SPCHereVenueSelectionViewController.h
//  Spayce
//
//  Created by Jake Rosin on 6/18/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCHereVenueSelectionViewControllerDelegate.h"

@interface SPCHereVenueSelectionViewController: UIViewController

@property (nonatomic, strong) NSArray *venues;
@property (nonatomic, weak) NSObject<SPCHereVenueSelectionViewControllerDelegate> *delegate;
@property (nonatomic, assign) BOOL selectingFromFullScreenMap;

- (void)sizeToFitPerPage:(NSInteger)numberOfVenues;

@end
