//
//  IntroAnimation.h
//  Spayce
//
//  Created by Christopher Taylor on 1/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCNewMemberView.h"

extern NSString * kIntroAnimationDidBeginNotification;
extern NSString * kIntroAnimationDidEndNotification;

@interface IntroAnimation : UIView <SPCNewMemberViewDelegate> {
    
    int animationCounter;
    int beginS_Count;
    int animationEndCount;
    BOOL animationStopped;
    float starsHeight;
    float logoStopY;
    BOOL continueUntilProfileExists;
    BOOL shouldObserveProfileNeeded;
    BOOL justLoggedIn;
    BOOL validatingSession;
    BOOL hasStartedFBInviteAll;
    BOOL hasCompletedFBInviteAll;
    BOOL justSignedUp;
    
    
}

@property (strong,nonatomic) UIImageView *stars1;
@property (strong,nonatomic) UIImageView *stars2;
@property (strong,nonatomic) UIImageView *stars3;
@property (strong, nonatomic) UIImageView *logoImgView;
@property (strong, nonatomic) UIImageView *rocketImgView;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UIView *initialLoadingView;
@property (strong, nonatomic) UIImageView *bigLogoImgView;
@property (strong, nonatomic) UILabel *progressHeaderLabel;
@property (strong, nonatomic) UILabel *progressLabel;

-(void)prepAnimation;
-(void)loginStarted;
-(void)startAnimation;

@end
