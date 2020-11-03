//
//  SPCWelcomeIntroView.m
//  Spayce
//
//  Created by Arria P. Owlia on 4/8/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCWelcomeIntroView.h"

const CGFloat ANIMATION_DURATION_DEFAULT = 0.55f;
const CGFloat SPRING_DAMPING_DEFAULT = 0.6f;
const CGFloat INITIAL_VELOCITY_DEFAULT = -0.003f;

const CGFloat IPHONE_HEIGHT_OFFSET = 144.0f / 1163.0f; // This is the height of the iphone image that is cut off below the screen, should be multiplied by the iphone image height

@interface SPCWelcomeIntroView()

// Helpers
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

// Background
@property (nonatomic, strong) UIImageView *ivBackground;

// State
@property (nonatomic) enum ScreenState screenState;

// Screen 1
@property (nonatomic, strong) UILabel *lblScreen1;
@property (nonatomic, strong) UIImage *imageS1Bg;
@property (nonatomic, strong) UIImageView *ivS1Phone;
@property (nonatomic, strong) UIImageView *ivShareButton;
@property (nonatomic, strong) UIImageView *ivS1Graphic;

// Screen 2
@property (nonatomic, strong) UILabel *lblScreen2;
@property (nonatomic, strong) UIImage *imageS2Bg;
@property (nonatomic, strong) UIImageView *ivS2Phone;
@property (nonatomic, strong) UIImageView *ivS2Graphic1;
@property (nonatomic, strong) UIImageView *ivS2Graphic2;

// Screen 3
@property (nonatomic, strong) UILabel *lblScreen3;
@property (nonatomic, strong) UIImage *imageS3Bg;
@property (nonatomic, strong) UIImageView *ivS3Phone;
@property (nonatomic, strong) UIImageView *ivS3Graphic;
@property (nonatomic, strong) UIImageView *ivStar;


@end

@implementation SPCWelcomeIntroView

typedef enum ScreenState {
    ScreenStateUnknown,
    ScreenStateOne,
    ScreenStateTwo,
    ScreenStateThree,
} ScreenState;

#pragma mark - dealloc

- (void)dealloc {
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Actions

- (void)play {
    self.screenState = ScreenStateOne;
}

- (void)stop {
    [self.layer removeAllAnimations];
    [UIView transitionWithView:self
                      duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                           [self.layer displayIfNeeded];
                       } completion:nil];
    for (UIView *subview in self.subviews) {
        if (NO == [subview isEqual:self.ivBackground]) {
            [subview removeFromSuperview];
        }
    }
}

#pragma mark - Screen 1

