//
//  SPCPeopleViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 11/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCPeopleViewController;

@protocol SPCPeopleViewControllerDelegate <NSObject>

@required

- (void)peopleViewControllerPerformPlaceholderAction:(SPCPeopleViewController *)viewController;

@end

typedef NS_ENUM(NSInteger, PeopleState) {
    PeopleStateEmpty,
    PeopleStateSearchResults,
    PeopleStateCitySearchResults,
    PeopleStateNeighborhoodSearchResults,
};

@interface SPCPeopleViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate,UITableViewDataSource, UITableViewDelegate,UITextFieldDelegate>

@property (nonatomic, weak) NSObject<SPCPeopleViewControllerDelegate> *delegate;
@end
