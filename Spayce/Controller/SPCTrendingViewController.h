//
//  SPCTrendingViewController.h
//  Spayce
//
//  Created by Jake Rosin on 7/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCTrendingViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, readonly) BOOL hasContent;
@property (nonatomic, assign) BOOL prefetchPaused;
@property (nonatomic, strong) UICollectionView * collectionView;

- (void)prefetchContent;

@end