- (void)playScreenOne {
    [self blendInBackgroundImage:self.imageS1Bg withCompletionBlock:^{
        // Keep track of time
        CGFloat timeElapsed = 0;
        
        // Step 1 - Slide in label
        // Add it to the view offscreen
        [self.lblScreen1 sizeToFit];
        self.lblScreen1.center = CGPointMake([self centerPointXOffscreenLeftForView:self.lblScreen1], 160.0f/1334.0f * self.height);
        [self addSubview:self.lblScreen1];
        
        // Slide it in
        [self slideView:self.lblScreen1
          toCenterPoint:CGPointMake(CGRectGetWidth(self.lblScreen1.frame)/2.0f + 24.0f, self.lblScreen1.center.y)
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:0
    withCompletionBlock:nil];
        
        timeElapsed += ANIMATION_DURATION_DEFAULT;
        
        // Step 2 - Slide in iphone
        // Add it to the view offscreen
        CGFloat phoneImageHWRatio = self.ivS1Phone.image.size.height / self.ivS1Phone.image.size.width;
        self.ivS1Phone.bounds = CGRectMake(0, 0, 560.0f/750.0f * self.width * self.aspectRatioScaleOffset, 560.0f/750.0f * self.width * phoneImageHWRatio * self.aspectRatioScaleOffset);
        self.ivS1Phone.center = CGPointMake([self centerPointXOffscreenLeftForView:self.ivS1Phone], CGRectGetHeight(self.bounds) - CGRectGetHeight(self.ivS1Phone.frame)/2.0f + IPHONE_HEIGHT_OFFSET * CGRectGetHeight(self.ivS1Phone.bounds));
        [self insertSubview:self.ivS1Phone belowSubview:self.lblScreen1];
        
        // Slide it in
        [self slideView:self.ivS1Phone
          toCenterPoint:CGPointMake(CGRectGetWidth(self.ivS1Phone.frame)/2.0f + 24.0f, self.ivS1Phone.center.y)
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed
    withCompletionBlock:^{
        // Show the ivShare button, since the phone is now fully in-view
        self.ivShareButton.hidden = NO;
    }];
        
        timeElapsed += ANIMATION_DURATION_DEFAULT;
        
        // Step 3 - Show/Hide enlarged Share button
        CGFloat shareImageHWRatio = self.ivShareButton.image.size.height / self.ivShareButton.image.size.width;
        self.ivShareButton.bounds = CGRectMake(0, 0, 493.0f/750.0f * self.width * self.aspectRatioScaleOffset, 493.0f/750.0f * self.width * shareImageHWRatio * self.aspectRatioScaleOffset);
        self.ivShareButton.center = CGPointMake(self.ivS1Phone.center.x, self.height - CGRectGetHeight(self.ivShareButton.frame)/2.0f);
        self.ivShareButton.hidden = YES;
        [self addSubview:self.ivShareButton];
        
        CGRect originalShareButtonBounds = self.ivShareButton.bounds;
        CGRect enlargedShareButtonBounds = CGRectInset(originalShareButtonBounds, -20, -20 * shareImageHWRatio);
        
        // Enlarge!
        [self resizeView:self.ivShareButton
           withNewBounds:enlargedShareButtonBounds
            withDuration:ANIMATION_DURATION_DEFAULT/3.0f
           andFinalAlpha:1.0f
              afterDelay:timeElapsed
     withCompletionBlock:^{
         // Shrink :'(
         [self resizeView:self.ivShareButton
            withNewBounds:originalShareButtonBounds
             withDuration:ANIMATION_DURATION_DEFAULT
            andFinalAlpha:1.0f
               afterDelay:0
      withCompletionBlock:nil];
     }];
        
        timeElapsed += 4.0f/3.0f * ANIMATION_DURATION_DEFAULT; // 1x for enlarge, 1x for shrink
        
        // Step 4 - Show the magnification graphic
        // We need to place it at a specific point of the iphone. Let's compute that point
        self.ivS1Graphic.bounds = CGRectMake(0, 0, 0, 0);
        self.ivS1Graphic.center = CGPointMake(self.ivS1Phone.frame.origin.x + 520.0f/560.0f * self.ivS1Phone.frame.size.width, self.ivS1Phone.frame.origin.y + 770.0f/1163.0f * self.ivS1Phone.bounds.size.height);
        [self addSubview:self.ivS1Graphic];
        
        CGFloat graphicImageHWRatio = self.ivS1Graphic.image.size.height / self.ivS1Graphic.image.size.width;
        CGRect newS1GraphicsBounds = CGRectMake(0, 0, self.width, self.width * graphicImageHWRatio);
        // Enlarge to full size!
        [self resizeView:self.ivS1Graphic
           withNewBounds:newS1GraphicsBounds
            withDuration:ANIMATION_DURATION_DEFAULT
           andFinalAlpha:1.0f
              afterDelay:timeElapsed
     withCompletionBlock:nil];
        
        timeElapsed += ANIMATION_DURATION_DEFAULT;
        
        // Let's add a pause here, since everything is finally in-view
        timeElapsed += 1.75f;
        
        // Step 5 - Start removing everything! Start with the graphic
        CGPoint graphicCenterOffscreenRight = CGPointMake([self centerPointXOffscreenRightForView:self.ivS1Graphic], self.ivS1Graphic.center.y);
        [self slideView:self.ivS1Graphic
          toCenterPoint:graphicCenterOffscreenRight
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed
    withCompletionBlock:^{
        [self.ivS1Graphic removeFromSuperview];
    }];
        
        timeElapsed += ANIMATION_DURATION_DEFAULT;
        
        // Phone and share button next
        const CGFloat delayBetweenPhontAndTextSlideOut = 0.2f;
        CGPoint phoneCenterOffscreenRight = CGPointMake([self centerPointXOffscreenRightForView:self.ivS1Phone], self.ivS1Phone.center.y);
        [self slideView:self.ivS1Phone
          toCenterPoint:phoneCenterOffscreenRight
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed
    withCompletionBlock:^{
        [self.ivS1Phone removeFromSuperview];
    }];
        
        CGPoint shareCenterOffscreenRight = CGPointMake([self centerPointXOffscreenRightForView:self.ivShareButton], self.ivShareButton.center.y);
        [self slideView:self.ivShareButton
          toCenterPoint:shareCenterOffscreenRight
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed
    withCompletionBlock:^{
        [self.ivShareButton removeFromSuperview];
    }];
        
        // Finally, the label
        CGPoint labelCenterOffscreenRight = CGPointMake([self centerPointXOffscreenRightForView:self.lblScreen1], self.lblScreen1.center.y);
        [self slideView:self.lblScreen1
          toCenterPoint:labelCenterOffscreenRight
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed + delayBetweenPhontAndTextSlideOut
    withCompletionBlock:^{
        [self.lblScreen1 removeFromSuperview];
        
        self.screenState = ScreenStateTwo;
    }];
        
    }];
}

