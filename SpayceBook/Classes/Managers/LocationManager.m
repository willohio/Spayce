//
//  LocationManager.m
//  SpayceBook
//
//  Created by Dmitry Miller on 8/9/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "LocationManager.h"
#import "Flurry.h"

// Model
#import "SPCWander.h"

// General
#import "Constants.h"
#import "Singleton.h"

// Manager
#import "AuthenticationManager.h"

// Utility
#import "APIService.h"

#define STABLE_LOCATION_RADIUS 6

#define WALKABOUT_ON NO
#define WALKABOUT_LAT 37.7952788
#define WALKABOUT_LNG -122.4304724

NSString * kLocationManagerDidUpdateLocationNotification = @"LocationManagerDidUpdateLocationNotification";
NSString * kLocationManagerDidFailNotification = @"LocationManagerDidFailNotification";
NSString * SPCLocationManagerDidUpdateDeviceLocation = @"SPCLocationManagerDidUpdateDeviceLocation";
NSString * SPCLocationManagerDidUpdateManualLocation = @"SPCLocationManagerDidUpdateManualLocation";

NSInteger const kChangeInMeters = 20;

@interface LocationManager()

@property (nonatomic, strong) CLLocation *currentLocationWhenManualLocationSelected;

@property (nonatomic, strong) SPCWander *wander;
@property (nonatomic, strong) NSTimer *wanderTimer;

@property (nonatomic, strong) Venue *tempMemVenue;

@property (nonatomic, assign) NSTimeInterval screenTurnedOnAtTime;
@property (nonatomic, assign) NSTimeInterval locationUpdateReceivedAtTime;

-(void)informListenersDidGetLocationWithLatitude:(double)gpsLat longitude:(double)gpsLng;
-(void)informListenersDidFailLocationWithError:(NSError *)error;

@end

@implementation LocationManager {
    CLLocationManager *locationManager;
    BOOL shouldMonitorLocation;
    LocationMonitorWithCallbacks *currentLocationMonitor;
    LocationMonitorWithCallbacks *informListenersLocationMonitor;
    NSMutableArray *listeners;
    
    NSMutableArray *uptimeMonitors;
}

@synthesize manualVenue = _manualVenue;

#pragma mark - Object lifecycle

