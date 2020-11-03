//
//  SPCLocationPromptViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 10/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCLocationPromptViewController.h"

#import "SPCInSpaceView.h"
#import "LocationManager.h"
#import <AVFoundation/AVFoundation.h>

@interface SPCLocationPromptViewController ()

@property (nonatomic, strong) SPCInSpaceView *spaceView;
@property (nonatomic, assign) BOOL isActiveTab;
@property (nonatomic, strong) UIView *locationPromptView;
@end

@implementation SPCLocationPromptViewController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBar.hidden = YES;
    
    [self.view addSubview:self.locationPromptView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isActiveTab = YES;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.isActiveTab = NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}


#pragma mark - Accessors

- (SPCInSpaceView *)spaceView {
    
    if (!_spaceView) {
        _spaceView = [[SPCInSpaceView alloc] initWithFrame:self.view.frame];
    }
    return _spaceView;
}

- (UIView *)locationPromptView {
    
    if (!_locationPromptView) {
        _locationPromptView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        _locationPromptView.backgroundColor = [UIColor whiteColor];
        
        UILabel *promptLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, (self.view.bounds.size.height - 77)/2 - 55, self.view.bounds.size.width, 40)];
        promptLbl.text = @"Spayce requires location to anchor \nyour memories in place.";
        promptLbl.textAlignment = NSTextAlignmentCenter;
        promptLbl.numberOfLines = 0;
        promptLbl.lineBreakMode = NSLineBreakByWordWrapping;
        promptLbl.font = [UIFont spc_regularSystemFontOfSize:14];
        promptLbl.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        [_locationPromptView addSubview:promptLbl];
        
        UIButton *locationBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 210)/2, CGRectGetMaxY(promptLbl.frame) + 20, 210, 40)];
        [locationBtn setTitle:@"Turn On Location" forState:UIControlStateNormal];
        locationBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        [locationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [locationBtn setBackgroundColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f]];
        locationBtn.layer.cornerRadius = 20;
        [locationBtn addTarget:self action:@selector(showLocationPrompt:) forControlEvents:UIControlEventTouchUpInside];
        [_locationPromptView addSubview:locationBtn];
        
    }
    return _locationPromptView;
}


#pragma mark - App Became Active

-(void)applicationDidBecomeActive:(id)sender {

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if ([[LocationManager sharedInstance] locServicesAvailable]) {
            if (self.isActiveTab) {
                
                
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        // Permission has been granted. Use dispatch_async for any UI updating
                        // code because this block may be executed in a thread.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"jumpToHere" object:nil];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"handleMAM" object:nil];

                        });
                    } else {
                        // Permission has been denied.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"jumpToHere" object:nil];
                            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera Access Disabled", nil)
                                                        message:NSLocalizedString(@"Spayce functionality will be limited without access to the camera. Please go to Settings > Privacy > Camera > and turn on Spayce", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil] show];
                        });
                        
                    }
                }];
            }
            else {
                NSLog(@"not active tab");
            }
        }
    }

}

-(void)showLocationPrompt:(id)sender {
    
    BOOL hasShownSystemPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:@"systemHasShownLocationPrompts"];
    
    if (!hasShownSystemPrompt && [CLLocationManager locationServicesEnabled]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"systemHasShownLocationPrompts"];
        [[LocationManager sharedInstance] requestSystemAuthorization];
    }
    else if (!hasShownSystemPrompt && ![CLLocationManager locationServicesEnabled]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
    else {
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services for the \"Spayce\" app", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

@end
