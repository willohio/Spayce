//
//  SPCMAMViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 2/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMAMViewController.h"


// Framework
#import <AVFoundation/AVFoundation.h>
#import "Flurry.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>


// Model
#import "Memory.h"
#import "SPCImageToCrop.h"
#import "Venue.h"
#import "ProfileDetail.h"
#import "User.h"
#import "UserProfile.h"
#import "Person.h"
#import "Asset.h"
#import "Friend.h"

// View
#import "PXAlertView.h"
#import "SPCNavControllerLight.h"
#import "SPCHashTagSuggestions.h"
#import "RadialProgressBarView.h"
#import "UAProgressView.h"
#import "SPCAVPlayerView.h"
#import "AppDelegate.h"
#import "SPCFriendPicker.h"

// Controller
#import "SPCTagFriendsViewController.h"
#import "SPCMAMLocationViewController.h"

// General
#import "SPCLiterals.h"
#import "Constants.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "LocationManager.h"
#import "LocationContentManager.h"
#import "SPCCaptureManager.h"
#import "MeetManager.h"
#import "SettingsManager.h"

// Coordinator
#import "SPCAssetUploadCoordinator.h"

// Utility
#import "ImageUtils.h"
#import "UIColor+Expanded.h"

#define MINIMUM_LOCATION_MANAGER_UPTIME 6
#define CAPTURE_FRAMES_PER_SECOND		20

static NSString *ATTRIBUTE_USERTOKEN = @"ATTRIBUTE_USERTOKEN";
static NSString *ATTRIBUTE_USERID = @"ATTRIBUTE_USERID";
static NSString *ATTRIBUTE_USERNAME = @"ATTRIBUTE_USERNAME";
static NSString *ATTRIBUTE_USERHANDLE = @"ATTRIBUTE_USERHANDLE";

@interface SPCMAMViewController () <SPCTagFriendsViewControllerDelegate, SPCHashTagSuggestionsDelegate, UITextViewDelegate, SPCMAMLocationViewControllerDelegate, SPCCaptureManagerDelegate, SPCAVPlayerViewDelegate, SPCMAMCoachmarkViewDelegate, SPCFriendPickerDelegate>

//Image Capture
@property (nonatomic, strong) UIImagePickerController *spcImagePickerController;
@property (nonatomic, strong) SPCMamCaptureControls *customControls;
@property (nonatomic, assign) BOOL captureIsAdded;
@property (nonatomic, assign) BOOL isFlashOn;
@property (nonatomic, assign) BOOL isFrontFacing;
@property (nonatomic, assign) BOOL cameraIsLocked;
@property (nonatomic, strong) UILabel *processingAsset;
@property (nonatomic, strong) SPCImageToCrop *capturedImage;
@property (nonatomic, strong) UIView *frontFacingFlash;

//Video Capture
//@property (nonatomic, strong) RadialProgressBarView *videoProgress;
@property (nonatomic, strong) SPCCaptureManager *captureManager;
@property (nonatomic, strong) UIImagePickerController *spcVideoPickerController;
@property (nonatomic, strong) UAProgressView *pvCountdown;
@property (nonatomic, assign) BOOL videoCaptureInProgress;
@property (nonatomic, assign) NSInteger videoCaptureCounter;
@property (nonatomic, assign) NSInteger numVideosProcesssing;
@property (nonatomic, assign) BOOL landscapeLeft;
@property (nonatomic, assign) BOOL portraitVid;
@property (nonatomic, assign) BOOL upsideDownPortraitVid;
@property (strong, nonatomic) PXAlertView *alertView;


//Photo Roll Capture
@property (nonatomic, strong) UIImagePickerController *cameraRollPickerController;
@property (nonatomic, assign) BOOL tryToSaveToPhotoRoll;

//Permissions & User Education
@property (nonatomic, strong) UIImageView *micPermissionImgView;

//Image Preview
@property (nonatomic, strong) UIImageView *capturePreviewImage;
@property (nonatomic, strong) SPCAVPlayerView *playerView;
@property (nonatomic, strong) UIButton *videoPlayBtn;

//Image Editing
@property (nonatomic, strong) SPCImageEditingController *spcImageEditingController;

// -- Post Prep
@property (nonatomic, strong) UIView *postOptionsMenuView;
@property (nonatomic, assign) CGFloat postOptionsMenuViewHeight;

//Text
@property (nonatomic, strong) UIButton *textBtn;
@property (nonatomic, strong) UILabel *textLbl;

@property (nonatomic, strong) UIView *textMenu;
@property (nonatomic, strong) UILabel *textMenuTitleLabel;

@property (nonatomic, strong) UIView *textBgView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSAttributedString *previousText;
@property (nonatomic, strong) UILabel *placeholderTextLabel;
@property (nonatomic, strong) SPCHashTagSuggestions *hashTagSuggestions;
@property (nonatomic, assign) BOOL hashTagIsPending;


//Tagging
@property (nonatomic, strong) NSMutableAttributedString *memTextWithMarkup;
@property (nonatomic, strong) NSDictionary *memTextPrefixMarkup;
@property (nonatomic, strong) UILabel *taggingLabel;
@property (nonatomic, strong) SPCFriendPicker *friendPicker;
@property (nonatomic, strong) NSArray *selectedFriends;
@property (nonatomic, assign) BOOL isTaggingAFriend;
@property (nonatomic, assign) NSInteger taggedUserCount;

//Location
@property (nonatomic, strong) UIView *locationOptionsView;
@property (nonatomic, assign) CGFloat locationOptionsMenuViewHeight;
@property (nonatomic, strong) UIImageView *locationKnob;
@property (nonatomic, strong) UILabel *activeLocationTypeLabel;
@property (nonatomic, strong) UILabel *selectedLocationNameLabel;
@property (nonatomic, strong) UILabel *locationLeftSpectrum;
@property (nonatomic, strong) UILabel *locationMidSpectrum;
@property (nonatomic, strong) UILabel *locationRightSpectrum;

@property (nonatomic, strong) UIButton *mapBtn;
@property (nonatomic, assign) BOOL viewingMap;

@property (nonatomic, assign) CGFloat locMinX;
@property (nonatomic, assign) CGFloat locMidX;
@property (nonatomic, assign) CGFloat locMaxX;

@property (nonatomic, assign) BOOL venuesAreCurrent;
@property (nonatomic, assign) BOOL performingRefresh;
@property (nonatomic, strong) Venue *fuzzedCityVenue;
@property (nonatomic, strong) Venue *fuzzedNeighorhoodVenue;
@property (nonatomic, strong) Venue *placeVenue;
@property (nonatomic, strong) Venue *selectedVenue;
@property (nonatomic, strong) NSArray *nearbyVenues;

@property (nonatomic, strong) SPCMAMLocationViewController *mamLocationViewController;




//Anon-Real
@property (nonatomic, strong) UIImageView *anonRealKnob;
@property (nonatomic, strong) UILabel *anonLbl;
@property (nonatomic, strong) UILabel *realLbl;
@property (nonatomic, assign) CGFloat anonRealMinX;
@property (nonatomic, assign) CGFloat anonRealMidX;
@property (nonatomic, assign) CGFloat anonRealMaxX;
@property (nonatomic, assign) CGFloat anonTapX;
@property (nonatomic, assign) BOOL hasToggledAnon;


//Posting Params
@property (nonatomic, strong) SPCAssetUploadCoordinator *assetUploadCoordinator;
@property (nonatomic, strong) NSString *includedIds;
@property (nonatomic, assign) NSInteger memoryType;
@property (nonatomic, assign) BOOL isAnon;
@property (nonatomic, strong) UserProfile *profile;

@property (nonatomic, strong) UIButton *spayceBtn;

//Posting
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *progressBar;
@property (nonatomic, strong) NSTimer *stepTimer;


@property (nonatomic, assign) NSInteger progressBarUploadsComplete;
@property (nonatomic, assign) NSInteger progressBarUploadsCompleteBeforeAnchor;

@property (nonatomic, assign) NSTimeInterval uploadStartTime;
@property (nonatomic, assign) NSTimeInterval uploadStepStartTime;
@property (nonatomic, assign) NSTimeInterval uploadStepDurationEstimate;
@property (nonatomic, assign) CGFloat uploadProgress;
@property (nonatomic, assign) CGFloat uploadStepProgressStart;
@property (nonatomic, assign) CGFloat uploadStepProgressEnd;
@property (nonatomic, assign) BOOL memoryPostDidFault;
@property (nonatomic, assign) BOOL expandedStatusBar;
@property (nonatomic, assign) BOOL isPhotoRollMem;
@property (nonatomic, assign) BOOL didFilterImage;

//Coachmark
@property (nonatomic, strong) SPCMAMCaptureCoachmarkView *viewCaptureCoachmark;
@property (nonatomic, assign) BOOL captureCoachmarkWasShown;
@property (nonatomic, strong) SPCMAMAdjustmentCoachmarkView *viewAdjustmentCoachmark;
@property (nonatomic, assign) BOOL adjustmentCoachmarkWasShown;

@end

@implementation SPCMAMViewController

-(void)dealloc {
    NSLog(@"------------ mam vc dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_customControls];
}

#pragma mark - UIViewController - Managing the View

-(void)viewDidLoad {
    
    [super viewDidLoad];
    NSLog(@"------------ spc mam did load!");
    NSLog(@"view frame height %f",self.view.frame.size.height);
    
    CGRect statusBarFrame =  [(AppDelegate*)[[UIApplication sharedApplication] delegate] currentStatusBarFrame];
    NSLog(@"statusBarFrame height %f", CGRectGetHeight(statusBarFrame));
    if ( CGRectGetHeight(statusBarFrame) > 0) {
        self.expandedStatusBar = YES;
    }
    else {
        self.expandedStatusBar = NO;
    }
    
    self.navigationController.navigationBarHidden = YES;
    
 
    [self.view addSubview:self.customControls];
    
    //add preview/editing view
    [self.view addSubview:self.capturePreviewImage];
    
    //set asset coordinator precache view
    self.assetUploadCoordinator.precacheImgView = self.capturePreviewImage;
  
    [self.view addSubview:self.micPermissionImgView];
    
    // add menus and supporting views
    [self.view addSubview:self.videoPlayBtn];
    [self.view addSubview:self.processingAsset];
    [self.view addSubview:self.textBgView];
    
    [self.view addSubview:self.locationOptionsView];
    [self.view addSubview:self.postOptionsMenuView];
    [self.view addSubview:self.textMenu];
    [self.view addSubview:self.hashTagSuggestions];
    [self.view addSubview:self.friendPicker];
    [self.view addSubview:self.taggingLabel];
    
    [self.view addSubview:self.frontFacingFlash];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameChanged:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];

    // add capture manager on slight delay to enable controller to load
    [self performSelector:@selector(addCaptureManager) withObject:nil afterDelay:.1];
    
    
    self.memTextPrefixMarkup = @{NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Light" size:20],
                                     NSForegroundColorAttributeName : [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f] };
    self.memTextWithMarkup = [[NSMutableAttributedString alloc] initWithString:@"" attributes:self.memTextPrefixMarkup];
    

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
  
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            // the user granted permission!
            self.micPermissionImgView.hidden = YES;
            self.hasMicPermission = YES;
            
            [self showCaptureCoachmarkIfNeeded];
        }
        else {
            // show a reminder to let the user know that the app has no permission?
            self.micPermissionImgView.hidden = NO;
            self.hasMicPermission = NO;
    }}];
  
    if (!self.venuesAreCurrent && !self.performingRefresh) {
        [self refreshVenues];
    }
}

-(void)resetMAM {
    
    NSLog(@"reset mam!");
    //reset capture
    [self.captureManager closeSession];
    self.customControls.closeBtn.userInteractionEnabled = YES;
    self.videoCaptureInProgress = NO;
    [self restoreCaptureControls];
    [self.assetUploadCoordinator clearAllAssets];
    
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        NSLog(@"file exists at path?");
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
            NSLog(@"remove file?");
            //Error - handle if requried
            NSLog(@"error %@",error.description);
        }
        if ([fileManager removeItemAtPath:outputPath error:&error]) {
            NSLog(@"removed file?");
            NSLog(@"error %@",error.description);
        }
    }
    
    //reset controls
    self.pvCountdown.progress = 0;
    self.videoPlayBtn.hidden = YES;
    
    //reset editing views
    self.postOptionsMenuView.frame = CGRectMake(0, -self.postOptionsMenuViewHeight, self.view.bounds.size.width,self.postOptionsMenuViewHeight);
    self.locationOptionsView.frame = CGRectMake(0, self.view.bounds.size.height + self.locationOptionsMenuViewHeight, self.view.bounds.size.width, self.locationOptionsMenuViewHeight);

    //reset preview
    self.capturedImage = nil;
    self.capturePreviewImage.hidden = YES;
    self.capturePreviewImage.image = nil;
    self.capturePreviewImage.alpha = 1.0f;
    self.captureManager.previewLayer.hidden = NO;
    [self.playerView removeFromSuperview];
    self.playerView = nil;
    
    //reset tagged friends
    self.selectedFriends = nil;

    //reset text
    self.textMenu.frame = CGRectMake(0, -self.postOptionsMenuViewHeight, self.view.bounds.size.width,self.postOptionsMenuViewHeight);
    [self.textBtn setBackgroundImage:[UIImage imageNamed:@"mamNoTextIcon"] forState:UIControlStateNormal];
    self.textBgView.hidden = YES;
    self.textBgView.alpha = 0.0f;
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:@""];
    self.previousText = self.textView.attributedText;
    self.textLbl.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
    self.hashTagSuggestions.hidden = YES;
    self.hashTagSuggestions.alpha = 0;
    self.hashTagSuggestions.selectedHashTags = nil;
    [self.hashTagSuggestions.collectionView reloadData];
    
    //reset anon/real
    [self setToReal];
    self.anonRealKnob.center = CGPointMake(self.anonRealMaxX, self.anonRealKnob.center.y);
 
    //reset location
    self.venuesAreCurrent = NO;
    self.nearbyVenues = nil;
    self.selectedVenue = nil;
    self.mamLocationViewController = nil;
    [self.mapBtn setTitle:@"Map" forState:UIControlStateNormal];

    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.customControls];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors

// --- CAPTURE ---- //

-(SPCMamCaptureControls *)customControls {
    if (!_customControls) {
        _customControls = [[SPCMamCaptureControls alloc] initWithFrame:self.view.bounds];
        _customControls.backgroundColor = [UIColor clearColor];
        [_customControls.closeBtn addTarget:self action:@selector(dismissImagePicker) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.skipBtn addTarget:self action:@selector(textOnly) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.flashBtn addTarget:self action:@selector(toggleFlash) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.flipCamBtn addTarget:self action:@selector(flipCam) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.cameraRollBtn addTarget:self action:@selector(displayCameraRoll) forControlEvents:UIControlEventTouchUpInside];
     
        [_customControls.takePicBtn addTarget:self action:@selector(detectedPossibleLongTap) forControlEvents:UIControlEventTouchDown];
        [_customControls.takePicBtn addTarget:self action:@selector(takePictureOrEndVideo) forControlEvents:UIControlEventTouchUpInside];
        
        
        UIView *countdownBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 118, 118)];
        countdownBgView.backgroundColor = [UIColor whiteColor];
        countdownBgView.layer.cornerRadius = CGRectGetHeight(countdownBgView.frame)/2.0f;
        countdownBgView.layer.masksToBounds = YES;
        countdownBgView.clipsToBounds = YES;
        
        
        [_customControls.bottomOverlay insertSubview:self.pvCountdown belowSubview:_customControls.takePicBtn];
        [_customControls.bottomOverlay insertSubview:countdownBgView belowSubview:self.pvCountdown];
        
        countdownBgView.center = CGPointMake(_customControls.bottomOverlay.frame.size.width/2, _customControls.bottomOverlay.frame.size.height/2);
        self.pvCountdown .center = CGPointMake(_customControls.bottomOverlay.frame.size.width/2, _customControls.bottomOverlay.frame.size.height/2);
        
        
    }
    
  return _customControls;
}

-(UIImagePickerController *)cameraRollPickerController{
  if (!_cameraRollPickerController) {
      _cameraRollPickerController = [[UIImagePickerController alloc] init];
      _cameraRollPickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
      _cameraRollPickerController.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage];
      _cameraRollPickerController.delegate = (id)self;
      _cameraRollPickerController.modalPresentationStyle = UIModalPresentationFullScreen;
      _cameraRollPickerController.navigationBar.tintColor = [UIColor whiteColor];
  }
  return _cameraRollPickerController;
}

-(UIImageView *)micPermissionImgView {
    if (!_micPermissionImgView) {
        
        _micPermissionImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"micPermissionBG"]];
        _micPermissionImgView.hidden = YES;
        _micPermissionImgView.userInteractionEnabled = YES;
        _micPermissionImgView.center = CGPointMake(self.view.bounds.size.width/2, CGRectGetMaxY(self.capturePreviewImage.frame));

        UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(0, 53, _micPermissionImgView.frame.size.width,20)];
        header.text= NSLocalizedString(@"Permission Needed", nil);
        header.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        header.textColor = [UIColor colorWithWhite:45.0f/255.0f alpha:1.0f];
        header.textAlignment = NSTextAlignmentCenter;
        [_micPermissionImgView addSubview:header];

        UILabel *subhead = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(header.frame)+2, _micPermissionImgView.frame.size.width,40)];
        subhead.text= NSLocalizedString(@"Go to Settings/Privacy/Microphone\nfrom your home screen to enable.", nil);
        subhead.font = [UIFont fontWithName:@"OpenSans" size:11];
        subhead.textColor = [UIColor colorWithWhite:45.0f/255.0f alpha:1.0f];
        subhead.textAlignment = NSTextAlignmentCenter;
        subhead.numberOfLines = 0;
        subhead.lineBreakMode = NSLineBreakByWordWrapping;
        [_micPermissionImgView addSubview:subhead];
  }
  return _micPermissionImgView;
}

-(UILabel *)processingAsset {
    if (!_processingAsset) {
        _processingAsset = [[UILabel alloc] initWithFrame:self.capturePreviewImage.frame    ];
        _processingAsset.backgroundColor = [UIColor colorWithWhite:0.0f/255.0f alpha:.7];
        _processingAsset.hidden = YES;
        _processingAsset.text = @"Processing Video..";
        _processingAsset.textAlignment = NSTextAlignmentCenter;
        _processingAsset.textColor = [UIColor whiteColor];
        _processingAsset.font = [UIFont spc_boldSystemFontOfSize:14];
    }
    return _processingAsset;
}

