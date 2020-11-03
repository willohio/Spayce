//
//  SPCAlertCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 10/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCAlertCell : UITableViewCell

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle style:(NSInteger)style image:(UIImage *)image;

@end