#pragma mark - Screen 2

- (void)playScreenTwo {
    [self blendInBackgroundImage:self.imageS2Bg withCompletionBlock:^{
        // Keep track of time
        CGFloat timeElapsed = 0;
        
        // Step 1 - Slide in label
        // Add it to the view offscreen
        [self.lblScreen2 sizeToFit];
        self.lblScreen2.center = CGPointMake(self.center.x, [self centerPointYOffscreenTopForView:self.lblScreen2]);
        [self addSubview:self.lblScreen2];
        
        // Slide it in
        [self slideView:self.lblScreen2
          toCenterPoint:CGPointMake(self.center.x, 160.0f/1334.0f * self.height)
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:0
    withCompletionBlock:nil];
        
        // Step 2 - Slide in iphone
        const CGFloat delayBetweenTextAndPhoneSlideIn = 0.2f;
        // Add it to the view offscreen
        CGFloat phoneImageHWRatio = self.ivS2Phone.image.size.height / self.ivS2Phone.image.size.width;
        self.ivS2Phone.bounds = CGRectMake(0, 0, 560.0f/750.0f * self.width * self.aspectRatioScaleOffset, 560.0f/750.0f * self.width * phoneImageHWRatio * self.aspectRatioScaleOffset);
        self.ivS2Phone.center = CGPointMake(self.center.x, [self centerPointYOffscreenBottomForView:self.ivS2Phone]);
        [self insertSubview:self.ivS2Phone belowSubview:self.lblScreen2];
        
        // Slide it in
        [self slideView:self.ivS2Phone
          toCenterPoint:CGPointMake(self.ivS2Phone.center.x, self.height - CGRectGetHeight(self.ivS2Phone.frame)/2.0f + IPHONE_HEIGHT_OFFSET * CGRectGetHeight(self.ivS2Phone.bounds))
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:delayBetweenTextAndPhoneSlideIn
    withCompletionBlock:nil];
        
        timeElapsed += ANIMATION_DURATION_DEFAULT + delayBetweenTextAndPhoneSlideIn;
        
        // Step 3 - Slide in the two graphics
        const CGFloat delayBetweenGraphicsPopins = 0.2f;
        // Place in the first graphic
        self.ivS2Graphic1.bounds = CGRectMake(0, 0, 0, 0);
        self.ivS2Graphic1.center = CGPointMake(self.ivS2Phone.frame.origin.x + 470.0f/560.0f * self.ivS2Phone.frame.size.width, self.ivS2Phone.frame.origin.y + 515.0f/1163.0f * self.ivS2Phone.bounds.size.height);
        self.ivS2Graphic1.alpha = 0.0f;
        [self addSubview:self.ivS2Graphic1];
        
        CGFloat graphic1ImageHWRatio = self.ivS2Graphic1.image.size.height / self.ivS2Graphic1.image.size.width;
        CGRect newS2Graphics1Bounds = CGRectMake(0, 0, 456.0f/750.0f * self.width, 456.0f/750.0f * self.width * graphic1ImageHWRatio);
        // Enlarge to full size!
        [self resizeView:self.ivS2Graphic1
           withNewBounds:newS2Graphics1Bounds
            withDuration:ANIMATION_DURATION_DEFAULT
           andFinalAlpha:1.0f
              afterDelay:timeElapsed
     withCompletionBlock:nil];
        
        // Place in the second graphic
        self.ivS2Graphic2.bounds = CGRectMake(0, 0, 0, 0);
        self.ivS2Graphic2.center = CGPointMake(self.ivS2Phone.frame.origin.x + 38.0f/560.0f * self.ivS2Phone.frame.size.width, self.ivS2Phone.frame.origin.y + 814.0f/1163.0f * self.ivS2Phone.bounds.size.height);
        self.ivS2Graphic2.alpha = 0.0f;
        [self addSubview:self.ivS2Graphic2];
        
        CGFloat graphic2ImageHWRatio = self.ivS2Graphic2.image.size.height / self.ivS2Graphic2.image.size.width;
        CGRect newS2Graphics2Bounds = CGRectMake(0, 0, 485.0f/750.0f * self.width, 485.0f/750.0f * self.width * graphic2ImageHWRatio);
        // Enlarge to full size!
        [self resizeView:self.ivS2Graphic2
           withNewBounds:newS2Graphics2Bounds
            withDuration:ANIMATION_DURATION_DEFAULT
           andFinalAlpha:1.0f
              afterDelay:timeElapsed + delayBetweenGraphicsPopins
     withCompletionBlock:nil];
        
        timeElapsed += ANIMATION_DURATION_DEFAULT + delayBetweenGraphicsPopins;
        // Pause for some time
        timeElapsed += 2.0f;
        
        // Step 4 - Remove the popins in LIFO order
        // Remove the first popin
        CGRect finalS2Graphics2Bounds = CGRectMake(self.ivS2Graphic2.center.x, self.ivS2Graphic2.center.y, 0, 0);
        [self resizeView:self.ivS2Graphic2
           withNewBounds:finalS2Graphics2Bounds
            withDuration:ANIMATION_DURATION_DEFAULT * 3.0f
           andFinalAlpha:0.0f
              afterDelay:timeElapsed
     withCompletionBlock:^{
         [self.ivS2Graphic2 removeFromSuperview];
     }];
        // Remove the second popin
        CGRect finalS2Graphics1Bounds = CGRectMake(self.ivS2Graphic1.center.x, self.ivS2Graphic1.center.y, 0, 0);
        [self resizeView:self.ivS2Graphic1
           withNewBounds:finalS2Graphics1Bounds
            withDuration:ANIMATION_DURATION_DEFAULT * 3.0f
           andFinalAlpha:0.0f
              afterDelay:timeElapsed + delayBetweenGraphicsPopins
     withCompletionBlock:^{
         [self.ivS2Graphic1 removeFromSuperview];
     }];
        
        timeElapsed += ANIMATION_DURATION_DEFAULT + delayBetweenGraphicsPopins;
        
        // Step 5 - Remove the text and phone at the same time
        [self slideView:self.ivS2Phone
          toCenterPoint:CGPointMake(self.center.x, [self centerPointYOffscreenBottomForView:self.ivS2Phone])
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed
    withCompletionBlock:^{
            [self.ivS2Phone removeFromSuperview];
    }];
        
        [self slideView:self.lblScreen2
          toCenterPoint:CGPointMake(self.center.x, [self centerPointYOffscreenTopForView:self.lblScreen2])
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed
    withCompletionBlock:^{
        [self.lblScreen2 removeFromSuperview];
        
        self.screenState = ScreenStateThree;
    }];
    }];
}