-(UAProgressView *)pvCountdown {
    if (!_pvCountdown) {
        // Countdown progress view
        _pvCountdown = [[UAProgressView alloc] initWithFrame:CGRectMake(0, 0, 118, 118)];
        _pvCountdown.borderWidth = 0.0f;
        _pvCountdown.lineWidth = 8.0f/[UIScreen mainScreen].scale;
        _pvCountdown.tintColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _pvCountdown.backgroundColor = [UIColor colorWithRed:74.0f/255.0f green:81.0f/255.0f blue:94.0f/255.0f alpha:1.0f];
        _pvCountdown.autoresizingMask = UIViewAutoresizingNone;
        _pvCountdown.hidden = YES;
        _pvCountdown.layer.cornerRadius = CGRectGetHeight(_pvCountdown.frame)/2.0f;
       
        /*
        __weak typeof(self) weakSelf = self;
        [_pvCountdown setFillChangedBlock:^(UAProgressView *pv, BOOL filled, BOOL animated) {
            if (filled) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
            }
        }];
        */

    }
    return _pvCountdown;
}

-(UIView *)frontFacingFlash {
    if (!_frontFacingFlash) {
        _frontFacingFlash = [[UIView alloc] initWithFrame:self.view.frame];
        _frontFacingFlash.backgroundColor = [UIColor whiteColor];
        _frontFacingFlash.hidden = YES;
    }
    return _frontFacingFlash;
}

// ---- PREVIEW ---- //

-(UIImageView *)capturePreviewImage {
    if (!_capturePreviewImage) {
        _capturePreviewImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.customControls.topOverlay.frame), self.view.bounds.size.width, self.view.bounds.size.width)];
        _capturePreviewImage.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];
        _capturePreviewImage.hidden = YES;
        _capturePreviewImage.userInteractionEnabled = YES;
        _capturePreviewImage.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _capturePreviewImage;
}

-(UIButton *)videoPlayBtn {
    if (!_videoPlayBtn) {
        _videoPlayBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _videoPlayBtn.layer.cornerRadius = _videoPlayBtn.frame.size.height/2;
        _videoPlayBtn.backgroundColor = [UIColor clearColor];
        [_videoPlayBtn setBackgroundImage:[UIImage imageNamed:@"mamVidPlayBtn"] forState:UIControlStateNormal];
        _videoPlayBtn.hidden = YES;
        [_videoPlayBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _videoPlayBtn;
}


// ---- POST PREP ---- //

- (SPCAssetUploadCoordinator *)assetUploadCoordinator {
    if (!_assetUploadCoordinator) {
        _assetUploadCoordinator = [[SPCAssetUploadCoordinator alloc] init];
    }
    return _assetUploadCoordinator;
}

-(UIView *)postOptionsMenuView {
    if (!_postOptionsMenuView) {
        
        self.postOptionsMenuViewHeight = 60; //TODO adjust for other devices
        
        _postOptionsMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, -self.postOptionsMenuViewHeight, self.view.bounds.size.width,self.postOptionsMenuViewHeight)];
        _postOptionsMenuView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];
        
        UIButton *backToCaptureBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        [backToCaptureBtn setBackgroundImage:[UIImage imageNamed:@"mamBackToCapture"] forState:UIControlStateNormal];
        [backToCaptureBtn addTarget:self action:@selector(hidePostingOptions) forControlEvents:UIControlEventTouchDown];
        [_postOptionsMenuView addSubview:backToCaptureBtn];
        
        [_postOptionsMenuView addSubview:self.textBtn];
        
        UIImageView *anonRealBg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 85, 0, 85, 60)];
        anonRealBg.image = [UIImage imageNamed:@"mamAnonSwitchBg"];
        [_postOptionsMenuView addSubview:anonRealBg];
        
        [_postOptionsMenuView addSubview:self.anonRealKnob];
        
        self.anonRealMaxX = self.view.bounds.size.width - 25;
        self.anonRealMidX = self.view.bounds.size.width - 47;
        self.anonRealMinX = self.view.bounds.size.width - 65;
        
        self.anonRealKnob.center = CGPointMake(self.anonRealMaxX, self.anonRealKnob.center.y);
        
        [_postOptionsMenuView addSubview:self.anonLbl];
        [_postOptionsMenuView addSubview:self.realLbl];
    }
    return _postOptionsMenuView;
}

-(UIView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
        _loadingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.2];
    }
    
    return _loadingView;
}

-(UIView *)progressBar {
    if (!_progressBar) {
        _progressBar = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.postOptionsMenuView.frame), 20, 4)];
        _progressBar.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        NSLog(@"progress bar frame made as %@", NSStringFromCGRect(_progressBar.frame));
    }
    return _progressBar;
}


// -- IMG EDITING -- //

-(SPCImageEditingController *)spcImageEditingController {
    if (!_spcImageEditingController) {
        _spcImageEditingController = [[SPCImageEditingController alloc] init];
        _spcImageEditingController.delegate = self;
    }
    return _spcImageEditingController;
}

// ---- TEXT ---- //

-(UIButton *)textBtn {
    if (!_textBtn) {
        float textOriginX = roundf(.32 * self.view.bounds.size.width);
        
        _textBtn = [[UIButton alloc] initWithFrame:CGRectMake(textOriginX, 0, 57, 50)];
        [_textBtn setBackgroundImage:[UIImage imageNamed:@"mamNoTextIcon"] forState:UIControlStateNormal];
        [_textBtn addTarget:self action:@selector(showTextInput) forControlEvents:UIControlEventTouchDown];
        [_textBtn addSubview:self.textLbl];
    }
    return _textBtn;
}

-(UILabel *)textLbl {
    if (!_textLbl) {
        _textLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 37, 57, 20)];
        _textLbl.text = NSLocalizedString(@"TEXT", nil);
        _textLbl.font = [UIFont fontWithName:@"OpenSans" size:7];
        _textLbl.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
        _textLbl.textAlignment = NSTextAlignmentCenter;
    }
    return _textLbl;
}

-(UIView *)textMenu {
    if (!_textMenu) {
        _textMenu = [[UIView alloc] initWithFrame:CGRectMake(0, - self.postOptionsMenuViewHeight, self.view.bounds.size.width,self.postOptionsMenuViewHeight)];
        _textMenu.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];

        [_textMenu addSubview:self.textMenuTitleLabel];

        UIButton *backToCaptureBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        [backToCaptureBtn setBackgroundImage:[UIImage imageNamed:@"mamTextCancel"] forState:UIControlStateNormal];
        [backToCaptureBtn addTarget:self action:@selector(cancelText) forControlEvents:UIControlEventTouchDown];
        [_textMenu addSubview:backToCaptureBtn];

        UIButton *saveTextBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 70, 0, 70, self.postOptionsMenuViewHeight)];
        [saveTextBtn addTarget:self action:@selector(saveTextAndDismiss) forControlEvents:UIControlEventTouchDown];
        [saveTextBtn setTitle:@"SAVE" forState:UIControlStateNormal];
        saveTextBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [saveTextBtn.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:12]];
        [saveTextBtn setTitleColor:[UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [saveTextBtn setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];

        [_textMenu addSubview:saveTextBtn];
  }
  return _textMenu;
}

-(UILabel *)textMenuTitleLabel {
    if (!_textMenuTitleLabel) {
        _textMenuTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, _textMenu.frame.size.height)];
        _textMenuTitleLabel.textAlignment = NSTextAlignmentCenter;
        _textMenuTitleLabel.text = NSLocalizedString(@"Add Caption", nil);
        _textMenuTitleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
        _textMenuTitleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
    }
    return _textMenuTitleLabel;
}

-(UIView *)textBgView {
    if (!_textBgView) {
        _textBgView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.customControls.topOverlay.frame), self.view.bounds.size.width, self.view.bounds.size.width)];
        _textBgView.backgroundColor = [UIColor whiteColor];
        _textBgView.alpha = 0.0f;
        _textBgView.userInteractionEnabled = YES;
        [_textBgView addSubview:self.textView];
        [_textBgView addSubview:self.placeholderTextLabel];
    }
    return _textBgView;
}

-(UITextView *)textView {
    if (!_textView) {
        
       //3.5"
        float textViewHeight = 50;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            textViewHeight = 140;
        }
        
        //4.7" & 5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            textViewHeight = self.textBgView.frame.size.height-10;
        }
        
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(5, 5, self.view.bounds.size.width-10, textViewHeight)];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont fontWithName:@"OpenSans-Light" size:20];
        _textView.textColor = [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f];
        _textView.keyboardType = UIKeyboardTypeTwitter;
        _textView.spellCheckingType  = UITextSpellCheckingTypeYes;
        _textView.autocorrectionType = UITextAutocorrectionTypeYes;
        _textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textView.delegate = self;
    }
    return _textView;
}

-(UILabel *)placeholderTextLabel {
    if (!_placeholderTextLabel) {
        _placeholderTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeholderTextLabel.text = @"What's happening...";
        _placeholderTextLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
        _placeholderTextLabel.frame = CGRectMake(13, 14 , 300, _placeholderTextLabel.font.lineHeight);
        _placeholderTextLabel.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
        _placeholderTextLabel.userInteractionEnabled = NO;
    }
    return _placeholderTextLabel;
}

-(SPCHashTagSuggestions *)hashTagSuggestions {
    if (!_hashTagSuggestions) {
        _hashTagSuggestions = [[SPCHashTagSuggestions alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.textView.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetMaxY(self.textView.frame))];
        _hashTagSuggestions.hidden = YES;
        _hashTagSuggestions.alpha = 0;
        _hashTagSuggestions.delegate = self;
        _hashTagSuggestions.locationHashTags = nil;
        [_hashTagSuggestions updateForNewMam];
        [_hashTagSuggestions.collectionView reloadData];
    }
    return _hashTagSuggestions;
}

-(UILabel *)taggingLabel {
    if (!_taggingLabel) {
        _taggingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,50)];
        _taggingLabel.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _taggingLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
        _taggingLabel.backgroundColor = [UIColor whiteColor];
        _taggingLabel.textAlignment = NSTextAlignmentCenter;
        _taggingLabel.hidden = YES;
        _taggingLabel.userInteractionEnabled = YES;
        
        UIButton *backToCaptureBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        [backToCaptureBtn setBackgroundImage:[UIImage imageNamed:@"mamTextCancel"] forState:UIControlStateNormal];
        [backToCaptureBtn addTarget:self action:@selector(cancelPicker) forControlEvents:UIControlEventTouchDown];
        [_taggingLabel addSubview:backToCaptureBtn];
        
    }
    
    return _taggingLabel;
}

-(SPCFriendPicker *)friendPicker {
    if (!_friendPicker) {
        _friendPicker = [[SPCFriendPicker alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, self.view.bounds.size.height - 50 - 216)];
        _friendPicker.delegate = self;
        _friendPicker.hidden = YES;
    }
    
    return _friendPicker;
}

// -- TAGGING  -- //

-(NSArray *)selectedFriends {
    if (!_selectedFriends) {
        _selectedFriends = [[NSArray alloc] init];
    }
    return _selectedFriends;
}


// -- REAL-ANON -- //

-(UILabel *)anonLbl {
    if (!_anonLbl) {
        _anonLbl = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 90, 37, 57, 20)];
        _anonLbl.text = NSLocalizedString(@"ANON", nil);
        _anonLbl.font = [UIFont fontWithName:@"OpenSans" size:7];
        _anonLbl.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
        _anonLbl.textAlignment = NSTextAlignmentCenter;
    }
    return _anonLbl;
}

-(UILabel *)realLbl {
    if (!_realLbl) {
        _realLbl = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 55, 37, 57, 20)];
        _realLbl.text = NSLocalizedString(@"REAL", nil);
        _realLbl.font = [UIFont fontWithName:@"OpenSans" size:7];
        _realLbl.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _realLbl.textAlignment = NSTextAlignmentCenter;
    }
    return _realLbl;
}

-(UIImageView *)anonRealKnob {
    if (!_anonRealKnob) {
        _anonRealKnob = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mamRealKnob"]];
        _anonRealKnob.userInteractionEnabled = YES;
    }
    return _anonRealKnob;
}


// -- LOCATION -- //

-(UIView *)locationOptionsView {
    if (!_locationOptionsView) {

        self.locationOptionsMenuViewHeight = 232;
        
        self.locMidX = self.view.bounds.size.width/2;
        self.locMinX = self.locMidX - 110;		         
        self.locMaxX = self.locMidX + 110;
        
        _locationOptionsView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height + self.locationOptionsMenuViewHeight, self.view.bounds.size.width, self.locationOptionsMenuViewHeight)];
        _locationOptionsView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        
        //add base track
        UIView *locationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 18)];
        locationBarView.center = CGPointMake(_locationOptionsView.frame.size.width/2, _locationOptionsView.frame.size.height/2);
        locationBarView.layer.cornerRadius = 8;
        locationBarView.backgroundColor = [UIColor colorWithWhite:236.0f/255.0f alpha:1.0f];
        [_locationOptionsView addSubview:locationBarView];
        
        
        //add labels
        [_locationOptionsView addSubview:self.locationLeftSpectrum];
        [_locationOptionsView addSubview:self.locationMidSpectrum];
        [_locationOptionsView addSubview:self.locationRightSpectrum];
        [_locationOptionsView addSubview:self.activeLocationTypeLabel];
        [_locationOptionsView addSubview:self.selectedLocationNameLabel];
        
        
        self.locationMidSpectrum.center = CGPointMake(self.locMidX, CGRectGetMaxY(locationBarView.frame) + 8);
        self.locationLeftSpectrum.center = CGPointMake(self.locMinX, CGRectGetMaxY(locationBarView.frame) + 8);
        self.locationRightSpectrum.center = CGPointMake(self.locMaxX, CGRectGetMaxY(locationBarView.frame) + 8);
        
        //add button
        [_locationOptionsView addSubview:self.mapBtn];
        self.mapBtn.center = CGPointMake(self.view.bounds.size.width/2, locationBarView.frame.origin.y - 30);
        
        
        self.activeLocationTypeLabel.center = CGPointMake(self.view.bounds.size.width/2, locationBarView.frame.origin.y - 80);
        self.selectedLocationNameLabel.center = CGPointMake(self.view.bounds.size.width/2, locationBarView.frame.origin.y - 62);
        
        
        //add slider
        [_locationOptionsView addSubview:self.locationKnob];
        self.locationKnob.center = CGPointMake(self.locMidX, locationBarView.center.y);
        
        //add spayce btn
        [_locationOptionsView addSubview:self.spayceBtn];
    }
  
  return _locationOptionsView;
}

-(UILabel *)activeLocationTypeLabel {
    if (!_activeLocationTypeLabel) {
        _activeLocationTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 90, 15)];
        _activeLocationTypeLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
        _activeLocationTypeLabel.textColor = [UIColor colorWithWhite:178.0f/255.0f alpha:1.0f];
        _activeLocationTypeLabel.textAlignment = NSTextAlignmentCenter;
        _activeLocationTypeLabel.text = @"Neighborhood";
    }
    return _activeLocationTypeLabel;
}

-(UIButton *)mapBtn {
    if (!_mapBtn) {
        _mapBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 2000, 50)];
        [_mapBtn setTitle:@"Map" forState:UIControlStateNormal];
        [_mapBtn addTarget:self action:@selector(viewMap) forControlEvents:UIControlEventTouchDown];
        _mapBtn.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
        [_mapBtn setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        _mapBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_mapBtn setTitleColor:[UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    }
    return _mapBtn;
}

-(UILabel *)selectedLocationNameLabel {
    if (!_selectedLocationNameLabel) {
        _selectedLocationNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 240, 25)];
        _selectedLocationNameLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
        _selectedLocationNameLabel.textColor = [UIColor colorWithWhite:0.0f/255.0f alpha:1.0f];
        _selectedLocationNameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _selectedLocationNameLabel;
}

-(UILabel *)locationLeftSpectrum {
    if (!_locationLeftSpectrum) {
        _locationLeftSpectrum = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 15)];
        _locationLeftSpectrum.font = [UIFont fontWithName:@"OpenSans" size:10];
        _locationLeftSpectrum.textColor = [UIColor colorWithWhite:211.0f/255.0f alpha:1.0f];
        _locationLeftSpectrum.text = NSLocalizedString(@"Place", nil);
        _locationLeftSpectrum.textAlignment = NSTextAlignmentCenter;
    }
    return _locationLeftSpectrum;
}

-(UILabel *)locationMidSpectrum {
    if (!_locationMidSpectrum) {
        _locationMidSpectrum = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 15)];
        _locationMidSpectrum.font = [UIFont fontWithName:@"OpenSans" size:10];
        _locationMidSpectrum.textColor = [UIColor colorWithWhite:211.0f/255.0f alpha:1.0f];
        _locationMidSpectrum.text = NSLocalizedString(@"Neighborhood", nil);
        _locationMidSpectrum.textAlignment = NSTextAlignmentCenter;
        _locationMidSpectrum.alpha = 0;
    }
    return _locationMidSpectrum;
}

-(UILabel *)locationRightSpectrum {
    if (!_locationRightSpectrum) {
        _locationRightSpectrum = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 15)];
        _locationRightSpectrum.font = [UIFont fontWithName:@"OpenSans" size:10];
        _locationRightSpectrum.textColor = [UIColor colorWithWhite:211.0f/255.0f alpha:1.0f];
        _locationRightSpectrum.text = NSLocalizedString(@"City", nil);
        _locationRightSpectrum.textAlignment = NSTextAlignmentCenter;
    }
    return _locationRightSpectrum;
}

-(UIImageView *)locationKnob {
    if (!_locationKnob) {
        _locationKnob = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mamLocationKnob"]];
        _locationKnob.userInteractionEnabled = YES;
    }
    return _locationKnob;
}

-(UIButton *)spayceBtn {
    if (!_spayceBtn) {
        _spayceBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.locationOptionsView.frame.size.height - 55, self.view.bounds.size.width, 55)];
        [_spayceBtn setBackgroundColor:[UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f]];
        [_spayceBtn addTarget:self action:@selector(postMem) forControlEvents:UIControlEventTouchDown];
        [_spayceBtn setImage:[UIImage imageNamed:@"mamSpayceIcon"] forState:UIControlStateNormal];
    }
    return _spayceBtn;
}

-(SPCMAMLocationViewController *)mamLocationViewController {
    if (!_mamLocationViewController) {
        _mamLocationViewController = [[SPCMAMLocationViewController alloc] initWithNearbyVenues:self.nearbyVenues selectedVenue:self.placeVenue];
        _mamLocationViewController.delegate = self;
    }
    return _mamLocationViewController;
}


