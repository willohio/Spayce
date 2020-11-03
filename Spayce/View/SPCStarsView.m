//
//  SPCStarsView.m
//  Spayce
//
//  Created by Jake Rosin on 8/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCStarsView.h"

@interface SPCStarsView()

@property (strong,nonatomic) UIImageView *stars1;
@property (strong,nonatomic) UIImageView *stars2;
@property (strong,nonatomic) UIImageView *stars3;

@property (assign, nonatomic) BOOL animating;

-(void)prepAnimation;

@end

@implementation SPCStarsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
    }
    return self;
}

-(void)prepAnimation {
    
    //TODO -- ADD STARS IMAGES SIZED FOR IPAD
    UIImage *stars1Img = [UIImage imageNamed:@"animation-stars-1"];
    UIImage *stars2Img = [UIImage imageNamed:@"animation-stars-2"];
    UIImage *stars3Img = [UIImage imageNamed:@"animation-stars-3"];
    starsHeight = 368;
    
    self.stars1 = [[UIImageView alloc] initWithImage:stars1Img];
    self.stars2 = [[UIImageView alloc] initWithImage:stars2Img];
    self.stars3 = [[UIImageView alloc] initWithImage:stars3Img];
    
    [self addSubview:self.stars1];
    [self addSubview:self.stars2];
    [self addSubview:self.stars3];
    
    self.stars1.center = CGPointMake(self.bounds.size.width/2, starsHeight + starsHeight/2);
    self.stars2.center = CGPointMake(self.bounds.size.width/2, starsHeight/2);
    self.stars3.center = CGPointMake(self.bounds.size.width/2, -1 * starsHeight/2);
}


-(void)startAnimation {
    if (!self.stars1) {
        [self prepAnimation];
    }
    [self stopAnimation];
    self.animating = YES;
    [self animationLoop];
}

-(void)animationLoop {
    [UIView animateWithDuration:3.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        for (UIView *view in self.subviews) {
            view.center = CGPointMake(view.center.x, view.center.y + starsHeight/2);
        }
    } completion:^(BOOL finished) {
        
        if (finished && self.animating) {
            
            for (UIView *view in self.subviews) {
                if (view.center.y >= ((starsHeight * 2) + starsHeight/2)) {
                    view.center = CGPointMake(self.bounds.size.width/2, -1 * starsHeight/2);
                }
            }
            
            [self animationLoop];
        }
    }];
}

-(void)stopAnimation {

    if (self.animating) {
        //NSLog(@"stop stars animation!");
        self.animating = NO;
        
        [self.stars1.layer removeAllAnimations];
        [self.stars2.layer removeAllAnimations];
        [self.stars3.layer removeAllAnimations];
        
        self.stars1.center = CGPointMake(self.bounds.size.width/2, starsHeight + starsHeight/2);
        self.stars2.center = CGPointMake(self.bounds.size.width/2, starsHeight/2);
        self.stars3.center = CGPointMake(self.bounds.size.width/2, -1 * starsHeight/2);
        
    }
}


@end
