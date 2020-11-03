//
//  SPCPullToRefreshView.m
//  Spayce
//
//  Created by Jake Rosin on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCPullToRefreshView.h"

#define FIXED_HEIGHT 102
#define VIEW_HEIGHT 600
#define CONTENT_HEIGHT 82

#define ROCKET_BOTTOM_MARGIN 19
#define SCAFFOLD_BOTTOM_MARGIN 21.5
#define PLANET_BOTTOM_MARGIN 220

/* Note for @JR - when simulating load, all the planets were visbiile on screen, but 1 & 2 are set to a delay before animating, which is why they appeared frozen.  I moved them just off screen.  CT
   Note from @JR - I'm removing simulated loads.  Our real loads are long enough that we don't need to deliberately provoke issue reports.
*/
@interface SPCPullToRefreshView()

/*
 * Current state of the control.
 */
@property (nonatomic, readwrite, assign) MNMPullToRefreshViewState state;

/*
 * The number of pixels within this view that have been dragged into the containing
 * scroll view.  Is equal to -1 times the scroll view's current offset (e.g.
 * while pulling-to-refresh, this value is positive).
 */
@property (nonatomic, readwrite, assign) CGFloat offset;


/*
 * VIEWS
 */
@property (nonatomic, strong) UIImageView *rocketStationary;

@property (nonatomic, strong) UIImageView *rocketScaffold;

@property (nonatomic, strong) UIImageView *rocketFlying;

@property (nonatomic, strong) UIImageView *planets0;
@property (nonatomic, strong) UIImageView *planets1;
@property (nonatomic, strong) UIImageView *planets2;

@end

@implementation SPCPullToRefreshView

- (id)init
{
    self = [super initWithFixedHeight:FIXED_HEIGHT frameHeight:VIEW_HEIGHT contentHeight:CONTENT_HEIGHT];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
        
        // rockets!
        UIImage * rocketStationaryImage = [UIImage imageNamed:@"animation-rocket-small-0"];
        self.rocketStationary = [[UIImageView alloc] initWithImage:rocketStationaryImage];
        self.rocketFlying = [[UIImageView alloc] initWithImage:rocketStationaryImage];
        self.rocketFlying.animationImages = @[
                [UIImage imageNamed:@"animation-rocket-small-1"],
                [UIImage imageNamed:@"animation-rocket-small-2"],
                [UIImage imageNamed:@"animation-rocket-small-3"],
                [UIImage imageNamed:@"animation-rocket-small-4"],
                [UIImage imageNamed:@"animation-rocket-small-5"]
        ];
        self.rocketFlying.animationDuration = 0.5f;
        
        UIImage * rocketScaffoldImage = [UIImage imageNamed:@"launch-pad"];
        self.rocketScaffold = [[UIImageView alloc] initWithImage:rocketScaffoldImage];
        
        UIImage * planetsImage = [UIImage imageNamed:@"planets"];
        self.planets0 = [[UIImageView alloc] initWithImage:planetsImage];
        self.planets1 = [[UIImageView alloc] initWithImage:planetsImage];
        self.planets2 = [[UIImageView alloc] initWithImage:planetsImage];
        
        [self addSubview:self.rocketFlying];
        [self addSubview:self.rocketStationary];
        [self addSubview:self.rocketScaffold];
        
        [self addSubview:self.planets0];
        [self addSubview:self.planets1];
        [self addSubview:self.planets2];

        _state = MNMPullToRefreshViewStateUnset;
        
        self.clipsToBounds = YES;
    }
    return self;
}

