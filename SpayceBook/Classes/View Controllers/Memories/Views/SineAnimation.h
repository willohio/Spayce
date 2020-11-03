//
//  SineAnimation.h
//  Spayce
//
//  Created by Christopher Taylor on 1/3/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SineAnimation : UIView {
    
    float amplitude;
}
-(void)updateAmplitude:(float)amp;
@end
