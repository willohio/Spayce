//
//  SPCInSpaceView.h
//  Spayce
//
//  Created by Christopher Taylor on 9/30/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCStarsView.h"
#import "LLARingSpinnerView.h"

@interface SPCInSpaceView : UIView {
    CGRect spaceManRect;
    CGPoint startPoint;
    CGPoint prevPoint;
}

@property (nonatomic, strong) LLARingSpinnerView *spinnerView;

-(void)restartAnimation;

-(void)promptForOptimizing;
-(void)promptForFix;
-(void)promptForLocation;
-(void)promptForLocationFromSpayce;
-(void)promptForData;
-(void)promptForMemory;
-(void)promptForTrending;
-(void)promptForMAMRefresh;
-(void)promptForSwipe;
- (void)spayceCentering;

-(instancetype)initWithFrame:(CGRect)frame showTabBar:(BOOL)showTabBar;
@end
