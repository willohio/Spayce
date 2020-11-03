//
//  LocationManager.h
//  SpayceBook
//
//  Created by Dmitry Miller on 8/9/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "Venue.h"

@class LocationMonitorWithCallbacks;

extern NSString * kLocationManagerDidUpdateLocationNotification;
extern NSString * kLocationManagerDidFailNotification;
extern NSString * SPCLocationManagerDidUpdateDeviceLocation;
extern NSString * SPCLocationManagerDidUpdateManualLocation;

@interface LocationManager : NSObject <CLLocationManagerDelegate>

+ (LocationManager *)sharedInstance;

@property (nonatomic, readonly) CLLocation *locationInUse;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocation *currentStableLocation;
@property (nonatomic, strong) CLLocation *manualLocation;
@property (nonatomic, strong) CLLocation *spayceMeetLocation;
@property (nonatomic, assign) BOOL userManuallySelectedLocation;
@property (nonatomic, strong) Venue *manualVenue;
@property (nonatomic, readonly) Venue *tempMemVenue;
@property (nonatomic, readonly) CLLocation *tempMemLocation;


/* The time the location manager has been receiving uninterupted location updates.
    Will be 0 at all times when location is disabled, and will begin counting upward
    from 0 when the device is reactivated after a break or when the LocationManager is
    first initialized. */
@property (nonatomic, readonly) NSTimeInterval uptime;

@property (nonatomic, assign) BOOL userHasTempSelectedLocation; //occurs when user changes location in MAM before posting a mem

- (void)enableLocationServicesWithCompletionHandler:(void (^)(NSError *error))completionHandler;

- (void)waitForUptime:(NSTimeInterval)uptime
  withSuccessCallback:(void (^)(NSTimeInterval))successCallback
        faultCallback:(void (^)(NSError *))faultCallback;

- (void)sendLocationData;
- (void)resetCurrentLocationWithResultCallback:(void (^)(double gpsLat, double gpsLong))resultCallback
                                 faultCallback:(void (^)(NSError * fault))faultCallback;
- (void)forceBackgroundMonitoringIfApplicable;
- (void)getCurrentLocationWithResultCallback:(void (^)(double gpsLat, double gpsLong))resultCallback
                               faultCallback:(void (^)(NSError * fault))faultCallback;
- (void)updateManualLocation:(CLLocation *)manualLocation;
- (void)updateManualLocationWithVenue:(Venue *)manualVenue;
- (void)updateTempLocationWithVenue:(Venue *)tempVenue;
- (void)cancelTempLocation;
- (BOOL)locServicesAvailable;
- (BOOL)userHasManuallySelectedLocation;
- (void)cancelHiSpeed;
- (void)requestSystemAuthorization;
@end




@interface UptimeMonitorWithCallbacks : NSObject

@property (nonatomic, readonly) NSTimeInterval uptimeInitial;
@property (nonatomic, readonly) NSTimeInterval uptimeGoal;
@property (nonatomic, readonly) BOOL isStarted;
@property (nonatomic, readonly) BOOL isFinished;
@property (nonatomic, readonly) BOOL isSuccessful;

@property (copy, nonatomic) void (^didReachUptimeGoalCallback)(NSTimeInterval uptimeGoal);
@property (copy, nonatomic) void (^didCancelCallback)(NSError * fault);
@property (copy, nonatomic) void (^didFinishCallback)();

- (instancetype) initWithCurrentUptime:(NSTimeInterval)currentUpdate goalUptime:(NSTimeInterval)goalUptime;
- (void)start;
- (void)cancel;

@end



@interface LocationMonitorWithCallbacks : NSObject <CLLocationManagerDelegate>

@property (nonatomic, assign) BOOL reusable;
@property (nonatomic, assign) BOOL stopMonitorUpdates;

@property (copy, nonatomic) void (^didGetLocationCallback)(double gpsLat, double gpsLong);
@property (copy, nonatomic) void (^didFailLocationCallback)(NSError * fault);

-(instancetype) initWithStrongReferenceUntilCallback:(NSObject *)reference;


@end