//
//  IntroAnimation.m
//  Spayce
//
//  Created by Christopher Taylor on 1/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "IntroAnimation.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"

NSString * kIntroAnimationDidBeginNotification = @"IntroAnimationDidBeginNotification";
NSString * kIntroAnimationDidEndNotification = @"IntroAnimationDidEndNotification";

@interface IntroAnimation ()

@property (nonatomic, strong) UIImage *launchImg;
@end

@implementation IntroAnimation

const int starsTag = -1;

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame
{
    //NSLog(@"init intro animation");
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:28.0f/255.0f green:26.0f/255.0f blue:33.0f/255.0f alpha:1.0f];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loginStarted)
                                                     name:@"loginStarted"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loginComplete)
                                                     name:kAuthenticationDidFinishWithSuccessNotification
                                                   object:nil];
    }
    return self;
}


-(void)prepAnimation {
    
    logoStopY = -22+self.bounds.size.height/2;
    
    
    //add rocket
    UIImage *baseRocketImage = [UIImage imageNamed:@"animation-rocket-0"];
    self.rocketImgView = [[UIImageView alloc]initWithImage:baseRocketImage];
    self.rocketImgView.animationImages = @[
            [UIImage imageNamed:@"animation-rocket-1"],
            [UIImage imageNamed:@"animation-rocket-2"],
            [UIImage imageNamed:@"animation-rocket-3"],
            [UIImage imageNamed:@"animation-rocket-4"],
            [UIImage imageNamed:@"animation-rocket-3"],
            [UIImage imageNamed:@"animation-rocket-2"]
    ];

    self.rocketImgView.alpha = 1;
    self.rocketImgView.animationDuration = .4; // seconds
    self.rocketImgView.animationRepeatCount = 0; // 0 = loops forever
    self.rocketImgView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    [self addSubview:self.rocketImgView];
    [self.rocketImgView startAnimating];
    
    //TODO -- ADD STARS IMAGES SIZED FOR IPAD
    UIImage *starsImg = [UIImage imageNamed:@"animation-ftl-0"];
    UIImage *stars2Img = [UIImage imageNamed:@"animation-ftl-1"];
    UIImage *stars3Img = [UIImage imageNamed:@"animation-ftl-2"];
    starsHeight = 284;
    
    self.stars1 = [[UIImageView alloc] initWithImage:starsImg];
    self.stars1.tag = starsTag;
    
    self.stars2 = [[UIImageView alloc] initWithImage:stars2Img];
    self.stars2.tag = starsTag;
    
    self.stars3 = [[UIImageView alloc] initWithImage:stars3Img];
    self.stars3.tag = starsTag;
    
    [self addSubview:self.stars1];
    [self addSubview:self.stars2];
    [self addSubview:self.stars3];

    [self bringSubviewToFront:self.rocketImgView];
    
    UIImage *logoImg = [UIImage imageNamed:@"animation-rocket-initial-letter"];
    self.logoImgView = [[UIImageView alloc] initWithImage:logoImg];
    self.logoImgView.center = CGPointMake(-1+self.bounds.size.width/2, -30);
    [self addSubview:self.logoImgView];
    
    self.stars1.center = CGPointMake(self.bounds.size.width/2, starsHeight+starsHeight/2);
    self.stars2.center = CGPointMake(self.bounds.size.width/2, starsHeight/2);
    self.stars3.center = CGPointMake(self.bounds.size.width/2, -1 * starsHeight/2);
    
    self.initialLoadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.initialLoadingView.backgroundColor = [UIColor colorWithRed:28.0f/255.0f green:26.0f/255.0f blue:33.0f/255.0f alpha:1.0f];
    [self addSubview:self.initialLoadingView];
    
    self.bigLogoImgView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.bigLogoImgView.image = self.launchImg;
    self.bigLogoImgView.center = CGPointMake(self.initialLoadingView.frame.size.width/2, self.initialLoadingView.frame.size.height/2);
    [self.initialLoadingView addSubview:self.bigLogoImgView];

    self.initialLoadingView.hidden = YES;
    self.bigLogoImgView.hidden = YES;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"validatingSession"]){
        justLoggedIn = YES;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"validatingSession"];
    }
    
    if (justLoggedIn) {
        self.initialLoadingView.hidden = NO;
        self.bigLogoImgView.hidden = NO;
    }
}

