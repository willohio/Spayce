//
//  SPCMapDataSource.h
//  Spayce
//
//  Created by Jake Rosin on 6/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "Venue.h"
#import "Memory.h"
#import "SPCGoogleMapInfoView.h"
#import "SPCMarker.h"

typedef NS_ENUM(NSInteger, MarkerStarType) {
    MarkerStarTypeNone = 0,
    MarkerStarTypeGold = 1,
    MarkerStarTypeSilver = 2,
    MarkerStarTypeBronze = 3
};

typedef NS_ENUM(NSInteger, MapMarkerStyle) {
    MapMarkerStyleNormal,
    MapMarkerStyleEmphasizeOwned
};

extern const NSInteger spc_VENUE_DATA_OPTION_STAR_NONE;
extern const NSInteger spc_VENUE_DATA_OPTION_STAR_GOLD;
extern const NSInteger spc_VENUE_DATA_OPTION_STAR_SILVER;
extern const NSInteger spc_VENUE_DATA_OPTION_STAR_BRONZE;

extern const NSInteger spc_VENUE_DATA_OPTION_USER_LOCATION_CURRENT;
extern const NSInteger spc_VENUE_DATA_OPTION_USER_LOCATION_ORIGINAL;

extern const NSInteger spc_VENUE_DATA_OPTION_REALTIME;

extern const NSInteger spc_VENUE_DATA_OPTION_EMPHASIZE_OWNED;

@interface SPCMarkerVenueData : NSObject

@property (nonatomic, strong) Venue *venue;
@property (nonatomic, strong) Memory *memory;
@property (nonatomic, strong) NSArray *venues;
@property (nonatomic, assign) BOOL isCurrentUserLocation;
@property (nonatomic, assign) BOOL isOriginalUserLocation;
@property (nonatomic, assign) BOOL isRealtime;
@property (nonatomic, readonly) BOOL isOwnedByUser;
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) MarkerStarType markerStarType;
@property (nonatomic, assign) MapMarkerStyle mapMarkerStyle;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *subtitle;
@property (nonatomic, readonly) UIImage *markerIcon;
@property (nonatomic, readonly) BOOL markerIconIsPlaceholder;
@property (nonatomic, readonly) CGPoint markerGroundAnchor;
@property (nonatomic, readonly) CGPoint markerInfoWindowAnchor;
@property (nonatomic, readonly) NSInteger memoryCount;
@property (nonatomic, assign) NSInteger starCount;

@property (nonatomic, strong) Asset *exploreAsset;

- (instancetype)initWithLocation:(CLLocation *)location venue:(Venue *)venue;
- (instancetype)initWithVenue:(Venue *)venue;
- (instancetype)initWithVenues:(NSArray *)venues;
- (instancetype)initWithMemory:(Memory *)memory;
- (instancetype)initWithMemory:(Memory *)memory venue:(Venue *)venue;



+ (SPCMarker *)markerWithCurrentLocation:(CLLocation *)location venue:(Venue *)venue;
+ (SPCMarker *)markerWithOriginalLocation:(CLLocation *)location venue:(Venue *)venue;
+ (SPCMarker *)markerWithOriginalAndCurrentLocation:(CLLocation *)location venue:(Venue *)venue;
+ (SPCMarker *)markerWithCurrentLocation:(CLLocation *)location venue:(Venue *)venue draggable:(BOOL)draggable;
+ (SPCMarker *)markerWithOriginalLocation:(CLLocation *)location venue:(Venue *)venue draggable:(BOOL)draggable;
+ (SPCMarker *)markerWithOriginalAndCurrentLocation:(CLLocation *)location venue:(Venue *)venue draggable:(BOOL)draggable;
+ (SPCMarker *)markerWithVenue:(Venue *)venue;
+ (SPCMarker *)markerWithVenues:(NSArray *)venues;
+ (SPCMarker *)markerWithCurrentVenue:(Venue *)venue;
+ (SPCMarker *)markerWithCurrentVenues:(NSArray *)venues;
+ (SPCMarker *)markerWithOriginalVenues:(NSArray *)venues;
+ (SPCMarker *)markerWithOriginalAndCurrentVenues:(NSArray *)venues;
+ (SPCMarker *)markerWithMemory:(Memory *)memory;
+ (SPCMarker *)markerWithRealtimeMemory:(Memory *)memory venue:(Venue *)venue iconReadyHandler:(void (^)(SPCMarker *marker))iconReadyHandler;
+ (SPCMarker *)markerWithVenueData:(SPCMarkerVenueData *)venueData;
+ (SPCMarker *)markerWithVenueData:(SPCMarkerVenueData *)venueData iconReadyHandler:(void (^)(SPCMarker *marker))iconReadyHandler;

+ (SPCMarker *)markerWithLocation:(CLLocation *)location venue:(Venue *)venue options:(NSInteger)options;
+ (SPCMarker *)markerWithVenue:(Venue *)venue options:(NSInteger)options;
+ (SPCMarker *)markerWithVenues:(NSArray *)venues options:(NSInteger)options;

