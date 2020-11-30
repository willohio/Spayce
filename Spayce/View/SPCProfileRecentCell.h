//
//  SPCProfileRecentCell.h
//  Spayce
//
//  Created by William Santiago on 2014-10-24.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileRecentCell : UITableViewCell

- (void)configureWithUrlString:(NSString *)urlString author:(NSString *)author friends:(NSArray *)friends timestamp:(NSString *)timestamp text:(NSString *)text detailedText:(NSString *)detailedText;

@end