- (void)dealloc {
    if (self.wanderTimer) {
        [self.wanderTimer invalidate];
        self.wanderTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

SINGLETON_GCD(LocationManager);

- (id)init
{
    self = [super init];

    if (self != nil) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        //NSLog(@"real location manager %@ initialized", locationManager);
        
        // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            NSLog(@"request when in use authorization");
            [locationManager requestWhenInUseAuthorization];
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = kChangeInMeters;
        locationManager.pausesLocationUpdatesAutomatically = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAuthenticationSuccess:)
                                                     name:kAuthenticationDidFinishWithSuccessNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLogout:)
                                                     name:kAuthenticationDidLogoutNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        
        
        // Restrict location services to authorized state only
        // User has accepted location services permissions dialog
        if ([CLLocationManager locationServicesEnabled] &&
            ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
            //NSLog(@"startUpdatingLocation of real manager in init");
            [locationManager startUpdatingLocation];
        }
        
        if (locationManager.location){
            self.currentLocation = locationManager.location;
            self.spayceMeetLocation = self.currentLocation;
            [[NSNotificationCenter defaultCenter] postNotificationName:SPCLocationManagerDidUpdateDeviceLocation object:nil];
            [self sendLocationData];
        } else {
            //init currentLocation with placeholder values to avoid crash
            self.currentLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
            self.spayceMeetLocation = self.currentLocation;
        }
        
        
        __weak typeof(self) weakSelf = self;
        __weak typeof(locationManager) weakLocationManager = locationManager;
        informListenersLocationMonitor = [[LocationMonitorWithCallbacks alloc] init];
        informListenersLocationMonitor.reusable = YES;
        informListenersLocationMonitor.stopMonitorUpdates = YES;
        informListenersLocationMonitor.didGetLocationCallback = ^(double lat, double lng) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakLocationManager) strongLocationManager = weakLocationManager;
            if (!strongSelf) {
                return;
            }
            
            if (WALKABOUT_ON) {
                CLLocationCoordinate2D location = CLLocationCoordinate2DMake(lat, lng);
                if (!strongSelf.wander) {
                    strongSelf.wander = [[SPCWander alloc] initWithLocation:CLLocationCoordinate2DMake(WALKABOUT_LAT, WALKABOUT_LNG) realLocation:location];
                } else {
                    //NSLog(@"Setting real location within callback");
                    strongSelf.wander.realLocation = location;
                }
                CLLocationCoordinate2D coord = strongSelf.wander.location;
                lat = coord.latitude;
                lng = coord.longitude;
            }
            
            BOOL spoofLoc = [[NSUserDefaults standardUserDefaults] boolForKey:@"spoofOn"];
            
            if (spoofLoc) {
                
                NSString *spoofLatStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"spoofLatStr"];
                NSString *spoofLongStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"spoofLongStr"];
                
                lat = [spoofLatStr floatValue];
                lng = [spoofLongStr floatValue];
                NSLog(@"spoofing on!  spoof lat %f, spoof long %f",lat,lng);
            }
          
            // Force the application location manager to update its location
            //NSLog(@"startUpdatingLocation of real manager in informListenersLocationMonitor callback");
            [strongLocationManager startUpdatingLocation];
            
            [strongSelf informListenersDidGetLocationWithLatitude:lat longitude:lng];
        };
        
        informListenersLocationMonitor.didFailLocationCallback = ^(NSError * fault) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakLocationManager) strongLocationManager = weakLocationManager;
            if (!strongSelf) {
                return;
            }
            
            // Force the application location manager to stop updating its location
            NSLog(@"stopUpdatingLocation of real manager in informListenersLocationMonitorCallback");
            [strongLocationManager stopUpdatingLocation];
            strongSelf.locationUpdateReceivedAtTime = 0;
            
            [strongSelf informListenersDidFailLocationWithError:fault];
        };
        
        listeners = [[NSMutableArray alloc] init];
        
        if (WALKABOUT_ON) {
            self.wanderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(wanderTimerDidTrigger) userInfo:nil repeats:YES];
        }
    }

    return self;
}

-(void)requestSystemAuthorization {
    //ios 8
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
    //ios 7
    else {
        [locationManager startUpdatingLocation];
    }
}

#pragma mark - Location services

- (void)enableLocationServicesWithCompletionHandler:(void (^)(NSError *error))completionHandler {
    currentLocationMonitor = [[LocationMonitorWithCallbacks alloc] init];
    
    CLLocationManager *manager = [[CLLocationManager alloc] init];
    manager.delegate = currentLocationMonitor;
    
    __weak typeof(locationManager) weakLocationManager = locationManager;
    
    currentLocationMonitor.didGetLocationCallback = ^(double lat, double lng) {
        __strong typeof(weakLocationManager) strongLocationManager = weakLocationManager;
        [manager stopUpdatingLocation];
        
        CLLocation *location = manager.location;
        [Flurry setLatitude:location.coordinate.latitude longitude:location.coordinate.longitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy];
        
        // Force the application location manager to update it's location
        [strongLocationManager startUpdatingLocation];
        
        if (completionHandler) {
            completionHandler(nil);
        }
    };
    
    currentLocationMonitor.didFailLocationCallback = ^(NSError * fault) {
        [manager stopUpdatingLocation];
        
        if (completionHandler) {
            completionHandler(fault);
        }
    };
    
    [manager startUpdatingLocation];
}

#pragma mark - Location manager delegate

- (void)wanderTimerDidTrigger {
    if (self.wander) {
        CLLocationCoordinate2D coord = self.wander.location;
        CLLocation * location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
        [self updateLocation:location isReal:NO];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self updateLocation:locations.lastObject isReal:YES];
}

