//
//  SPCNewMemberView.h
//  Spayce
//
//  Created by Christopher Taylor on 5/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPCNewMemberViewDelegate <NSObject>

@optional

- (void)dismissIntro;

@end

@interface SPCNewMemberView : UIView

@property (nonatomic, weak) id<SPCNewMemberViewDelegate> delegate;

- (void)prepIntroScroller;
- (void)updateProgress:(NSString *)progress;
- (void)simulateProgress;
- (void)showDoneButton;


@end
