//
//  SPCVenueDetailHeaderView.m
//  Spayce
//
//  Created by Pavel Dusatko on 9/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

// Framework
#import <GoogleMaps/GoogleMaps.h>

#import "SPCVenueDetailHeaderView.h"
#import "Venue.h"

@implementation SPCVenueDetailHeaderView

#pragma mark - Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [self initWithFrame:frame venue:nil];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame venue:(Venue *)venue {
    self = [super initWithFrame:frame];
    if (self) {
        
        CLLocationDegrees latitude = [venue.latitude doubleValue];
        CLLocationDegrees longitude = [venue.longitude doubleValue];
        CGFloat zoom = 17;
        if (venue.specificity == SPCVenueIsFuzzedToCity) {
            zoom = 7;
        } else if (venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
            zoom = 11;
        }
        
        /********** Venue detail container *****/
        GMSMapView *mapView = [GMSMapView mapWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 100) camera:[GMSCameraPosition cameraWithLatitude:latitude longitude:longitude zoom:zoom]];
        mapView.translatesAutoresizingMaskIntoConstraints = NO;
        mapView.userInteractionEnabled = NO;
        mapView.padding = UIEdgeInsetsMake(0, 5, 25, 0);
        // TODO adjust insets
        _venueMapView = mapView;
        [self addSubview:_venueMapView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_venueMapView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_venueMapView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_venueMapView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:100]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_venueMapView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        
        UIView *bottomGradientView = [[UIView alloc] init];
        bottomGradientView.translatesAutoresizingMaskIntoConstraints = NO;
        bottomGradientView.backgroundColor = [UIColor clearColor];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = CGRectMake(0, 70, CGRectGetWidth(frame), 30);
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRGBHex:0xf8f8f8 alpha:0.0] CGColor], (id)[[UIColor colorWithRGBHex:0xf8f8f8 alpha:1] CGColor], nil];
        [bottomGradientView.layer insertSublayer:gradient atIndex:0];
        [self addSubview:bottomGradientView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bottomGradientView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_venueMapView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bottomGradientView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_venueMapView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bottomGradientView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_venueMapView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bottomGradientView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_venueMapView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];

        
        /********* Icon Bubble that sits astride the map view and the parallax banner ***********/
        
        UIView *iconBubble = [[UIView alloc] init];
        iconBubble.translatesAutoresizingMaskIntoConstraints = NO;
        iconBubble.backgroundColor = [UIColor whiteColor];
        iconBubble.layer.cornerRadius = 40;
        iconBubble.layer.shadowColor = [UIColor blackColor].CGColor;
        iconBubble.layer.shadowRadius = 2;
        iconBubble.layer.shadowOffset = CGSizeMake(0, 0.5);
        iconBubble.layer.shadowOpacity = 0.2;
        [self addSubview:iconBubble];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:iconBubble attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:80]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:iconBubble attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:80]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:iconBubble attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:8]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:iconBubble attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_venueMapView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        
         
        /********** Distance label *************/
        
        _distanceLabel = [[UILabel alloc] init];
        _distanceLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _distanceLabel.font = [UIFont spc_lightSystemFontOfSize:10];
        _distanceLabel.textColor = [UIColor colorWithRGBHex:0xb3b3b3];
        [iconBubble addSubview:_distanceLabel];
        [iconBubble addConstraint:[NSLayoutConstraint constraintWithItem:_distanceLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:iconBubble attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [iconBubble addConstraint:[NSLayoutConstraint constraintWithItem:_distanceLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:iconBubble attribute:NSLayoutAttributeTop multiplier:1.0 constant:54]];
        
        
        /********** Venue icon *****************/
        
        _venueImageView = [[UIImageView alloc] init];
        _venueImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [iconBubble addSubview:_venueImageView];
        [iconBubble addConstraint:[NSLayoutConstraint constraintWithItem:_venueImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:iconBubble attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [iconBubble addConstraint:[NSLayoutConstraint constraintWithItem:_venueImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_distanceLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-5]];
        [iconBubble addConstraint:[NSLayoutConstraint constraintWithItem:_venueImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:32]];
        [iconBubble addConstraint:[NSLayoutConstraint constraintWithItem:_venueImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:32]];
    
        if (venue.specificity != SPCVenueIsReal) {
            iconBubble.hidden = YES;
        }
        
    }
    return self;
}

@end
