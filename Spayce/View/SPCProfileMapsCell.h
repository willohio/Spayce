//
//  SPCProfileMapsCell.h
//  Spayce
//
//  Created by William Santiago on 2014-10-23.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileMapsCell : UITableViewCell

@property (nonatomic, weak) id dataSource;

- (void)configureWithDataSource:(id)dataSource cities:(NSArray *)cities neightborhoods:(NSArray *)neighborhoods name:(NSString *)name isCurrentUser:(BOOL)isCurrentUser;

@end
