//
//  SPCMemoriesViewController.h
//  Spayce
//
//  Created by Pavel Dušátko on 11/28/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SPCMemoriesViewControllerDelegate <NSObject>
@optional
- (void)spcMemoriesViewControllerDidLoadFeed:(UIViewController *)viewController;
@end

@interface SPCMemoriesViewController : UIViewController

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong) UIView *pullToRefreshFadingHeader;
@property (nonatomic) BOOL draggingScrollView;
@property (nonatomic, weak) NSObject <SPCMemoriesViewControllerDelegate> *delegate;
@property (nonatomic, readonly) BOOL hasContent;
@property (nonatomic, assign) BOOL pullToRefreshStarted;

@end
