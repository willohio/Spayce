//
//  SPCMessageThreadTableViewCell.h
//  Spayce
//
//  Created by Christopher Taylor on 3/23/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCMessageThread.h"
#import "SWTableViewCell.h"

@interface SPCMessageThreadTableViewCell : SWTableViewCell

@property (weak, nonatomic) UILabel *customLabel;
@property (weak, nonatomic) UIImageView *customImageView;

- (void)configureWitMessageThread:(SPCMessageThread *)thread;
@end
