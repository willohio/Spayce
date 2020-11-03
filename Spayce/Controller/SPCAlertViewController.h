//
//  SPCAlertViewController.h
//  Spayce
//
//  Created by Pavel Dusatko on 10/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCAlertAction;

@interface SPCAlertViewController : UIViewController

@property (nonatomic, strong) NSString *alertTitle;
@property (nonatomic, strong) UIImage *alertImage;

- (void)addAction:(SPCAlertAction *)action;

@end
