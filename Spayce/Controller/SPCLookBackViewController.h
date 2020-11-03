//
//  SPCLookBackViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 7/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHTCollectionViewWaterfallLayout.h"

@protocol SPCLookBackViewControllerDelegate <NSObject>

@optional

-(void)dismissLookBack;

@end

@interface SPCLookBackViewController : UIViewController <UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout>

@property (nonatomic, weak) NSObject <SPCLookBackViewControllerDelegate> *delegate;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

-(void)fetchLookBackWithID:(int)notificationID;
@end