-(void)loginStarted {
    justLoggedIn = YES;
}

-(void)loginComplete {
    //NSLog(@"login complete, begin intro animation");
    justLoggedIn = NO;
}

-(void)startAnimation {
    
    //NSLog(@"start animation");
    
    if (justLoggedIn) {
        animationEndCount = 10;
    }
    else {
        animationEndCount = 190;
    }
    
    beginS_Count = 100;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.01f target:self selector:@selector(animationLoop) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIntroAnimationDidBeginNotification object:nil];
}

-(void)animationLoop {
    
    if (!animationStopped) {
       
        animationCounter = animationCounter + 1;

        UIView *view;
        NSArray *subs = [self subviews];
        
        for (view in subs) {
            
            //handle stars
            if (view.tag == starsTag) {
                view.center = CGPointMake(view.center.x, view.center.y+10);
                if (view.center.y > ((starsHeight * 2)+ starsHeight/2)) {
                    view.center = CGPointMake(self.bounds.size.width/2, -1 * starsHeight/2);
                }
            }
            
            //handle s
            if (animationCounter >= beginS_Count) {
                self.logoImgView.center = CGPointMake(self.logoImgView.center.x,  self.logoImgView.center.y+2);
                if (self.logoImgView.center.y >= (-30+self.bounds.size.height/2)) {
                    self.logoImgView.center = CGPointMake(self.logoImgView.center.x, logoStopY);
                }
            }
        }
        
        if (animationCounter == animationEndCount) {
            [self stopAnimation];
        }
    }
}

-(void)stopAnimation {
    
    //NSLog(@"stop animation");
    animationStopped = YES;
    
    [self.timer invalidate];
    self.timer = nil;
    
    self.progressLabel.hidden = YES;
    self.progressHeaderLabel.hidden = YES;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.rocketImgView.center = CGPointMake(self.rocketImgView.center.x, (self.rocketImgView.center.y-(self.frame.size.height*0.6)));
                         self.logoImgView.center = CGPointMake(self.logoImgView.center.x, (self.logoImgView.center.y-(self.frame.size.height*0.6)));
                         if (!justSignedUp){
                             self.alpha = 0.0;
                         }
                     } completion:^(BOOL finished) {
                         
                         //NSLog(@"stop animating????");
                         if (finished) {
                             //NSLog(@"remove intro from superview!");
                             [self.rocketImgView stopAnimating];
                             [self removeFromSuperview];
                             [[NSNotificationCenter defaultCenter] postNotificationName:kIntroAnimationDidEndNotification object:nil];
                         }
                     }];

}


- (void)dismissIntro {
    [self removeFromSuperview];
}

-(UIImage *)launchImg {
    NSArray *allPngImageNames = [[NSBundle mainBundle] pathsForResourcesOfType:@"png"
                                                                   inDirectory:nil];
    
        for (NSString *imgName in allPngImageNames) {
            //ios 8
            if ([imgName respondsToSelector:@selector(containsString:)]) {
            
                if ([imgName rangeOfString:@"LaunchImage"].location != NSNotFound) {
                    UIImage *img = [UIImage imageNamed:imgName];
                    // Has image same scale and dimensions as our current device's screen?
                    if (img.scale == [UIScreen mainScreen].scale && CGSizeEqualToSize(img.size, [UIScreen mainScreen].bounds.size)) {
                        return img;
                        break;
                    }
                }
            }
            //ios 7
            else {
                if ([imgName rangeOfString:@"LaunchImage"].location != NSNotFound) {
                    NSMutableString *mutImgName = [NSMutableString stringWithString:imgName];
                    NSInteger loc = [imgName rangeOfString:@"LaunchImage"].location;
                    NSInteger length = imgName.length - loc;
                    NSString *trimmedStr = [mutImgName substringWithRange:NSMakeRange(loc,length)];
                    UIImage *img = [UIImage imageNamed:trimmedStr];
                    
                    if (img.scale * img.size.width == [UIScreen mainScreen].scale * [UIScreen mainScreen].bounds.size.width) {
                        return img;
                        break;
                    }
                }
            }
        }
    
    return nil;
}

@end
