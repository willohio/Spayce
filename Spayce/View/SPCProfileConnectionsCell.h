//
//  SPCProfileConnectionsCell.h
//  Spayce
//
//  Created by William Santiago on 2014-10-22.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * SPCProfileDidSelectConnectionNotification;

typedef NS_ENUM(NSInteger, SPCProfileConnectionType){
    SPCProfileConnectionTypeFriends,
};

@interface SPCProfileConnectionsCell : UITableViewCell

@property (nonatomic, weak) id dataSource;

- (void)configureWithDataSource:(id)dataSource friendsCount:(NSInteger)friendsCount isCeleb:(BOOL)isCeleb;

@end
