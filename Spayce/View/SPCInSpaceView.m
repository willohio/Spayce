//
//  SPCInSpaceView.m
//  Spayce
//
//  Created by Christopher Taylor on 9/30/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCInSpaceView.h"
#import "SPCSpaceMan.h"
#import "SPCStarsView.h"
#import "LocationManager.h"

static CGFloat COMPASS_WAGGLE = M_PI / 48;
static CGFloat COMPASS_WAGGLE_TIME = 1.2;
static CGFloat COMPASS_SPIN_PROBABILITY = 0.2;

@interface SPCInSpaceView ()

@property (nonatomic, assign) BOOL showTabBar;
@property (nonatomic, strong) SPCSpaceMan *spaceMan;
@property (nonatomic, strong) SPCStarsView *stars;
@property (nonatomic, strong) UILabel *msgLabel;
@property (nonatomic, assign) BOOL animationStarted;
@property (nonatomic, assign) BOOL animationComplete;
@property (nonatomic, assign) BOOL animationPausedForTouch;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIButton *locationBtn;
@property (nonatomic, strong) UIImageView *iconImgView;
@property (nonatomic, strong) UIImageView *logoImgView;

@property (nonatomic, assign) BOOL venueCompassAnimating;
@property (nonatomic, assign) BOOL venueCompassHasSpunThisAnimation;
@property (nonatomic, strong) UIImageView *venueCompassArrowImageView;

@end

@implementation SPCInSpaceView

-(void)dealloc {
    [self stopAnimation];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)initWithFrame:(CGRect)frame showTabBar:(BOOL)showTabBar {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.showTabBar = showTabBar;
        
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.stars];
        
        
        [self addSubview:self.msgLabel];
        [self addSubview:self.iconImgView];
        [self addSubview:self.venueCompassArrowImageView];
        [self addSubview:self.locationBtn];
        [self addSubview:self.spaceMan];
        
        
        [self addSubview:self.logoImgView];
        
        // Initialize the progress view
        self.spinnerView = [[LLARingSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        self.spinnerView.lineWidth = 3.0f;
        self.spinnerView.hidesWhenStopped = YES;
        self.spinnerView.tintColor = [UIColor whiteColor];
        self.spinnerView.hidden = YES;
        [self addSubview:self.spinnerView];
        
       
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidChangeStatusBarFrameNotification object:nil];
        
        [self restartAnimation];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame showTabBar:YES];
}

-(UIImageView *)logoImgView {
    if (!_logoImgView) {
        CGFloat logoHeight = (CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) + 45)/2 ;
        _logoImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spayce-logo-title"]];
        _logoImgView.backgroundColor = [UIColor clearColor];
        _logoImgView.contentMode = UIViewContentModeCenter;
        _logoImgView.frame = CGRectMake(CGRectGetMidX(self.frame) - 75.0, logoHeight, 150.0, _logoImgView.frame.size.height);
    }
    return _logoImgView;
}

-(SPCStarsView *)stars {
    if (!_stars) {
        _stars = [[SPCStarsView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, [[UIScreen mainScreen] bounds].size.height - (self.showTabBar ? 45 : 0))];
        [_stars prepAnimation];
        [_stars startAnimation];
    }
    return _stars;
}

-(SPCSpaceMan *)spaceMan {
    if (!_spaceMan) {
        _spaceMan = [[SPCSpaceMan alloc] initWithFrame:CGRectMake(100, 100, 50, 70)];
        _spaceMan.image = [UIImage imageNamed:@"spaceman"];;
        _spaceMan.position = CGPointMake(250.0, self.frame.size.height - 1);
        _spaceMan.velocity = CGPointMake(0.0, -1.0);
        _spaceMan.baseVelocity = _spaceMan.velocity;
        _spaceMan.radius = 24.0;
        _spaceMan.maxWidth = self.frame.size.width;
        _spaceMan.maxHeight = self.frame.size.height;
        _spaceMan.userInteractionEnabled = YES;
        
    }
    return _spaceMan;
}

- (UILabel *)msgLabel {
    if (!_msgLabel) {
        _msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,self.frame.size.height/2 - 45, self.frame.size.width-20, 40)];
        _msgLabel.backgroundColor = [UIColor clearColor];
        _msgLabel.text = @"Refreshing Your Location..";
        _msgLabel.font = [UIFont spc_boldSystemFontOfSize:14];
        _msgLabel.textColor = [UIColor whiteColor];
        _msgLabel.numberOfLines = 0;
        _msgLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _msgLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _msgLabel;
}