#pragma mark - Screen 3

- (void)playScreenThree {
    [self blendInBackgroundImage:self.imageS3Bg withCompletionBlock:^{
        // Keep track of time
        CGFloat timeElapsed = 0;
        
        // Step 1 - Slide in label
        // Add it to the view offscreen
        [self.lblScreen3 sizeToFit];
        self.lblScreen3.center = CGPointMake([self centerPointXOffscreenRightForView:self.lblScreen3], 130.0f/1334.0f * self.height);
        [self addSubview:self.lblScreen3];
        
        // Slide it in
        [self slideView:self.lblScreen3
          toCenterPoint:CGPointMake(CGRectGetWidth(self.lblScreen3.frame)/2.0f + 24.0f, self.lblScreen3.center.y)
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:0
    withCompletionBlock:nil];
        
        // Step 2 - Slide in iphone
        const CGFloat delayBetweenTextAndPhoneSlideIn = 0.3f;
        // Add it to the view offscreen
        CGFloat phoneImageHWRatio = self.ivS3Phone.image.size.height / self.ivS3Phone.image.size.width;
        self.ivS3Phone.bounds = CGRectMake(0, 0, 560.0f/750.0f * self.width * self.aspectRatioScaleOffset, 560.0f/750.0f * self.width * phoneImageHWRatio * self.aspectRatioScaleOffset);
        self.ivS3Phone.center = CGPointMake([self centerPointXOffscreenRightForView:self.ivS1Phone], CGRectGetHeight(self.bounds) - CGRectGetHeight(self.ivS3Phone.frame)/2.0f + IPHONE_HEIGHT_OFFSET * CGRectGetHeight(self.ivS3Phone.bounds));
        [self insertSubview:self.ivS3Phone belowSubview:self.lblScreen3];
        
        // Slide it in
        [self slideView:self.ivS3Phone
          toCenterPoint:CGPointMake(CGRectGetWidth(self.ivS3Phone.frame)/2.0f + 24.0f, self.ivS3Phone.center.y)
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:delayBetweenTextAndPhoneSlideIn
    withCompletionBlock:nil];
    
        timeElapsed += ANIMATION_DURATION_DEFAULT + delayBetweenTextAndPhoneSlideIn;
        
        // Step 3 - Pop in the graphic
        self.ivS3Graphic.bounds = CGRectMake(0, 0, 0, 0);
        self.ivS3Graphic.center = CGPointMake(self.ivS3Phone.frame.origin.x + 520.0f/560.0f * self.ivS3Phone.frame.size.width, self.ivS3Phone.frame.origin.y + 650.0f/1163.0f * self.ivS3Phone.bounds.size.height);
        self.ivS3Graphic.alpha = 0.0f;
        [self addSubview:self.ivS3Graphic];
        
        CGFloat graphicImageHWRatio = self.ivS3Graphic.image.size.height / self.ivS3Graphic.image.size.width;
        CGRect newS3GraphicsBounds = CGRectMake(0, 0, 374.0f/750.0f * self.width, 374.0f/750.0f * self.width * graphicImageHWRatio);
        // Enlarge to full size!
        [self resizeView:self.ivS3Graphic
           withNewBounds:newS3GraphicsBounds
            withDuration:ANIMATION_DURATION_DEFAULT
           andFinalAlpha:1.0f
              afterDelay:timeElapsed
     withCompletionBlock:nil];
        
        timeElapsed += ANIMATION_DURATION_DEFAULT;
        
        // Step 4 - Animate in the star
        CGFloat starImageHWRatio = self.ivStar.image.size.height / self.ivStar.image.size.width;
        self.ivStar.bounds = CGRectMake(0, 0, 35.0f/750.0f * self.width, 35.0f/750.0f * self.width * starImageHWRatio);
        self.ivStar.center = CGPointMake(self.ivS3Phone.frame.origin.x + 415.0f/560.0f * CGRectGetWidth(self.ivS3Phone.frame), [self centerPointYOffscreenBottomForView:self.ivStar]);
        [self addSubview:self.ivStar];
        
        // Slide it up
        [self slideView:self.ivStar
          toCenterPoint:CGPointMake(self.ivStar.center.x, CGRectGetMinY(self.ivS3Phone.frame))
           withDuration:ANIMATION_DURATION_DEFAULT * 2.0f
             afterDelay:timeElapsed
    withCompletionBlock:^{
        self.hasPlayedToEnd = YES;
    }];
        
        timeElapsed += 2.0f * ANIMATION_DURATION_DEFAULT;
        
        // Let's pause for a bit here, since everything's in-view
        timeElapsed += 1.75f;
        
        // Slide it even farther up
        [self slideView:self.ivStar
          toCenterPoint:CGPointMake(self.ivStar.center.x, [self centerPointYOffscreenTopForView:self.ivStar])
           withDuration:ANIMATION_DURATION_DEFAULT * 2.0f
             afterDelay:timeElapsed
    withCompletionBlock:^{
        [self.ivStar removeFromSuperview];
    }];
        
        timeElapsed += 2.0f * ANIMATION_DURATION_DEFAULT;
        
        // Let's have the removal start as the star is animating out
        timeElapsed -= 1.0f * ANIMATION_DURATION_DEFAULT;
        
        // Step 6 - Start removing everything, beginning with the phone
        [self slideView:self.ivS3Phone
          toCenterPoint:CGPointMake([self centerPointXOffscreenLeftForView:self.ivS3Phone], self.ivS3Phone.center.y)
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed
    withCompletionBlock:^{
        [self.ivS3Phone removeFromSuperview];
    }];
        
        // Then the text
        [self slideView:self.lblScreen3
          toCenterPoint:CGPointMake([self centerPointXOffscreenLeftForView:self.lblScreen3], self.lblScreen3.center.y)
           withDuration:ANIMATION_DURATION_DEFAULT
             afterDelay:timeElapsed + delayBetweenTextAndPhoneSlideIn
    withCompletionBlock:^{
        [self.lblScreen3 removeFromSuperview];
        
        // Let's set this in the completion block here, because we have a 'normal' animation duration, as opposed to the 3x duration of the graphic of this scene
        self.screenState = ScreenStateOne;
    }];
        
        // Finally, the graphic
        const CGFloat delayBetweenTextAndGraphicSlideOut = 0.1f;
        CGRect finalS3GraphicsBounds = CGRectMake(self.ivS3Graphic.center.x, self.ivS3Graphic.center.y, 0, 0);
        [self resizeView:self.ivS3Graphic
           withNewBounds:finalS3GraphicsBounds
            withDuration:ANIMATION_DURATION_DEFAULT * 3.0f
           andFinalAlpha:0.0f
              afterDelay:timeElapsed + delayBetweenTextAndPhoneSlideIn + delayBetweenTextAndGraphicSlideOut
     withCompletionBlock:^{
         [self.ivS2Graphic2 removeFromSuperview];
     }];
    }];
}

