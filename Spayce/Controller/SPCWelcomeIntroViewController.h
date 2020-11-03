//
//  SPCWelcomeIntroViewController.h
//  Spayce
//
//  Created by Arria P. Owlia on 4/9/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCWelcomeIntroViewController;
@protocol SPCWelcomeIntroDelegate <NSObject>

- (void)tappedWelcomeIntroVC:(SPCWelcomeIntroViewController *)welcomeIntroVC andHasPlayedToEnd:(BOOL)hasPlayedToEnd;

@end

@interface SPCWelcomeIntroViewController : UIViewController

@property (weak, nonatomic) id<SPCWelcomeIntroDelegate> delegate;

@end
