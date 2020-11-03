//
//  LargeBlockingProgressView.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/21/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LargeBlockingProgressView : UIView

@property (nonatomic, strong) UIView * backgroundView;
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, strong) UILabel * label;

@property (nonatomic, assign) CGFloat messageViewWidth;
@property (nonatomic, assign) CGFloat messageViewHeight;

@end
