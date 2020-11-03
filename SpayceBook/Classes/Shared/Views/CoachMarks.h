//
//  CoachMarks.h
//  Spayce
//
//  Created by Christopher Taylor on 2/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * kCoachMarkMAMSkipKey;
extern NSString * kCoachMarkMAMPublicKey;
extern NSString * kCoachMarkMAMPrivateKey;
extern NSString * kCoachMarkVenueFavKey;
extern NSString * kCoachMarkSpayceKey;

@interface CoachMarks : UIView
{
    int currCoachMarkScreen;
    CGRect currCtlFrame;
}

@property (nonatomic, strong) UIImageView *backgroundImage;
@property (nonatomic, strong) UILabel *headlineLbl1;
@property (nonatomic, strong) UILabel *headlineLbl2;
@property (nonatomic, strong) UILabel *headlineLbl3;
@property (nonatomic, strong) UILabel *headlineLbl4;
@property (nonatomic, strong) UILabel *msgLbl1;
@property (nonatomic, strong) UILabel *msgLbl2;
@property (nonatomic, strong) UILabel *msgLbl3;
@property (nonatomic, strong) UILabel *msgLbl4;
@property (nonatomic, strong) UIButton *dismissBtn;

@property (nonatomic, assign) BOOL dismissOnTouch;

- (id)initWithFrame:(CGRect)frame type:(int)coachMarkScreenNum boundFrame:(CGRect)ctlFrame;
- (void)configureForType:(int)currType;

@end
