//
//  SPCStarsView.h
//  Spayce
//
//  Created by Jake Rosin on 8/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCStarsView : UIView {
    float starsHeight;
}
-(void)prepAnimation;
-(void)startAnimation;
-(void)stopAnimation;

@end
