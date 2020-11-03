//
//  CoachMarks.m
//  Spayce
//
//  Created by Christopher Taylor on 2/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "CoachMarks.h"

#import "SPCColorManager.h"

NSString * kCoachMarkMAMSkipKey = @"CoachMarkMAMSkipKey";
NSString * kCoachMarkMAMPublicKey = @"CoachMarkMAMPublicKey";
NSString * kCoachMarkMAMPrivateKey = @"CoachMarkMAMPrivateKey";
NSString * kCoachMarkVenueFavKey = @"CoachMarkVenueFavKey";
NSString * kCoachMarkSpayceKey = @"CoachMarkSpayceKey";



@implementation CoachMarks


- (id)initWithFrame:(CGRect)frame type:(int)currType boundFrame:(CGRect)ctlFrame
{
    self = [super initWithFrame:frame];
    if (self) {
        currCoachMarkScreen = currType;
        currCtlFrame = ctlFrame;
        
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.9];

        self.backgroundImage = [[UIImageView alloc] initWithFrame:frame];
        self.backgroundImage.hidden = YES;
        [self addSubview:self.backgroundImage];
        
        UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:singleFingerTap];

        self.headlineLbl1 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.headlineLbl1.backgroundColor = [UIColor clearColor];
        self.headlineLbl1.textColor = [UIColor colorWithRed:1 green:131.0f/255.0f blue:0 alpha:1.0f];
        self.headlineLbl1.numberOfLines = 0;
        self.headlineLbl1.textAlignment = NSTextAlignmentCenter;
        self.headlineLbl1.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
        [self addSubview:self.headlineLbl1];
        
        self.msgLbl1 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.msgLbl1.backgroundColor = [UIColor clearColor];
        self.msgLbl1.textColor = [UIColor whiteColor];
        self.msgLbl1.numberOfLines = 0;
        self.msgLbl1.lineBreakMode = NSLineBreakByWordWrapping;
        self.msgLbl1.textAlignment = NSTextAlignmentCenter;
        self.msgLbl1.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        [self addSubview:self.msgLbl1];
        
        
        self.headlineLbl2 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.headlineLbl2.backgroundColor = [UIColor clearColor];
        self.headlineLbl2.textColor = [UIColor colorWithRGBHex:0x3598c0];
        self.headlineLbl2.numberOfLines = 0;
        self.headlineLbl2.textAlignment = NSTextAlignmentCenter;
        self.headlineLbl2.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        [self addSubview:self.headlineLbl2];
        
        self.msgLbl2 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.msgLbl2.backgroundColor = [UIColor clearColor];
        self.msgLbl2.textColor = [UIColor whiteColor];
        self.msgLbl2.numberOfLines = 0;
        self.msgLbl2.textAlignment = NSTextAlignmentCenter;
        self.msgLbl2.lineBreakMode = NSLineBreakByWordWrapping;
        self.msgLbl2.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        [self addSubview:self.msgLbl2];
        
        self.headlineLbl3 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.headlineLbl3.backgroundColor = [UIColor clearColor];
        self.headlineLbl3.textColor = [UIColor colorWithRGBHex:0x3598c0];
        self.headlineLbl3.numberOfLines = 0;
        self.headlineLbl3.textAlignment = NSTextAlignmentCenter;
        self.headlineLbl3.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        [self addSubview:self.headlineLbl3];
        
        self.msgLbl3 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.msgLbl3.backgroundColor = [UIColor clearColor];
        self.msgLbl3.textColor = [UIColor whiteColor];
        self.msgLbl3.numberOfLines = 0;
        self.msgLbl3.textAlignment = NSTextAlignmentCenter;
        self.msgLbl3.lineBreakMode = NSLineBreakByWordWrapping;
        self.msgLbl3.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        [self addSubview:self.msgLbl3];
        
        self.headlineLbl4 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.headlineLbl4.backgroundColor = [UIColor clearColor];
        self.headlineLbl4.textColor = [UIColor colorWithRGBHex:0x3598c0];
        self.headlineLbl4.numberOfLines = 0;
        self.headlineLbl4.textAlignment = NSTextAlignmentCenter;
        self.headlineLbl4.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        [self addSubview:self.headlineLbl4];
        
        self.msgLbl4 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.msgLbl4.backgroundColor = [UIColor clearColor];
        self.msgLbl4.textColor = [UIColor whiteColor];
        self.msgLbl4.numberOfLines = 0;
        self.msgLbl4.lineBreakMode = NSLineBreakByWordWrapping;
        self.msgLbl4.textAlignment = NSTextAlignmentCenter;
        self.msgLbl4.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        [self addSubview:self.msgLbl4];
        
        // dismiss btn!
        self.dismissBtn = [[UIButton alloc] initWithFrame:frame];
        self.dismissBtn.backgroundColor = [UIColor clearColor];
        [self.dismissBtn setTitleColor:[UIColor colorWithRGBHex:0x546270] forState:UIControlStateNormal];
        self.dismissBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        [self.dismissBtn addTarget:self action:@selector(dismissOverlay) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.dismissBtn];
        
        [self configureForType:currType];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOverlayTriggeredFromNav) name:@"removeCoachOverlay" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureForType:(int)currType
{
    if (currType == CoachMarkTypeMAMSkip) {
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *image = [UIImage imageNamed:@"coach-mark-mam-skip"];
        
        self.backgroundImage.frame = CGRectMake(40.0, 35.0, image.size.width, image.size.height);
        self.backgroundImage.image = image;
        self.backgroundImage.hidden = NO;
        
        self.msgLbl1.frame = CGRectOffset(CGRectInset(self.backgroundImage.frame, 10.0, 20.0), 0.0, -10.0);
        self.msgLbl1.text = @"Don't feel like taking a picture or video? Skip right to a text memory.";
        self.msgLbl1.textColor = [UIColor colorWithRGBHex:0x696969];
        self.msgLbl1.font = [UIFont spc_coachMarkTextFont];
        
        self.dismissBtn.titleLabel.font = [UIFont spc_coachMarkButtonFont];
        [self.dismissBtn setTitle:@"Got it" forState:UIControlStateNormal];
        [self.dismissBtn sizeToFit];
        [self.dismissBtn setTitleColor:[SPCColorManager sharedInstance].buttonEnabledColor forState:UIControlStateNormal];
        self.dismissBtn.center = CGPointMake(CGRectGetMidX(self.backgroundImage.frame), CGRectGetMaxY(self.msgLbl1.frame)+CGRectGetHeight(self.dismissBtn.frame)/2.0-10.0);
    }
    else if (currType == CoachMarkTypeMAMPublic) {
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *image = [UIImage imageNamed:@"coach-mark-mam-public"];
        
        
        float centerX = currCtlFrame.origin.x + currCtlFrame.size.width/2;
        
        self.backgroundImage.frame = CGRectMake(centerX - 36, currCtlFrame.origin.y - image.size.height + 10, image.size.width, image.size.height);

        self.backgroundImage.image = image;
        self.backgroundImage.hidden = NO;
        
        self.msgLbl1.frame = CGRectOffset(CGRectInset(self.backgroundImage.frame, 10.0, 20.0), 0.0, -20.0);
        self.msgLbl1.text = @"Your friends and public can see it.";
        self.msgLbl1.textColor = [UIColor colorWithRGBHex:0x696969];
        self.msgLbl1.font = [UIFont spc_coachMarkTextFont];
        
        self.dismissBtn.titleLabel.font = [UIFont spc_coachMarkButtonFont];
        [self.dismissBtn setTitle:@"OK" forState:UIControlStateNormal];
        [self.dismissBtn sizeToFit];
        [self.dismissBtn setTitleColor:[SPCColorManager sharedInstance].buttonEnabledColor forState:UIControlStateNormal];
        self.dismissBtn.center = CGPointMake(CGRectGetMidX(self.backgroundImage.frame), CGRectGetMaxY(self.msgLbl1.frame)+CGRectGetHeight(self.dismissBtn.frame)/2.0-7.0);
    }
    else if (currType == CoachMarkTypeMAMPrivate) {
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *image = [UIImage imageNamed:@"coach-mark-mam-private"];
        
        float centerX = currCtlFrame.origin.x + currCtlFrame.size.width/2;
        
        self.backgroundImage.frame = CGRectMake(centerX - 188, currCtlFrame.origin.y - image.size.height + 10, image.size.width, image.size.height);
        self.backgroundImage.image = image;
        self.backgroundImage.hidden = NO;

        self.msgLbl1.frame = CGRectOffset(CGRectInset(self.backgroundImage.frame, 10.0, 20.0), 0.0, -20.0);
        self.msgLbl1.text = @"Only you and people you tag can see it.";
        self.msgLbl1.textColor = [UIColor colorWithRGBHex:0x696969];
        self.msgLbl1.font = [UIFont spc_coachMarkTextFont];
        
        self.dismissBtn.titleLabel.font = [UIFont spc_coachMarkButtonFont];
        [self.dismissBtn setTitle:@"OK" forState:UIControlStateNormal];
        [self.dismissBtn sizeToFit];
        [self.dismissBtn setTitleColor:[SPCColorManager sharedInstance].buttonEnabledColor forState:UIControlStateNormal];
        self.dismissBtn.center = CGPointMake(CGRectGetMidX(self.backgroundImage.frame), CGRectGetMaxY(self.msgLbl1.frame)+CGRectGetHeight(self.dismissBtn.frame)/2.0-7.0);
    }
    else if (currType == CoachMarkTypeVenueFav) {
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *image = [UIImage imageNamed:@"coach-mark-mam-fav"];
        
        float centerX = currCtlFrame.origin.x + currCtlFrame.size.width/2;
        
        self.backgroundImage.frame = CGRectMake(centerX - 239, currCtlFrame.origin.y + currCtlFrame.size.height + 5, image.size.width, image.size.height);
        self.backgroundImage.image = image;
        self.backgroundImage.hidden = NO;
        
        self.headlineLbl1.frame = CGRectOffset(CGRectInset(self.backgroundImage.frame, 10.0, 20.0), 0.0, -25.0);
        self.headlineLbl1.text = @"Favorited!";
        self.headlineLbl1.textColor = [UIColor colorWithRGBHex:0x696969];
        self.headlineLbl1.font = [UIFont spc_coachMarkTitleFont];
        
        self.msgLbl1.frame = CGRectOffset(CGRectInset(self.backgroundImage.frame, 10.0, 20.0), 0.0, 0.0);
        self.msgLbl1.text = @"We will show this venue next time you are in the neighborhood.";
        self.msgLbl1.textColor = [UIColor colorWithRGBHex:0x696969];
        self.msgLbl1.font = [UIFont spc_coachMarkTextFont];
        
        
        self.dismissBtn.titleLabel.font = [UIFont spc_coachMarkButtonFont];
        [self.dismissBtn setTitle:@"OK" forState:UIControlStateNormal];
        [self.dismissBtn sizeToFit];
        [self.dismissBtn setTitleColor:[SPCColorManager sharedInstance].buttonEnabledColor forState:UIControlStateNormal];
        self.dismissBtn.center = CGPointMake(CGRectGetMidX(self.backgroundImage.frame), CGRectGetMaxY(self.msgLbl1.frame)+CGRectGetHeight(self.dismissBtn.frame)/2.0-12.0);
    }
    
    
    
}

- (void)removeOverlayTriggeredFromNav {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self removeFromSuperview];
}

- (void)dismissOverlay {
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeCoachMarkNavOverlay" object:nil];
    if (currCoachMarkScreen == CoachMarkTypeMAMPublic) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"restoreKeyboard" object:nil];
    }
    [self removeFromSuperview];
}


- (void)handleSingleTap:(id)sender {
    if (self.dismissOnTouch) {
        [self dismissOverlay];
    }
}


@end
