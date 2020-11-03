//
//  AppDelegate.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FICImageCache.h"

@class SPCMainViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, FICImageCacheDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong, readonly) SPCMainViewController *mainViewController;
@property (assign, nonatomic) CGRect currentStatusBarFrame;

@end
