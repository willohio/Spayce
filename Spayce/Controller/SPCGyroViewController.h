//
//  SPCGyroViewController.h
//  Spayce
//
//  Created by Pavel Dusatko on 5/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface SPCGyroViewController : UIViewController

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) double tiltRotationRate;

- (void)startReceivingGyroUpdates;
- (void)stopReceivingGyroUpdates;

@end