-(void) updateLocation:(CLLocation *)location isReal:(BOOL)real
{
    /*
    if (self.currentLocation) {
        NSLog(@"updateLocation %f, %f moved %f", location.coordinate.latitude, location.coordinate.longitude,
              [location distanceFromLocation:self.currentLocation]);
    } else {
        NSLog(@"updateLocation %f, %f", location.coordinate.latitude, location.coordinate.longitude);
    }
     */
    
    if (self.locationUpdateReceivedAtTime == 0) {
        self.locationUpdateReceivedAtTime = [[NSDate date] timeIntervalSince1970];
    }
    
    //NSLog(@"uptime is %f", self.uptime);
    
    if (WALKABOUT_ON && real) {
        if (!_wander) {
            _wander = [[SPCWander alloc] initWithLocation:CLLocationCoordinate2DMake(WALKABOUT_LAT, WALKABOUT_LNG) realLocation:location.coordinate];
        } else {
            //NSLog(@"Setting real location within updateLocation call");
            self.wander.realLocation = location.coordinate;
        }
        CLLocationCoordinate2D coord = self.wander.location;
        location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    }
    BOOL spoofLoc = [[NSUserDefaults standardUserDefaults] boolForKey:@"spoofOn"];
    
    if (spoofLoc) {
 
        NSString *spoofLatStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"spoofLatStr"];
        NSString *spoofLongStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"spoofLongStr"];
        
        float spoofLat = [spoofLatStr floatValue];
        float spoofLong = [spoofLongStr floatValue];
        
        NSLog(@"spoofing on!  spoof lat %f, spoof long %f",spoofLat,spoofLong);
        location = [[CLLocation alloc] initWithLatitude:spoofLat longitude:spoofLong];
    }
    
    
    if (!self.currentLocation || self.currentLocation.coordinate.latitude != location.coordinate.latitude ||
        self.currentLocation.coordinate.longitude != location.coordinate.longitude)
    {
        if (self.currentLocation) {
            
            CLLocationDistance meters = [location distanceFromLocation:self.currentLocation];
            if (meters < kChangeInMeters) {
                //NSLog(@"hasn't moved 20 meters");
                return;
            }
            //once a location is established, only send location data if the user has moved
            else {
                self.currentLocation = location;
                [self sendLocationData];
            }
        }
        //if no location data exists, send the location data
        else {
            self.currentLocation = location;
            [self sendLocationData];
        }
   }
    
}

- (void)sendLocationData
{
    //NSLog(@"sendLocationData called");
    if ([AuthenticationManager sharedInstance].currentUser != nil)
    {
        [Flurry setLatitude:self.currentLocation.coordinate.latitude
                  longitude:self.currentLocation.coordinate.longitude
         horizontalAccuracy:self.currentLocation.horizontalAccuracy
           verticalAccuracy:self.currentLocation.verticalAccuracy];

        NSDate *date = [NSDate date];
        NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
        NSInteger currentGMTOffset = [currentTimeZone secondsFromGMTForDate:date];
        
        NSDictionary *params = @{
                                 @"latitude": @(self.currentLocation.coordinate.latitude),
                                 @"longitude": @(self.currentLocation.coordinate.longitude),
                                 @"gmtOffset": @(currentGMTOffset)
                                 };
        //NSLog(@"sendLocationData params: %@", params);

        [APIService makeApiCallWithMethodUrl:@"/location/updateV2"
                              andRequestType:RequestTypePost
                               andPathParams:nil
                              andQueryParams:params
                              resultCallback:^(NSObject *result) {
                                  //NSLog(@"Here");
                              } faultCallback:^(NSError *fault) {
                                  //do nothing
                                  //NSLog(@"send location fault");
                              }];

        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidUpdateLocationNotification
                                                            object:nil
                                                          userInfo:params];
    }
}

