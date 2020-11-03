//
//  SPCSpaceMan.m
//  Spayce
//
//  Created by Christopher Taylor on 9/30/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSpaceMan.h"


@implementation SPCSpaceMan

@synthesize radius,velocity,baseVelocity,position,maxHeight,maxWidth;

- (void)update {

    position.x += velocity.x;
    position.y += velocity.y;
    
    //decelerate
    if ((velocity.x > 0)) {
        velocity.x = velocity.x - 1;
    }
    if ((velocity.x < 0)) {
        velocity.x = velocity.x + 1;
    }
    if ((velocity.y > baseVelocity.y) && (baseVelocity.y > 0)){
        velocity.y = velocity.y - 1;
    }
    if ((velocity.y < baseVelocity.y) && (baseVelocity.y < 0)) {
        velocity.y = velocity.y + 1;
    }
    
    if(position.x + radius/2 > maxWidth) {
        position.x = maxWidth - radius/2;
        velocity.x *= -1.0;
        baseVelocity.x *= -1.0;
        //NSLog(@"flip left");
    }
    else if(position.x - radius/2 < 0.0) {
        position.x = radius/2;
        velocity.x *= -1.0;
        baseVelocity.x *= -1.0;
        //NSLog(@"flip right");
    }
    
    if(position.y + radius > maxHeight) {
        position.y = maxHeight - radius;
        velocity.y *= -1.0;
        baseVelocity.y *= -1.0;
        //NSLog(@"flip up");
    }
    else if(position.y - radius < 0.0) {
        position.y = radius;
        velocity.y *= -1.0;
        baseVelocity.y *= -1.0;
        //NSLog(@"flip down");
    }

    //bail out in case we come to a dead stop..
    if (velocity.x == 0) {
        velocity.x = 0;
        baseVelocity.x = 0;
    }
    if (velocity.y == 0) {
        velocity.y = -1;
        baseVelocity.y = -1;
    }
}

@end
