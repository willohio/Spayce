//
//  FeedViewController.h
//  Spayce
//
//  Created by Jake Rosin on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCLookBackViewController.h"


typedef NS_ENUM (NSInteger, FeedControllerType) {
    FeedControllerMemories,
    FeedControllerTrending
};

@interface SPCFeedViewController : UIViewController <SPCLookBackViewControllerDelegate>

- (id)initWithType:(NSInteger)type;
- (void)onLookBackNotificationClick:(NSDictionary *)remoteNotification;

@end
