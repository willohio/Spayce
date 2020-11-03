//
//  SPCFeedVideoScrollerViewController.h
//  Spayce
//
//  Created by Jake Rosin on 5/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPCFeedVideoScrollerViewControllerDelegate <NSObject>
- (void)hideVideos;
@end

@interface SPCFeedVideoScrollerViewController : UIViewController {
    
}

@property (nonatomic, weak) NSObject <SPCFeedVideoScrollerViewControllerDelegate> *delegate;
- (id)initWithPics:(NSArray *)pics videoURL:(NSArray *)urls index:(int)index;
@end
