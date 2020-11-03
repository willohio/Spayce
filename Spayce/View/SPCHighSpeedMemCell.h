//
//  SPCHighSpeedMemCell.h
//  Spayce
//
//  Created by Christopher Taylor on 9/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPCHighSpeedMemCellDelegate <NSObject>

@optional
- (void)fetchMemForComments:(NSInteger)memId;
@end

@interface SPCHighSpeedMemCell : UICollectionViewCell
@property (nonatomic, weak) id <SPCHighSpeedMemCellDelegate> delegate;
-(void)configureWithAssetsArray:(NSArray *)assets;

@end
