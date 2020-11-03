//
//  SPCCallout.h
//  Spayce
//
//  Created by Arria P. Owlia on 1/28/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Enums.h"

@interface SPCCallout : UIView

// The button used to dismiss the callout
@property (strong, nonatomic) UIButton *btnDismiss;

// string: the callout's string to display - font color will be set by SPCCallout
// arrowLocation: whether the arrow will point to above or below the callout's content
// offset: between [0, self.bounds.width] - the center offset of the arrow from the left of the content rectangle
- (void)configureWithString:(NSAttributedString *)string arrowLocation:(CalloutArrowLocation)arrowLocation andArrowOffset:(CGFloat)arrowOffset;

// A horizontal offset for label placement, dx - used for custom label placement
@property (nonatomic) CGFloat labelHorizontalOffset;

@end
