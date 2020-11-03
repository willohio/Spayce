//
//  SPCGoogleMapInfoView.m
//  Spayce
//
//  Created by Jake Rosin on 6/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCGoogleMapInfoView.h"
#import "SMCalloutView.h"
#import "SPCMarker.h"


#define ARROW_HEIGHT 13

const CGFloat SPCGoogleMapInfoViewDefaultInsetHorizontal = 8;
const CGFloat SPCGoogleMapInfoViewDefaultInsetVertical = 8;


@interface SPCGoogleMapInfoViewCustomInfoWindowContainer : NSObject

@property (nonatomic, strong) UIView *infoWindow;
@property (nonatomic, assign) CGFloat calloutVerticalOffset;
@property (nonatomic, assign) CLLocationCoordinate2D position;
@property (nonatomic, strong) SPCMarker *marker;

@end


@interface SPCGoogleMapInfoView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) SMCalloutMaskedBackgroundView *backgroundView;

@end

@implementation SPCGoogleMapInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.clipsToBounds = YES;
        _containerView.layer.cornerRadius = 8;
        [self addSubview:_containerView];
    }
    return _containerView;
}

-(SMCalloutMaskedBackgroundView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[SMCalloutMaskedBackgroundView alloc] init];
        [self addSubview:_backgroundView];
    }
    return _backgroundView;
}

-(void) setContentView:(UIView *)contentView {
    [self setContentView:contentView withEdgeInsets:UIEdgeInsetsMake(SPCGoogleMapInfoViewDefaultInsetHorizontal, SPCGoogleMapInfoViewDefaultInsetVertical, SPCGoogleMapInfoViewDefaultInsetHorizontal, SPCGoogleMapInfoViewDefaultInsetVertical)];
}

-(void) setContentView:(UIView *)contentView withEdgeInsets:(UIEdgeInsets)insets {
    if (_contentView) {
        [_contentView removeFromSuperview];
    }
    _contentView = contentView;
    if (self.contentView) {
        // Resize our frame and the background.
        // we size everything to put our own origin at (0,0).
        _contentView.frame = CGRectOffset(contentView.frame, -contentView.frame.origin.x, -contentView.frame.origin.y);
        self.containerView.frame = CGRectOffset(_contentView.frame, insets.left, insets.top);
        [self.containerView addSubview:_contentView];
        
        CGRect frame = CGRectMake(0, 0, contentView.frame.size.width + insets.left + insets.right, contentView.frame.size.height + insets.top + insets.bottom + ARROW_HEIGHT);
        self.backgroundView.frame = frame;
        [self.backgroundView setArrowPoint:CGPointMake(frame.size.width / 2.0, frame.size.height)];
        self.frame = frame;
        
        // make sure background is in the background
        [self bringSubviewToFront:self.containerView];
        
        [self.backgroundView setBackgroundColor:_contentView.backgroundColor];
        [self.backgroundView setUseSharpEdges:YES];
    }
}

@end



@interface SPCGoogleMapInfoViewSupportDelegate ()

@property (nonatomic, strong) UIView *calloutView;
@property (nonatomic, strong) SPCGoogleMapInfoViewCustomInfoWindowContainer *fakeCalloutView;
@property (nonatomic, strong) NSMutableArray *dismissingFakeCalloutViews;

@end

@implementation SPCGoogleMapInfoViewCustomInfoWindowContainer

// nothing to do

@end

@implementation SPCGoogleMapInfoViewSupportDelegate

#pragma mark - Properties

-(NSMutableArray *)dismissingFakeCalloutViews {
    if (!_dismissingFakeCalloutViews) {
        _dismissingFakeCalloutViews = [[NSMutableArray alloc] initWithCapacity:4];
    }
    return _dismissingFakeCalloutViews;
}

#pragma mark - Google maps delegate
// The Google maps iOS SDK does not support yet the actions on annotation detail since it is render as an image (03/28)
// So, we are forced to provide a false annotation view + add our own and handles the repositining!
// Shame
// For details / discussion, see https://code.google.com/p/gmaps-api-issues/issues/detail?id=4961

+ (CGFloat)calloutHeightAboveMarker:(SPCMarker *)marker {
    CGFloat markerHeight = [marker icon].size.height;
    // We want the # of pixels above the map coordinate to display the
    // downward facing arrow point for a callout.  That distance is
    // (groundAnchor.y - infoWindowAchor.y) * height.
    return (marker.groundAnchor.y - marker.infoWindowAnchor.y) * markerHeight + 5;
}

