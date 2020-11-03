//
//  SPCAnimationDelegate.m
//  Spayce
//
//  Created by Jake Rosin on 8/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAnimationDelegate.h"

@implementation SPCAnimationDelegate

-(instancetype)initWithStartCallback:(void (^)(CAAnimation * anim))startCallback
                        stopCallback:(void (^)(CAAnimation * anim, BOOL finished))stopCallback {
    self = [super init];
    if (self) {
        self.animationDidStartCallback = startCallback;
        self.animationDidStopCallback = stopCallback;
    }
    return self;
}

-(instancetype)initWithStopCallback:(void (^)(CAAnimation * anim, BOOL finished))stopCallback {
    self = [super init];
    if (self) {
        self.animationDidStopCallback = stopCallback;
    }
    return self;
}


-(void)animationDidStart:(CAAnimation *)anim {
    if (self.animationDidStartCallback) {
        self.animationDidStartCallback(anim);
    }
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (self.animationDidStopCallback) {
        self.animationDidStopCallback(anim, flag);
    }
}

@end