//
//  SPCMapFilterCollectionViewCell.h
//  Spayce
//
//  Created by Christopher Taylor on 12/3/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCMapFilterCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) BOOL filterSelected;
@property (nonatomic, strong) NSString *filterName;

- (void)configureWithFilter:(NSString *)filter;
- (void)toggleFilter;

@end