#pragma mark - UIImagePickerControllerDelegate methods

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (picker == self.spcImagePickerController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        }];
    }
    else {
        [self.cameraRollPickerController dismissViewControllerAnimated:YES completion:^ {
        }];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *type = info[UIImagePickerControllerMediaType];
  
    // - handle vidoes

    if ([type isEqualToString:(NSString *)kUTTypeVideo] ||
        [type isEqualToString:(NSString *)kUTTypeMovie]) {
        
        if (picker == self.cameraRollPickerController) {
            self.isPhotoRollMem = YES;
            self.tryToSaveToPhotoRoll = NO;
            [self.cameraRollPickerController dismissViewControllerAnimated:YES completion:nil];
        }
        
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        self.numVideosProcesssing = 1;
        [self addVideoWithURL:videoURL];
        self.memoryType = MemoryTypeVideo;
        
        
        
        [self performSelector:@selector(confirmVideoIsProcessed) withObject:nil afterDelay:.1];
    }

    // - handle photos
    if ([type isEqualToString:(NSString *)kUTTypeImage]) {
    
        UIImage *sourceImage = info[UIImagePickerControllerOriginalImage];
        
        self.memoryType = MemoryTypeImage;
        self.processingAsset.hidden = NO;
        self.processingAsset.text = @"Processing Image..";
        
        if (picker == self.cameraRollPickerController) {
               //NSLog(@"cam roll!");
            self.isPhotoRollMem = YES;
            self.tryToSaveToPhotoRoll = NO;
            [self.cameraRollPickerController dismissViewControllerAnimated:YES completion:^ {
                [self showPostingOptions];
            }];
        }
        else {
            //NSLog(@"snapped photo!");
            [self showPostingOptions];
        }
        
        //process image on delay to enable immediate display of posting options
        [self performSelector:@selector(prepImage:) withObject:sourceImage afterDelay:.25];
    }
}


#pragma mark - SPCCaptureManagerDelegate methods

-(void)capturedImage:(UIImage *)stillImage   {
    //NSLog(@"captured still image from AVCaptureSession!");
    self.frontFacingFlash.hidden = YES;
    self.isPhotoRollMem = NO;
    self.cameraIsLocked = NO;
    self.memoryType = MemoryTypeImage;
    self.processingAsset.hidden = NO;
    self.processingAsset.text = @"Processing Image..";
    [self showPostingOptions];

    //process image on delay to enable immediate display of posting options
    [self performSelector:@selector(prepImage:) withObject:stillImage afterDelay:.25];
}


#pragma mark - SPCImageEditingControllerDelegate

- (void)cancelEditing {
    [self.spcImageEditingController.view removeFromSuperview];
    [self.spcImageEditingController cleanUp];
    self.spcImageEditingController = nil;
}

- (void)finishedEditingImage:(SPCImageToCrop *)newImage {
    
    self.didFilterImage = YES; //used for flurry logs
    self.capturedImage = newImage;

    [self.assetUploadCoordinator clearAllAssets];
    
    
    SPCPendingAsset *assetNew = [[SPCPendingAsset alloc] initWithImageToCrop:newImage];
    [self.assetUploadCoordinator addPendingAsset:assetNew];
    
    
    //update view
    self.capturePreviewImage.image = [newImage cropPreviewImage];
    
    
    [self.spcImageEditingController.view removeFromSuperview];
    [self.spcImageEditingController cleanUp];
    self.spcImageEditingController = nil;
}

#pragma mark - SPCTagFriendsViewControllerDelegate

-(void)pickedFriends:(NSArray *)selectedFriends {
    
    self.selectedFriends = selectedFriends;
    
}

-(void)cancelTaggingFriends {

}


#pragma mark - UITextViewDelegate

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.hashTagSuggestions.hidden = NO;
    [self showTextMenu];
    return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *resultString = [textView.text stringByReplacingCharactersInRange:range withString:text];
  
    self.placeholderTextLabel.hidden = resultString.length > 0;
    BOOL needsRestyling = NO;
    
    //hide tagged friends view @ has been deleted
    NSString *textToChange  = [textView.text substringWithRange:range];
    NSRange rangeOld = [textToChange rangeOfString:@"@" options:NSBackwardsSearch];
    NSRange rangeNew = [text rangeOfString:@"@" options:NSBackwardsSearch];
    if (rangeOld.location != NSNotFound && rangeNew.location == NSNotFound) {
        self.friendPicker.isSearching = NO;
        self.friendPicker.hidden = YES;
        self.taggingLabel.hidden = YES;
    }
    
    if ([text isEqualToString:@"#"]){
        self.hashTagIsPending = YES;
        needsRestyling = YES;
    }
    
    if ([text isEqualToString:@"@"]){
        self.isTaggingAFriend = YES;
        self.friendPicker.hidden = NO;
        self.friendPicker.isSearching = NO;
        [self.friendPicker reloadData];
        self.friendPicker.collectionView.frame = CGRectMake(0, 0, self.friendPicker.frame.size.width, self.friendPicker.frame.size.height);
    }
    
    if ([text isEqualToString:@" "] || [text isEqualToString:@"\n"]){
        self.friendPicker.hidden = YES;
        NSLog(@"hide friend picker after space!!");
    }
  
 
    NSRange cursorPosition = [self.textView selectedRange];
  
    
    //update tagged friends search string if @ has previously been typed
    NSArray *currentlyTaggedUserNames = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USERNAME];
    self.taggedUserCount = currentlyTaggedUserNames.count;
   
    if (!self.friendPicker.hidden && resultString.length > 0) {
        //NSLog(@"@ was previously typed");
        self.isTaggingAFriend = YES;
        self.taggingLabel.hidden = NO;
        
        //find search string to use for @username autocompletion/filtering
        NSString *searchString;
        NSRange searchRangeStart = [resultString rangeOfString:@"@" options:NSBackwardsSearch];
        NSString *stringFromAt = [resultString substringFromIndex:searchRangeStart.location+1];
        NSRange endOfWordRange = [stringFromAt rangeOfString:@" " options:NSCaseInsensitiveSearch];
        
        if (endOfWordRange.location != NSNotFound) {
            //get the range for the first full word from the current @ position
            searchString = [stringFromAt substringToIndex:endOfWordRange.location];
        }
        else {
            //no spaces from the @ position
            searchString = stringFromAt;
        }
        
        //NSLog(@"searchString %@",searchString);
        
        if (searchString.length > 0) {
            [self.friendPicker updateFilterString:searchString];
            self.taggingLabel.text = [NSString stringWithFormat:@"@%@",searchString];
        }

    }
    
    [textView setSelectedRange:cursorPosition];

    
    return resultString.length <= 141;
}

-(void)textViewDidChange:(UITextView *)textView  {
    [self restyleText:self.textView.attributedText.string];
    [self hashTagFullSweep];
}

-(void)restyleText:(NSString *)textToRestyle {
    
    NSArray *currentlyTaggedUserNames = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USERNAME];
    NSArray *currentlyTaggedUserIds = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USERID];
    NSArray *currentlyTaggedUserTokens = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USERTOKEN];
    NSArray *currentlyTaggedUserHandles = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USERHANDLE];
    
    //NSLog(@"textToRestyle %@",textToRestyle);
    //NSLog(@"currently tagged users %@",currentlyTaggedUserNames);
    
    
    self.memTextWithMarkup = [[NSMutableAttributedString alloc] initWithString:textToRestyle];
    
    // create an attributed (with no attributes) string, to terminate any previous attribution.
    NSRange fullRange = NSMakeRange(0, textToRestyle.length);
    fullRange = NSMakeRange(0, self.memTextWithMarkup.length);
    [self.memTextWithMarkup addAttributes:self.memTextPrefixMarkup range:fullRange];
    
    for (int i = 0; i < currentlyTaggedUserNames.count; i++)  {
        NSString *taggedUser = currentlyTaggedUserNames[i];
        //NSLog(@"search for %@",taggedUser);
        
        NSRange tagguedUserRange = [textToRestyle rangeOfString:taggedUser options:NSCaseInsensitiveSearch];
        
        if (tagguedUserRange.location == NSNotFound) {
            
            //remove this tagged user?
            //NSLog(@"%@ not found!!",taggedUser);
        }
        
        else {
            NSLog(@"restyle for tagged user %@",taggedUser);
            
            NSString *userToken = currentlyTaggedUserTokens[i];
            NSString *userId = currentlyTaggedUserIds[i];
            NSString *userHandle = currentlyTaggedUserHandles[i];
            
            NSDictionary *attributes = @{ ATTRIBUTE_USERTOKEN : userToken,
                                          ATTRIBUTE_USERNAME : taggedUser,
                                          ATTRIBUTE_USERID : userId,
                                          ATTRIBUTE_USERHANDLE : userHandle};
            NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:taggedUser attributes:attributes];
            [self replaceCharactersOfMarkupString:self.memTextWithMarkup inRange:tagguedUserRange withAttributedString:attributedName];
            //NSLog(@"markup string is %@", self.commentTextWithMarkup);
            
            
        }
    }
    
    self.textView.attributedText = self.memTextWithMarkup;
}


#pragma mark - SPCFriendPicker delegate

- (void)selectedFriend:(Friend *)f {
    
    self.friendPicker.hidden = YES;
    self.taggingLabel.hidden = YES;
    self.friendPicker.isSearching = NO;
    self.taggingLabel.text = @"@";
    
    //update text view text with name of selected friend
    BOOL newUser = YES;
    
    NSArray *currentlyTaggedUserIds = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USERID];
    
    for (int i = 0; i< currentlyTaggedUserIds.count; i++) {
        
        NSString *recStr = [NSString stringWithFormat:@"%i",(int)f.recordID];
        if ([recStr isEqualToString:currentlyTaggedUserIds[i]]) {
            NSLog(@"already added this user!");
            newUser = NO;
            break;
        }
    }
    
    
    
    //find the begining of our range to replace
    NSRange searchRangeStart = [self.textView.text rangeOfString:@"@" options:NSBackwardsSearch];
    NSString *stringFromAt = [self.textView.attributedText.string substringFromIndex:searchRangeStart.location];
    
    NSLog(@"searchRangeStart.location %li",searchRangeStart.location);
    NSLog(@"stringFromAt %@",stringFromAt);
    
    NSRange endOfWordRange = [stringFromAt rangeOfString:@" " options:NSCaseInsensitiveSearch];
    NSRange removedRange; // = NSMakeRange(searchRangeEnd.location, self.commentInput.text.length - searchRangeEnd.location);
    
    if (endOfWordRange.location != NSNotFound) {
        //get the range for the first full word from the current @ position
        NSString *wordToSwap = [stringFromAt substringToIndex:endOfWordRange.location];
        NSLog(@"wordToSwap %@",wordToSwap);
        removedRange = NSMakeRange(searchRangeStart.location, wordToSwap.length);
    }
    else {
        //no spaces from the @ position
        removedRange = NSMakeRange(searchRangeStart.location, stringFromAt.length);
    }
    
    // add the username (w/ annotation markup)
    NSDictionary *attributes = @{ ATTRIBUTE_USERTOKEN : f.userToken,
                                  ATTRIBUTE_USERNAME : f.displayName,
                                  ATTRIBUTE_USERID : [NSString stringWithFormat:@"%@", @(f.recordID)],
                                  ATTRIBUTE_USERHANDLE : f.handle
                                  };
    NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:f.displayName attributes:attributes];
    [attributedName appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];

     NSLog(@"self.textView.attributedText is %@", self.textView.attributedText);
    self.memTextWithMarkup = nil;
    self.memTextWithMarkup = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    if (newUser) {
        [self replaceCharactersOfMarkupString:self.memTextWithMarkup inRange:removedRange withAttributedString:attributedName];
    }
    else {
        NSMutableAttributedString *nothingStr = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
        [self replaceCharactersOfMarkupString:self.memTextWithMarkup inRange:removedRange withAttributedString:nothingStr];
    }
        NSLog(@"updated markup string is %@", self.memTextWithMarkup);
    
    self.textView.attributedText = self.memTextWithMarkup;
    [self hashTagFullSweep];
    
    if (newUser) {
        [self selectTextForInput:self.textView atRange:NSMakeRange(removedRange.location + attributedName.length, 0)];
    }
    else {
        [self selectTextForInput:self.textView atRange:NSMakeRange(self.textView.attributedText.length, 0)];
    }
}

-(void)replaceCharactersOfMarkupString:(NSMutableAttributedString *)markupString inRange:(NSRange)range withString:(NSString *)string {
    [self replaceCharactersOfMarkupString:markupString inRange:range withAttributedString:[[NSAttributedString alloc] initWithString:string]];
}

-(void)selectTextForInput:(UITextView *)input atRange:(NSRange)range {
    UITextPosition *start = [input positionFromPosition:[input beginningOfDocument]
                                                 offset:range.location];
    UITextPosition *end = [input positionFromPosition:start
                                               offset:range.length];
    [input setSelectedTextRange:[input textRangeFromPosition:start toPosition:end]];
}

-(void)replaceCharactersOfMarkupString:(NSMutableAttributedString *)markupString inRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString {
    NSRange fullRange = NSMakeRange(0, markupString.length);
    NSLog(@"markupString.length %i",(int)fullRange.length);
    [markupString enumerateAttributesInRange:fullRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange attrRange, BOOL *stop) {
        if (NSIntersectionRange(range, attrRange).length > 0) {
            [attrs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [markupString removeAttribute:key range:attrRange];
            }];
        }
    }];
    // create an attributed (with no attributes) string, to terminate any previous attribution.
    [self.memTextWithMarkup replaceCharactersInRange:range withAttributedString:attributedString];
    fullRange = NSMakeRange(0, self.memTextWithMarkup.length);
    [markupString addAttributes:self.memTextPrefixMarkup range:fullRange];
    [markupString enumerateAttribute:ATTRIBUTE_USERNAME inRange:fullRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange attrRange, BOOL *stop) {
        if (value) {
            [markupString addAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f],NSFontAttributeName : [UIFont fontWithName:@"OpenSans-SemiBold" size:20]  } range:attrRange];
        }
    }];
}

-(NSArray *)uniqueAttributeValuesForAttribute:(NSString *)attribute {
    __block NSMutableArray *values = [[NSMutableArray alloc] init];
    [self.memTextWithMarkup enumerateAttribute:attribute inRange:NSMakeRange(0, self.memTextWithMarkup.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (range.length > 0 && value) {
            if (![values containsObject:value]) {
                [values addObject:value];
            }
        }
    }];
    return [NSArray arrayWithArray:values];
}

-(NSString *)markupString {
    // Prepare a plaintext markup string from our attributed string.
    // First replace all instances of '@' in the string with the escaped version
    // '@\' (yes, we escape after the character.  This makes parsing easier on the
    // server).
    // Second, for any attributed string with a user display name, replace the entire range
    // with @ userHandle .
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.memTextWithMarkup];
    NSRange rangeOfAt = [[attributedString string] rangeOfString:@"@" options:0 range:NSMakeRange(0, attributedString.length)];
    while (rangeOfAt.location != NSNotFound) {
        // replace...
        [attributedString replaceCharactersInRange:rangeOfAt withString:@"@\\"];
        rangeOfAt = [[attributedString string] rangeOfString:@"@" options:0 range:NSMakeRange(rangeOfAt.location + 1, attributedString.length - rangeOfAt.location - 1)];
    }
    
    [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if (attrs) {
            if ([attrs objectForKey:@"ATTRIBUTE_USERNAME"] && [attrs objectForKey:@"ATTRIBUTE_USERHANDLE"] ) {
                [attributedString replaceCharactersInRange:range withString:[NSString stringWithFormat:@"@ %@ ", [attrs objectForKey:@"ATTRIBUTE_USERHANDLE"]]];
            }
        }
    }];
    
    return [attributedString string];
}

#pragma mark - SPCHashTagSuggestionsDelegate

-(void)tappedToAddHashTag:(NSString *)hashTag {
    if (self.hashTagIsPending) {
        [self updatePendingHashTags];
    }
  
    [self updateStyling];
  
    NSMutableAttributedString *attStr;
  
    if (self.textView.attributedText.length > 0) {
        //NSLog(@"hash tag tapped and string is already styled");
        attStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    
        //append styled hashtag with spacing
        NSMutableAttributedString *newHashStr;
    
        //add spacing if needed
        unichar last = [attStr.string characterAtIndex:[attStr.string length] - 1];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:last]) {
            //new hashtag is preceded by a space, we are ok
            newHashStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",hashTag]];
        }
        else {
            //we need to add a space before (and after) the hashtag!
            newHashStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ ",hashTag]];
        }
    
        [newHashStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] range:NSMakeRange(0, newHashStr.length-1)];
        [newHashStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Light" size:20] range:NSMakeRange(0, newHashStr.length-1)];
        [attStr appendAttributedString:newHashStr];
    
        self.textView.attributedText = attStr;
    }
    else {
        //NSLog(@"hash tag tapped and string is not yet styled");
        attStr = [[NSMutableAttributedString alloc] initWithString:self.textView.text];
        [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f] range:NSMakeRange(0, attStr.length)];
        [attStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Light" size:20] range:NSMakeRange(0, attStr.length)];
    
        //append styled hashtag with spacing
        NSMutableAttributedString *newHashStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",hashTag]];
        [newHashStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] range:NSMakeRange(0, newHashStr.length-1)];
        [newHashStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Light" size:20] range:NSMakeRange(0, newHashStr.length-1)];
        [attStr appendAttributedString:newHashStr];
    
        self.textView.attributedText = attStr;
    }
  
    self.placeholderTextLabel.hidden = YES;
}

-(void)tappedToRemoveHashTag:(NSString *)hashTag {
  
    //traverse text to remove and then restyle everything
    NSString *originalString = self.textView.attributedText.string;
  
    NSString *placeholder = @"%(?<!\\S)%@(?!\\S)";
    NSString *pattern = [NSString stringWithFormat:placeholder, hashTag];
    NSError* regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&regexError];

    NSLog(@"pattern %@",pattern);

    NSString *modifiedString = [regex stringByReplacingMatchesInString:originalString
                                                             options:0
                                                               range:NSMakeRange(0, [originalString length])
                                                        withTemplate:@""];

    NSString *twiceUpdatedString = [modifiedString stringByReplacingOccurrencesOfString:@"  " withString:@" "];

    NSLog(@"modified string %@",modifiedString);
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:twiceUpdatedString];

    self.textView.attributedText = attString;
    [self updateStyling];
}

-(void)hashTagsDidScroll {
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}


#pragma mark - SPCMAMLocationViewControllerDelegate