- (void)repositionCalloutViewForCoordinates:(CLLocationCoordinate2D)coordinate inMap:(GMSMapView *)pMapView {
    [self repositionCalloutView:self.calloutView forCoordinates:coordinate inMap:pMapView withCalloutVerticalOffset:[SPCGoogleMapInfoViewSupportDelegate calloutHeightAboveMarker:(SPCMarker *)pMapView.selectedMarker]];
}

- (void)repositionCalloutView:(UIView *)view forCoordinates:(CLLocationCoordinate2D)coordinate inMap:(GMSMapView *)pMapView withCalloutVerticalOffset:(CGFloat)calloutVerticalOffset {
    
    CGPoint arrowPt = CGPointMake(CGRectGetWidth(view.frame) / 2.0, CGRectGetHeight(view.frame));
    
    CGPoint pt = [pMapView.projection pointForCoordinate:coordinate];
    pt.x -= arrowPt.x;
    pt.y -= arrowPt.y + calloutVerticalOffset; /*height of POI Image*/;
    
    view.frame = (CGRect) {.origin = pt, .size = view.frame.size };
}

-(void)repositionCalloutsForMapView:(GMSMapView *)pMapView {
    if (pMapView.selectedMarker != nil && self.calloutView.superview) {
        [self repositionCalloutViewForCoordinates:[pMapView.selectedMarker position] inMap:pMapView];
    } else {
        [self.calloutView removeFromSuperview];
    }
    if (self.fakeCalloutView.infoWindow.superview) {
        [self repositionCalloutView:self.fakeCalloutView.infoWindow forCoordinates:self.fakeCalloutView.position inMap:pMapView withCalloutVerticalOffset:self.fakeCalloutView.calloutVerticalOffset];
    }
    [self.dismissingFakeCalloutViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SPCGoogleMapInfoViewCustomInfoWindowContainer * callout = obj;
        [self repositionCalloutView:callout.infoWindow forCoordinates:callout.position inMap:pMapView withCalloutVerticalOffset:callout.calloutVerticalOffset];
    }];
}

-(void) mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:willMove:)]) {
        [self.delegate mapView:mapView willMove:gesture];
    }
}

- (void)mapView:(GMSMapView *)pMapView didChangeCameraPosition:(GMSCameraPosition *)position {
    [self repositionCalloutsForMapView:pMapView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:didChangeCameraPosition:)]) {
        [self.delegate mapView:pMapView didChangeCameraPosition:position];
    }
}

-(void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    [self repositionCalloutsForMapView:mapView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:idleAtCameraPosition:)]) {
        [self.delegate mapView:mapView idleAtCameraPosition:position];
    }
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:didTapAtCoordinate:)]) {
        BOOL customBehavior = [self.delegate mapView:mapView didTapAtCoordinate:coordinate];
        
        if (!customBehavior) {
            [mapView animateToLocation:coordinate];
        }
    }
    if (self.calloutView.superview) {
        [self.calloutView removeFromSuperview];
    } 
}

-(BOOL) mapView:(GMSMapView *)mapView didTapMarker:(SPCMarker *)marker {
    //NSLog(@"didTapMarker");
    BOOL customBehavior = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:didTapMarker:)]) {
        customBehavior = [self.delegate mapView:mapView didTapMarker:marker];
    }
    if (!customBehavior) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:calloutHeightForMarker:)]) {
            CGFloat height = [self.delegate mapView:mapView calloutHeightForMarker:marker];
            if (height + 80 > CGRectGetHeight(mapView.frame) / 2) {
                // reposition downward to fit
                CGPoint markerPoint = [mapView.projection pointForCoordinate:marker.position];
                CGPoint adjustedPoint = { .x = markerPoint.x, .y = markerPoint.y - (height/2 + 40) };
                CLLocationCoordinate2D adjustedCoordinate = [mapView.projection coordinateForPoint:adjustedPoint];
                [mapView animateToLocation:adjustedCoordinate];
                [mapView setSelectedMarker:marker];
                customBehavior = YES;
            } else if (height > 70) {
                // adjust to display the window more "centered"
                CGPoint markerPoint = [mapView.projection pointForCoordinate:marker.position];
                CGPoint adjustedPoint = { .x = markerPoint.x, .y = markerPoint.y - (height-70) };
                CLLocationCoordinate2D adjustedCoordinate = [mapView.projection coordinateForPoint:adjustedPoint];
                [mapView animateToLocation:adjustedCoordinate];
                [mapView setSelectedMarker:marker];
                customBehavior = YES;
            }
        }
    }
    return customBehavior;
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(SPCMarker *)marker {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:markerInfoWindow:)]) {
        [self.calloutView removeFromSuperview];
        
        UIView * calloutView = [self.delegate mapView:mapView markerInfoWindow:marker];
        self.calloutView = calloutView;
        
        if (self.infoWindowContainerView) {
            [self.infoWindowContainerView addSubview:self.calloutView];
        } else {
            [mapView addSubview:self.calloutView];
        }
        
        calloutView.alpha = 0.0;
        [UIView animateWithDuration:0.2f
                         animations:^{
                             calloutView.alpha = 1.0f;
                         }];
        
        [self repositionCalloutViewForCoordinates:marker.position inMap:mapView];
        
        // unnecessary: we animate there automatically
        // [mapView animateToLocation:[marker position]];
        
        return [[UIView alloc] initWithFrame:self.calloutView.frame];
    }
    return nil;
}

