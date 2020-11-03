//
//  SPCView.h
//  Spayce
//
//  Created by Jake Rosin on 5/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//
//  A general-purpose view that allows customized blocks for pointInside and hitTest.
//  Example of use: designating specific areas of a UIViewController.view as "pass through"
//  for taps, such as if one ViewController is layered over another.  Spayce HERE
//  uses a similar construction to ensure that taps in the transparent area of a
//  table view header are disregarded by the top VC and processed by the one below it
//  (while still maintaining the full area as space the top VC can place interactive views).

#import <UIKit/UIKit.h>

typedef BOOL (^PointInsideBlock)(CGPoint point, UIEvent *event);
typedef UIView * (^HitTestBlock)(CGPoint point, UIEvent *event);

@interface SPCView : UIView

@property (nonatomic, copy) PointInsideBlock pointInsideBlock;
@property (nonatomic, copy) HitTestBlock hitTestBlock;

@property (nonatomic, assign) BOOL clipsHitsToBounds;

@property (nonatomic, strong) UIColor *hairlineFooterColor;

-(void)setPointInsideBlock:(PointInsideBlock)pointInsideBlock;

@end