- (void)spcPickLocationViewControllerDidFinish:(id)sender withSelectedVenue:(Venue *)venue {
  
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.mamLocationViewController.view.frame = CGRectMake(self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
                     
                     }
                     completion:^(BOOL completed){
                         [self.mamLocationViewController.view removeFromSuperview];
                         self.viewingMap = NO;
                     }
     ];
    
    self.placeVenue = venue;
      
    self.selectedVenue = self.placeVenue;
    
    BOOL nearbyVenuesAlreadyIncludesVenue = NO;
    
    for (int i = 0; i < self.nearbyVenues.count; i++) {
        Venue *tempV = (Venue *)self.nearbyVenues[i];
        if (tempV.addressId == venue.addressId) {
            nearbyVenuesAlreadyIncludesVenue = YES;
            break;
        }
    }
    
    if (!nearbyVenuesAlreadyIncludesVenue && venue) {
        NSMutableArray *updatedVenues = [NSMutableArray arrayWithArray:self.nearbyVenues];
        [updatedVenues addObject:venue];
        self.nearbyVenues = [NSArray arrayWithArray:updatedVenues];
    }

    self.selectedLocationNameLabel.text = self.placeVenue.displayNameTitle;
    self.activeLocationTypeLabel.text = NSLocalizedString(@"Place", nil);
    [self.mapBtn setTitle:@"Tap to change" forState:UIControlStateNormal];

    self.locationLeftSpectrum.alpha = 0;
    self.locationRightSpectrum.alpha = 1;
    self.locationMidSpectrum.alpha = 1;
    self.hashTagSuggestions.alpha = 0;


    self.locationKnob.center = CGPointMake(self.locMinX, self.locationKnob.center.y);
}


#pragma mark - SPCAVPlayerView delegate

- (void)didStartPlaybackWithPlayerView:(SPCAVPlayerView *)playerView {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.playerView isEqual:playerView]) {

        }
    });
}

- (void)didFinishPlaybackToEndWithPlayerView:(SPCAVPlayerView *)playerView {
    if ([self.playerView isEqual:playerView]) {
        self.videoPlayBtn.hidden = NO;
        self.playerView.bufferView.hidden = YES;
    }
}

- (void)didFailToPlayWithError:(NSError *)error withPlayerView:(SPCAVPlayerView *)playerView {
    if ([self.playerView isEqual:playerView]) {
        self.videoPlayBtn.hidden = NO;
        NSLog(@"failed to play with error!");
    }
}

#pragma mark - SPCMAMCoachmarkViewDelegate & Associated Methods

- (void)didTapToEndOnCoachmarkView:(UIView *)mamCoachmarkView {
    if ([self.viewCaptureCoachmark isEqual:mamCoachmarkView]) {
        self.captureCoachmarkWasShown = YES;
        
        [UIView animateWithDuration:0.3f animations:^{
            mamCoachmarkView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.viewCaptureCoachmark = nil;
        }];
    } else if ([self.viewAdjustmentCoachmark isEqual:mamCoachmarkView]) {
        self.adjustmentCoachmarkWasShown = YES;
        
        [UIView animateWithDuration:0.3f animations:^{
            mamCoachmarkView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.viewAdjustmentCoachmark = nil;
        }];
    }
}

- (void)showCaptureCoachmarkIfNeeded {
    if (NO == self.captureCoachmarkWasShown && nil == self.viewCaptureCoachmark) {
        self.viewCaptureCoachmark = [[SPCMAMCaptureCoachmarkView alloc] initWithFrame:self.view.bounds];
        self.viewCaptureCoachmark.delegate = self;
        self.viewCaptureCoachmark.alpha = 0.0f;
        
        [self.view addSubview:self.viewCaptureCoachmark];
        [UIView animateWithDuration:0.3f animations:^{
            self.viewCaptureCoachmark.alpha = 1.0f;
        }];
    }
}

- (void)showAdjustmentCoachmarkIfNeeded {
    if (MemoryTypeImage == self.memoryType && NO == self.adjustmentCoachmarkWasShown && nil == self.viewAdjustmentCoachmark) { // Show only for images, and if it hasn't been shown already
        self.viewAdjustmentCoachmark = [[SPCMAMAdjustmentCoachmarkView alloc] initWithFrame:self.view.bounds];
        self.viewAdjustmentCoachmark.delegate = self;
        self.viewAdjustmentCoachmark.alpha = 0.0f;
        self.viewAdjustmentCoachmark.userInteractionEnabled = NO;
        
        [self.view addSubview:self.viewAdjustmentCoachmark];
        [UIView animateWithDuration:0.2f delay:2.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.viewAdjustmentCoachmark.alpha = 1.0f;
        } completion:^(BOOL finished) {
            self.viewAdjustmentCoachmark.userInteractionEnabled = YES;
        }];
    }
}

- (void)setCaptureCoachmarkWasShown:(BOOL)captureCoachmarkWasShown {
    NSString *strCaptureCoachmarkStringUserLiteralKey = [SPCLiterals literal:kSPCMAMCaptureCoachmarkWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setBool:captureCoachmarkWasShown forKey:strCaptureCoachmarkStringUserLiteralKey];
}

- (BOOL)captureCoachmarkWasShown {
    BOOL wasShown = NO;
    
    NSString *strCaptureCoachmarkStringUserLiteralKey = [SPCLiterals literal:kSPCMAMCaptureCoachmarkWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:strCaptureCoachmarkStringUserLiteralKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strCaptureCoachmarkStringUserLiteralKey];
    }
    
    return wasShown;
}

- (void)setAdjustmentCoachmarkWasShown:(BOOL)adjustmentCoachmarkWasShown {
    NSString *strAdjustmentCoachmarkStringUserLiteralKey = [SPCLiterals literal:kSPCMAMAdjustmentCoachmarkWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setBool:adjustmentCoachmarkWasShown forKey:strAdjustmentCoachmarkStringUserLiteralKey];
}

- (BOOL)adjustmentCoachmarkWasShown {
    BOOL wasShown = NO;
    
    NSString *strAdjustmentCoachmarkStringUserLiteralKey = [SPCLiterals literal:kSPCMAMAdjustmentCoachmarkWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:strAdjustmentCoachmarkStringUserLiteralKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strAdjustmentCoachmarkStringUserLiteralKey];
    }
    
    return wasShown;
}

#pragma mark - Custom Camera Control Actions

-(void)flipCam {
    
    [self.captureManager toggleInput];
    self.isFrontFacing = !self.captureManager.isBackCam;
    
    if (!self.isFrontFacing) {
        [self.captureManager toggleFlash:self.isFlashOn];
    }
}

-(void)toggleFlash {
    if (!self.isFlashOn) {
        self.isFlashOn = YES;
        UIImage *flashImg = [UIImage imageNamed:@"camera-flash-on"];
        [self.customControls.flashBtn setBackgroundImage:flashImg forState:UIControlStateNormal];
    }
    else {
        self.isFlashOn = NO;
        UIImage *flashImg = [UIImage imageNamed:@"camera-flash-off"];
        [self.customControls.flashBtn setBackgroundImage:flashImg forState:UIControlStateNormal];
    }
    
    if (!self.isFrontFacing) {
        [self.captureManager toggleFlash:self.isFlashOn];
    }
}

-(void)detectedPossibleLongTap {
    NSLog(@"possible long tap?");
    [self performSelector:@selector(prepToBeginVideoCapture) withObject:nil afterDelay:1.0];
}

-(void)takePictureOrEndVideo {
    
    if (self.captureIsAdded) {
    
        if (!self.cameraIsLocked && !self.videoCaptureInProgress && self.processingAsset.hidden && [self.captureManager.captureSession isRunning]) {
            self.micPermissionImgView.hidden = YES;
            self.cameraIsLocked = YES;
            if (self.isFrontFacing && self.isFlashOn){
                self.frontFacingFlash.hidden = NO;
                [self.view bringSubviewToFront:self.frontFacingFlash];
            }
            self.tryToSaveToPhotoRoll = YES;
            [self.captureManager takePicture];
        }
        if (self.videoCaptureInProgress) {
            [self stopVideoCapture];
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prepToBeginVideoCapture) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(takeVideo) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startVideoCapture) object:nil];
        
    }
}

-(void)prepToBeginVideoCapture {
    
    self.customControls.closeBtn.alpha = .2f;
    self.customControls.closeBtn.userInteractionEnabled = NO;

    self.customControls.cameraRollBtn.alpha = 0.2f;
    self.customControls.cameraRollBtn.userInteractionEnabled = NO;
    
    self.customControls.skipBtn.alpha = .2f;
    self.customControls.skipBtn.userInteractionEnabled = NO;

    self.customControls.flashBtn.alpha = .2f;
    self.customControls.flashBtn.userInteractionEnabled = NO;

    self.customControls.flipCamBtn.alpha = .2f;
    self.customControls.flipCamBtn.userInteractionEnabled = NO;
    
    self.micPermissionImgView.hidden = YES;
    
    [self startVideoCapture];
}

-(void)startVideoCapture {
    if (!self.videoCaptureInProgress) {
        NSLog(@"start recording video!");
        [self.captureManager beginSavingVideoCapture];
        self.videoCaptureInProgress = YES;
        self.videoCaptureCounter = 0;
        self.pvCountdown.hidden = NO;
        [self incrementVideoProgress];
    }
}

-(void)incrementVideoProgress {
    
    self.videoCaptureCounter = self.videoCaptureCounter + 1;
    float progress = self.videoCaptureCounter;
    float total = 150.0f;
    self.pvCountdown.progress = (progress/total);
    
    if (self.videoCaptureCounter < total  && self.videoCaptureInProgress) {
        NSLog(@"incrementing video progress bar!");
        [self performSelector:@selector(incrementVideoProgress) withObject:nil afterDelay:0.1f];
    }
    else {
        NSLog(@"auto stopping!");
        [self autoStopVideo];
    }
    
}

-(void)stopVideoCapture {
    
    if (self.videoCaptureInProgress) {
        NSLog(@"DONE recording video, time to stop");
        self.tryToSaveToPhotoRoll  = YES;
        self.videoCaptureInProgress = NO;
        self.processingAsset.text = @"Processing Video..";
        self.processingAsset.hidden = NO;
        [self.captureManager endVideoCapture];
        [self showPostingOptions];
        self.pvCountdown.hidden = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementVideoProgress) object:nil];
    }
}

-(void)autoStopVideo{
    NSLog(@"auto stop video!");
    [self stopVideoCapture];
}

-(void)restoreCaptureControls {
    
    NSLog(@"restore capture controls!");
    
    self.customControls.closeBtn.alpha = 1.0f;
    self.customControls.closeBtn.userInteractionEnabled = YES;
    
    self.customControls.skipBtn.alpha = 1.0f;
    self.customControls.skipBtn.userInteractionEnabled = YES;
    
    self.customControls.flashBtn.alpha = 1.0f;
    self.customControls.flashBtn.userInteractionEnabled = YES;
    
    self.customControls.flipCamBtn.alpha = 1.0f;
    self.customControls.flipCamBtn.userInteractionEnabled = YES;
    
    self.customControls.cameraRollBtn.alpha = 1.0f;
    self.customControls.cameraRollBtn.userInteractionEnabled = YES;
    
    
    self.customControls.takePicBtn.enabled = YES;
    self.customControls.takePicBtn.alpha = 1.0f;
    self.customControls.takePicBtn.userInteractionEnabled = YES;
    self.capturePreviewImage.userInteractionEnabled = YES;
    self.processingAsset.hidden = YES;
}

#pragma mark - Navigation methods

-(void)dismissImagePicker {
    self.customControls.closeBtn.userInteractionEnabled = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMAM" object:nil];
}

-(void)displayCameraRoll {
    self.micPermissionImgView.hidden = YES;
  
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    
    if (status == ALAuthorizationStatusNotDetermined) {
        NSLog(@"not determined!");
        //just get the count of the asset library to trigger the system permission prompt
        ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
        [lib enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        } failureBlock:^(NSError *error) {
        }];
    }
    else if (status == ALAuthorizationStatusAuthorized) {
      NSLog(@"cam roll authorized!");
      [self presentViewController:self.cameraRollPickerController animated:YES completion:^{
      }];
    }
    else if (status == ALAuthorizationStatusDenied || ALAuthorizationStatusRestricted){
      [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Photo Access Disabled", nil)
                                message:NSLocalizedString(@"Spayce functionality will be limited without access to the camera roll. Please go to Settings > Privacy > Photos > and turn on Spayce", nil)
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
    }
}

-(void)showPostingOptions {
    
    self.customControls.bottomOverlay.hidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.captureManager.previewLayer.hidden = YES;
    self.micPermissionImgView.hidden = YES;
    NSLog(@"self.assetUploadCoordinator pending assets count: %li",self.assetUploadCoordinator.pendingAssets.count);
    
    float statusBarAdj = 0;
    
    if (self.expandedStatusBar) {
        statusBarAdj = 20;
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.postOptionsMenuView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.postOptionsMenuViewHeight);
                         self.locationOptionsView.frame = CGRectMake(0, self.view.bounds.size.height - self.locationOptionsMenuViewHeight - statusBarAdj, self.view.bounds.size.width, self.locationOptionsMenuViewHeight);
                     } completion:nil];
    
    // Show the adjustment coachmark as well, if needed
    [self showAdjustmentCoachmarkIfNeeded]; // Will display after 3 seconds
}

-(void)hidePostingOptions {
    
    self.view.backgroundColor = [UIColor blackColor];
    self.capturePreviewImage.hidden = YES;
    self.captureManager.previewLayer.hidden = NO;
    self.cameraIsLocked = NO;
    self.textBgView.hidden = YES;
    self.hashTagSuggestions.hidden = YES;
    self.customControls.takePicBtn.enabled = YES;
    self.customControls.takePicBtn.alpha = 1.0f;
    self.customControls.takePicBtn.userInteractionEnabled = YES;
    self.customControls.bottomOverlay.hidden = NO;
    self.pvCountdown.progress = 0;
    [self.playerView removeFromSuperview];
    self.playerView = nil;
    self.videoPlayBtn.hidden = YES;
    [self.assetUploadCoordinator clearAllAssets];
    self.capturePreviewImage.image = nil;
    
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         
                         self.locationOptionsView.frame = CGRectMake(0, self.view.bounds.size.height + self.locationOptionsMenuViewHeight, self.view.bounds.size.width, self.locationOptionsMenuViewHeight);
                         self.postOptionsMenuView.frame = CGRectMake(0, -self.postOptionsMenuViewHeight, self.view.bounds.size.width,self.postOptionsMenuViewHeight);
                  
                     } completion:nil];
}

-(void)showNoCamAlert {
  
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                      message:@"There is no camera available"
                                                     delegate:nil
                                            cancelButtonTitle:@"Dismiss"
                                            otherButtonTitles:nil];
    [alertView show];
}

-(void)textOnly {
    self.memoryType = MemoryTypeText;
    self.micPermissionImgView.hidden = YES;
    self.isPhotoRollMem = NO;
    [self.assetUploadCoordinator clearAllAssets];
    self.captureManager.previewLayer.hidden = YES;
    self.capturePreviewImage.image = nil;
    self.capturePreviewImage.alpha = 0.0f;
    self.postOptionsMenuView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.postOptionsMenuViewHeight);
    self.locationOptionsView.frame = CGRectMake(0, self.view.bounds.size.height - self.locationOptionsMenuViewHeight, self.view.bounds.size.width, self.locationOptionsMenuViewHeight);
    [self showTextInput];
}

-(void)viewMap{
    
    if (!self.viewingMap) {
        [Flurry logEvent:@"MAM_CHANGE_LOCATION_VIEWED"];
        self.mamLocationViewController = nil;
        self.viewingMap = YES;
        
        self.mamLocationViewController.view.frame = CGRectMake(self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        [self.view addSubview:self.mamLocationViewController.view];
      
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.mamLocationViewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
                       }
                       completion:nil];
    }
}

#pragma mark - Image Editing Methods

-(void)editImage {

    self.spcImageEditingController.sourceImage = self.capturedImage;
    self.spcImageEditingController.view.alpha = 0.0f;
    self.spcImageEditingController.view.center = CGPointMake(self.view.bounds.size.width/2, self.view.frame.size.height/2);
    [self.view addSubview:self.spcImageEditingController.view];
    if (self.expandedStatusBar) {
        [self.spcImageEditingController updateForCall];
    }
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.spcImageEditingController.view.alpha = 1.0f;
                     }
                     completion:nil];
}



#pragma mark - Actions

-(void)showTextInput {
    [Flurry logEvent:@"MAM_ADD_TEXT"];
    [self.textView becomeFirstResponder];
}

-(void)showTextMenu {
    
    NSLog(@"show text menu?");

    //do we already have text or an image?
    BOOL hasText = NO;

    if (self.textView.attributedText.string.length > 0) {
        hasText = YES;
    }
    
    //adjust for presence of text
    if (hasText) {
        self.previousText = self.textView.attributedText;
        self.placeholderTextLabel.hidden = YES;
    }
    else {
        self.placeholderTextLabel.hidden = NO;
    }
    
    //reveal and animate in!
    self.textBgView.hidden = NO;
    
    BOOL hasImage = NO;
    if (self.capturePreviewImage.image) {
        hasImage = YES;
    }
    
    //adjust for presence of image
    if (hasImage) {
        self.textMenuTitleLabel.text = NSLocalizedString(@"ADD CAPTION", nil);
        self.capturePreviewImage.hidden = NO;
    }
    else {
        self.textMenuTitleLabel.text = NSLocalizedString(@"ADD TEXT", nil);
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         
                         self.textMenu.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.postOptionsMenuViewHeight);
                         self.textBgView.alpha = 1.0f;
                         
                         if (hasImage) {
                             self.textBgView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.9f];
                         }
                         else {
                             self.textBgView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];
                         }
                     }
                     completion:nil];
}

-(void)cancelText {
  
    NSLog(@"cancel text input!");

    [self.textView resignFirstResponder];

    self.textView.attributedText = self.previousText;
    self.friendPicker.hidden = YES;
    self.taggingLabel.hidden = YES;
    self.taggingLabel.text = @"@";

    [self hashTagFullSweep];

    if (self.textView.attributedText.length > 0) {
        self.placeholderTextLabel.hidden = YES;
        [self.textBtn setBackgroundImage:[UIImage imageNamed:@"mamTextIcon"] forState:UIControlStateNormal];
        self.textLbl.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
    }
    else {
        self.placeholderTextLabel.hidden = NO;
        [self.textBtn setBackgroundImage:[UIImage imageNamed:@"mamNoTextIcon"] forState:UIControlStateNormal];
        self.textLbl.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
    }

  
    [UIView animateWithDuration:0.2
                            delay:0.0
                          options:UIViewAnimationOptionCurveEaseOut
                       animations:^{
                         
                         self.hashTagSuggestions.alpha = 0;
                         self.textMenu.frame = CGRectMake(0, -self.postOptionsMenuViewHeight, self.view.bounds.size.width, self.postOptionsMenuViewHeight);
                         if (self.capturePreviewImage.image) {
                             self.textBgView.alpha = 0.0f;
                             self.textBgView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];
                         }
                       }
                     completion:^(BOOL finished) {
                         if (finished) {
                             self.textBgView.hidden = NO;
                         }
                     }];
}


-(void)cancelPicker {
    self.taggingLabel.hidden = YES;
    self.taggingLabel.text = @"@";
    self.friendPicker.hidden = YES;
}

