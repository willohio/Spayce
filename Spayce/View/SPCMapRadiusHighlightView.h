//
//  SPCMapRadiusHighlightView.h
//  Spayce
//
//  Created by Jake Rosin on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>

@interface SPCMapRadiusHighlightView : UIView

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) BOOL highlight;

-(void)updateWithMapView:(GMSMapView *)mapView;

@end