- (UIButton *)locationBtn {
    if (!_locationBtn) {
        _locationBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.bounds.size.width - 200)/2, CGRectGetMaxY(_msgLabel.frame)+20, 200, 40)];
        [_locationBtn setBackgroundColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f]];
        _locationBtn.layer.cornerRadius = 2;
        [_locationBtn setTitle:@"Turn on Location" forState:UIControlStateNormal];
        _locationBtn.titleLabel.font = [UIFont spc_boldSystemFontOfSize:14];
        [_locationBtn addTarget:self action:@selector(showLocationAlert:) forControlEvents:UIControlEventTouchDown];
    }
    return _locationBtn;
}

-(UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"location-off-icon"]];
        _iconImgView.contentMode = UIViewContentModeCenter;
        _iconImgView.center = CGPointMake(self.frame.size.width/2,CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 - 10);
    }
    return _iconImgView;
}

-(UIImageView *)venueCompassArrowImageView {
    if (!_venueCompassArrowImageView) {
        _venueCompassArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"new-compass-arrow"]];
        _venueCompassArrowImageView.center = CGPointMake(self.frame.size.width/2,CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 - 10);
    }
    return _venueCompassArrowImageView;
}

-(void)animateSpaceMan {
    if (!self.animationComplete) {
        [self.spaceMan update];
    }
    if (!self.animationPausedForTouch) {
        self.spaceMan.center = self.spaceMan.position;
    }
}


#pragma mark - Actions

