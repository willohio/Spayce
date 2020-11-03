//
//  SPCDeleteAccountConfirmationView.h
//  Spayce
//
//  Created by Arria P. Owlia on 2/21/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCDeleteAccountConfirmationView : UIView

// Action buttons
@property (strong, nonatomic) UIButton *btnDelete;
@property (strong, nonatomic) UIButton *btnCancel;

// Actions
- (void)showAnimated:(BOOL)animated;
- (void)showInView:(UIView *)view animated:(BOOL)animated;
- (void)showActivityIndicatorOnDelete:(BOOL)show;
- (void)hideAnimated:(BOOL)animated;

@end