-(void)saveTextAndDismiss {
    [self.textView resignFirstResponder];
    [self hashTagFullSweep];
    [self.hashTagSuggestions updateRecentHashTags];
    
    NSLog(@"saveTextAndDismiss and text:_%@_",self.textView.attributedText.string);
    
    if (self.textView.attributedText.string.length > 0) {
        NSLog(@"has text??");
        [self.textBtn setBackgroundImage:[UIImage imageNamed:@"mamTextIcon"] forState:UIControlStateNormal];
        self.textLbl.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
    }
    else {
        NSLog(@"NO text??");
        [self.textBtn setBackgroundImage:[UIImage imageNamed:@"mamNoTextIcon"] forState:UIControlStateNormal];
        self.textLbl.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
    }
  

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                     
                         self.hashTagSuggestions.alpha = 0;
                         self.textMenu.frame = CGRectMake(0, -self.postOptionsMenuViewHeight, self.view.bounds.size.width, self.postOptionsMenuViewHeight);
                     
                         if (self.capturePreviewImage.image) {
                             self.textBgView.alpha = 0.0f;
                             self.textBgView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0f];
                         }
                   }
                     completion:^(BOOL finished) {
                         if (finished) {
                             self.textBgView.hidden = NO;
                         }
                     }];
}

-(void)setToReal {
    self.isAnon = NO;
    self.anonRealKnob.image = [UIImage imageNamed:@"mamRealKnob"];
    self.realLbl.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
    self.anonLbl.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
}

-(void)setToAnon {
    
    BOOL canPostAnon = [SettingsManager sharedInstance].anonPostingEnabled;
    
    if (canPostAnon) {
        self.isAnon = YES;
        [Flurry logEvent:@"MAM_SET_TO_ANON"];
        self.anonRealKnob.image = [UIImage imageNamed:@"mamAnonKnob"];
        self.realLbl.textColor = [UIColor colorWithRed:137.0f/255.0f green:137.0f/255.0f blue:137.0f/255.0f alpha:1.0f];
        self.anonLbl.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
    }
    else {
        [self showAnonAlert];
        
        [self setToReal];
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.anonRealKnob.center = CGPointMake(self.anonRealMaxX, self.anonRealKnob.center.y);
                         }
                         completion:nil];
    }
}

-(void)postMem {
    //TODO !
    NSLog(@"--- post when everything is done! --- ");
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [self.view addSubview:self.loadingView];
    [self.view addSubview:self.progressBar];
    
    self.progressBarUploadsComplete = -1;
    self.progressBarUploadsCompleteBeforeAnchor = self.assetUploadCoordinator.uploadedAssetCount;
    
    self.uploadStartTime = [[NSDate date] timeIntervalSince1970];
    self.uploadProgress = 0;
    self.uploadStepProgressStart = 0;
    
    [self updateProgressBar:self.assetUploadCoordinator.uploadedAssetCount];
    
    int memType = [self getMemoryType];
    if (memType == 1) {
        //text mem - cleared to send to server
        [self savePost];
    } else {
    
        __weak typeof(self) weakSelf = self;
        [self.assetUploadCoordinator uploadAssetsWithProgressHandler:^(SPCAssetUploadCoordinator *coordinator, NSInteger assetsUploaded, NSInteger totalAssets) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf updateProgressBar:assetsUploaded];
        } completionHander:^(SPCAssetUploadCoordinator *coordinator) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf updateProgressBar:coordinator.uploadedAssetCount];
            [strongSelf savePost];
            
        } failureHandler:^(SPCAssetUploadCoordinator *coordinator, NSError *error) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf stopLoadingProgressView];
            self.progressBarUploadsComplete = 0;
            
            NSString *message = (strongSelf.assetUploadCoordinator.hasVideos
                                 ? @"There was an error saving your videos for this memory. Please try again"
                                 : @"There was an error saving your images for this memory. Please try again");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
            [alertView show];
            
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            
        }];
    }
    
}

-(void)savePost {
    
    //MEMORY TEXT
    NSString *memText = self.markupString;
    
    //TAGGED FRIENDS
    self.includedIds = [self createIdList];
    
    //PUBLIC/PRIVATE
    NSString *access = [self getPrivacy];
    
    //LOCATION
    NSLog(@"sel ven lat ? %@",self.selectedVenue.latitude);
    
    double memLat = [self.selectedVenue.latitude doubleValue];
    double memLong = [self.selectedVenue.longitude doubleValue];
    
    //LOCATION NAME
    NSString *locationName = self.selectedVenue.displayName;
    
    //MEMORY TYPE
    int memType = [self getMemoryType];
    
    //ASSET IDS
    NSString *assetIds = [self getAssetIds];
    
    //HASHTAGS
    NSString *hashtags = [self getHashTags];
    
    //Venue Address ID
    NSInteger addyId = self.selectedVenue.addressId;
    
    __weak typeof(self)weakSelf = self;
    
    self.memoryPostDidFault = NO;
    
    
    [MeetManager postMemoryWithUserIds:self.includedIds
                                  text:memText
                              assetIds:assetIds
                             addressId:(int)addyId
                              latitude:memLat
                             longitude:memLong
                            accessType:access
                              hashtags:hashtags
                        fbShareEnabled:NO
                      twitShareEnabled:NO
                                isAnon:self.isAnon
                             territory:nil
                                  type:memType
                        resultCallback:^(NSInteger memId, Venue *memVenue, NSString *memoryKey) {
                            __strong typeof(weakSelf)strongSelf = weakSelf;
                            
                            //[strongSelf stopLoadingProgressView];
                            
                            if (strongSelf.didFilterImage) {
                                [Flurry logEvent:@"MAM_FILTERED_MEM_POSTED"];
                            }
                            if (memType == MemoryTypeText) {
                                [Flurry logEvent:@"MAM_TEXT_MEM_POSTED"];
                            }
                            
                            if (strongSelf.isPhotoRollMem) {
                                if (memType == MemoryTypeImage) {
                                    [Flurry logEvent:@"MAM_PHOTO_ROLL_MEM_POSTED"];
                                }
                                if (memType == MemoryTypeVideo) {
                                    [Flurry logEvent:@"MAM_VIDEO_ROLL_MEM_POSTED"];
                                }
                            }
                            else {
                                if (memType == MemoryTypeImage) {
                                    [Flurry logEvent:@"MAM_SPAYCE_PHOTO_POSTED"];
                                }
                                if (memType == MemoryTypeVideo) {
                                    [Flurry logEvent:@"MAM_SPAYCE_VID_POSTED"];
                                }
                            }
                            
                            
                            //populate memory object to pass back to the MemoriesViewController
                            NSDictionary *locationDict;
                            
                            NSDictionary *venueDict;
                            
                            if (memVenue) {
                                locationDict = @{@"latitude" : memVenue.latitude,
                                                 @"longitude" : memVenue.longitude};
                                
                                if (memVenue.specificity == SPCVenueIsFuzzedToCity) {
                                    venueDict = @{@"name" : locationName,
                                                  @"latitude" : memVenue.latitude,
                                                  @"longitude" : memVenue.longitude,
                                                  @"addressId" : @(memVenue.addressId),
                                                  @"city" : memVenue.city,
                                                  @"specificity" : @"CITY" };
                                }
                                else if (memVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                                    venueDict = @{@"name" : locationName,
                                                  @"latitude" : memVenue.latitude,
                                                  @"longitude" : memVenue.longitude,
                                                  @"addressId" : @(memVenue.addressId),
                                                  @"neighborhood" : memVenue.neighborhood,
                                                  @"specificity" : @"NEIGHBORHOOD"  };
                                }
                                else {
                                    venueDict = @{@"name" : locationName,
                                                  @"latitude" : memVenue.latitude,
                                                  @"longitude" : memVenue.longitude,
                                                  @"addressId" : @(memVenue.addressId) };
                                }
                                
                            }
                            else {
                                locationDict = @{@"latitude" : @(memLat),
                                                 @"longitude" : @(memLong)};
                                
                                venueDict = @{@"name" : locationName,
                                              @"latitude" : @(memLat),
                                              @"longitude" : @(memLong),
                                              @"addressId" : @(addyId) };
                                
                            }
                            
                            //NSLog(@"location dict %@",locationDict);
                            //NSLog(@"venue dict %@",venueDict);
                            
                            
                            strongSelf.profile = [ContactAndProfileManager sharedInstance].profile;
                            User *tempMe = [AuthenticationManager sharedInstance].currentUser;
                            int authorId = (int)tempMe.userId;
                            
                            NSString *myFirstName =  self.profile.profileDetail.firstname;
                            NSString *myId = [NSString stringWithFormat:@"%i",authorId];
                            NSDictionary *myPhoto = self.profile.profileDetail.imageAsset.attributes;
                            NSString *userToken = tempMe.userToken;
                            NSDictionary *authorDict;
                            
                            int isAnonymousPost = 0;
                            
                            if (strongSelf.isAnon) {
                                NSLog(@"is anon memory!");
                                myFirstName = @"Anonymous";
                                authorId = -2;
                                myId = [NSString stringWithFormat:@"%i",authorId];
                                
                                userToken = @"";
                                myPhoto = [ContactAndProfileManager sharedInstance].profile.profileDetail.anonImageAsset.attributes;
                                isAnonymousPost = 1;
                                strongSelf.selectedFriends = nil;
                            }
                            
                            
                            if (myPhoto) {
                                
                                authorDict = @{
                                               @"firstname" : myFirstName,
                                               @"id" : myId,
                                               @"profilePhotoAssetInfo" : myPhoto,
                                               @"userToken" : userToken,
                                               };
                            } else {
                                authorDict = @{
                                               @"firstname" : myFirstName,
                                               @"id" : myId,
                                               @"userToken" : userToken,
                                               };
                            }
                            
                            
                            NSTimeInterval interval = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate])*1000;
                            NSNumber *dateNum = @(interval);
                            
                            int friendsCount = (int)[self.selectedFriends count];
                            NSNumber *fCount = @(friendsCount);
                            
                            NSLog(@"posted mem & callback mem id: %i",(int)memId);
                            NSNumber *memIdNum = @(memId);
                            
                            
                            
                            NSNumber *typeNum = @(memType);
                            
                            NSDictionary *memAttributes;
                            Memory *newMemory;
                            
                            if (memType == 1){
                                
                                NSString *adjMemText = memText;
                                
                                //adjust local copy of wordless text mems
                                if (adjMemText.length == 0) {
                                    adjMemText = @"is here.";
                                }
                                
                                memAttributes = @{
                                                  @"author" : authorDict,
                                                  @"dateCreated" : dateNum,
                                                  @"friends_count" : fCount,
                                                  @"id" : memIdNum,
                                                  @"locationName" : locationName,
                                                  @"location" : locationDict,
                                                  @"text" : adjMemText,
                                                  @"type" : typeNum,
                                                  @"accessType" : access,
                                                  @"localTaggedUsers" : self.selectedFriends,
                                                  @"venue" : venueDict,
                                                  @"isAnonMem" : @(isAnonymousPost)
                                                  };
                                
                                newMemory = [[Memory alloc] initWithAttributes:memAttributes];
                            }
                            
                            if (memType == 2) {
                                memAttributes = @{
                                                  @"author" : authorDict,
                                                  @"dateCreated" : dateNum,
                                                  @"friends_count" : fCount,
                                                  @"id" : memIdNum,
                                                  @"locationName" : locationName,
                                                  @"location" : locationDict,
                                                  @"text" : memText,
                                                  @"type" : typeNum,
                                                  @"assetsInfo" : [Asset arrayOfAttributesWithAssets:self.assetUploadCoordinator.uploadedAssets],
                                                  @"assets" : self.assetUploadCoordinator.uploadedAssetIdStrings,
                                                  @"accessType" : access,
                                                  @"localTaggedUsers" : self.selectedFriends,
                                                  @"venue" : venueDict,
                                                  @"isAnonMem" : @(isAnonymousPost)
                                                  };
                                
                                newMemory = [[ImageMemory alloc] initWithAttributes:memAttributes];
                            }
                            
                            if (memType == 3) {
                                memAttributes = @{
                                                  @"author" : authorDict,
                                                  @"dateCreated" : dateNum,
                                                  @"friends_count" : fCount,
                                                  @"id" : memIdNum,
                                                  @"locationName" : locationName,
                                                  @"location" : locationDict,
                                                  @"text" : memText,
                                                  @"type" : typeNum,
                                                  @"assetsInfo" : [Asset arrayOfAttributesWithAssets:self.assetUploadCoordinator.uploadedAssets],
                                                  @"assets" : self.assetUploadCoordinator.uploadedAssetIdStrings,
                                                  @"accessType" : access,
                                                  @"localTaggedUsers" : self.selectedFriends,
                                                  @"venue" : venueDict,
                                                  @"isAnonMem" : @(isAnonymousPost)
                                                  };
                                
                                newMemory = [[VideoMemory alloc] initWithAttributes:memAttributes];
                            }
                            
                            if (memoryKey) {
                                newMemory.key = memoryKey;
                            }
                            if (newMemory.isAnonMem) {
                                newMemory.userIsWatching = YES;
                            }
                            
                            [strongSelf saveMemoryAndAddToFeed:newMemory withVenue:strongSelf.selectedVenue];
                            
                            
                            [strongSelf updateProgressBar:self.assetUploadCoordinator.uploadedAssetCount + 1];
                            
                            // 'isAnchoring' is still true; we will set it to false AFTER
                            // taking a screenshot, which happens in saveScreenshotAndFinish
                        }
                         faultCallback:^(NSError *fault) {
                             NSLog(@"post mem faultCallback: %@", fault);
                             self.memoryPostDidFault = YES;
                             
                             //self.isAnchoring = NO;
                             //self.anchorBtn.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
                             //[self.anchorBtn setTitle:NSLocalizedString(@"Spayce", nil) forState:UIControlStateNormal];
                             
                             [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                             self.progressBarUploadsComplete = -1;
                             [weakSelf stopLoadingProgressView];
                             
                         }
     ];

}

- (void)saveMemoryAndAddToFeed:(Memory *)m withVenue:(Venue *)venue {
    m.addressID = venue.addressId;
    m.venue = venue;
    if (!m.isAnonMem){
        m.author.firstname = self.profile.profileDetail.firstname;
        m.author.userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
        if (m.type == MemoryTypeText && [m.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
            m.text = @"is here.";
        }
    }
    // count memories posted
    NSString * numMemoriesPostedKey = [SPCLiterals literal:kSPCNumMemoriesPosted forUser:[AuthenticationManager sharedInstance].currentUser];
    NSInteger numMemoriesPosted = [[NSUserDefaults standardUserDefaults] integerForKey:numMemoriesPostedKey];
    numMemoriesPosted++;
    [[NSUserDefaults standardUserDefaults] setInteger:numMemoriesPosted forKey:numMemoriesPostedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"addMemoryLocally" object:m];
    
    // 'isAnchoring' is still true; we will set it to false AFTER
    // taking a screenshot, which happens in saveScreenshotAndFinish

}


#pragma mark - Private

-(void)addCaptureManager {
    
    self.captureManager = [[SPCCaptureManager alloc] init];
    self.captureManager.delegate = self;
    [self.captureManager addInputs];
    [self.captureManager addVideoPreviewLayer];
    [self.captureManager addOutputs];
    
    
    self.captureManager.previewLayer.frame = self.capturePreviewImage.frame;
    [self.view.layer addSublayer:self.captureManager.previewLayer];
    
    self.captureIsAdded = YES;
    
    [self.view bringSubviewToFront:self.micPermissionImgView];
    self.micPermissionImgView.center = CGPointMake(self.view.bounds.size.width/2, CGRectGetMaxY(self.capturePreviewImage.frame));

}

-(void)refreshVenues {
    if (self.performingRefresh) {
        return;
    }
    
    self.performingRefresh = YES;
  
    //NSLog(@"refreshing mam venues!");
  
    // load locations around the user's current location
    [[LocationManager sharedInstance] waitForUptime:MINIMUM_LOCATION_MANAGER_UPTIME withSuccessCallback:^(NSTimeInterval uptime) {
        
        [[LocationContentManager sharedInstance] getContent:@[SPCLocationContentVenue, SPCLocationContentDeviceVenue,SPCLocationContentFuzzedNeighborhoodVenue,SPCLocationContentFuzzedCityVenue, SPCLocationContentNearbyVenues]
                                             resultCallback:^(NSDictionary *results) {
                                                 
                                                 //NSLog(@"got mam venue results!");
                                                 [self updateWithLocationContentResults:results];
                                                 self.performingRefresh = NO;
                                             }
                                              faultCallback:^(NSError *fault) {
                                                  // TODO: Show error table view cell
                                                  // No nearby locations found
                                                  //NSLog(@"error fetching nearby locations: %@", fault);
                                                  self.performingRefresh = NO;
                                              }];
    }
                                      faultCallback:^(NSError *error) {
                                          // TODO: Show error table view cell
                                          // No nearby locations found
                                          //NSLog(@"error waiting for uptime: %@", error);
                                          self.performingRefresh = NO;
                                      }];
}

-(void)updateWithLocationContentResults:(NSDictionary *)results {
    if ((Venue *)results[SPCLocationContentFuzzedCityVenue]) {
        //NSLog(@"got fuzzed city venue!");
        Venue *fuzzedCityVenue = (Venue *)results[SPCLocationContentFuzzedCityVenue];
        self.fuzzedCityVenue = fuzzedCityVenue;
        self.selectedVenue = self.fuzzedCityVenue;
        self.selectedLocationNameLabel.text = fuzzedCityVenue.city;
    }
    else {
        //NSLog(@"no city venue!");
        self.locationMidSpectrum.alpha = 0;
        self.locationKnob.center = CGPointMake(self.locMaxX, self.locationKnob.center.y);
    
        //do we have a neighborhood w/o a city?
        if ((Venue *)results[SPCLocationContentFuzzedNeighborhoodVenue]) {
            //NSLog(@"got fuzzed neighborhood venue!");
            Venue *fuzzedNeighborhoodVenue = (Venue *)results[SPCLocationContentFuzzedNeighborhoodVenue];
            self.selectedVenue = fuzzedNeighborhoodVenue;
            self.selectedLocationNameLabel.text = fuzzedNeighborhoodVenue.neighborhood;
            self.activeLocationTypeLabel.text = NSLocalizedString(@"Neighborhood", nil);
            self.locationRightSpectrum.text = NSLocalizedString(@"Neighborhood", nil);
      
            self.locationKnob.center = CGPointMake(self.locMaxX, self.locationKnob.center.y);
        }
    }
  
    if ((Venue *)results[SPCLocationContentFuzzedNeighborhoodVenue]) {
        //NSLog(@"got fuzzed neighborhood venue!");
        Venue *fuzzedNeighborhoodVenue = (Venue *)results[SPCLocationContentFuzzedNeighborhoodVenue];
        self.fuzzedNeighorhoodVenue = fuzzedNeighborhoodVenue;
        self.selectedLocationNameLabel.text = fuzzedNeighborhoodVenue.neighborhood;
    }
    else {
        //NSLog(@"no neighboorhood venue!");
        self.locationMidSpectrum.alpha = 0;
        self.locationRightSpectrum.text = NSLocalizedString(@"City", nil);
        self.selectedLocationNameLabel.text = self.fuzzedCityVenue.city;
        self.activeLocationTypeLabel.text = NSLocalizedString(@"City", nil);
        self.locationKnob.center = CGPointMake(self.locMaxX, self.locationKnob.center.y);
    }
  
  
    if ((Venue *)results[SPCLocationContentDeviceVenue]) {
        self.placeVenue = (Venue *)results[SPCLocationContentDeviceVenue];
    }
  
    if (results[SPCLocationContentNearbyVenues]) {
    
        self.nearbyVenues = results[SPCLocationContentNearbyVenues];
    
        CLLocation *location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            location = [LocationManager sharedInstance].currentLocation;
        }
        
        for (Venue *venue in self.nearbyVenues) {
            CGFloat distance = (location && venue.location) ? [location distanceFromLocation:venue.location] : -1;
            venue.distanceAway = distance;
        }
    }
  
    self.venuesAreCurrent = YES;
}