- (void)promptForFix {
    self.spaceMan.alpha = 0;
    self.msgLabel.text = @"Refreshing location...";  //FINDING
    self.msgLabel.font = [UIFont spc_boldSystemFontOfSize:14];
    self.locationBtn.hidden = YES;
    self.iconImgView.hidden = YES;
    self.venueCompassArrowImageView.hidden = YES;
    self.stars.hidden = YES;
    self.backgroundColor = [UIColor colorWithRed:77.0f/255.0f green:99.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    [self updateCentering];
    [self.spinnerView startAnimating];

}

- (void)promptForOptimizing {
    self.spaceMan.alpha = 0;
    self.msgLabel.text = @"Refreshing location...";
    self.msgLabel.font = [UIFont spc_boldSystemFontOfSize:14];
    self.locationBtn.hidden = YES;
    self.venueCompassArrowImageView.hidden = YES;
    self.iconImgView.hidden = YES;
    self.stars.hidden = YES;
    self.backgroundColor = [UIColor colorWithRed:77.0f/255.0f green:99.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    [self updateCentering];
    [self.spinnerView startAnimating];
    
}

- (void)promptForLocation {
    self.spaceMan.alpha = 1;
    self.msgLabel.text = @"Spayce needs location to show you\nthe great memories around you.";
    self.msgLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    self.locationBtn.hidden = NO;
    self.iconImgView.image = [UIImage imageNamed:@"location-off-icon"];
    self.venueCompassArrowImageView.hidden = YES;
    
    self.msgLabel.frame = CGRectMake(10,self.frame.size.height/2 - 45, self.frame.size.width-20, 40);
    self.iconImgView.center = CGPointMake(self.frame.size.width/2,CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 - 10);
    self.venueCompassArrowImageView.center = CGPointMake(self.frame.size.width/2,CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 - 10);
    [self.spinnerView stopAnimating];
}


- (void)promptForLocationFromSpayce {
    NSLog(@"prompt for loc from spayce");
    self.msgLabel.text = @"Spayce needs location to show you\nthe great memories around you.";
    self.msgLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
    self.locationBtn.hidden = NO;
    self.iconImgView.hidden = YES;
    self.venueCompassArrowImageView.hidden = YES;
    self.spaceMan.alpha = 0;
    self.stars.hidden = YES;
    self.backgroundColor = [UIColor colorWithRed:77.0f/255.0f green:99.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    
    self.msgLabel.frame = CGRectMake(10,self.frame.size.height/6, self.frame.size.width-20, 40);
    self.locationBtn.center = CGPointMake(self.bounds.size.width/2, self.msgLabel.center.y + 60);
    [self.spinnerView stopAnimating];
}

- (void)promptForMemory {
    self.spaceMan.alpha = 1;
    self.backgroundColor = [UIColor clearColor];
    self.stars.hidden = NO;
    self.msgLabel.text = @"Spayce needs location to anchor\nyour memories to places.";
    self.msgLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    self.locationBtn.hidden = NO;
    self.iconImgView.image = [UIImage imageNamed:@"location-off-icon"];
    self.venueCompassArrowImageView.hidden = YES;
}
- (void)promptForTrending {
    self.spaceMan.alpha = 1;
    self.msgLabel.text = @"Spayce needs location to show\nyou the memories trending locally.";
    self.backgroundColor = [UIColor clearColor];
    self.stars.hidden = NO;
    self.msgLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    self.locationBtn.hidden = NO;
    self.iconImgView.image = [UIImage imageNamed:@"location-off-icon"];
    self.venueCompassArrowImageView.hidden = YES;
    self.logoImgView.hidden = YES;
}
- (void)promptForMAMRefresh {
    self.spaceMan.alpha = 0;
    self.msgLabel.text = @"Optimizing Your Location...";
    self.msgLabel.font = [UIFont spc_boldSystemFontOfSize:14];
    self.locationBtn.hidden = YES;
    self.logoImgView.hidden = YES;
    self.iconImgView.image = [UIImage imageNamed:@"new-compass-icon"];
    self.venueCompassArrowImageView.hidden = NO;
    [self startCompassAnimation];
    
    [self updateCentering];
}

-(void)promptForSwipe {
    self.msgLabel.textColor =[UIColor colorWithWhite:1 alpha:1];
    self.msgLabel.text = @"Done! Swipe to start!";
    self.locationBtn.hidden = YES;
    self.logoImgView.hidden = YES;
    self.iconImgView.hidden = NO;
    self.iconImgView.image = [UIImage imageNamed:@"swipe-arrow"];
    self.iconImgView.center = CGPointMake(self.iconImgView.center.x, CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 + 5);
    self.venueCompassArrowImageView.hidden = YES;
    [self.spinnerView stopAnimating];
}

- (void)promptForData {
    [self promptForOptimizing];
}



#pragma mark - Properties

-(void)setHidden:(BOOL)hidden {
    BOOL changed = self.isHidden != hidden;
    
    [super setHidden:hidden];
    if (changed) {
        if (!hidden) {
            [self restartAnimation];
        } else {
            [self performSelector:@selector(stopAnimationIfHidden) withObject:nil afterDelay:0.5f];
        }
    }
}


#pragma mark - Animations

// master controls

-(void)restartAnimation {
    [self stopAnimation];
    if (!self.isHidden) {
        [self startAnimation];
    }
}

-(void)startAnimation {
    if (!self.animationStarted) {
        self.animationStarted = YES;
        self.animationComplete = NO;
        [self startSpaceManAnimation];
        [self.stars startAnimation];
        if (!self.venueCompassArrowImageView.hidden) {
            [self startCompassAnimation];
        }
    }
}
-(void)stopAnimation {
    if (self.animationStarted) {
        self.animationStarted = NO;
        self.animationComplete = YES;
        [self.stars stopAnimation];
        [self stopSpaceManAnimation];
        [self stopCompassAnimation];
    }
}
-(void)stopAnimationIfHidden {
    if (self.isHidden) {
        [self stopAnimation];
    }
}

// spaceman animations
- (void)startSpaceManAnimation {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(animateSpaceMan)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopSpaceManAnimation {
    [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.displayLink invalidate];
}

- (void)fadeDownSpaceMan {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.1];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    self.spaceMan.alpha = 0;
    [UIView commitAnimations];
}

- (void)updateCentering {
    self.msgLabel.frame = CGRectMake(10,self.frame.size.height/2, self.frame.size.width-20, 40);
    self.iconImgView.center = CGPointMake(self.frame.size.width/2,CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 - 10);
    self.venueCompassArrowImageView.center = CGPointMake(self.frame.size.width/2,CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 - 10);
}

- (void)spayceCentering {
    self.msgLabel.textColor =[UIColor colorWithWhite:1 alpha:.4];
    self.logoImgView.hidden = YES;
    self.msgLabel.frame = CGRectMake(10,self.frame.size.height/4, self.frame.size.width-20, 40);
    self.iconImgView.center = CGPointMake(self.frame.size.width/2,CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 - 10);
    self.venueCompassArrowImageView.center = CGPointMake(self.frame.size.width/2,CGRectGetMinY(_msgLabel.frame) - _iconImgView.image.size.height/2 - 10);
    self.spinnerView.center = CGPointMake(self.msgLabel.center.x, self.msgLabel.center.y - 40);
}

// compass animations
- (void)startCompassAnimation {
    if (_venueCompassArrowImageView && !self.venueCompassAnimating) {
        // start a looping animation; tweak side-to-side, spin, etc.
        self.venueCompassAnimating = YES;
        self.venueCompassHasSpunThisAnimation = NO;
        _venueCompassArrowImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -COMPASS_WAGGLE);
        [self animateCompassWaggleForward];
    }
}

- (void)stopCompassAnimation {
    if (self.venueCompassAnimating) {
        [_venueCompassArrowImageView.layer removeAllAnimations];
        _venueCompassArrowImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -COMPASS_WAGGLE);
        
        self.venueCompassAnimating = NO;
    }
}

- (void)animateCompassWaggleForward {
    if (!_venueCompassArrowImageView.hidden) {
        //NSLog(@"animating forward");
        [UIView animateWithDuration:COMPASS_WAGGLE_TIME delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGAffineTransform rotateTransform = CGAffineTransformRotate(_venueCompassArrowImageView.transform, COMPASS_WAGGLE*2);
            _venueCompassArrowImageView.transform = rotateTransform;
        } completion:^(BOOL finished) {
            if (finished) {
                CGFloat random = ((CGFloat)rand()) / RAND_MAX;
                if (random < COMPASS_SPIN_PROBABILITY || !self.venueCompassHasSpunThisAnimation) {
                    [self animateCompassSpin];
                } else {
                    [self animateCompassWaggleBack];
                }
            }
        }];
    } else {
        self.venueCompassAnimating = NO;
        _venueCompassArrowImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -COMPASS_WAGGLE);
    }
}

