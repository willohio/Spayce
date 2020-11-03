//
//  AppDelegate.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <GooglePlus/GooglePlus.h>

#import "AppDelegate.h"
#import "SPCMainViewController.h"
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "PNSManager.h"
#import "SettingsManager.h"
#import "LocationManager.h"
#import "AppSettings.h"
#import <FacebookSDK/FacebookSDK.h>
#import "SPCLiterals.h"
#import "SocialService.h"
#import "DZNSegmentedControl.h"
#import <GoogleMaps/GoogleMaps.h>
#import "MeetManager.h"
#import "SPCMessageManager.h"
#import "FICPhoto.h"
#import "Flurry.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


static NSString *const kGaPropertyId = @"UA-59208347-1";
static int const kGaDispatchPeriod = 20;
static BOOL const kGaDryRun = NO;  //SET TO NO TO ACTIVATE Google Analytics reporting for staging!

@interface AppDelegate ()

@property (nonatomic, strong) SPCMainViewController *mainViewController;
@property (strong, nonatomic) id<GAITracker> tracker;

@end

@implementation AppDelegate

#pragma mark - UIApplicationDelegate - Monitoring App State Changes

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:@"3G3DTPPSZC4MVMRHGM63"];
    
    [GMSServices provideAPIKey:@"AIzaSyB8R9Cwfik880qw0f4PbNcC23wLdkPx4fc"];

    [self initializeGoogleAnalytics];
    
    [Fabric with:@[CrashlyticsKit]]; // Must be the last-initialized 3rd-party SDK
    
    // Load settings and check for force update or nag update
    [[AppSettings sharedInstance] loadAndCheckForUpdate];

    [self setupImageCache];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor colorWithRGBHex:0x1D1D1F];
    self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
    
    // Appearance
    [self initializeAppearance];

    // Apple Push Notification Service
    [PNSManager sharedInstance];
    
    //check to see if we already have permission for pns
    if ([self havePermissionForPNS]) {
        NSLog(@"have notification permisssion already!");
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [application registerForRemoteNotifications];
        } else  {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
        }
    }

    // Managers
    [SettingsManager sharedInstance];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [LocationManager sharedInstance];
        
        if (launchOptions[UIApplicationLaunchOptionsLocationKey]) {
            [[LocationManager sharedInstance] forceBackgroundMonitoringIfApplicable];
        }
    }
    [SocialService sharedInstance];
    [MeetManager sharedInstance];
    [ContactAndProfileManager sharedInstance];
    [SPCMessageManager sharedInstance];

    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        NSMutableDictionary *mutableUserInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
        mutableUserInfo[@"launchedFromOutsideApp"] = @YES;
        
        [[PNSManager sharedInstance] scheduleRemoteNotificationOnAuthenticationSuccess:mutableUserInfo];
    }

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[SettingsManager sharedInstance] saveSettings];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[SettingsManager sharedInstance] saveSettings];
}


- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame
{
    NSMutableDictionary *statusBarChangeInfo = [[NSMutableDictionary alloc] init];
    [statusBarChangeInfo setObject:@"statusbarchange"
                            forKey:@"frame"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"statusbarchange"
                                                        object:self
                                                      userInfo:statusBarChangeInfo];
}


- (void)application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)newStatusBarFrame {
    NSLog(@"willChangeStatusBarFrame : newSize %f, %f", newStatusBarFrame.size.width, newStatusBarFrame.size.height);
    self.currentStatusBarFrame = newStatusBarFrame;

}


#pragma mark - UIApplicationDelegate - Opening a URL Resource

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSPCKeyGoogleAuthenticationInProgress]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kSPCKeyGoogleAuthenticationInProgress];
        return [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    else {
        return [FBSession.activeSession handleOpenURL:url];
    }
}

