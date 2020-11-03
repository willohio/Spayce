//
//  SPCVenueHashTagsViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 12/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"

@protocol SPCVenueHashTagsViewControllerDelegate <NSObject>

@optional
- (void)showMemoriesForHashTag:(NSString *)hashTag;
@end


@interface SPCVenueHashTagsViewController : UIViewController

@property (nonatomic, weak) NSObject <SPCVenueHashTagsViewControllerDelegate> *delegate;

-(void)configureForHashTags:(NSArray *)venueHashTags withSelectedTag:(NSString *)selectedTag;

@end
