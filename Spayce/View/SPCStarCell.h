//
//  SPCStarCell.h
//  Spayce
//
//  Created by William Santiago on 5/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCStarCell : UITableViewCell

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle timestampText:(NSString *)timestampText url:(NSURL *)url;

@end
