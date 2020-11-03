//
//  SPCNewsLogCell.h
//  Spayce
//
//  Created by Christopher Taylor on 10/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpayceNotification.h"
#import "SPCNotificationCell.h"

@interface SPCNewsLogCell : SPCNotificationCell



-(void)configureWithNotification:(SpayceNotification *)mostRecentNotification count:(NSInteger)unreadCount;

@end