- (void)animateCompassWaggleBack {
    if (!_venueCompassArrowImageView.hidden) {
        //NSLog(@"animating back");
        [UIView animateWithDuration:COMPASS_WAGGLE_TIME delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGAffineTransform rotateTransform = CGAffineTransformRotate(_venueCompassArrowImageView.transform, -COMPASS_WAGGLE*2);
            _venueCompassArrowImageView.transform = rotateTransform;
        } completion:^(BOOL finished) {
            if (finished) {
                [self animateCompassWaggleForward];
            }
        }];
    } else {
        self.venueCompassAnimating = NO;
        _venueCompassArrowImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -COMPASS_WAGGLE);
    }
}

// starting from a 'forward' position...
- (void)animateCompassSpin {
    self.venueCompassHasSpunThisAnimation = YES;
    [self animateCompassSpinStep:0];
}

- (void)animateCompassSpinStep:(NSInteger)step {
    if (!_venueCompassArrowImageView.hidden) {
        switch (step) {
            case 0: {
                // back up further to get ready for the spin
                [UIView animateWithDuration:0.7 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    CGAffineTransform rotateTransform = CGAffineTransformRotate(_venueCompassArrowImageView.transform, -COMPASS_WAGGLE*5);
                    _venueCompassArrowImageView.transform = rotateTransform;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self animateCompassSpinStep:step+1];
                    }
                }];
                break;
            }
                
            case 1:
            case 2:
            case 3:
            case 4: {
                // 4 part spin.  The first is EaseIn, the rest linear.
                int options = (step == 1) ? UIViewAnimationOptionCurveEaseIn : UIViewAnimationOptionCurveLinear;
                [UIView animateWithDuration:0.15 delay:0 options:options animations:^{
                    CGAffineTransform rotateTransform = CGAffineTransformRotate(_venueCompassArrowImageView.transform, M_PI/2);
                    _venueCompassArrowImageView.transform = rotateTransform;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self animateCompassSpinStep:step+1];
                    }
                }];
                break;
            }
                
            case 5: {
                // spin recovery.  We have done a complete rotation, and are now at -WAGGLE*4.
                // ease out to get to WAGGLE + M_PI / 6
                [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    CGAffineTransform rotateTransform = CGAffineTransformRotate(_venueCompassArrowImageView.transform, COMPASS_WAGGLE*5 + M_PI / 6);
                    _venueCompassArrowImageView.transform = rotateTransform;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self animateCompassSpinStep:step+1];
                    }
                }];
                break;
            }
                
            case 6: {
                // final spin recovery.  Return to resting at -WAGGLE.
                [UIView animateWithDuration:0.9 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    CGAffineTransform rotateTransform = CGAffineTransformRotate(_venueCompassArrowImageView.transform, -COMPASS_WAGGLE*2 - M_PI / 6);
                    _venueCompassArrowImageView.transform = rotateTransform;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self animateCompassSpinStep:step+1];
                    }
                }];
                break;
            }
                
            default: {
                // we're back to normal: waggle forward.
                [self animateCompassWaggleForward];
                break;
            }
        }
    } else {
        self.venueCompassAnimating = NO;
        _venueCompassArrowImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -COMPASS_WAGGLE);
    }
}


