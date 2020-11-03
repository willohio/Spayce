//
//  SPCEarthquakeLoader.h
//  Spayce
//
//  Created by Christopher Taylor on 12/4/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCEarthquakeLoader : UIView
@property (nonatomic, strong) UILabel *msgLabel;


-(void)startAnimating;
-(void)stopAnimating;
@end
