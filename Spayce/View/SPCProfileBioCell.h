//
//  SPCProfileBioCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-23.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileBioCell : UITableViewCell

@property (nonatomic, strong) UIButton *btnBioEdit;

- (void)configureWithDataSource:(id)dataSource text:(NSString *)text andCanEditProfile:(BOOL)canEditProfile;
+ (CGFloat)heightOfCellWithText:(NSString *)text andTableWidth:(CGFloat)tableWidth;

@end
