//
//  SPCAnimationDelegate.h
//  Spayce
//
//  Created by Jake Rosin on 8/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCAnimationDelegate : NSObject

@property (copy, nonatomic) void (^animationDidStartCallback)(CAAnimation * anim);
@property (copy, nonatomic) void (^animationDidStopCallback)(CAAnimation * anim, BOOL finished);

-(instancetype)initWithStartCallback:(void (^)(CAAnimation * anim))startCallback
                        stopCallback:(void (^)(CAAnimation * anim, BOOL finished))stopCallback;

-(instancetype)initWithStopCallback:(void (^)(CAAnimation * anim, BOOL finished))stopCallback;

@end
