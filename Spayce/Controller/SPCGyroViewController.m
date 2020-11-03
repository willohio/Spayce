//
//  SPCGyroViewController.m
//  Spayce
//
//  Created by Pavel Dusatko on 5/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCGyroViewController.h"

@interface SPCGyroViewController ()

@property (nonatomic, strong) CMGyroData *gyroData;

@end

@implementation SPCGyroViewController

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark - Private

- (void)initialize {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startReceivingGyroUpdates)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopReceivingGyroUpdates)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

#pragma mark - Accessors

- (double)tiltRotationRate {
    CMRotationRate rotationRate = self.gyroData.rotationRate;
    return (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? rotationRate.x : rotationRate.y);
}

#pragma mark - UIViewController - Responding to View Rotation Events

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self stopReceivingGyroUpdates];
}

#pragma mark - Target-Action

- (void)startReceivingGyroUpdates {
    CMMotionManager *motionManager = self.motionManager;
    
    if (motionManager.isGyroAvailable) {
        motionManager.gyroUpdateInterval = 1.0/60.0;
        
        [motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
                                   withHandler:^(CMGyroData *gyroData, NSError *error) {
                                       self.gyroData = gyroData;
                                   }];
    }
}

- (void)stopReceivingGyroUpdates {
    CMMotionManager *motionManager = self.motionManager;
    
    if (motionManager.isGyroActive) {
        [motionManager stopGyroUpdates];
    }
}

@end