- (void) statusBarFrameChanged:(NSNotification*)notification
{
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    NSLog(@"status bar frame height %f",statusBarFrame.size.height);
    
    float maxUnexpandedHeight = 20;
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        maxUnexpandedHeight = 0;
    }
    
    if ( CGRectGetHeight(statusBarFrame) > maxUnexpandedHeight) {
        self.expandedStatusBar = YES;
    }
    else {
        self.expandedStatusBar = NO;
        NSLog(@"view frame height %f",self.view.frame.size.height);
        CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
        NSLog(@"status bar frame height %f",statusBarFrame.size.height);
    }
    
    if (self.captureManager.previewLayer.hidden && !self.expandedStatusBar) {
        NSLog(@"displaying preview - and status bar is not expanded?");
        self.locationOptionsView.frame = CGRectMake(0, self.view.frame.size.height - self.locationOptionsMenuViewHeight, self.view.bounds.size.width, self.locationOptionsMenuViewHeight);
    
        NSLog(@"view frame height %f",self.view.frame.size.height);
    }
    
    if (!self.captureManager.previewLayer.hidden && !self.expandedStatusBar) {
        NSLog(@"in capture mode and not expanded status bar!");
        NSLog(@"view frame height %f",self.view.frame.size.height);
    }
}

- (void)showAnonAlert {
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Anonymous Posting Disabled", nil)
                                message:NSLocalizedString(@"You are not authorized to post anonymously at this time.", nil)
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
}

#pragma mark - Helper Methods to prep params when posting a memory

-(NSString *)createIdList {
    //get user ids
    NSString *includedUserIds = @"";
    
    NSArray *currentlyTaggedUserIds = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USERID];
    includedUserIds = [(NSArray *)currentlyTaggedUserIds componentsJoinedByString:@","];
    
    return includedUserIds;
}

-(NSString *)getPrivacy {
    
    NSString *accessType = @"PUBLIC";
    return accessType;
}

-(int)getMemoryType {
    
    int currType = 1;
    
    if (self.assetUploadCoordinator.hasImages) {
        currType = 2;
    }
    if (self.assetUploadCoordinator.hasVideos) {
        currType = 3;
    }
    
    return currType;
}

-(NSString *)getAssetIds {
    NSString *assetIds = @"";
    NSArray *assetIdStrs = self.assetUploadCoordinator.uploadedAssetIdStrings;
    
    if ([assetIdStrs count] > 0) {
        assetIds = [assetIdStrs componentsJoinedByString:@","];
    }
    
    return assetIds;
}

-(NSString *)getHashTags {
    
    //turn our array of selected hash tags into a " " separated string with all #'s stripped out
    NSMutableArray *hashTagsArray = [NSMutableArray arrayWithArray:[self.hashTagSuggestions getSelectedHashTags]];
    NSMutableString *fullHashTagString = [[NSMutableString alloc] initWithString:@""];
    
    while (hashTagsArray.count > 0) {
        
        //get the next hash tag
        NSString *hashedTag = [hashTagsArray objectAtIndex:0];
        
        // sanity check
        if (hashedTag.length > 1) {
            
            //strip out the #s
            NSString *cleanTag = [hashedTag substringFromIndex:1];
            //NSLog(@"cleanTag %@",cleanTag);
            
            //append to our full string with a trailing space
            if (hashTagsArray.count > 1) {
                [fullHashTagString appendString:[NSString stringWithFormat:@"%@ ",cleanTag]];
                //NSLog(@"updated full string %@",fullHashTagString);
            }
            //add just the tag to our full string (it's the last one)
            else {
                [fullHashTagString appendString:[NSString stringWithFormat:@"%@",cleanTag]];
                //NSLog(@"updated full string %@",fullHashTagString);
            }
        }
        
        //update our data
        [hashTagsArray removeObjectAtIndex:0];
    }
    
    //NSLog(@"full hash tag string :%@",fullHashTagString);
    return fullHashTagString;
}


#pragma mark - Image Rotation/Scaling methods

-(void)prepImage:(UIImage *)image {
    //handling scaling/saving of image on background thread to maintain UI responsiveness when transitioning directly to Post Mem VC
  
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage *scaledSourceImg = [self scaleUIImage:image];
    
        //saving scaled image to cam roll rather that source image to reduce memory pressure
        if (self.tryToSaveToPhotoRoll) {
            if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                UIImageWriteToSavedPhotosAlbum(scaledSourceImg, nil, nil, nil);
            }
        }
    
        
        //finish off back on main thread
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSLog(@"display catured image!");
            
            NSLog(@"scaled source img width %f height %f",scaledSourceImg.size.width,scaledSourceImg.size.height);
            
            SPCImageToCrop *imageToCrop = [[SPCImageToCrop alloc] initWithNewMAMDefaultsAndImage:scaledSourceImg];
            self.capturedImage = imageToCrop;
            self.capturePreviewImage.image = imageToCrop.cropPreviewImage;
            self.capturePreviewImage.hidden = NO;
            self.capturePreviewImage.alpha = 1.0f;
            self.processingAsset.hidden = YES;
            self.captureManager.previewLayer.hidden = YES;
        
            [self.assetUploadCoordinator addPendingAsset:[[SPCPendingAsset alloc] initWithImageToCrop:imageToCrop]];
        });
    });
}

-(UIImage*)rotateUIImage:(UIImage*)sourceImage clockwise:(BOOL)clockwise {
    CGSize size = sourceImage.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    [[UIImage imageWithCGImage:[sourceImage CGImage] scale:1.0 orientation:clockwise ? UIImageOrientationRight : UIImageOrientationLeft] drawInRect:CGRectMake(0,0,size.height ,size.width)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  
    return newImage;
}

-(UIImage *)scaleUIImage:(UIImage *)sourceImage {
    CGSize size = sourceImage.size;

    float scaleFactor = 1000/size.width;

    if (size.width > size.height) {
        scaleFactor = 1334/size.height;
    }

    float adjWidth = floorf(size.width*scaleFactor);
    float adjHeight = floorf(size.height*scaleFactor);
    //NSLog(@"re adjustedWidth %f, re adjustedHeight %f",adjWidth,adjHeight);

    UIGraphicsBeginImageContext(CGSizeMake(adjWidth, adjHeight));
    [[UIImage imageWithCGImage:[sourceImage CGImage] scale:scaleFactor orientation:[sourceImage imageOrientation]]
    drawInRect:CGRectMake(0,0,adjWidth,adjHeight)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

-(void)keyboardOnScreen:(NSNotification *)notification {
    NSDictionary *info  = notification.userInfo;
    NSValue *value = info[UIKeyboardFrameEndUserInfoKey];

    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    float hashOriginY = keyboardFrame.origin.y - 110;

    self.hashTagSuggestions.frame = CGRectMake(0, hashOriginY, self.view.bounds.size.width, self.view.bounds.size.height - hashOriginY);

    [UIView animateWithDuration:0.1
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^{
                     
                     self.hashTagSuggestions.alpha = 1.0f;
                     
                   } completion:nil];
}


#pragma mark - Video Processing methods

-(void)addVideoWithURL:(NSURL *)videoURL {
    
    self.memoryType = MemoryTypeVideo;
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    CMTime duration = sourceAsset.duration;
    float seconds = CMTimeGetSeconds(duration);
    //NSLog(@"got video with duration %f",seconds);
    
    if (seconds > 16) {
        NSLog(@"video is too long!");
        [self videoLengthAlert];
        
        self.numVideosProcesssing = self.numVideosProcesssing - 1;
        [self restoreCaptureControls];
    }
    else {
        
        if (self.tryToSaveToPhotoRoll) {
            if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                NSLog(@"save video to cam roll!");
                ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
                [assetLibrary writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error){ }];
            }
        }
        
        //compress vid & save url to use when uploading
        NSArray *searchPaths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath_ = searchPaths[0];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"ddMMMYY_hhmmssa";
        NSString *datedStr = [formatter stringFromDate:[NSDate date]];
        NSString *uniquePath = [NSString stringWithFormat:@"%@compressedVid.mp4",datedStr];
        NSString *pathToSave = [documentPath_ stringByAppendingPathComponent:uniquePath];
        
        __block SPCImageToCrop *imageToCrop = nil;
        
        // File URL
        NSURL *outputURL = [NSURL fileURLWithPath:pathToSave];
        [self convertVideoToLowQuailtyWithInputURL:videoURL outputURL:outputURL handler:^(BOOL success) {
             if (success) {
                 NSLog(@"completed compression\n");
                 // Place this video, with thumbnail, in our pending asset list.
                 [self.assetUploadCoordinator addPendingAsset:[[SPCPendingAsset alloc] initWithImageToCrop:imageToCrop videoURL:outputURL]];
                 
                 self.memoryType = MemoryTypeVideo;
                 
                 [self.playerView removeFromSuperview];
                 self.playerView = nil;
                 NSLog(@"Initing playerItem");
                 AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
                 NSLog(@"Initing player");
                 AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
                 NSLog(@"Initing playerView");
                 SPCAVPlayerView *playerView = [[SPCAVPlayerView alloc] initWithPlayer:player];
                 playerView.delegate = self;
                 self.playerView = playerView;
 
                //finish off back on main thread
                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                     [self.view insertSubview:self.playerView belowSubview:self.videoPlayBtn];
                     self.videoPlayBtn.center = CGPointMake(self.capturePreviewImage.center.x, self.capturePreviewImage.center.y);
                     self.videoPlayBtn.hidden = NO;
                 });
                 
                 self.numVideosProcesssing = self.numVideosProcesssing - 1;
                 [self performSelectorOnMainThread:@selector(restoreCaptureControls) withObject:nil waitUntilDone:NO];
             } else {
                 NSLog(@"compression error\n");
                 self.numVideosProcesssing = self.numVideosProcesssing - 1;
                 [self performSelectorOnMainThread:@selector(restoreCaptureControls) withObject:nil waitUntilDone:NO];
             }
         }];
        
        // Create a thumbnail image to use for this video
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        AVAssetImageGenerator *imageGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        NSError *err = NULL;
        CMTime time = CMTimeMake(0, 60);
        CGImageRef imgRef = [imageGen copyCGImageAtTime:time actualTime:NULL error:&err];
        UIImage *thumb = [[UIImage alloc] initWithCGImage:imgRef];
        
        if (self.portraitVid) {
            self.portraitVid = NO;
            thumb = [self rotateUIImage:thumb clockwise:YES];
        }
        if (self.upsideDownPortraitVid) {
            self.upsideDownPortraitVid = NO;
            thumb = [self rotateUIImage:thumb clockwise:NO];
        }
        
        if (self.landscapeLeft) {
            thumb = [self rotateUIImage:thumb clockwise:NO];
            thumb = [self rotateUIImage:thumb clockwise:NO];
        }
        
        
        
        
        imageToCrop = [[SPCImageToCrop alloc] initWithNewMAMDefaultsAndImage:thumb];
        self.capturePreviewImage.image = imageToCrop.cropPreviewImage;
        self.capturePreviewImage.hidden = NO;
        
        //show psoting options right away
        [self showPostingOptions];
    }
}

-(void)compressVideoWithInputURL:(NSURL*)inputURL
                        outputURL:(NSURL*)outputURL
                          handler:(void (^)(AVAssetExportSession*))handler {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetTrack* videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    CGSize size = [videoTrack naturalSize];
    //NSLog(@"vid size w:%f h:%f",size.width,size.height);
    CGAffineTransform txf = [videoTrack preferredTransform];
    NSLog(@"txf.a = %f txf.b = %f txf.c = %f txf.d = %f txf.tx = %f txf.ty = %f", txf.a, txf.b, txf.c, txf.d, txf.tx, txf.ty);
    
    if (size.width == txf.tx && size.height == txf.ty) {
        self.landscapeLeft = YES;
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    
    if (txf.d == 0){
        NSLog(@"not landscape! rotate!");
        self.landscapeLeft = NO;
        self.portraitVid = YES;
        if (txf.tx == 0 && txf.ty == videoTrack.naturalSize.width) {
            self.portraitVid = NO;
            self.upsideDownPortraitVid = YES;
        }
        
        //Create AVMutableComposition object.
        AVMutableComposition *composition = [AVMutableComposition composition];
        
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
        
        //only try to handle audio if it's availalbe
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
            
            AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
        }
        
        //Create AVMutableVideoCompositionInstruction
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration);
        
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        
        if (self.portraitVid){
            CGAffineTransform t1 = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
            [layerInstruction setTransform:t2 atTime:kCMTimeZero];
        }
        if (self.upsideDownPortraitVid) {
            CGAffineTransform t1 = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
            CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, videoTrack.naturalSize.width);
            CGAffineTransform t3 = CGAffineTransformConcat(t2, flipVertical);
            
            [layerInstruction setTransform:t3 atTime:kCMTimeZero];
        }
        
        instruction.layerInstructions = @[layerInstruction];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.instructions = @[instruction];
        videoComposition.frameDuration = CMTimeMake(1, 600);
        videoComposition.renderScale = 1.0;
        CGSize naturalSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
        videoComposition.renderSize =  naturalSize;
        
        //export!
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
        exportSession.outputURL = outputURL;
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.videoComposition = videoComposition;
        [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
         {
             handler(exportSession);
         }];
        
        
    }
    
    else {
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
        exportSession.outputURL = outputURL;
        exportSession.outputFileType = AVFileTypeMPEG4;
        [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
         {
             handler(exportSession);
         }];
    }
}

-(void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
                                   outputURL:(NSURL*)outputURL
                                     handler:(void (^)(BOOL success))handler {
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    
    
    //setup video writer
    AVAsset *videoAsset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize videoSize = videoTrack.naturalSize;
    
    //handle rotation as needed!
    CGAffineTransform txf = [videoTrack preferredTransform];
    NSLog(@"txf.a = %f txf.b = %f txf.c = %f txf.d = %f txf.tx = %f txf.ty = %f", txf.a, txf.b, txf.c, txf.d, txf.tx, txf.ty);
    
    if (videoSize.width == txf.tx && videoSize.height == txf.ty) {
        self.landscapeLeft = YES;
    }
    
    CGAffineTransform preferredTransform = videoTrack.preferredTransform;
    
    if (txf.d == 0){
        NSLog(@"not landscape! rotate!");
        self.landscapeLeft = NO;
        self.portraitVid = YES;
        if (txf.tx == 0 && txf.ty == videoTrack.naturalSize.width) {
            self.portraitVid = NO;
            self.upsideDownPortraitVid = YES;
        }
        if (self.portraitVid){
            CGAffineTransform t1 = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
            preferredTransform = t2;
        }
        if (self.upsideDownPortraitVid) {
            CGAffineTransform t1 = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
            CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, videoTrack.naturalSize.width);
            CGAffineTransform t3 = CGAffineTransformConcat(t2, flipVertical);
            preferredTransform = t3;
        }
    }
    
    NSDictionary *videoWriterCompressionSettings =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1960000], AVVideoAverageBitRateKey, nil];
    
    NSDictionary *videoWriterSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, videoWriterCompressionSettings, AVVideoCompressionPropertiesKey, [NSNumber numberWithFloat:videoSize.width], AVVideoWidthKey, [NSNumber numberWithFloat:videoSize.height], AVVideoHeightKey, nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoWriterSettings];
    
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    videoWriterInput.transform = preferredTransform;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:nil];
    
    [videoWriter addInput:videoWriterInput];
    
    //setup video reader
    NSDictionary *videoReaderSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoReaderSettings];
    
    AVAssetReader *videoReader = [[AVAssetReader alloc] initWithAsset:videoAsset error:nil];
    
    [videoReader addOutput:videoReaderOutput];
    
    //setup audio writer
    AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeAudio
                                            outputSettings:nil];
    
    audioWriterInput.expectsMediaDataInRealTime = NO;
    
    [videoWriter addInput:audioWriterInput];
    
    BOOL hasAudio = NO;
    
    if ([videoAsset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
        hasAudio = YES;
    }
    
    //setup audio reader
    AVAssetReader *audioReader;
    AVAssetReaderOutput *audioReaderOutput;
    AVAssetTrack *audioTrack;
    if (hasAudio) {
        audioTrack  = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        audioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        audioReader = [AVAssetReader assetReaderWithAsset:videoAsset error:nil];
        [audioReader addOutput:audioReaderOutput];
    }
    
    [videoWriter startWriting];
    
    //start writing from video reader
    [videoReader startReading];
    
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t processingQueue = dispatch_queue_create("processingQueue1", NULL);
    
    [videoWriterInput requestMediaDataWhenReadyOnQueue:processingQueue usingBlock:
     ^{
         
         while ([videoWriterInput isReadyForMoreMediaData]) {
             
             CMSampleBufferRef sampleBuffer;
             
             if ([videoReader status] == AVAssetReaderStatusReading &&
                 (sampleBuffer = [videoReaderOutput copyNextSampleBuffer])) {
                 
                 [videoWriterInput appendSampleBuffer:sampleBuffer];
                 CFRelease(sampleBuffer);
             }
             
             else {
                 
                 [videoWriterInput markAsFinished];
                 
                 if (!hasAudio && [videoReader status] == AVAssetReaderStatusCompleted) {
                     [videoWriter finishWritingWithCompletionHandler:^{
                         NSLog(@"no audio, finish export!");
                         
                         BOOL success = videoWriter.status == AVAssetWriterStatusCompleted;
                         if (success) {
                             handler(success);
                         }
                         else {
                             NSLog(@"videoWriter error %@",videoWriter.error);
                             handler(success);
                         }
                         
                     }];
                 }
                 
                 
                 if (hasAudio && [videoReader status] == AVAssetReaderStatusCompleted) {
                     
                     //start writing from audio reader
                     [audioReader startReading];
                     
                     [videoWriter startSessionAtSourceTime:kCMTimeZero];
                     
                     dispatch_queue_t processingQueue = dispatch_queue_create("processingQueue2", NULL);
                     
                     [audioWriterInput requestMediaDataWhenReadyOnQueue:processingQueue usingBlock:^{
                         
                         while (audioWriterInput.readyForMoreMediaData) {
                             
                             CMSampleBufferRef sampleBuffer;
                             
                             if ([audioReader status] == AVAssetReaderStatusReading &&
                                 (sampleBuffer = [audioReaderOutput copyNextSampleBuffer])) {
                                 
                                 [audioWriterInput appendSampleBuffer:sampleBuffer];
                                 CFRelease(sampleBuffer);
                             }
                             
                             else {
                                 [audioWriterInput markAsFinished];
                                 
                                 if ([audioReader status] == AVAssetReaderStatusCompleted) {
                                     
                                     [videoWriter finishWritingWithCompletionHandler:^{
                                         
                                         BOOL success = videoWriter.status == AVAssetWriterStatusCompleted;
                                         if (success) {
                                             handler(success);
                                         }
                                         else {
                                             NSLog(@"videoWriter error %@",videoWriter.error);
                                             handler(success);
                                         }
                                         
                                     }];
                                     
                                 }
                             }
                         }
                         
                     }
                      ];
                 }
             }
         }
     }
     ];
}


