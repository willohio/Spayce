//
//  ShadowedLabel.h
//
//  Created by Tyler Neylon on 4/19/10.
//  Copyleft 2010 Bynomial.
//
//  Same as UILabel, except it draws a shadow
//  under the text.
//

#import <Foundation/Foundation.h>


@interface ShadowedLabel : UILabel {}

@property (nonatomic, assign) CGSize textShadowOffset;
@property (nonatomic, strong) UIColor *textShadowColor;
@property (nonatomic, assign) CGFloat textShadowRadius;

@end
