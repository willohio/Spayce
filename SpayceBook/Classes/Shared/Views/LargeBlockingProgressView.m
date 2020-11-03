//
//  LargeBlockingProgressView.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/21/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "LargeBlockingProgressView.h"

@implementation LargeBlockingProgressView

-(id) initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor colorWithRGBHex:0x000000 alpha:0.3];
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.backgroundView.backgroundColor = [UIColor colorWithRGBHex:0x000000 alpha:0.5];
        self.backgroundView.layer.cornerRadius = 10;
        [self addSubview:self.backgroundView];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self.activityIndicator sizeToFit];
        self.activityIndicator.hidesWhenStopped = YES;
        [self.backgroundView addSubview:self.activityIndicator];
        
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.font = [UIFont boldSystemFontOfSize:16];
        self.label.textAlignment = NSTextAlignmentCenter;
        [self.backgroundView addSubview:self.label];
        
        self.messageViewWidth = 200;
        self.messageViewHeight= 100;
    }
    
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat const backgroundViewWidth = self.messageViewWidth;
    CGFloat const backgroundViewHeight = self.messageViewHeight;
    
    CGFloat x = (self.bounds.size.width - backgroundViewWidth) / 2;
    CGFloat y = (self.bounds.size.height- backgroundViewHeight)/ 2;
    
    self.backgroundView.frame = CGRectMake(x, y, backgroundViewWidth, backgroundViewHeight);
    x = (backgroundViewWidth - self.activityIndicator.bounds.size.width)  / 2;
    y = (backgroundViewHeight - self.activityIndicator.bounds.size.height - 10 - self.label.font.lineHeight) /2;
    
    self.activityIndicator.frame = CGRectOffset(self.activityIndicator.bounds, x, y);
    y += self.activityIndicator.bounds.size.height;
    
    x = 10;
    y += 10;
    self.label.frame = CGRectMake(x, y, backgroundViewWidth - 2*x, self.label.font.lineHeight);
    
}

@end