-(void)confirmVideoIsProcessed {
    
    //NSLog(@"processing video...");
    self.processingAsset.hidden = NO;
    self.processingAsset.text = @"Processing Video..";
    
    // Ensure the user cannot select/capture video while processing
    
    if (self.numVideosProcesssing == 0) {
        NSLog(@"finished processing video!");
        self.processingAsset.hidden = YES;
        self.customControls.takePicBtn.enabled = YES;
    }
    else {
        self.customControls.takePicBtn.enabled = NO;
        [self performSelector:@selector(confirmVideoIsProcessed) withObject:nil afterDelay:.1];
    }
}


-(void)videoLengthAlert {
    
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 220)];
    demoView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 10, 270, 40);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [demoView addSubview:imageView];
    
    NSString *title = @"Hold on!";
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 270, 20)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:titleLabel];
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 230, 60)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.numberOfLines = 3;
    messageLabel.text = @"Videos can't be longer than 15 seconds. Please select a different video and try again!";
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:messageLabel];
    
    UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    okBtn.frame = CGRectMake(70, 165, 130, 40);
    
    [okBtn setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    okBtn.backgroundColor = [UIColor colorWithRGBHex:0x4ACBEB];
    okBtn.layer.cornerRadius = 4.0;
    okBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    
    UIImage *selectedImage = [ImageUtils roundedRectImageWithColor:[UIColor colorWithRGBHex:0x4795AC] size:okBtn.frame.size corners:4.0f];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
    
    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okBtn addTarget:self action:@selector(dismissAlert:) forControlEvents:UIControlEventTouchUpInside];
    [demoView addSubview:okBtn];
    
    self.alertView = [PXAlertView showAlertWithView:demoView completion:^(BOOL cancelled) {
        self.alertView = nil;
    }];
}

-(void)dismissAlert:(id)sender {
    [self.alertView dismiss:sender];
    self.alertView = nil;
}

#pragma mark - Text Styling Helper Methods

-(void)updatePendingHashTags {
  
    //NSLog(@" --- update pending hash tags ----");

    //get range of any pending hash tags
    NSRange recentHashRange = NSMakeRange(0, 0);
    NSString *lastWord;
    NSString *newHashTag;

    if (self.textView.attributedText.length > 0) {

        //NSLog(@"updatePendingHashTags from text:%@",self.textView.attributedText.string);

        NSRange cursorPosition = [self.textView selectedRange];
        NSString *stringFromCursor = [self.textView.attributedText.string substringToIndex:cursorPosition.location];

        NSRange lastWordRange = [stringFromCursor rangeOfString:@" " options:NSBackwardsSearch];

        if (lastWordRange.location != NSNotFound) {
            //just check the last full word from the current cursor position
            lastWord = [stringFromCursor substringFromIndex:lastWordRange.location+1];
            //NSLog(@"last word from cursor position %@",lastWord);
        }
        else {
            //no spaces before the last current word from the cursor position
            //check to see if we should scan the full text for hashtags
            //(only do this if there are no spaces in the whole string; i.e. the first word)
          
            NSString *fullText = self.textView.attributedText.string;
            NSRange fullRange = [fullText rangeOfString:@" " options:NSBackwardsSearch];
          
            if (fullRange.location == NSNotFound) {
                //no spaces at all so far - this is the only word, see if there is a hashtag
                lastWord = self.textView.attributedText.string;
                //NSLog(@"only word %@",lastWord);
            }
        }

        //NSLog(@"last word? %@",lastWord);

        recentHashRange = [lastWord rangeOfString:@"#" options:NSBackwardsSearch];

        if (recentHashRange.location != NSNotFound) {
            //look like we've got a hashtag?
            newHashTag = [lastWord substringFromIndex:recentHashRange.location];
        }

        self.textView.selectedRange = NSMakeRange(cursorPosition.location, 0);
    }

    if (newHashTag.length > 0) {
        //NSLog(@"new hashTag %@",newHashTag);
        [self.hashTagSuggestions addedHashTagViaKeyboard:newHashTag];
    }

    self.hashTagIsPending = NO;
}

-(BOOL)updateHashTagsAfterDelete {
    
    //get range of any pending hash tags
    NSRange recentHashRange = NSMakeRange(0, 0);
    NSString *lastWord;
    NSString *removeHashTag;
    BOOL deletedHashTag = NO;
  
    NSRange cursorPosition = [self.textView selectedRange];
  
    NSString *stringBeforeCursor = [self.textView.attributedText.string substringToIndex:cursorPosition.location];
    NSString *stringAfterCursor = [self.textView.attributedText.string substringFromIndex:cursorPosition.location];
  
    NSLog(@"string before cursor %@",stringBeforeCursor);
    NSLog(@"string after cursor %@",stringAfterCursor);
  
    if (stringBeforeCursor > 0) {
        //NSLog(@"updateHashTagsAfterDelete from text:%@",self.textView.attributedText.string);
        NSRange lastWordRange = [stringBeforeCursor rangeOfString:@" " options:NSBackwardsSearch];
        if (lastWordRange.location != NSNotFound) {
            //just check the last word
            lastWord = [stringBeforeCursor substringFromIndex:lastWordRange.location+1];
        }
        else {
            //no spaces yet, use full text
            lastWord = stringBeforeCursor;
        }
    
        //NSLog(@"last word? %@",lastWord);
    
        recentHashRange = [lastWord rangeOfString:@"#" options:NSBackwardsSearch];
    
        if (recentHashRange.location != NSNotFound) {
        
            //look like we've got a hashtag?
            removeHashTag = [lastWord substringFromIndex:recentHashRange.location];
            NSLog(@"remove hash tag %@",removeHashTag);
      
            NSInteger remainingTextLength = lastWordRange.location + recentHashRange.location + 1;
            
            if (remainingTextLength > self.textView.attributedText.string.length) {
                remainingTextLength = 0;
            }
      
            NSString *remainingTextBeforeCursor = [stringBeforeCursor substringWithRange:NSMakeRange(0, remainingTextLength)];
            NSLog(@"remaining text %@",remainingTextBeforeCursor);
            
            if (remainingTextBeforeCursor.length > 0) {
                NSString *remainingText = [NSString stringWithFormat:@"%@%@",remainingTextBeforeCursor,stringAfterCursor];
                NSMutableAttributedString *remText = [[NSMutableAttributedString alloc] initWithString:remainingText];
                self.textView.attributedText = remText;
            }
            else {
                self.textView.text = stringAfterCursor;
            }
        }
    }
    
    if (removeHashTag.length > 0) {
        //NSLog(@"remove hashTag %@",removeHashTag);
        [self.hashTagSuggestions deletedHashTagViaKeyboard:removeHashTag];
        deletedHashTag = YES;
    }
    
    self.hashTagIsPending = NO;
    return deletedHashTag;
}

-(void)updateStyling {
    
   // NSString *memText = [NSString stringWithFormat:@"%@",self.textView.text];

    NSMutableAttributedString *attStr;
    if (self.textView.attributedText) {
        attStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    }
    else {
        attStr = [[NSMutableAttributedString alloc] initWithString:self.textView.text];
    }
    
    //get updated list of included hash tags
    NSArray *tempArray = [self.hashTagSuggestions getSelectedHashTags];
    NSLog(@"currently selected hash tags %@",tempArray);
  
    //style any included hash tags
    for (int i = 0; i < tempArray.count; i++) {
        NSString *hashTag = [tempArray objectAtIndex:i];
    
        //get range(s) of hashtag in current text
    
        NSRange hashRange = [attStr.string rangeOfString:hashTag options:NSBackwardsSearch];
    
        while(hashRange.location != NSNotFound) {
            //NSRange hashRange = [attStr.string rangeOfString:hashTag];
            NSLog(@"style hash %@", hashTag);
            
            [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] range:hashRange];
            [attStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Light" size:20] range:hashRange];
            hashRange = [attStr.string rangeOfString:hashTag options:NSBackwardsSearch range:NSMakeRange(0, hashRange.location)];
        }
    }
    
    
    //update styling after a space is tapped
    if (attStr.string.length > 0) {
        NSString *lastCharStr = [attStr.string substringFromIndex:attStr.string.length - 1];
        if ([lastCharStr isEqualToString:@" "]) {
            [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f] range:NSMakeRange(attStr.length-1, 1)];
            [attStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Light" size:20] range:NSMakeRange(attStr.length-1, 1)];
        }
    }
    self.textView.attributedText = attStr;
    
}

-(void)hashTagFullSweep {
    NSString *workingString = [NSString stringWithFormat:@"%@",self.textView.text];
    NSLog(@"working string %@",workingString);
    
    NSRange range = [workingString rangeOfString:@"#"];
    NSMutableArray *updatedHashArray = [[NSMutableArray alloc] init];
    
    while(range.location != NSNotFound) {
    
        //found a #, get the hashtag
        NSRange currRange = [workingString rangeOfString:@"#"];
    
        if (currRange.location != NSNotFound) {
            NSString *hashSearchString = [workingString substringFromIndex:currRange.location];
            NSLog(@"hash search string %@",hashSearchString);
      
            NSRange hashEndRange = [hashSearchString rangeOfString:@" "];
            NSString *hashTag;
      
            //this is the last word in our text
            
            if (hashEndRange.location == NSNotFound) {
                NSLog(@"looks like the last word is a hashtag!");
                hashTag = hashSearchString;
            }
            //just get the chunk between the '#' and the ' '
            else {
                hashTag = [hashSearchString substringWithRange:NSMakeRange(0, hashEndRange.location)];
            }
      
            NSLog(@"found hashTag:%@", hashTag);
            
            if (hashTag.length > 1){
                [updatedHashArray addObject:hashTag];
            }
            
            NSInteger lastHashEndLocation = currRange.location + hashTag.length;
            
            //continue on our our search
            
            if (workingString.length > lastHashEndLocation && workingString.length > 0) {
                workingString = [workingString substringFromIndex:lastHashEndLocation];
                NSLog(@"updated working string %@",workingString);
                
                if (workingString.length == 0) {
                    break;
                }
            }
            else  {
                NSLog(@"string all done!");
                break;
            }
        }
        else {
            NSLog(@"no more hashtags!");
            break;
        }
    }
    
    NSLog(@"updatedHashArray count %i",(int)updatedHashArray.count);
  
    //update our array!
    [self.hashTagSuggestions updateAllSelectedHashTags:updatedHashArray];
    [self.hashTagSuggestions.collectionView reloadData];
  
    //now that we've updated our list of hashtags, update our styling
    [self updateStyling];
}


#pragma mark - Loading Screen Helper Methods

-(void)stopLoadingProgressView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.loadingView removeFromSuperview];
    [self.progressBar removeFromSuperview];
    self.view.userInteractionEnabled = YES;
}

-(void)updateProgressBar:(NSInteger)operationsCompleted {
    NSLog(@"updateProgressBar: %i", (int)operationsCompleted);
    if (self.progressBarUploadsComplete == -1 || operationsCompleted != self.progressBarUploadsComplete) {
        float fullWidth = self.view.bounds.size.width;
        
        self.progressBarUploadsComplete = operationsCompleted;
        float numUploadsComplete = operationsCompleted - self.progressBarUploadsCompleteBeforeAnchor;
        float totalUploads = self.assetUploadCoordinator.totalAssetCount - self.progressBarUploadsCompleteBeforeAnchor + 1;
        
        self.uploadStepProgressEnd = numUploadsComplete == totalUploads ? 1.0 : (numUploadsComplete + 1) / totalUploads;
        self.uploadStepProgressStart = self.uploadProgress;
        while (self.uploadStepProgressStart >= self.uploadStepProgressEnd && self.uploadStepProgressEnd < 1) {
            self.uploadStepProgressEnd += 1.0 / totalUploads;
        }
        self.uploadStepStartTime = [[NSDate date] timeIntervalSince1970];
        
        //if (numUploadsComplete == totalUploads) {
        //    self.uploadProgress = 1;
        //}
        
        float currWidth = fullWidth * self.uploadProgress;
        self.progressBar.frame = CGRectMake(0, self.progressBar.frame.origin.y, currWidth, self.progressBar.frame.size.height);
        
        NSTimeInterval loopTicker = 1.0 / 30.0;
        
        if (operationsCompleted == 0) {
            self.uploadStepDurationEstimate = (totalUploads <= 1 ? 1 : 3.0);    // estimate 3 seconds to upload an image, 1 to post the mem.
        } else if (operationsCompleted == totalUploads - 1) {
            // one left: the final post animation.  Estimate just a second.
            self.uploadStepDurationEstimate = 1;
        } else if (operationsCompleted == totalUploads) {
            // finished!  Zip to the finish line.
            if (self.uploadStepProgressStart < self.uploadStepProgressEnd) {
                self.uploadStepDurationEstimate = 0.3;
            }
        } else {
            // normal: use previous uploads as a guide.
            self.uploadStepDurationEstimate = ([[NSDate date] timeIntervalSince1970] - self.uploadStartTime) / numUploadsComplete;
        }
        
        [self.stepTimer invalidate];
        
        //NSLog(@"updating progress bar with progress %f, step estimate %f", self.uploadProgress, self.uploadStepDurationEstimate);
        
        self.stepTimer = [NSTimer scheduledTimerWithTimeInterval:loopTicker target:self selector:@selector(stepProgress:) userInfo:nil repeats:YES];
    }
}

-(void)stepProgress:(NSTimer *)timer {
    
    long numUploadsComplete = self.progressBarUploadsComplete - self.progressBarUploadsCompleteBeforeAnchor;
    long totalUploads = self.assetUploadCoordinator.totalAssetCount - self.progressBarUploadsCompleteBeforeAnchor + 1;
    
    CGFloat stepProportion = ([[NSDate date] timeIntervalSince1970] - self.uploadStepStartTime) / self.uploadStepDurationEstimate;
    self.uploadProgress = self.uploadStepProgressStart + (self.uploadStepProgressEnd - self.uploadStepProgressStart) * stepProportion;
    if (numUploadsComplete < totalUploads) {
        
        // not the final step.  Smooth out the progress by applying Zeno's paradox,
        // so the progress bar never actually reaches the end point, and never fully stops.
        CGFloat maxStepProportion = (totalUploads - numUploadsComplete);
        
        // the first 0.X step covers the first 0.X of distance.  The next
        // 0.X covers the next 0.X of the REMAINING distance, and so on.
        // In so doing the arrow never reaches its target.
        CGFloat stepRemaining = stepProportion / maxStepProportion;
        CGFloat scale = 1;
        stepProportion = 0;
        
        CGFloat scaleStep = 0.1;        // 0.5 in the original paradox
        while (stepRemaining > 0) {
            // take 0.X of the distance remaining...
            stepProportion += maxStepProportion * scale * MIN(scaleStep, stepRemaining);
            scale *= (1 - scaleStep);
            stepRemaining -= scaleStep;
        }
        
        self.uploadProgress = self.uploadStepProgressStart + (self.uploadStepProgressEnd - self.uploadStepProgressStart) * stepProportion;
        
        //NSLog(@"Zeno-scaled the step proportion %f to %f", originalStepProportion, stepProportion);
    }
    
    if (self.uploadProgress > 1) {
        self.uploadProgress = 1;
        if (numUploadsComplete >= totalUploads) {
            [timer invalidate];
        }
    }
    
    float fullWidth = self.view.bounds.size.width;
    float currWidth = fullWidth * self.uploadProgress;
    
    //NSLog(@"step progress with progress %f, step proportion %f", self.uploadProgress, stepProportion);
    //NSLog(@"step proportion was formed by time-since-start %f, estimated duration %f", ([[NSDate date] timeIntervalSince1970] - self.uploadStepStartTime), self.uploadStepDurationEstimate);
    
    CGRect frame = self.progressBar.frame;
    frame = CGRectMake(0, CGRectGetMinY(frame), currWidth, CGRectGetHeight(frame));
    self.progressBar.frame = frame;
    
    if (self.uploadProgress >= 1 && !self.memoryPostDidFault && numUploadsComplete >= totalUploads) {
        if (self.stepTimer) {
            [self.stepTimer invalidate];
        }
        [self saveScreenshotAndFinish];
        NSLog(@"save screenshot and finish!");
    }
}

-(void)saveScreenshotAndFinish {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    //NSLog(@"saveScreenshotAndFinish");
    
    self.view.userInteractionEnabled = YES;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    
    //capture image of screen to use in MAM completion animation
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *dataForMaMAnimationImage = UIImagePNGRepresentation(currentScreenImg);
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *mamPath = [documentsDirectory stringByAppendingPathComponent:@"mamAnimationImg.png"];
    [dataForMaMAnimationImage writeToFile:mamPath atomically:YES];
    
    [self.view endEditing:YES];
    
    [self.loadingView removeFromSuperview];
    [self.progressBar removeFromSuperview];
    self.view.userInteractionEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"handleMakeMemAnimation" object:nil];
}

#pragma mark - Video Playback Actions

- (void)playVideo {
    NSLog(@"play video!");
    
    // Set the playerView's frame/background
    self.playerView.frame = self.capturePreviewImage.frame;
    self.videoPlayBtn.hidden = YES;
    
    self.playerView.volume = 1.0f;
    [self.playerView resetForReplay];
    [self.playerView playNow];
    self.videoPlayBtn.hidden = YES;
}

