//
//  BlockedUserCell.h
//  Spayce
//
//  Created by Pavel Dušátko on 11/23/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCBlockedUserCell : UITableViewCell

@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *actionButton;

- (void)configureWithText:(NSString *)text detailText:(NSString *)detailText url:(NSURL *)url;

@end
