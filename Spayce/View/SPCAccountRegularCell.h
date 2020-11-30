//
//  SPCAccountRegularCell.h
//  Spayce
//
//  Created by William Santiago on 2014-11-06.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCGroupedCell.h"

@interface SPCAccountRegularCell : SPCGroupedCell

- (void)configureWithStyle:(SPCGroupedStyle)style text:(NSString *)text textColor:(UIColor *)textColor accessoryType:(UITableViewCellAccessoryType)accessoryType;

@end