#pragma mark - Alerts

-(void)showLocationAlert:(id)sender {

    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
       
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServicesAuthorizationStatusWillChangeNotification object:nil];
        [[LocationManager sharedInstance] enableLocationServicesWithCompletionHandler:^(NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServicesAuthorizationStatusDidChangeNotification object:nil];
        }];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services for the \"Spayce\" app", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

#pragma mark - Handle Touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    
    if (touch.view == self.spaceMan) {
        self.animationPausedForTouch = YES;
        CGPoint currTouchPoint = [touch locationInView:self];
        self.spaceMan.position = currTouchPoint;
        self.spaceMan.center = self.spaceMan.position;
        startPoint = currTouchPoint;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if (touch.view == self.spaceMan) {
        CGPoint currTouchPoint = [touch locationInView:self];
        self.spaceMan.position = currTouchPoint;
        self.spaceMan.center = self.spaceMan.position;
        prevPoint = currTouchPoint;
 
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.animationPausedForTouch = NO;
    UITouch *touch = [touches anyObject];
    
    if (touch.view == self.spaceMan) {
        CGPoint currTouchPoint = [touch locationInView:self];
        
        float newVelX;
        float baseVelX;
        
        // -- user dragged to the right
        
        if (currTouchPoint.x > prevPoint.x) {
            NSLog(@"right");
            newVelX = fabsf(self.spaceMan.velocity.x);
            baseVelX = fabsf(self.spaceMan.baseVelocity.x);
            
            if (fabsf((currTouchPoint.x - startPoint.x)) > 20) {
                NSLog(@"soft right");
                newVelX = newVelX + 10;
            }
            
            //add extra velocity if we moved a lot
            if (fabsf((currTouchPoint.x - startPoint.x)) > 100) {
                NSLog(@"hard right");
                newVelX = newVelX + 20;
            }
        }
        
        // -- user dragged to the left
        if (currTouchPoint.x < prevPoint.x)  {
            newVelX = -1 * fabsf(self.spaceMan.velocity.x);
            baseVelX = -1 * fabsf(self.spaceMan.baseVelocity.x);
            NSLog(@"left");
            //add extra velocity if we moved a lot
         
            if (fabsf((currTouchPoint.x - startPoint.x)) > 20) {
                NSLog(@"soft left");
                newVelX = newVelX - 10;
            }
            
            if (fabsf((currTouchPoint.x - startPoint.x)) > 100) {
                NSLog(@"hard left");
                newVelX = newVelX - 20;
            }
        }
        
        
        float newVelY;
        float baseVelY;
        
        // -- user dragged down
        if (currTouchPoint.y > prevPoint.y) {
            newVelY = fabsf(self.spaceMan.velocity.y);
            baseVelY = fabsf(self.spaceMan.baseVelocity.y);
            NSLog(@"down");
            
            //add velocity if we moved
            if (fabsf((currTouchPoint.y - startPoint.y)) > 50) {
                NSLog(@"soft down");
                newVelY = newVelY + 10;
            }
            
            //add extra velocity if we moved a lot
            if (fabsf((currTouchPoint.y - startPoint.y)) > 100) {
                NSLog(@"hard down");
                newVelY = newVelY + 30;
            }
        }
        
        // -- user dragged up
        if (currTouchPoint.y < prevPoint.y) {
           NSLog(@"up");
            newVelY = -1 * fabsf(self.spaceMan.velocity.y);
            baseVelY = -1 * fabsf(self.spaceMan.baseVelocity.y);
            
            //add velocity if we moved
            if (fabsf((currTouchPoint.y - startPoint.y)) > 50) {
                NSLog(@"soft down");
                newVelY = newVelY - 10;
            }
            
            //add extra velocity if we moved a lot
            if (fabsf((currTouchPoint.y - startPoint.y)) > 100) {
               NSLog(@"hard up");
                newVelY = newVelY - 30;
            }
        }
     
        self.spaceMan.baseVelocity = CGPointMake(baseVelX, baseVelY);
        self.spaceMan.velocity = CGPointMake(newVelX, newVelY);
    }
}

-(void)applicationDidBecomeActive:(id)sender {
    //self.venueCompassAnimating = NO;
    //[self.stars startAnimation];
    [self restartAnimation];
}


@end
