//
//  SPCAdminSockPuppetChooserViewController.h
//  Spayce
//
//  Created by Jake Rosin on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Person;


typedef NS_ENUM(NSInteger, SPCAdminSockPuppetAction) {
    SPCAdminSockPuppetActionStar = 1,
    SPCAdminSockPuppetActionUnstar = 2,
    SPCAdminSockPuppetActionStarComment = 3,
    SPCAdminSockPuppetActionUnstarComment = 4,
    SPCAdminSockPuppetActionComment = 5
};


@protocol SPCAdminSockPuppetChooserViewControllerDelegate <NSObject>
@optional
- (void)adminSockPuppetChooserViewController:(UIViewController *)vc didChoosePuppet:(Person *)puppet forAction:(SPCAdminSockPuppetAction)action object:(NSObject *)object;
- (void)adminSockPuppetChooserViewControllerDidCancel:(UIViewController *)vc;

@end

@interface SPCAdminSockPuppetChooserViewController : UIViewController

@property (nonatomic, weak) id<SPCAdminSockPuppetChooserViewControllerDelegate> delegate;

- (instancetype)initWithSockPuppetAction:(SPCAdminSockPuppetAction)action object:(NSObject *)object;

+ (void)allowSockPuppetSelectionIfAdminForAction:(SPCAdminSockPuppetAction)action object:(NSObject *)object withNavigationController:(UINavigationController *)navigationController transitioningDelegate:(id<UIViewControllerTransitioningDelegate>)transitioningDelegate delegate:(id<SPCAdminSockPuppetChooserViewControllerDelegate>)delegate defaultBlock:(void (^)())defaultBlock;

@end
