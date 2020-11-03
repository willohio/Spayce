//
//  SPCGoogleMapInfoView.h
//  Spayce
//
//  Created by Jake Rosin on 6/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "SPCMarker.h"

extern const CGFloat SPCGoogleMapInfoViewDefaultInsetHorizontal;
extern const CGFloat SPCGoogleMapInfoViewDefaultInsetVertical;

@interface SPCGoogleMapInfoView : UIView

- (void) setContentView:(UIView *)view;
- (void) setContentView:(UIView *)view withEdgeInsets:(UIEdgeInsets)insets;

@end

@protocol SPCGoogleMapInfoViewSupportDelegateDelegate <NSObject>
-(UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(SPCMarker *)marker;
@optional
-(void) mapView:(GMSMapView *)mapView willMove:(BOOL)gesture;
-(void) mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position;
-(void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position;
-(BOOL) mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate;
-(BOOL) mapView:(GMSMapView *)mapView didTapMarker:(SPCMarker *)marker;
-(void) mapView:(GMSMapView *)mapView didBeginDraggingMarker:(SPCMarker *)marker;
-(void) mapView:(GMSMapView *)mapView didEndDraggingMarker:(SPCMarker *)marker;
-(void) mapView:(GMSMapView *)mapView didDragMarker:(SPCMarker *)marker;
-(CGFloat) mapView:(GMSMapView *)mapView calloutHeightForMarker:(SPCMarker *)marker;
@end

@interface SPCGoogleMapInfoViewSupportDelegate : NSObject <GMSMapViewDelegate>

@property (nonatomic, weak) NSObject <SPCGoogleMapInfoViewSupportDelegateDelegate> *delegate;
@property (nonatomic, strong) UIView *infoWindowContainerView;

- (void)selectMarker:(SPCMarker *)marker withMapView:(GMSMapView *)mapView;
- (void)selectMarker:(SPCMarker *)marker withMapView:(GMSMapView *)mapView showCallout:(BOOL)calloutVisible;


-(void)repositionCalloutsForMapView:(GMSMapView *)mapView;
- (void)showInvisibleCalloutCoveringMarker:(SPCMarker *)marker inMapView:(GMSMapView *)mapView;
- (void)dismissFakeCalloutWindow;

- (void)dismissFakeCalloutWindowWithFadeDuration:(CGFloat)fadeDuration;

@end