#pragma mark - Screen State

- (void)setScreenState:(enum ScreenState)screenState {
    _screenState = screenState;
    
    switch (screenState) {
        case ScreenStateOne:
            [self playScreenOne];
            break;
            
        case ScreenStateTwo:
            [self playScreenTwo];
            break;
            
        case ScreenStateThree:
            [self playScreenThree];
            break;
            
        default:
            [self stop];
            break;
    }
}

#pragma mark - Helpers

- (void)blendInBackgroundImage:(UIImage *)imageBackground withCompletionBlock:(void (^)())completionBlock {
    self.ivBackground.frame = self.bounds;
    [UIView transitionWithView:self.ivBackground duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.ivBackground.image = imageBackground;
    } completion:^(BOOL finished) {
        if (finished) {
            if (nil != completionBlock) {
                completionBlock();
            }
        }
    }];
}

- (void)slideView:(UIView *)view toCenterPoint:(CGPoint)centerPointFinal withDuration:(CGFloat)duration afterDelay:(CGFloat)delay withCompletionBlock:(void (^)())completionBlock {
    [UIView animateWithDuration:duration
                          delay:delay
         usingSpringWithDamping:SPRING_DAMPING_DEFAULT
          initialSpringVelocity:INITIAL_VELOCITY_DEFAULT
                        options:0
                     animations:^{
                         view.center = centerPointFinal;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             if (nil != completionBlock) {
                                 completionBlock();
                             }
                         }
                     }];
}