- (void)resetCurrentLocationWithResultCallback:(void (^)(double gpsLat, double gpsLong))resultCallback
                                 faultCallback:(void (^)(NSError * fault))faultCallback {
    __weak typeof(self) weakSelf = self;
    [self getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
        if (resultCallback) {
            resultCallback(gpsLat, gpsLong);
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        // update manual and current
        [strongSelf updateManualLocationWithVenue:nil sendNotification:NO];
        strongSelf.currentLocation = nil;
        [strongSelf updateLocation:[[CLLocation alloc] initWithLatitude:gpsLat longitude:gpsLong] isReal:NO];
        // not real; we've already adjusted the result to account for wandering.
    } faultCallback:^(NSError *fault) {
        if (faultCallback) {
            faultCallback(fault);
        }
        // meh... just reset manual location
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.manualVenue = nil;
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager didFailWithError: %@",error);
    if (error.code == kCLErrorDenied) {
        NSLog(@"locationManager denied");
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location Disabled", nil)
                                    message:NSLocalizedString(@"Spayce functionality will be limited with location services off.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationManagerDidFailNotification object:nil];
    }
}

#pragma mark Property accessors / Mutators


- (NSTimeInterval)uptime {
    
    if (self.screenTurnedOnAtTime == 0) {
        self.screenTurnedOnAtTime = [[NSDate date] timeIntervalSince1970];
    }
    
    if (self.screenTurnedOnAtTime == 0 || self.locationUpdateReceivedAtTime == 0) {
        return 0;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval zero = 0L;
    return MAX(zero, MIN(now - self.screenTurnedOnAtTime, now - self.locationUpdateReceivedAtTime));
}

- (void)setScreenTurnedOnAtTime:(NSTimeInterval)screenTurnedOnAtTime {
    _screenTurnedOnAtTime = screenTurnedOnAtTime;
    [self cancelUptimeMonitors];
}

- (void)setLocationUpdateReceivedAtTime:(NSTimeInterval)locationUpdateReceivedAtTime {
    _locationUpdateReceivedAtTime = locationUpdateReceivedAtTime;
    [self cancelUptimeMonitors];
}

- (CLLocation *)locationInUse {
    if (self.userHasManuallySelectedLocation) {
        return self.manualLocation;
    } else {
        return self.currentLocation;
    }
}

- (CLLocation *)currentStableLocation {
    @synchronized(self) {
        if ([self currentStableLocationNeedsUpdate]) {
            _currentStableLocation = _currentLocation;
        }
        return _currentStableLocation;
    }
}

- (BOOL)currentStableLocationNeedsUpdate {
    if (!_currentStableLocation) {
        return YES;
    }
    if (!_currentLocation) {
        return NO;
    }
    return [_currentLocation distanceFromLocation:_currentStableLocation] > STABLE_LOCATION_RADIUS;
}

- (void)setManualLocation:(CLLocation *)manualLocation {
    [self updateManualLocation:manualLocation sendNotification:YES];
}

- (void)updateManualLocation:(CLLocation *)manualLocation {
    [self updateManualLocation:manualLocation sendNotification:YES];
}

- (void)updateManualLocation:(CLLocation *)manualLocation sendNotification:(BOOL)sendNotification {
    //NSLog(@"manual location established");
    _manualLocation = manualLocation;
    _currentLocationWhenManualLocationSelected = _currentLocation;
    _userManuallySelectedLocation = nil != manualLocation;
}

- (void)setManualVenue:(Venue *)manualVenue {
    [self updateManualLocationWithVenue:manualVenue sendNotification:YES];
}

- (void)updateManualLocationWithVenue:(Venue *)manualVenue {
    [self updateManualLocationWithVenue:manualVenue sendNotification:YES];
}

- (void)updateManualLocationWithVenue:(Venue *)manualVenue sendNotification:(BOOL)sendNotification {
    //NSLog(@"manual location established by venue");
    if (manualVenue) {
        _manualLocation = [[CLLocation alloc] initWithLatitude:[manualVenue.latitude floatValue] longitude:[manualVenue.longitude floatValue]];
        _currentLocationWhenManualLocationSelected = _currentLocation;
        _userManuallySelectedLocation = YES;
        _manualVenue = manualVenue;
    } else {
        [self updateManualLocation:nil sendNotification:sendNotification];
    }
}

- (Venue*)manualVenue {
    if (self.userManuallySelectedLocation) {
        return _manualVenue;
    }
    return nil;
}

- (BOOL)userHasManuallySelectedLocation {
    return self.userManuallySelectedLocation;
}

- (void)setUserManuallySelectedLocation:(BOOL)didManuallySelect {
    if (!didManuallySelect) {
        [self updateManualLocation:nil];
    }
}

- (CLLocation *)tempMemLocation {
    if (self.userHasTempSelectedLocation) {
        return self.tempMemVenue.location;
    }
    return nil;
}

- (void)updateTempLocationWithVenue:(Venue *)tempVenue {
    self.tempMemVenue = tempVenue;
    self.userHasTempSelectedLocation = YES;
}

- (void)cancelTempLocation {
    self.userHasTempSelectedLocation = NO;
}

- (BOOL)locServicesAvailable {
    BOOL available = YES;
    
    if (![CLLocationManager locationServicesEnabled]){
        available = NO;
    }
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse){
        available = NO;
    }
    return available;
}

#pragma mark - Actions

- (void)forceBackgroundMonitoringIfApplicable
{
    if (shouldMonitorLocation) {
        NSLog(@"forceBackgroundMonitoring");
        // Restrict location services to authorized state only
        // User has accepted location services permissions dialog
        if ([CLLocationManager locationServicesEnabled] &&
            ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
            NSLog(@"startUpdatingLocation of real manager in forceBackgroundMonitoringIfApplicable");
            [locationManager startUpdatingLocation];
        }
    }
}

- (void)waitForUptime:(NSTimeInterval)uptime
  withSuccessCallback:(void (^)(NSTimeInterval))successCallback
        faultCallback:(void (^)(NSError *))faultCallback {
    if (!self.locServicesAvailable) {
        if (faultCallback) {
            faultCallback(nil);
        }
        return;
    }
    
    NSTimeInterval uptimeNow = self.uptime;
    if (uptimeNow >= uptime) {
        if (successCallback) {
            successCallback(uptimeNow);
        }
        return;
    }
    
    // start an update listener with an alarm scheduled to go off in
    // uptime - uptimeNow seconds.  It will be canceled if uptime is reset;
    // otherwise, assume everything worked out fine.
    __weak typeof(self) weakSelf = self;
    UptimeMonitorWithCallbacks *uptimeMonitor = [[UptimeMonitorWithCallbacks alloc] initWithCurrentUptime:uptimeNow goalUptime:uptime];
    uptimeMonitor.didReachUptimeGoalCallback = successCallback;
    uptimeMonitor.didCancelCallback = faultCallback;
    __weak typeof(uptimeMonitor) weakUptimeMonitor = uptimeMonitor;
    uptimeMonitor.didFinishCallback = ^() {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakUptimeMonitor) strongUptimeMonitor = weakUptimeMonitor;
        if (strongSelf && strongUptimeMonitor) {
            [strongSelf popUptimeMonitor:strongUptimeMonitor];
        }
    };
    [self pushAndStartUptimeMonitor:uptimeMonitor];
}

- (void)pushAndStartUptimeMonitor:(UptimeMonitorWithCallbacks *)uptimeMonitor {
    @synchronized(uptimeMonitors) {
        [uptimeMonitors addObject:uptimeMonitor];
        [uptimeMonitor start];
    }
}

- (BOOL)popUptimeMonitor:(UptimeMonitorWithCallbacks *)uptimeMonitor {
    @synchronized(uptimeMonitors) {
        if ([uptimeMonitors containsObject:uptimeMonitor]) {
            [uptimeMonitors removeObject:uptimeMonitor];
            return YES;
        }
    }
    return NO;
}

- (void)cancelUptimeMonitors {
    NSArray *monitors;
    @synchronized(uptimeMonitors) {
        monitors = [NSArray arrayWithArray:uptimeMonitors];
        [uptimeMonitors removeAllObjects];
    }
    [monitors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UptimeMonitorWithCallbacks *uptimeMonitor = obj;
        [uptimeMonitor cancel];
    }];
}

- (void)getCurrentLocationWithResultCallback:(void (^)(double, double))resultCallback
                               faultCallback:(void (^)(NSError *))faultCallback
{
    CLLocationManager *manager = [[CLLocationManager alloc] init];
    manager.delegate = informListenersLocationMonitor;
    
    // Restrict location services to authorized state only
    // User has accepted location services permissions dialog
    if ([CLLocationManager locationServicesEnabled] &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        // add listener
        LocationMonitorWithCallbacks * listener = [[LocationMonitorWithCallbacks alloc] initWithStrongReferenceUntilCallback:manager];
        
        listener.didGetLocationCallback = resultCallback;
        listener.didFailLocationCallback = faultCallback;
        [self pushListener:listener];
        [manager startUpdatingLocation];
    }
    else {
        // We have to make sure to call error handler if location services are not authorized
        // in order to propagate error up the responder chain and toggle back the state of
        // respectitive view controllers
        if (faultCallback) {
            faultCallback(nil);
        }
    }
}

-(void)pushListener:(LocationMonitorWithCallbacks *)locationMonitorWithCallbacks {
    @synchronized(listeners) {
        [listeners addObject:locationMonitorWithCallbacks];
    }
}

-(NSArray *)popListeners {
    NSArray * localListeners;
    @synchronized(listeners) {
        localListeners = [NSArray arrayWithArray:listeners];
        [listeners removeAllObjects];
    }
    return localListeners;
}

-(void)informListenersDidGetLocationWithLatitude:(double)gpsLat longitude:(double)gpsLng {
    // Exactly one callback per listener.
    NSArray * myListeners = [self popListeners];
    for (LocationMonitorWithCallbacks * monitor in myListeners) {
        if (monitor.didGetLocationCallback) {
            monitor.didGetLocationCallback(gpsLat, gpsLng);
        }
        monitor.didGetLocationCallback = nil;
        monitor.didFailLocationCallback = nil;
    }
}

-(void)informListenersDidFailLocationWithError:(NSError *)error {
    // Exactly one callback per listener.
    NSArray * myListeners = [self popListeners];
    for (LocationMonitorWithCallbacks * monitor in myListeners) {
        if (monitor.didFailLocationCallback) {
            monitor.didFailLocationCallback(error);
        }
        monitor.didGetLocationCallback = nil;
        monitor.didFailLocationCallback = nil;
    }
}

- (void)cancelHiSpeed {

}

#pragma mark - Handle notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.screenTurnedOnAtTime == 0) {
        self.screenTurnedOnAtTime = [[NSDate date] timeIntervalSince1970];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (self.screenTurnedOnAtTime == 0) {
        self.screenTurnedOnAtTime = [[NSDate date] timeIntervalSince1970];
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    self.screenTurnedOnAtTime = 0;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    self.screenTurnedOnAtTime = 0;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    self.screenTurnedOnAtTime = 0;
}


- (void)handleAuthenticationSuccess:(NSNotification *)notification
{
    shouldMonitorLocation = YES;
    //self.hiSpeedModeAvailable = NO;
    //self.hiSpeedModeCancelled = NO;
    //self.hiSpeedCancelledLocation = nil;
    //self.lastHiSpeedLocation = nil;
    //self.initialHiSpeedLocation = nil;
    
    // Restrict location services to authorized state only
    // User has accepted location services permissions dialog
    if ([CLLocationManager locationServicesEnabled] &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        //NSLog(@"startUpdatingLocation of real location manager in handleAuthenticationSuccess");
        [locationManager startUpdatingLocation];
    }
    //NSLog(@"shouldMonitorLocation");
}

- (void)handleLogout:(NSNotification *)notification
{
    shouldMonitorLocation = NO;
    //self.hiSpeedModeAvailable = NO;
    //self.hiSpeedModeCancelled = NO;
    //self.hiSpeedCancelledLocation = nil;
    //self.lastHiSpeedLocation = nil;
    //self.initialHiSpeedLocation = nil;
    
    //NSLog(@"stopUpdatingLocation of real manager in handleLogout");
    [locationManager stopUpdatingLocation];
    self.locationUpdateReceivedAtTime = 0;
    //NSLog(@"shouldMonitorLocation - NO (on logout)");
}


@end



@interface UptimeMonitorWithCallbacks()

@property (nonatomic, assign) NSTimeInterval uptimeInitial;
@property (nonatomic, assign) NSTimeInterval uptimeGoal;
@property (nonatomic, assign) BOOL isStarted;
@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, assign) BOOL isSuccessful;