-(void) mapView:(GMSMapView *)mapView didBeginDraggingMarker:(SPCMarker *)marker {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:didBeginDraggingMarker:)]) {
        [self.delegate mapView:mapView didBeginDraggingMarker:marker];
    }
}

-(void) mapView:(GMSMapView *)mapView didEndDraggingMarker:(SPCMarker *)marker {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:didEndDraggingMarker:)]) {
        [self.delegate mapView:mapView didEndDraggingMarker:marker];
        
        // adjust to display the window more centered
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:calloutHeightForMarker:)]) {
            CGFloat height = [self.delegate mapView:mapView calloutHeightForMarker:marker];
            CGPoint markerPoint = [mapView.projection pointForCoordinate:marker.position];
            CGPoint adjustedPoint = { .x = markerPoint.x, .y = markerPoint.y - (height) };
            CLLocationCoordinate2D adjustedCoordinate = [mapView.projection coordinateForPoint:adjustedPoint];
            [mapView animateToLocation:adjustedCoordinate];
            }
    }
}

-(void) mapView:(GMSMapView *)mapView didDragMarker:(SPCMarker *)marker {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapView:didDragMarker:)]) {
        [self.delegate mapView:mapView didDragMarker:marker];
    }
}


#pragma mark - Methods visible to users of this class

- (void)selectMarker:(SPCMarker *)marker withMapView:(GMSMapView *)mapView {
    if (marker) {
        mapView.selectedMarker = marker;
    } else {
        mapView.selectedMarker = nil;
        [self.calloutView removeFromSuperview];
    }
}

- (void)selectMarker:(SPCMarker *)marker withMapView:(GMSMapView *)mapView showCallout:(BOOL)calloutVisible {
    
    if (marker && !calloutVisible) {
        mapView.selectedMarker = marker;
        [self.calloutView removeFromSuperview];
    }
    else {
        [self selectMarker:marker withMapView:mapView];
    }
}

- (void)showInvisibleCalloutCoveringMarker:(SPCMarker *)marker inMapView:(GMSMapView *)mapView {
    [self dismissFakeCalloutWindow];
    
    UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, marker.icon.size.width, marker.icon.size.height)];
    [button addTarget:self action:@selector(invisibleCalloutCoveringMarkerTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.fakeCalloutView = [[SPCGoogleMapInfoViewCustomInfoWindowContainer alloc] init];
    self.fakeCalloutView.infoWindow = button;
    self.fakeCalloutView.infoWindow.backgroundColor = [UIColor clearColor];
    self.fakeCalloutView.calloutVerticalOffset = 0;
    self.fakeCalloutView.position = marker.position;
    self.fakeCalloutView.marker = marker;
    
    // position in view
    UIView *containerView = self.infoWindowContainerView ?: mapView;
    if (self.calloutView.superview == containerView) {
        [containerView insertSubview:self.fakeCalloutView.infoWindow belowSubview:self.calloutView];
    } else {
        [containerView addSubview:self.fakeCalloutView.infoWindow];
    }
    
    [self repositionCalloutView:self.fakeCalloutView.infoWindow forCoordinates:marker.position inMap:mapView withCalloutVerticalOffset:self.fakeCalloutView.calloutVerticalOffset];
}

- (void)invisibleCalloutCoveringMarkerTapped:(id)sender {
    [self mapView:self.fakeCalloutView.marker.map didTapMarker:self.fakeCalloutView.marker];
}

- (void)dismissFakeCalloutWindow  {
    [self dismissFakeCalloutWindowWithFadeDuration:0.2f];
}

- (void)dismissFakeCalloutWindowWithFadeDuration:(CGFloat)fadeDuration {
    if (self.fakeCalloutView) {
        __block SPCGoogleMapInfoViewCustomInfoWindowContainer * callout = self.fakeCalloutView;
        [self.dismissingFakeCalloutViews addObject:callout];
        self.fakeCalloutView = nil;
        [UIView animateWithDuration:fadeDuration animations:^{
            callout.infoWindow.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.dismissingFakeCalloutViews removeObject:callout];
        }];
    }
}


@end