- (void)pauseVideo {
    NSLog(@"pause video!");
    if (nil != self.playerView) {
        [self.playerView pause];
    }
}

- (void)resumeVideo {
    NSLog(@"resume video!");
    if (nil != self.playerView) {
        [self.playerView play];
    }
}



#pragma mark - Touches Handling

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if (touch.view == self.anonRealKnob) {
        self.anonTapX = self.anonRealKnob.center.x;
        self.hasToggledAnon = NO;
    }
    
    if (touch.view == self.micPermissionImgView) {
        self.micPermissionImgView.hidden = YES;
        
        [self showCaptureCoachmarkIfNeeded];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    
    
    if (touch.view == self.anonRealKnob) {
        
        if (touchLocation.x < self.anonRealMinX) {
            self.anonRealKnob.center = CGPointMake(self.anonRealMinX,self.anonRealKnob.center.y);
        }
        else if (touchLocation.x > self.anonRealMaxX)  {
            self.anonRealKnob.center = CGPointMake(self.anonRealMaxX,self.anonRealKnob.center.y);
        }
        else {
            self.anonRealKnob.center = CGPointMake(touchLocation.x,self.anonRealKnob.center.y);
        }
    
        if (self.anonRealKnob.center.x > self.anonRealMidX) {
            if (self.isAnon) {
                self.hasToggledAnon = YES;
            }
            [self setToReal];
        }
        else {
            if (!self.isAnon) {
                self.hasToggledAnon = YES;
            }
            [self setToAnon];
        }
    }
  
    
    if (touch.view == self.locationKnob) {
        //handle dragging
        if ((touchLocation.x < self.locMaxX) && (touchLocation.x > self.locMinX)) {
            self.self.locationKnob.center = CGPointMake(touchLocation.x,self.locationKnob.center.y);
        }
        
        float halfway = (self.locMaxX - self.locMidX)/2;
        
        //adjust places during drag
        
        
        if (self.fuzzedCityVenue && self.fuzzedNeighorhoodVenue) {
            
            if (touchLocation.x > self.locMidX + halfway) {
                
                self.selectedVenue = self.fuzzedCityVenue;
                
                self.selectedLocationNameLabel.text = self.fuzzedCityVenue.city;
                self.activeLocationTypeLabel.text = NSLocalizedString(@"City", nil);
                [self.mapBtn setTitle:@"Map" forState:UIControlStateNormal];
                self.locationLeftSpectrum.alpha = 1;
                self.locationRightSpectrum.alpha = 0;
                self.locationMidSpectrum.alpha = 1;
            }
            else if (touchLocation.x < self.locMidX - halfway) {
        
                self.selectedVenue = self.placeVenue;
        
                self.selectedLocationNameLabel.text = self.placeVenue.displayNameTitle;
                self.activeLocationTypeLabel.text = NSLocalizedString(@"Place", nil);
                [self.mapBtn setTitle:@"Tap to change" forState:UIControlStateNormal];
                
                self.locationLeftSpectrum.alpha = 0;
                self.locationRightSpectrum.alpha = 1;
                self.locationMidSpectrum.alpha = 1;
            }
            else {
                
                self.selectedVenue = self.fuzzedNeighorhoodVenue;
        
                self.selectedLocationNameLabel.text = self.fuzzedNeighorhoodVenue.neighborhood;
                self.activeLocationTypeLabel.text = NSLocalizedString(@"Neighborhood", nil);
                [self.mapBtn setTitle:@"Map" forState:UIControlStateNormal];

                self.locationLeftSpectrum.alpha = 1;
                self.locationMidSpectrum.alpha = 0;
                self.locationRightSpectrum.alpha = 1;
            }
        }
        
        if (self.fuzzedCityVenue && !self.fuzzedNeighorhoodVenue) {
            
            if (touchLocation.x > self.locMidX) {
        
                self.selectedVenue = self.fuzzedCityVenue;
        
                self.selectedLocationNameLabel.text = self.fuzzedCityVenue.city;
                self.activeLocationTypeLabel.text = NSLocalizedString(@"City", nil);
                [self.mapBtn setTitle:@"Map" forState:UIControlStateNormal];
        
                self.locationLeftSpectrum.alpha = 1;
                self.locationRightSpectrum.alpha = 0;
                self.locationMidSpectrum.alpha = 0;
            }
            else {
        
                self.selectedVenue = self.placeVenue;
                self.selectedLocationNameLabel.text = self.placeVenue.displayNameTitle;
                self.activeLocationTypeLabel.text = NSLocalizedString(@"Place", nil);
                [self.mapBtn setTitle:@"Tap to change" forState:UIControlStateNormal];
        
                self.locationLeftSpectrum.alpha = 0;
                self.locationRightSpectrum.alpha = 1;
                self.locationMidSpectrum.alpha = 0;
            }
        }
        
        if (!self.fuzzedCityVenue && self.fuzzedNeighorhoodVenue) {
            
            if (touchLocation.x > self.locMidX) {
                
                self.selectedVenue = self.fuzzedNeighorhoodVenue;
        
                self.selectedLocationNameLabel.text = self.fuzzedNeighorhoodVenue.neighborhood;
                self.activeLocationTypeLabel.text = NSLocalizedString(@"Neighborhood", nil);
                [self.mapBtn setTitle:@"Map" forState:UIControlStateNormal];
        
                self.locationLeftSpectrum.alpha = 1;
                self.locationRightSpectrum.alpha = 0;
                self.locationMidSpectrum.alpha = 0;
            }
            else {
        
                self.selectedVenue = self.placeVenue;
                
                self.selectedLocationNameLabel.text = self.placeVenue.displayNameTitle;
                self.activeLocationTypeLabel.text = NSLocalizedString(@"Place", nil);
                [self.mapBtn setTitle:@"Tap to change" forState:UIControlStateNormal];
                
                self.locationLeftSpectrum.alpha = 0;
                self.locationRightSpectrum.alpha = 1;
                self.locationMidSpectrum.alpha = 0;
            }
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    
    if (touch.view == self.anonRealKnob) {
        
        //handle case where user has simply tapped w/o draggin
        
        if (!self.hasToggledAnon) {
            
            NSLog(@"just a tap!");
            
            if (self.isAnon) {
                
                [self setToReal];
        
                [UIView animateWithDuration:0.2
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.anonRealKnob.center = CGPointMake(self.anonRealMaxX, self.anonRealKnob.center.y);
                                 }
                                 completion:nil];
            }
            else {
                
                [self setToAnon];
                [UIView animateWithDuration:0.2
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.anonRealKnob.center = CGPointMake(self.anonRealMinX, self.anonRealKnob.center.y);
                         }
                                 completion:nil];
            }
        }
        else {
            NSLog(@"finish a drag");
      
            if (self.anonRealKnob.center.x > self.anonRealMidX) {
              
              [self setToReal];
              [UIView animateWithDuration:0.1
                                    delay:0.0
                                  options:UIViewAnimationOptionCurveEaseOut
                               animations:^{
                                   self.anonRealKnob.center = CGPointMake(self.anonRealMaxX, self.anonRealKnob.center.y);
                             }
                             completion:nil];
            }
            else {
              [self setToAnon];
              [UIView animateWithDuration:0.1
                                    delay:0.0
                                  options:UIViewAnimationOptionCurveEaseOut
                               animations:^{
                                   self.anonRealKnob.center = CGPointMake(self.anonRealMinX, self.anonRealKnob.center.y);
                             }
                             completion:nil];
            }
        }
    }
    
    
    if (touch.view == self.locationKnob) {
    
        float halfway = (self.locMaxX - self.locMidX)/2;
        
        //adjust places during drag
        
        if (self.fuzzedCityVenue && self.fuzzedNeighorhoodVenue) {
            
            if (self.locationKnob.center.x > self.locMidX + halfway) {
                
                [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.locationKnob.center = CGPointMake(self.locMaxX, self.locationKnob.center.y);
                         }
                         completion:nil];
        
            }
            else if (self.locationKnob.center.x < self.locMidX - halfway) {
                [UIView animateWithDuration:0.2
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.locationKnob.center = CGPointMake(self.locMinX, self.locationKnob.center.y);
                                 }
                                 completion:nil];
            }
            else {
                [UIView animateWithDuration:0.2
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.locationKnob.center = CGPointMake(self.locMidX, self.locationKnob.center.y);
                                 }
                                 completion:nil];
            }
        }
        
        else {
            
            if (self.locationKnob.center.x > self.locMidX) {
                
                [UIView animateWithDuration:0.2
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.locationKnob.center = CGPointMake(self.locMaxX, self.locationKnob.center.y);
                         }
                         completion:nil];
            }
            else {
                [UIView animateWithDuration:0.2
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.locationKnob.center = CGPointMake(self.locMinX, self.locationKnob.center.y);
                                 }
                                 completion:nil];
            }
        }
    }
    
    if (touch.view == self.capturePreviewImage && self.memoryType == MemoryTypeImage) {
        [self editImage];
    }
}


-(bool)isOnPhoneCall {
    
    CTCallCenter *callCenter = [[CTCallCenter alloc] init];
    for (CTCall *call in callCenter.currentCalls)  {
        if (call.callState == CTCallStateConnected) {
            NSLog(@"is on call?");
            return YES;
        }
    }
    
    NSLog(@"not on a call");
    return NO;
}

@end

#pragma mark - SPCMAMCaptureCoachmarkView

@interface SPCMAMCaptureCoachmarkView()

@property (strong, nonatomic) UIView *contentView;

// Icon and message
@property (strong, nonatomic) UIImageView *ivTap;
@property (strong, nonatomic) UIImageView *ivClock;
@property (strong, nonatomic) UILabel *lblMessage;

// Button
@property (strong, nonatomic) UIButton *btn;

// Tap count / simple state variable
@property (nonatomic) NSInteger numberOfTaps;

@end

@implementation SPCMAMCaptureCoachmarkView

#pragma mark - Target-Action

- (void)tappedButton:(id)sender {
    // Check our state. We can improve this check to be more robust in the future if we expand on this coachmark
    if (0 == self.numberOfTaps++) {
        [self showHoldCoachmarkAnimated:YES];
    } else {
        self.numberOfTaps = 0;
        
        if ([self.delegate respondsToSelector:@selector(didTapToEndOnCoachmarkView:)]) {
            [self.delegate didTapToEndOnCoachmarkView:self];
        } else {
            [UIView animateWithDuration:0.3f animations:^{
                self.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [self removeFromSuperview];
                [self showTapCoachmarkAnimated:NO];
                self.alpha = 1.0f;
            }];
        }
    }
}

#pragma mark - Configuration

- (void)showTapCoachmarkAnimated:(BOOL)animated {
    // Icons
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.ivClock.alpha = 0.0f;
        }];
    } else {
        self.ivClock.alpha = 0.0f;
    }
    
    // Message
    NSString *strMessage = @"Tap to take photo";
    NSMutableAttributedString *strAttributedMessage = [[NSMutableAttributedString alloc] initWithString:strMessage attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14.0f] }];
    self.lblMessage.attributedText = strAttributedMessage;
    
    // Button
    [self.btn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"NEXT" attributes:nil] forState:UIControlStateNormal];
    
    [self setNeedsLayout];
}

- (void)showHoldCoachmarkAnimated:(BOOL)animated {
    // Icons
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.ivClock.alpha = 1.0f;
        }];
    } else {
        self.ivClock.alpha = 1.0f;
    }
    
    // Message
    NSString *strMessage = @"Press and hold for video";
    NSMutableAttributedString *strAttributedMessage = [[NSMutableAttributedString alloc] initWithString:strMessage attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14.0f] }];
    [strAttributedMessage addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Bold" size:14.0f] range:[strMessage rangeOfString:@"hold"]];
    self.lblMessage.attributedText = strAttributedMessage;
    
    // Button
    [self.btn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"GOT IT!" attributes:nil] forState:UIControlStateNormal];
    
    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    CGFloat PSD_WIDTH = 750.0f;
    CGFloat PSD_HEIGHT = 1334.0f;
    
    // Content view
    self.contentView.frame = self.bounds;
    
    // Icons
    self.ivClock.frame = CGRectMake(0, 0, 57.0f/PSD_WIDTH * viewWidth, 57.0f/PSD_HEIGHT * viewHeight);
    self.ivClock.center = CGPointMake(457.0f/PSD_WIDTH * viewWidth, 1162.0f/PSD_HEIGHT * viewHeight);
    self.ivTap.frame = CGRectMake(0, 0, 112.0f/PSD_WIDTH * viewWidth, 159.0f/PSD_HEIGHT * viewHeight);
    self.ivTap.center = CGPointMake(self.center.x, 1215.0f/PSD_HEIGHT * viewHeight);
    
    // Message
    // Update its font size
    CGFloat fontSize = 28.0f/PSD_HEIGHT * viewHeight;
    NSMutableAttributedString *strAttr = [[NSMutableAttributedString alloc] initWithAttributedString:self.lblMessage.attributedText];
    [self.lblMessage.attributedText enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, strAttr.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *oldFont = (UIFont *)value;
        UIFont *newFont = [oldFont fontWithSize:fontSize];
        
        [strAttr addAttribute:NSFontAttributeName value:newFont range:range];
    }];
    self.lblMessage.attributedText = strAttr;
    
    CGSize sizeMessage = [strAttr size];
    self.lblMessage.frame = CGRectMake(0, 0, sizeMessage.width, sizeMessage.height);
    self.lblMessage.center = CGPointMake(self.center.x, 935.0f/PSD_HEIGHT * viewHeight);
    
    // Button
    NSDictionary *btnAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:24.0f/PSD_HEIGHT * viewHeight],
                               NSForegroundColorAttributeName : [UIColor whiteColor] };
    [self.btn setAttributedTitle:[[NSAttributedString alloc] initWithString:self.btn.titleLabel.text attributes:btnAttributes] forState:UIControlStateNormal];
    self.btn.frame = CGRectMake(0, 0, 150.0f/PSD_WIDTH * viewWidth, 60.0f/PSD_HEIGHT * viewHeight);
    self.btn.center = CGPointMake(618.0f/PSD_WIDTH * viewWidth, 1095.0f/PSD_HEIGHT * viewHeight);
}

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // Content view
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    _contentView.autoresizesSubviews = YES;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_contentView];
    
    // Icons
    _ivTap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coachmark-tap"]];
    _ivTap.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:_ivTap];
    _ivClock = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coachmark-clock"]];
    _ivClock.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:_ivClock];
    
    // Label
    _lblMessage = [[UILabel alloc] init];
    _lblMessage.numberOfLines = 0;
    _lblMessage.font = [UIFont fontWithName:@"OpenSans" size:14.0f];
    _lblMessage.textAlignment = NSTextAlignmentCenter;
    _lblMessage.textColor = [UIColor whiteColor];
    _lblMessage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:_lblMessage];
    
    // Button
    _btn = [[UIButton alloc] init];
    _btn.layer.cornerRadius = 2.0f;
    _btn.layer.borderColor = [UIColor whiteColor].CGColor;
    _btn.layer.borderWidth = 1.0f;
    _btn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_btn addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_btn];
    
    [self showTapCoachmarkAnimated:NO];
}

@end

#pragma mark - SPCMAMAdjustmentCoachmarkView

@interface SPCMAMAdjustmentCoachmarkView()

@property (strong, nonatomic) UIView *contentView;

// Icon and message
@property (strong, nonatomic) UIImageView *ivTap;
@property (strong, nonatomic) UILabel *lblMessage;

// Tap count / simple state variable
@property (nonatomic) NSInteger numberOfTaps;

@end

@implementation SPCMAMAdjustmentCoachmarkView

#pragma mark - Target-Action

- (void)tappedView:(id)sender {
    self.numberOfTaps = 0;
    
    if ([self.delegate respondsToSelector:@selector(didTapToEndOnCoachmarkView:)]) {
        [self.delegate didTapToEndOnCoachmarkView:self];
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            self.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            self.alpha = 1.0f;
        }];
    }
}

#pragma mark - Configuration

- (void)showTapCoachmarkAnimated:(BOOL)animated {
    // Icons
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.ivTap.alpha = 1.0f;
        }];
    } else {
        self.ivTap.alpha = 1.0f;
    }
    
    // Message
    NSString *strMessage = @"Tap for filters and adjustments";
    NSMutableAttributedString *strAttributedMessage = [[NSMutableAttributedString alloc] initWithString:strMessage attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14.0f] }];
    [strAttributedMessage addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Bold" size:14.0f] range:[strMessage rangeOfString:@"filters"]];
    [strAttributedMessage addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Bold" size:14.0f] range:[strMessage rangeOfString:@"adjustments"]];
    self.lblMessage.attributedText = strAttributedMessage;
    
    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    CGFloat PSD_WIDTH = 750.0f;
    CGFloat PSD_HEIGHT = 1334.0f;
    
    // Content view
    self.contentView.frame = self.bounds;
    
    // Icon
    self.ivTap.frame = CGRectMake(0, 0, 112.0f/PSD_WIDTH * viewWidth, 159.0f/PSD_HEIGHT * viewHeight);
    self.ivTap.center = CGPointMake(self.center.x, 455.0f/PSD_HEIGHT * viewHeight);
    
    // Message
    // Update its font size
    CGFloat fontSize = 28.0f/PSD_HEIGHT * viewHeight;
    NSMutableAttributedString *strAttr = [[NSMutableAttributedString alloc] initWithAttributedString:self.lblMessage.attributedText];
    [self.lblMessage.attributedText enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, strAttr.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *oldFont = (UIFont *)value;
        UIFont *newFont = [oldFont fontWithSize:fontSize];
        
        [strAttr addAttribute:NSFontAttributeName value:newFont range:range];
    }];
    self.lblMessage.attributedText = strAttr;
    
    // The message's MinY should be 15pt below the ivTap icon
    CGSize sizeMessage = [strAttr size];
    self.lblMessage.frame = CGRectMake(0, 0, sizeMessage.width, sizeMessage.height);
    self.lblMessage.center = CGPointMake(self.center.x, CGRectGetMaxY(self.ivTap.frame) + 15.0f + sizeMessage.height/2.0f);
}

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // Content view
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    _contentView.autoresizesSubviews = YES;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _contentView.gestureRecognizers = @[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)]];
    [self addSubview:_contentView];
    
    // Icon
    _ivTap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coachmark-tap"]];
    _ivTap.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:_ivTap];
    
    // Label
    _lblMessage = [[UILabel alloc] init];
    _lblMessage.numberOfLines = 0;
    _lblMessage.font = [UIFont fontWithName:@"OpenSans" size:14.0f];
    _lblMessage.textAlignment = NSTextAlignmentCenter;
    _lblMessage.textColor = [UIColor whiteColor];
    _lblMessage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:_lblMessage];
    
    [self showTapCoachmarkAnimated:NO];
}

@end