#pragma mark - UIApplicationDelegate - Handling Remote Notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    NSLog(@"did register user notification settings!");
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    //NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken");
    
    NSString *tokenStr = [[[[deviceToken description]
                            stringByReplacingOccurrencesOfString:@"<" withString:@""]
                           stringByReplacingOccurrencesOfString:@">" withString:@""]
                          stringByReplacingOccurrencesOfString:@" " withString:@""];

    PNSManager *pnsManager = [PNSManager sharedInstance];
    pnsManager.pnsDeviceToken = tokenStr;
   // NSLog(@"%@",tokenStr);
    
    // If we are already authenticated then register the token right away
    if ([AuthenticationManager sharedInstance].currentUser) {
        [pnsManager registerPnsDeviceToken:pnsManager.pnsDeviceToken
                            resultCallback:^(NSString *pnsDeviceToken) {
                                //do nothing
                                NSLog(@"callback from server that device is registered!");
                                
                            } faultCallback:^(NSError *fault) {
                                [Flurry logError:@"registerPnsDeviceToken" message:@"Failed to register for notifications" error:fault];
                            }];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError error %@",error);
    // Use breakpoint to log
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Use breakpoint to log
    [[NSNotificationCenter defaultCenter] postNotificationName:PNSManagerDidReceiveRemoteNotification object:userInfo];
}

#pragma mark - App Icon Badging

- (BOOL)checkNotificationType:(UIUserNotificationType)type
{
    UIUserNotificationSettings *currentSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    
    return (currentSettings.types & type);
}
-(BOOL)havePermissionForPNS {
    BOOL havePermission = NO;
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        //iOS 8
        if ([self checkNotificationType:UIUserNotificationTypeAlert]) {
            havePermission = YES;
        }
        if ([self checkNotificationType:UIUserNotificationTypeBadge]) {
            havePermission = YES;
        }
        
        if ([self checkNotificationType:UIUserNotificationTypeSound]) {
            havePermission = YES;
        }
        
    }
    else {
        //iOS 7
        havePermission = YES;
    }
    
    return havePermission;
}

#pragma mark - UIApplicationDelegate - Managing the Default Interface Orientations

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Accessors

- (SPCMainViewController *)mainViewController {
    if (!_mainViewController) {
        _mainViewController = [[SPCMainViewController alloc] init];
    }
    return _mainViewController;
}


#pragma mark - GA

- (void)initializeGoogleAnalytics {
    [[GAI sharedInstance] setDispatchInterval:kGaDispatchPeriod];
    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:kGaPropertyId];
    [[GAI sharedInstance] setDryRun:kGaDryRun];
    
    [self.tracker send:[[[GAIDictionaryBuilder createAppView] set:@"App Launch"
                                                      forKey:kGAIScreenName] build]];
}

#pragma mark - Private

- (void)initializeAppearance {
    // UITabBar
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:139.0/255.0 green:154.0/255.0 blue:174.0/255.0 alpha:1.000]];
    [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setShadowImage:[UIImage new]];
    [[UITabBar appearance] setBackgroundImage:[UIImage new]];
    
    // UITabBarItem
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRed:0.578 green:0.587 blue:0.602 alpha:1.000],
                                                         NSFontAttributeName: [UIFont spc_tabBarFont] }
                                             forState:UIControlStateNormal];
    
    // UINavigationBar
    [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor],
                                                            NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:18.0] }];

    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f]];
    
    // UISwitch
    [[UISwitch appearance] setThumbTintColor:[UIColor colorWithRGBHex:0x7c7a72]];
    [[UISwitch appearance] setTintColor:[UIColor blackColor]];
    
    // DZNSegmentedControl
    [[DZNSegmentedControl appearance] setFont:[UIFont spc_segmentedControlFont]];
}

#pragma mark - FastImageCache

