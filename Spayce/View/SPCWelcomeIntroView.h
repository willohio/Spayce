//
//  SPCWelcomeIntroView.h
//  Spayce
//
//  Created by Arria P. Owlia on 4/8/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCWelcomeIntroView : UIView

// Progression State
@property (nonatomic) BOOL hasPlayedToEnd;

// Actions
- (void)play;
- (void)stop;

@end
