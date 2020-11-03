//
//  SPCSpaceMan.h
//  Spayce
//
//  Created by Christopher Taylor on 9/30/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCSpaceMan : UIImageView {
    
    CGPoint position;
    CGPoint velocity;
    CGPoint baseVelocity;
    CGFloat radius;
    CGFloat maxWidth;
    CGFloat maxHeight;
}

@property CGPoint position;
@property CGPoint velocity;
@property CGPoint baseVelocity;
@property CGFloat radius;
@property CGFloat maxWidth;
@property CGFloat maxHeight;

-(void)update;
@end
