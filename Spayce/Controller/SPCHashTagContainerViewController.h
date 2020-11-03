//
//  SPCHashTagContainerViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 12/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Memory.h"
@interface SPCHashTagContainerViewController : UIViewController



-(void)configureWithHashTag:(NSString *)hashTag memory:(Memory *)mem;
- (void)showFeedForMemories:(NSArray *)memories;
- (void)contentComplete;

@end