- (void)resizeView:(UIView *)view withNewBounds:(CGRect)newBounds withDuration:(CGFloat)duration andFinalAlpha:(CGFloat)finalAlpha afterDelay:(CGFloat)delay withCompletionBlock:(void (^)())completionBlock {
    [UIView animateWithDuration:duration
                          delay:delay
         usingSpringWithDamping:SPRING_DAMPING_DEFAULT / 1.4f
          initialSpringVelocity:INITIAL_VELOCITY_DEFAULT
                        options:0
                     animations:^{
                         view.bounds = newBounds;
                         view.alpha = finalAlpha;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             if (nil != completionBlock) {
                                 completionBlock();
                             }
                         }
                     }];
}

- (CGFloat)centerPointXOffscreenLeftForView:(UIView *)view {
    return 0 - CGRectGetWidth(view.bounds)/2.0f;
}

- (CGFloat)centerPointXOffscreenRightForView:(UIView *)view {
    return self.width + CGRectGetWidth(view.bounds)/2.0f;
}

- (CGFloat)centerPointYOffscreenTopForView:(UIView *)view {
    return 0 - CGRectGetHeight(view.bounds)/2.0f;
}

- (CGFloat)centerPointYOffscreenBottomForView:(UIView *)view {
    return self.height + CGRectGetHeight(view.bounds)/2.0f;
}

- (CGFloat)width {
    return CGRectGetWidth(self.bounds);
}

