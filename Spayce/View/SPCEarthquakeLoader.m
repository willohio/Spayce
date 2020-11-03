//
//  SPCEarthquakeLoader.m
//  Spayce
//
//  Created by Christopher Taylor on 12/4/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCEarthquakeLoader.h"

@interface SPCEarthquakeLoader ()

@property (nonatomic, strong) UIView *circleOne;
@property (nonatomic, strong) UIView *circleTwo;
@property (nonatomic, strong) UIView *circleThree;
@property (nonatomic, strong) UIView *circleFour;
@property (nonatomic, strong) UIView *circleFive;
@property (nonatomic, assign) BOOL prepToStop;

@end

@implementation SPCEarthquakeLoader

-(void)dealloc  {

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithRed:213.0f/255.0f green:218.0f/255.0f blue:223.0f/255.0f alpha:1.0f];
        
        float bgWidth = 160;
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake((self.bounds.size.width - bgWidth)/2, 87, bgWidth, 170)];
        bgView.layer.cornerRadius = 4;
        bgView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
        bgView.layer.shadowOffset = CGSizeMake(1, 2);
        bgView.backgroundColor  = [UIColor whiteColor];
        [self addSubview:bgView];
        
        
        self.msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 23, bgWidth, 30)];
        self.msgLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        self.msgLabel.textAlignment = NSTextAlignmentCenter;
        self.msgLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        [bgView addSubview:self.msgLabel];
        
        self.circleOne = [[UIView alloc] initWithFrame:CGRectZero];
        [bgView addSubview:self.circleOne];

        self.circleTwo = [[UIView alloc] initWithFrame:CGRectZero];
        [bgView addSubview:self.circleTwo];
        
        self.circleThree = [[UIView alloc] initWithFrame:CGRectZero];
        [bgView addSubview:self.circleThree];
        
        self.circleFour = [[UIView alloc] initWithFrame:CGRectZero];
        [bgView addSubview:self.circleFour];
        
        self.circleFive = [[UIView alloc] initWithFrame:CGRectZero];
        [bgView addSubview:self.circleFive];
    }
    return self;
}

-(void)stopAnimating {
    self.prepToStop = YES;
    [self.circleOne.layer removeAllAnimations];
    [self.circleTwo.layer removeAllAnimations];
    [self.circleThree.layer removeAllAnimations];
    [self.circleFour.layer removeAllAnimations];
    [self.circleFive.layer removeAllAnimations];
    
    self.circleOne.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    self.circleOne.alpha = 1.0f;
    self.circleTwo.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    self.circleTwo.alpha = 1.0f;
    self.circleThree.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    self.circleThree.alpha = 1.0f;
    self.circleFour.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    self.circleFour.alpha = 1.0f;
    self.circleFive.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    self.circleFive.alpha = 1.0f;
}

-(void)startAnimating {
    self.prepToStop = NO;
    
    self.circleOne.frame = CGRectMake(78, 103, 4, 4);
    self.circleOne.layer.cornerRadius = self.circleOne.frame.size.width/2;
    self.circleOne.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
    self.circleOne.layer.borderWidth = .2;
    
    self.circleTwo.frame = CGRectMake(78, 103, 4, 4);
    self.circleTwo.layer.cornerRadius = self.circleTwo.frame.size.width/2;
    self.circleTwo.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
    self.circleTwo.layer.borderWidth = .2;
    
    self.circleThree.frame = CGRectMake(78, 103, 4, 4);
    self.circleThree.layer.cornerRadius = self.circleThree.frame.size.width/2;
    self.circleThree.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
    self.circleThree.layer.borderWidth = .2;
    
    self.circleFour.frame = CGRectMake(78, 103, 4, 4);
    self.circleFour.layer.cornerRadius = self.circleFour.frame.size.width/2;
    self.circleFour.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
    self.circleFour.layer.borderWidth = .2;
    
    self.circleFive.frame = CGRectMake(78, 103, 4, 4);
    self.circleFive.layer.cornerRadius = self.circleFive.frame.size.width/2;
    self.circleFive.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
    self.circleFive.layer.borderWidth = .2;
    
    
    float stagger = .5;
    float fullDuration = stagger * 5;
    
    [UIView animateWithDuration:fullDuration
                          delay:0.0
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                     
                         self.circleOne.transform = CGAffineTransformMakeScale(25.0, 25.0);
                         self.circleOne.alpha = 0;
                     
                     } completion:^(BOOL finished) {
                         if (finished) {
                          
                             if (!self.prepToStop) {
                                 self.circleOne.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                 self.circleOne.alpha = 1.0f;
                             }
                             
                         }
                     }];
    
    
    [UIView animateWithDuration:fullDuration
                          delay:stagger
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                         
                         self.circleTwo.transform = CGAffineTransformMakeScale(25.0, 25.0);
                         self.circleTwo.alpha = 0;
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             if (!self.prepToStop) {
                                 self.circleTwo.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                 self.circleTwo.alpha = 1.0f;
                             }
                         }
                     }];
    
    [UIView animateWithDuration:fullDuration
                          delay:stagger * 2
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                         
                         self.circleThree.transform = CGAffineTransformMakeScale(25.0, 25.0);
                         self.circleThree.alpha = 0;
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             if (!self.prepToStop) {
                                 self.circleThree.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                 self.circleThree.alpha = 1.0f;
                             }
                         }
                     }];
    
    [UIView animateWithDuration:fullDuration
                          delay:stagger * 3
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                         
                         self.circleFour.transform = CGAffineTransformMakeScale(25.0, 25.0);
                         self.circleFour.alpha = 0;
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             if (!self.prepToStop) {
                                 self.circleFour.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                 self.circleFour.alpha = 1.0f;
                             }
                         }
                     }];
    
    [UIView animateWithDuration:fullDuration
                          delay:stagger * 4
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                         
                         self.circleFive.transform = CGAffineTransformMakeScale(25.0, 25.0);
                         self.circleFive.alpha = 0;
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             if (!self.prepToStop) {
                                 self.circleFive.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                 self.circleFive.alpha = 1.0f;
                             }
                         }
                     }];
}


@end
