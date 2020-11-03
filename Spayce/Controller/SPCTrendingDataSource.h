//
//  SPCTrendingDataSource.h
//  Spayce
//
//  Created by Jake Rosin on 7/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHereDataSource.h"

@interface SPCTrendingDataSource : SPCHereDataSource

@property (nonatomic, assign) CGFloat accordionHeight;
@property (nonatomic, assign) CGFloat accordionTop;
@property (nonatomic, strong) NSArray * accordionViews;
@property (nonatomic, strong) NSArray * accordionViewsUnfoldOrder;

@property (nonatomic, assign) CGFloat accordionHeightMin;
@property (nonatomic, assign) CGFloat accordionHeightMax;

@property (nonatomic, assign) CGFloat accordionStickyPixels;
@property (nonatomic, assign) CGFloat accordionStickyPixelsRestick;

-(void)configureAccordionViewsWithViewOrder:(NSArray *)viewsInViewOrder unfoldOrder:(NSArray *)viewsInUnfoldOrder accordionTop:(CGFloat)accordionTop;

-(void)setAccordionHeight:(CGFloat)accordionHeight forScrollView:(UIScrollView *)scrollView;

@end
