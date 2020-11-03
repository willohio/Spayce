//
//  SPCFeedPhotoScrollerViewController.h
//  Spayce
//
//  Created by Jake Rosin on 5/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPCFeedPhotoScrollerViewControllerDelegate <NSObject>
- (void)hidePics;
@end

@interface SPCFeedPhotoScrollerViewController : UIViewController {
    
}

@property (nonatomic, weak) NSObject <SPCFeedPhotoScrollerViewControllerDelegate> *delegate;
- (id)initWithPics:(NSArray *)pics index:(int)index;
@end