- (CGFloat)height {
    return CGRectGetHeight(self.bounds);
}

- (CGFloat)aspectRatioScaleOffset {
    // Used for the phones that have an aspect ratio other than 16:9 (looking at you, 4s users)
    static const CGFloat AR169 = 16.0f/9.0f;
    
    CGFloat AR = self.height/self.width; // Remember, we're viewing in portrait mode
    CGFloat scaleOffsetRet = 1.0f;
    
    if (ABS(AR - AR169) > .05f) { // If the difference in AR is large enough, return a non-unity scale
        scaleOffsetRet = AR/AR169;
    }
    
    return scaleOffsetRet;
}

- (void)createTextLabels {
    // fontSize = = 10.62ln(x) - 52.883, where x is SQRT(width^2 + height^2) - from Excel
    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGFloat screenWidthPixels = self.width * screenScale;
    CGFloat screenHeightPixels = self.height * screenScale;
    CGFloat fontSize = 10.62 * log(sqrt(screenWidthPixels * screenWidthPixels + screenHeightPixels * screenHeightPixels)) - 52.883;
    
    // Text attributes
    NSDictionary *defaultTextAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:fontSize],
                                             NSForegroundColorAttributeName : [UIColor whiteColor] };
    UIFont *fontBold = [UIFont fontWithName:@"OpenSans-Bold" size:fontSize];
    
    // Screen 1
    _lblScreen1 = [[UILabel alloc] init];
    _lblScreen1.numberOfLines = 3;
    _lblScreen1.textAlignment = NSTextAlignmentLeft;
    NSMutableAttributedString *strS1Text = [[NSMutableAttributedString alloc] initWithString:@"Share a moment with\nyour community" attributes:defaultTextAttributes];
    [strS1Text addAttribute:NSFontAttributeName value:fontBold range:[strS1Text.string rangeOfString:@"moment"]];
    _lblScreen1.attributedText = strS1Text;
    
    // Screen 2
    _lblScreen2 = [[UILabel alloc] init];
    _lblScreen2.numberOfLines = 3;
    _lblScreen2.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *strS2Text = [[NSMutableAttributedString alloc] initWithString:@"See what's happening\naround you and meet\ncool new people" attributes:defaultTextAttributes];
    [strS2Text addAttribute:NSFontAttributeName value:fontBold range:[strS2Text.string rangeOfString:@"happening\naround you"]];
    _lblScreen2.attributedText = strS2Text;
    
    // Screen 3
    _lblScreen3 = [[UILabel alloc] init];
    _lblScreen3.numberOfLines = 2;
    _lblScreen3.textAlignment = NSTextAlignmentLeft;
    NSMutableAttributedString *strS3Text = [[NSMutableAttributedString alloc] initWithString:@"Build your reputation\nand become a local star" attributes:defaultTextAttributes];
    [strS3Text addAttribute:NSFontAttributeName value:fontBold range:[strS3Text.string rangeOfString:@"reputation"]];
    [strS3Text addAttribute:NSFontAttributeName value:fontBold range:[strS3Text.string rangeOfString:@"local star"]];
    _lblScreen3.attributedText = strS3Text;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self createTextLabels];
}

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // Init properties
    self.clipsToBounds = YES;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor colorWithRGBHex:0x4cb0fb];
    _ivBackground = [[UIImageView alloc] init];
    _ivBackground.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:_ivBackground];
    
    [self createTextLabels];
    
    // Screen 1
    _imageS1Bg = [UIImage imageNamed:@"Slide-1-bg"];
    _ivS1Phone = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Slide-1-iphone"]];
    _ivShareButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Slide-1-share-btn"]];
    _ivS1Graphic = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Slide-1-graphic"]];
    
    // Screen 2
    _imageS2Bg = [UIImage imageNamed:@"Slide-2-bg"];
    _ivS2Phone = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slide-2-iphone"]];
    _ivS2Graphic1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Slide-2-graphic-1"]];
    _ivS2Graphic2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Slide-2-graphic-2"]];

    // Screen 3
    _imageS3Bg = [UIImage imageNamed:@"Slide-3-bg"];
    _ivS3Phone = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Slide-3-iphone"]];
    _ivS3Graphic = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Slide-3-graphic-1"]];
    _ivStar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Slide-3-star"]];
    
    _screenState = ScreenStateUnknown;
}

@end