+ (void)configureMarker:(SPCMarker *)marker withVenueData:(SPCMarkerVenueData *)venueData reposition:(BOOL)reposition;
+ (void)configureMarker:(SPCMarker *)marker withVenueData:(SPCMarkerVenueData *)venueData reposition:(BOOL)reposition iconReadyHandler:(void (^)(SPCMarker *marker))iconReadyHandler;

- (NSInteger)venueCount;
- (Venue *)venueAt:(NSInteger)index;
- (NSString *)titleForVenue:(Venue *)venue;
- (NSString *)subtitleForVenue:(Venue *)venue;
- (NSString *)titleForVenueAt:(NSInteger)index;
- (NSString *)subtitleForVenueAt:(NSInteger)index;
- (UIImage *)markerWithVenueForLocationId:(Venue *)venue;

@end



@protocol SPCMapDataSourceDelegate

@optional
- (void)userDidSelectVenue:(Venue *)venue fromStack:(NSInteger)stack withMarker:(SPCMarker *)marker;
- (void)userDidConfirmVenue:(Venue *)venue fromStack:(NSInteger)stack withMarker:(SPCMarker *)marker;
- (void)userDidCancelVenue:(Venue *)venue fromStack:(NSInteger)stack withMarker:(SPCMarker *)marker;

@end

typedef NS_ENUM(NSInteger, StackedVenueType) {
    StackedVenueTypeShowDeviceLocation = 1,
    StackedVenueTypeOmitDeviceLocation = 2
};

typedef NS_ENUM(NSInteger, InfoWindowType) {
    InfoWindowTypeVenueSelection = 1,
    InfoWindowTypeVenueSelectionOwned = 2,
    InfoWindowTypeVenueInformation = 3,
    InfoWindowTypeVenueConfirmation = 4
};


@interface SPCMapDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>

// Configurable properties
@property (nonatomic, weak) NSObject<SPCMapDataSourceDelegate> *delegate;
@property (nonatomic, assign) StackedVenueType stackedVenueType;
@property (nonatomic, assign) InfoWindowType infoWindowType;
@property (nonatomic, assign) MapMarkerStyle mapMarkerStyle;
@property (nonatomic, strong) NSString * infoWindowConfirmationText;
@property (nonatomic, strong) NSString * infoWindowSelectText;
@property (nonatomic, assign) int zIndexCurrent;
@property (nonatomic, assign) int zIndexDevice;
@property (nonatomic, assign) int zIndexVenue;

@property (nonatomic, assign) CGFloat deviceVenueAlpha;

// Read-only properties
@property (nonatomic, strong, readonly) NSArray *venues;
@property (nonatomic, strong, readonly) NSArray *venueStack;

@property (nonatomic, strong, readonly) NSArray *stackedVenues;
@property (nonatomic, strong, readonly) NSArray *stackedVenueMarkers;

@property (nonatomic, strong, readonly) Venue *currentVenue;
@property (nonatomic, strong, readonly) Venue *deviceVenue;
@property (nonatomic, strong, readonly) SPCMarker *currentVenueMarker;
@property (nonatomic, strong, readonly) SPCMarker *deviceVenueMarker;
@property (nonatomic, assign, readonly) NSInteger currentVenueStack;
@property (nonatomic, assign, readonly) NSInteger deviceVenueStack;

@property (nonatomic, strong, readonly) SPCMarker *deviceLocationMarker;
@property (nonatomic, strong, readonly) SPCMarker *deviceLocationCurrentMarker;

@property (nonatomic, strong, readonly) SPCMarker *locationMarker;

+ (BOOL) venue:(Venue *)venue is:(Venue *)venue2;
+ (BOOL) venue:(Venue *)venue isIdenticalTo:(Venue *)venue2;

- (BOOL)setAsVenueStacksWithVenues:(NSArray *)venues atCurrentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue;

- (SPCMarker *)markerWithStackAtVenue:(Venue *)venue;
- (SPCMarker *)markerWithStackAtCurrentVenue:(Venue *)venue;
- (SPCMarker *)markerWithStackAtDeviceVenue:(Venue *)venue;
- (SPCMarker *)markerWithStackAtDeviceAndCurrentVenue:(Venue *)venue;

- (void)configureMarker:(SPCMarker *)marker withStackAtVenue:(Venue *)venue reposition:(BOOL)reposition;
- (void)configureMarker:(SPCMarker *)marker withStackAtCurrentVenue:(Venue *)venue reposition:(BOOL)reposition;
- (void)configureMarker:(SPCMarker *)marker withStackAtDeviceVenue:(Venue *)venue reposition:(BOOL)reposition;
- (void)configureMarker:(SPCMarker *)marker withStackAtDeviceAndCurrentVenue:(Venue *)venue reposition:(BOOL)reposition;

- (CGFloat)infoWindowHeightForMarker:(SPCMarker *)marker mapView:(GMSMapView *)mapView;
- (UIView *)getInfoWindowForMarker:(SPCMarker *)marker mapView:(GMSMapView *)mapView;
- (void)refreshInfoWindowForMarker:(SPCMarker *)marker;

@end
