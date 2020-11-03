//
//  FriendUserCell.h
//  Spayce
//
//  Created by Pavel Dušátko on 12/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCFriendUserCell : UITableViewCell

@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *actionButton;

- (void)configureWithFriendId:(NSInteger)friendId text:(NSString *)text detailText:(NSString *)detailText url:(NSURL *)url;

@end
