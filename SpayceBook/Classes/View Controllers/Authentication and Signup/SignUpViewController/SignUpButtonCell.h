//
//  SignUpButtonCell.h
//  Spayce
//
//  Created by William Santiago on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignUpButton.h"

@interface SignUpButtonCell : UITableViewCell

@property (nonatomic, strong) SignUpButton *button;
@property (nonatomic, assign) BOOL isResetPassBtn;

@end
