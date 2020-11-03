//
//  SignUpViewController.h
//  Spayce
//
//  Created by Pavel Dusatko on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SignUpViewControllerDelegate <NSObject>

- (void)dismissViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

@interface SignUpViewController : UIViewController

@property (nonatomic, weak) NSObject <SignUpViewControllerDelegate> *delegate;

@end
