//
//  SPCSearchTextField.m
//  Spayce
//
//  Created by William Santiago on 8/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSearchTextField.h"

@implementation SPCSearchTextField

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"search-white"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        imageView.contentMode = UIViewContentModeCenter;
        self.leftView = imageView;
        self.leftViewMode = UITextFieldViewModeAlways;
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
    }
    return self;
}

#pragma mark - Text drawing rectangle

- (void)drawPlaceholderInRect:(CGRect)rect {
    NSDictionary *attributes = self.placeholderAttributes;
    CGRect boundingRect = [self.placeholder boundingRectWithSize:rect.size options:0 attributes:attributes context:nil];
    [self.placeholder drawAtPoint:CGPointMake(0, (rect.size.height/2)-boundingRect.size.height/2) withAttributes:attributes];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
    CGFloat leftX = 0;
    CGFloat width = 0;
    if (self.leftView) {
        width = CGRectGetWidth(self.leftView.frame);
        if ([self.leftView isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)self.leftView;
            width = imageView.image.size.width + 10;
            leftX = 5;
        }
    }
    
    return CGRectMake(leftX, 0, width, CGRectGetHeight(self.bounds));
}

#pragma mark - Accessors

- (BOOL)isSearching {
    return self.text.length > 0;
}

@end
