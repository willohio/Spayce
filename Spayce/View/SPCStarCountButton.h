//
//  SPCStarCountButton.h
//  Spayce
//
//  Created by William Santiago on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCStarCountButton : UIButton

@property (nonatomic) NSInteger count;

- (void)hideButtonAfterDelay:(NSTimeInterval)delay;
- (void)updateTitle;

@end
