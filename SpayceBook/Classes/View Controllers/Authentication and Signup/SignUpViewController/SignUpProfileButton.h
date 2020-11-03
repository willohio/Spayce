//
//  SignUpProfileButton.h
//  Spayce
//
//  Created by Pavel Dusatko on 3/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignUpProfileButton : UIButton

@property (nonatomic, assign, getter = isInvalid) BOOL invalid;
@property (nonatomic, strong) UIColor *highlightedBorderColor;
@property (nonatomic, strong) UIImage *customPlaceholderImage;
@property (nonatomic, strong) UIImage *customBackgroundImage;

@end
