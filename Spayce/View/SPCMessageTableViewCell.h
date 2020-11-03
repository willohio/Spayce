//
//  SPCMessageTableViewCell.h
//  Spayce
//
//  Created by Christopher Taylor on 3/19/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCMessage.h"
#import "UITableView+SPXRevealAdditions.h"


@interface SPCMessageTableViewCell : UITableViewCell

@property (nonatomic, strong) UIButton *authorBtn;

- (void)configureWitMessage:(SPCMessage *)message;


@end