@property (nonatomic, assign) NSTimer *timer;

@end


@implementation UptimeMonitorWithCallbacks

- (instancetype) initWithCurrentUptime:(NSTimeInterval)currentUpdate goalUptime:(NSTimeInterval)goalUptime {
    self = [super init];
    if (self) {
        _uptimeInitial = currentUpdate;
        _uptimeGoal = goalUptime;
        _isStarted = _isFinished = _isSuccessful = NO;
    }
    return self;
}

- (void)start {
    if (self.isStarted) {
        [NSException raise:@"Already started UptimeMonitor" format:@"This uptime monitor waiting until %f has already been started", self.uptimeGoal];
    }
    
    _isStarted = YES;
    _timer = [NSTimer scheduledTimerWithTimeInterval:(_uptimeGoal - _uptimeInitial) target:self selector:@selector(didReachUptimeGoal) userInfo:nil repeats:NO];
}

- (void)cancel {
    if (!self.isStarted) {
        [NSException raise:@"Never started UptimeMonitor" format:@"This uptime monitor waiting until %f has never been started", self.uptimeGoal];
    }
    
    @synchronized(self) {
        if (self.isFinished) {
            return;
        }
        _isFinished = YES;
    }
    
    [_timer invalidate];
    if (self.didCancelCallback) {
        self.didCancelCallback(nil);
    }
}