- (void)setupImageCache {
    NSMutableArray *mutableImageFormats = [NSMutableArray array];

    // Square image formats...
    NSInteger maximumCount = 400;
    FICImageFormatDevices formatDevices = FICImageFormatDevicePhone | FICImageFormatDevicePad;

    FICImageFormat *squareImageFormatName = [FICImageFormat formatWithName:FICDPhotoSquareImageFormatName
                                                                    family:FICDPhotoImageFormatFamily
                                                                 imageSize:FICDPhotoSquareImageSize style:FICImageFormatStyle32BitBGR
                                                              maximumCount:maximumCount
                                                                   devices:formatDevices
                                                            protectionMode:FICImageFormatProtectionModeNone];
    
    FICImageFormat *squareMediumImageFormatName = [FICImageFormat formatWithName:FICDPhotoSquareMediumImageFormatName
                                                                    family:FICDPhotoImageFormatFamily
                                                                 imageSize:FICDPhotoSquareMediumImageSize style:FICImageFormatStyle32BitBGR
                                                              maximumCount:maximumCount
                                                                   devices:formatDevices
                                                            protectionMode:FICImageFormatProtectionModeNone];
    
    FICImageFormat *xsmallThumbnailFormatName = [FICImageFormat formatWithName:FICDPhotoThumbnailXSmallFormatName
                                                                        family:FICDPhotoImageFormatFamily
                                                                     imageSize:FICDPhotoThumbnailXSmall style:FICImageFormatStyle32BitBGR
                                                                  maximumCount:maximumCount
                                                                       devices:formatDevices
                                                                protectionMode:FICImageFormatProtectionModeNone];
  
    FICImageFormat *smallThumbnailFormatName = [FICImageFormat formatWithName:FICDPhotoThumbnailSmallFormatName
                                                                       family:FICDPhotoImageFormatFamily
                                                                     imageSize:FICDPhotoThumbnailSmall style:FICImageFormatStyle32BitBGR
                                                                  maximumCount:maximumCount
                                                                       devices:formatDevices
                                                                protectionMode:FICImageFormatProtectionModeNone];

    FICImageFormat *mediumThumbnailFormatName = [FICImageFormat formatWithName:FICDPhotoThumbnailMediumFormatName
                                                                        family:FICDPhotoImageFormatFamily
                                                                     imageSize:FICDPhotoThumbnailMedium style:FICImageFormatStyle32BitBGR
                                                                  maximumCount:maximumCount
                                                                       devices:formatDevices
                                                                protectionMode:FICImageFormatProtectionModeNone];

    FICImageFormat *largeThumbnailFormatName = [FICImageFormat formatWithName:FICDPhotoThumbnailLargeFormatName
                                                                       family:FICDPhotoImageFormatFamily
                                                                    imageSize:FICDPhotoThumbnailLarge style:FICImageFormatStyle32BitBGR
                                                                 maximumCount:maximumCount
                                                                      devices:formatDevices
                                                               protectionMode:FICImageFormatProtectionModeNone];

    FICImageFormat *xlargeThumbnailFormatName = [FICImageFormat formatWithName:FICDPhotoThumbnailXLargeFormatName
                                                                        family:FICDPhotoImageFormatFamily
                                                                     imageSize:FICDPhotoThumbnailXLarge style:FICImageFormatStyle32BitBGR
                                                                  maximumCount:maximumCount
                                                                       devices:formatDevices
                                                                protectionMode:FICImageFormatProtectionModeNone];
    
    [mutableImageFormats addObject:xsmallThumbnailFormatName];
    [mutableImageFormats addObject:smallThumbnailFormatName];
    [mutableImageFormats addObject:mediumThumbnailFormatName];
    [mutableImageFormats addObject:largeThumbnailFormatName];
    [mutableImageFormats addObject:xlargeThumbnailFormatName];
    [mutableImageFormats addObject:squareImageFormatName];
    [mutableImageFormats addObject:squareMediumImageFormatName];

    // Configure the image cache
    FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
    [sharedImageCache setDelegate:self];
    [sharedImageCache setFormats:mutableImageFormats];
}

#pragma mark - FICImageCacheDelegate

- (void)imageCache:(FICImageCache *)imageCache wantsSourceImageForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName completionBlock:(FICImageRequestCompletionBlock)completionBlock {
    // Images typically come from the Internet rather than from the app bundle directly, so this would be the place to fire off a network request to download the image.
    // For the purposes of this demo app, we'll just access images stored locally on disk.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *sourceImage = [(FICPhoto *)entity sourceImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(sourceImage);
        });
    });
}

- (BOOL)imageCache:(FICImageCache *)imageCache shouldProcessAllFormatsInFamily:(NSString *)formatFamily forEntity:(id<FICEntity>)entity {
    return NO;
}

- (void)imageCache:(FICImageCache *)imageCache errorDidOccurWithMessage:(NSString *)errorMessage {
    //NSLog(@"%@", errorMessage);
}

@end