-(void)setIsInTable:(BOOL)isInTable {
    [super setIsInTable:isInTable];
    if (self.isInTable) {
        self.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

/*
 * Lays out subviews.
 */
- (void)layoutSubviews {
    // position rocket.  The rocket is pulled down with the view,
    // but reaches a fixed position at its resting place at an
    // offset of FIXED_HEIGHT
    
    CGFloat rocketMargin = ROCKET_BOTTOM_MARGIN;
    if (self.state != MNMPullToRefreshViewStateLoadingRetract) {
        if (self.offset > FIXED_HEIGHT && self.isInTable) {
            rocketMargin += (self.offset - FIXED_HEIGHT);
        }
    }
    
    self.rocketStationary.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds) - CGRectGetHeight(self.rocketStationary.bounds)/2 - rocketMargin + self.flyingRocketAdjustment);
    self.rocketFlying.center = self.rocketStationary.center;
    
    // scaffold position.  The scaffold is stationary; never pulled down.
    CGFloat scaffoldMargin = SCAFFOLD_BOTTOM_MARGIN;
    scaffoldMargin += (self.offset - FIXED_HEIGHT);
    self.rocketScaffold.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds) - CGRectGetHeight(self.rocketScaffold.bounds)/2 - scaffoldMargin);
    
    
    // The "resting position" of the planets is well above the rocket:
    // PLANET_BOTTOM_MARGIN from the bottom.  However, our offset behavior
    // is different: whereas we sometimes want the rocket to appear stationary
    // relative to view offsets, we ALWAYS want the planets to appear that way.
    CGFloat planetHeight = CGRectGetHeight(self.planets0.frame);
    self.planets0.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds) - planetHeight*0.5 - PLANET_BOTTOM_MARGIN);
    self.planets1.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds) - planetHeight*0.5 - PLANET_BOTTOM_MARGIN);
    self.planets2.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds) - planetHeight*0.5 - PLANET_BOTTOM_MARGIN);
}


- (void)hideContentUntilStateChange {
    self.rocketFlying.hidden = YES;
    self.rocketScaffold.hidden = YES;
    self.rocketStationary.hidden = YES;
    self.planets0.hidden = YES;
    self.planets1.hidden = YES;
    self.planets2.hidden = YES;
}


- (void)changeOffset:(CGFloat)offset {
    [self changeStateOfControl:_state withOffset:offset];
}

/*
 * Changes the state of the control depending in state and offset values
 */
- (void)changeStateOfControl:(MNMPullToRefreshViewState)state withOffset:(CGFloat)offset {
    
    BOOL stateChange = state != _state;
    
    _state = state;
    _offset = -offset;
    
    //NSLog(@"changeStateOfControl for %d with state %d, offset %f", (NSInteger)self, _state, _offset);
    
    CGFloat height = self.frameHeight;
    CGFloat yOrigin = -self.frameHeight;
    
    if (stateChange) {
        switch (_state) {
                
            case MNMPullToRefreshViewStateIdle: {
                // Hide planets.  Hide scaffold.
                self.rocketScaffold.hidden = YES;
                [self stopPlanetAnimation];
                
                // Empty?  Flying rocket?  Non-flying?
                self.rocketStationary.hidden = NO;
                [self.rocketFlying stopAnimating];
                self.rocketFlying.hidden = YES;
                
                // Configure frame...
                if (self.isInTable) {
                    CGRect frame = [self frame];
                    frame.size.height = height;
                    frame.origin.y = yOrigin;
                    [self setFrame:frame];
                }
                
                break;
                
            } case MNMPullToRefreshViewStatePull: {
                
                // No planets
                self.planets0.hidden = YES;
                self.planets1.hidden = YES;
                self.planets2.hidden = YES;
                
                // Non-flying rocket.  Set scaffolding offset.
                self.rocketStationary.hidden = NO;
                self.rocketFlying.hidden = YES;
                self.rocketScaffold.hidden = NO;
                
                break;
                
            } case MNMPullToRefreshViewStateRelease: {
                
                // No planets
                self.planets0.hidden = YES;
                self.planets1.hidden = YES;
                self.planets2.hidden = YES;
                
                // Pulled past the point where loading would be triggered.
                self.rocketStationary.hidden = NO;
                self.rocketFlying.hidden = YES;
                self.rocketScaffold.hidden = NO;
                
                break;
                
            } case MNMPullToRefreshViewStateLoading: {
                
                if (self.isInTable) {
                    // Show planet against the background, but hide everything else.
                    [self startPlanetAnimation];
                    
                    self.rocketStationary.hidden = YES;
                    self.rocketFlying.hidden = YES;
                    [self.rocketFlying startAnimating];
                    self.rocketScaffold.hidden = YES;
                } else {
                    // No planets
                    self.planets0.hidden = YES;
                    self.planets1.hidden = YES;
                    self.planets2.hidden = YES;
                    
                    // Reveal flying rocket
                    self.rocketStationary.hidden = YES;
                    self.rocketFlying.hidden = NO;
                    [self.rocketFlying startAnimating];
                    self.rocketScaffold.hidden = YES;
                }
                
                break;
                
            } case MNMPullToRefreshViewStateLoadingRetract: {
                
                // Show flying rocket
                self.rocketStationary.hidden = YES;
                self.rocketFlying.hidden = NO;
                self.rocketScaffold.hidden = YES;
                
                // Show planets...?
                if (self.isInTable) {
                    self.planets0.hidden = YES;
                    self.planets1.hidden = YES;
                    self.planets2.hidden = YES;
                }
                
                break;
            }
            
            default:
                break;
        }
    }
    
    [self setNeedsLayout];
}

