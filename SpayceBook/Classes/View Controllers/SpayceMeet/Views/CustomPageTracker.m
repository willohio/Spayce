//
//  CustomPageTracker.m
//  Spayce
//
//  Created by Christopher Taylor on 11/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "CustomPageTracker.h"

@implementation CustomPageTracker

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
 
        self.trackerColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.2];
        self.highlightColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    }
    return self;
}

- (void)totalPics:(int)totalPics currPic:(int)currPic {

    float spacing = 12;
    float width = 10;
    
    UIView *view;
    NSArray *subs = [self subviews];
    
    for (view in subs) {
        [view removeFromSuperview];
    }
    
    float totalCounterWidth = 0;
    totalCounterWidth=(totalPics*width)+((totalPics-1)*spacing);
    
    float startX = ((self.bounds.size.width-totalCounterWidth)/2);

    for (int i=0; i<totalPics; i++) {
        
        float x=startX+(i*spacing);
        if (i>0){
            x=x+(i*width);
        }
        
        UIView *counter = [[UIView alloc] initWithFrame:CGRectMake(x, 0, width, width)];
        counter.backgroundColor=self.trackerColor;
        counter.tag=i;
        counter.layer.cornerRadius = width/2;
        [self addSubview:counter];

        if (i==currPic) {
            counter.backgroundColor=self.highlightColor;
        }
    }
}

-(void)highlightPic:(int)currPic {
    
    UIView *view;
    NSArray *subs = [self subviews];
    
    for (view in subs) {
        view.backgroundColor=self.trackerColor;
       
        if (view.tag==currPic) {
            view.backgroundColor=self.highlightColor;
        }
    }
}


- (void)totalAssets:(int)totalAssets currAsset:(int)currAsset {
    
    UIView *view;
    NSArray *subs = [self subviews];
    
    for (view in subs) {
        [view removeFromSuperview];
    }
        
    self.pillView = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 87, 2, 30, 30)];
    self.pillView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.3];
    self.pillView.layer.borderColor = [UIColor colorWithWhite:225.0/255.0 alpha:1.0].CGColor;
    self.pillView.layer.borderWidth = .5;
    self.pillView.layer.cornerRadius = self.pillView.frame.size.height/2;
    self.pillView.clipsToBounds=YES;
    [self addSubview:self.pillView];
    
    float yOffset = 0;
    
    UILabel *counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width - 82, 7+yOffset, 20, 20)];
    counterLabel.text = [NSString stringWithFormat:@"%i/%i",currAsset+1,totalAssets];
    counterLabel.font = [UIFont systemFontOfSize:11];
    counterLabel.textAlignment = NSTextAlignmentCenter;
    counterLabel.textColor = [UIColor colorWithWhite:225.0/255.0 alpha:1.0];

    counterLabel.backgroundColor = [UIColor clearColor];
    counterLabel.tag = -2;
    [self addSubview:counterLabel];
    
}

-(void)adjustForAudioTracker{
    
    UILabel *tempCounter = (UILabel *)[self viewWithTag:-2];
    tempCounter.textColor =  [UIColor colorWithWhite:109.0/255.0 alpha:1.0];
    tempCounter.center = CGPointMake(tempCounter.center.x, tempCounter.center.y-6);
    
    self.pillView.center = CGPointMake(self.pillView.center.x,  self.pillView.center.y-6);
    self.pillView.frame = CGRectMake(self.pillView.frame.origin.x, self.pillView.frame.origin.y+2, self.pillView.frame.size.width, self.pillView.frame.size.height-5);
    self.pillView.layer.cornerRadius = self.pillView.frame.size.height/2;
    self.pillView.backgroundColor = [UIColor colorWithWhite:249.0/255.0 alpha:1.0];
}


-(void)configureWithTotal:(int)totalAssets curr:(int)currAsset {
    UILabel *tempLabel = (UILabel *)[self viewWithTag:-2];
    tempLabel.text = [NSString stringWithFormat:@"%i/%i",currAsset+1,totalAssets];
}

@end
