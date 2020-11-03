//
//  RadialProgressBarView.h
//  Radial Progress Bar
//
//  Created by Dmitry Miller on 7/22/13.
//  Copyright (c) 2013 Dmitry Miller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadialProgressBarView : UIView

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat progressBarWidth;
@property (nonatomic, strong) UIColor *emptyColor;
@property (nonatomic, strong) UIColor *progressColor;

@end