-(void)startPlanetAnimation {
    // planets begin at 0 alpha, and fade in quickly
    // (if the user significantly over-pulls the view, we
    // don't want the planets to suddenly appear)
    self.planets0.alpha = 0;
    self.planets1.alpha = 0;
    self.planets2.alpha = 0;
    
    self.planets0.hidden = NO;
    self.planets1.hidden = NO;
    self.planets2.hidden = NO;
    
    self.planets0.transform = CGAffineTransformIdentity;
    self.planets1.transform = CGAffineTransformIdentity;
    self.planets2.transform = CGAffineTransformIdentity;
    
    // Animate them into existence...
    [UIView animateWithDuration:0.1f delay:0.5f options:0 animations:^{
        self.planets0.alpha = 1.0f;
        self.planets1.alpha = 1.0f;
        self.planets2.alpha = 1.0f;
    } completion:^(BOOL finished) {
        if (_state == MNMPullToRefreshViewStateLoading || _state == MNMPullToRefreshViewStateLoadingRetract) {
            [self startPlanetAnimationTranslation];
        }
    }];
}

-(void)startPlanetAnimationTranslation {
    // animation speed is 10 pixels per 100 ms, or 100 / second
    NSTimeInterval seconds = CGRectGetHeight(self.planets0.frame) / 100.0f;
    // planets 0, the lowest planet, travels 3 times its height before
    // reset.  planets 1 travels 4 times its height, etc.
    [UIView animateWithDuration:seconds*3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.planets0.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.planets0.frame)*3);
    } completion:^(BOOL finished) {
        if (_state == MNMPullToRefreshViewStateLoading || _state == MNMPullToRefreshViewStateLoadingRetract) {
            [self loopPlanetAnimation:self.planets0];
        }
    }];
    
    [UIView animateWithDuration:seconds*3 delay:seconds options:UIViewAnimationOptionCurveLinear animations:^{
        self.planets1.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.planets1.frame)*3);
    } completion:^(BOOL finished) {
        if (_state == MNMPullToRefreshViewStateLoading || _state == MNMPullToRefreshViewStateLoadingRetract) {
            [self loopPlanetAnimation:self.planets1];
        }
    }];
    
    [UIView animateWithDuration:seconds*3 delay:seconds*2 options:UIViewAnimationOptionCurveLinear animations:^{
        self.planets2.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.planets2.frame)*3);
    } completion:^(BOOL finished) {
        if (_state == MNMPullToRefreshViewStateLoading || _state == MNMPullToRefreshViewStateLoadingRetract) {
            [self loopPlanetAnimation:self.planets2];
        }
    }];
    
    
}

-(void)loopPlanetAnimation:(UIView *)planetView {
    // translate its current transform 3 times its height upwards, then
    // animate back to its current transform.
    CGAffineTransform originalTransform = planetView.transform;
    CGAffineTransform startingTransform = CGAffineTransformIdentity;
    planetView.transform = startingTransform;
    NSTimeInterval seconds = CGRectGetHeight(self.planets0.frame) / 100.0f;
    [UIView animateWithDuration:seconds*3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        planetView.transform = originalTransform;
    } completion:^(BOOL finished) {
        if (_state == MNMPullToRefreshViewStateLoading || _state == MNMPullToRefreshViewStateLoadingRetract) {
            [self loopPlanetAnimation:planetView];
        }
    }];
}

-(void)stopPlanetAnimation {
    [CATransaction begin];
    [self.planets0.layer removeAllAnimations];
    [self.planets1.layer removeAllAnimations];
    [self.planets2.layer removeAllAnimations];
    [CATransaction commit];
    [CATransaction flush];
    
    self.planets0.transform = CGAffineTransformIdentity;
    self.planets1.transform = CGAffineTransformIdentity;
    self.planets2.transform = CGAffineTransformIdentity;
    self.planets0.hidden = YES;
    self.planets1.hidden = YES;
    self.planets2.hidden = YES;
    self.planets0.alpha = 0;
    self.planets1.alpha = 0;
    self.planets2.alpha = 0;
}

#pragma mark -
#pragma mark Properties

/*
 * Returns state of activity indicator
 */
- (BOOL)isLoading {
    return self.rocketFlying.isAnimating;
}

@end
