//
//  SPCMapRadiusHighlightView.m
//  Spayce
//
//  Created by Jake Rosin on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCMapRadiusHighlightView.h"

@interface SPCMapRadiusHighlightView()

@property (nonatomic, assign) CGRect elipseRect;
@property (nonatomic, assign) CGRect elipseBorderRect;
@property (nonatomic, assign) UIEdgeInsets coordinateBounds;

@end

@implementation SPCMapRadiusHighlightView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.highlight) {
        // draw dark region everywhere but the circle
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.0 alpha:0.4].CGColor);
        CGContextAddRect(context, rect);
        CGContextAddEllipseInRect(context, self.elipseRect);
        CGContextEOClip(context);
        CGContextFillRect(context, rect);
        CGContextRestoreGState(context);
        
        // add a blue ring around the circle edge
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRGBHex:0x6ab1fb].CGColor);
        CGContextSetLineWidth(context, 10);
        CGContextStrokeEllipseInRect(context, self.elipseBorderRect);
    } else {
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        CGContextFillRect(context, rect);
    }
}

-(void)updateWithMapView:(GMSMapView *)mapView {
    if (!mapView) {
        return;
    }
    
    // TODO: read the projection data necessary to determine where to draw the elipse.
    if (mapView.settings.rotateGestures || mapView.camera.bearing != 0) {
        NSLog(@"WARNING: SPCMapRadiusHighlightView does not support map rotation!");
    }
    
    // Project our coordinate bounds into view-coordinates.
    CGPoint origin = [mapView.projection pointForCoordinate:CLLocationCoordinate2DMake(self.coordinateBounds.top, self.coordinateBounds.left)];
    CGPoint bottomLeft = [mapView.projection pointForCoordinate:CLLocationCoordinate2DMake(self.coordinateBounds.bottom, self.coordinateBounds.right)];
    CGRect bounds = CGRectMake(origin.x, origin.y, bottomLeft.x - origin.x, bottomLeft.y - origin.y);
    if (!CGRectEqualToRect(self.elipseRect, bounds)) {
        self.elipseRect = bounds;
        self.elipseBorderRect = CGRectInset(bounds, -4, -4);
        // view needs draw
        [self setNeedsDisplay];
    }
}

-(void)updateCoordinateBound {
    // Short names for lat / lng
    CGFloat lat = self.location.coordinate.latitude;
    CGFloat lng = self.location.coordinate.longitude;
    
    // Earth's radius (spherical approx.)
    CGFloat R = 6378137;
    
    // Coordinate offsets in radius
    CGFloat dLat = self.radius / R;
    CGFloat dLon = self.radius / (R * cos(M_PI*lat/180.0));
    
    // Offset position in decimal degrees
    CGFloat mult = 180.0 / M_PI;
    self.coordinateBounds = UIEdgeInsetsMake(lat + dLat*mult, lng - dLon*mult, lat - dLat*mult, lng + dLon*mult);
}

-(void)setLocation:(CLLocation *)location {
    _location = location;
    [self updateCoordinateBound];
}

-(void)setRadius:(CGFloat)radius {
    _radius = radius;
    [self updateCoordinateBound];
}

-(void)setHighlight:(BOOL)highlight {
    _highlight = highlight;
    [self setNeedsDisplay];
}

@end
