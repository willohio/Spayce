//
//  SPCHereDataSource.h
//  Spayce
//
//  Created by Pavel Dusatko on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCBaseDataSource.h"

extern NSString * SPCHereTriggeringOffsetNotification;
extern NSString * SPCHereSignificantScrollTowardsTriggerNotification;
extern NSString * SPCHereSignificantScrollAwayFromTriggerNotification;
extern NSString * SPCHereSignificantScrollNotification;
extern NSString * SPCHereLoadMoreDataNotification;
extern NSString * SPCHereScrollHeaderOffContentAreaNotification;
extern NSString * SPCHereScrollHeaderOnContentAreaNotification;
extern NSString * SPCHereScrollHeaderOffTableNotification;
extern NSString * SPCHereScrollHeaderOnTableNotification;

extern NSString * SPCHerePushingViewController;


@interface SPCHereDataSource : SPCBaseDataSource

@property (nonatomic, weak) id<SPCDataSourceDelegate> delegate;

- (void)filterByRecency;
- (void)filterByStars;
- (void)filterByPersonal;

@end