- (void)didReachUptimeGoal {
    @synchronized(self) {
        if (self.isFinished) {
            return;
        }
        _isFinished = YES;
        _isSuccessful = YES;
    }
    
    [_timer invalidate];
    if (self.didFinishCallback) {
        self.didFinishCallback();
    }
    if (self.didReachUptimeGoalCallback) {
        self.didReachUptimeGoalCallback(self.uptimeGoal);
    }
}

@end


@interface LocationMonitorWithCallbacks()

@property (nonatomic, strong) NSObject *reference;

@end

@implementation LocationMonitorWithCallbacks

#pragma mark - Location manager delegate

- (LocationMonitorWithCallbacks *)init {
    self = [super init];
    if (self) {
        self.reusable = NO;
        self.stopMonitorUpdates = NO;
    }
    return self;
}

- (LocationMonitorWithCallbacks *)initWithStrongReferenceUntilCallback:(NSObject *)reference {
    self = [self init];
    if (self) {
        self.reference = reference;
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.reference = nil;
    
    CLLocation *location = (CLLocation *)locations.lastObject;
    
    if (self.didGetLocationCallback) {
        self.didGetLocationCallback(location.coordinate.latitude, location.coordinate.longitude);
        if (!self.reusable) {
            self.didGetLocationCallback = nil;
            self.didFailLocationCallback = nil;
        }
    }
    
    if (self.stopMonitorUpdates) {
        [manager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    self.reference = nil;
    
    if (self.didFailLocationCallback) {
        self.didFailLocationCallback(error);
        if (!self.reusable) {
            self.didGetLocationCallback = nil;
            self.didFailLocationCallback = nil;
        }
    }

    if (self.stopMonitorUpdates) {
        [manager stopUpdatingLocation];
    }
}

@end


