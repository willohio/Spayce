//
//  SPCCaptureMemoryViewController.m
//  Spayce
//
//  Created by William Santiago on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCCaptureMemoryViewController.h"

// Framework
#import <AVFoundation/AVFoundation.h>
#import "Flurry.h"

// Model
#import "Memory.h"

// View
#import "CoachMarks.h"
#import "PXAlertView.h"
#import "SPCNavControllerLight.h"

// Controller
#import "QBImagePickerController.h"

// General
#import "SPCLiterals.h"

// Manager
#import "AuthenticationManager.h"
#import "LocationManager.h"
#import "LocationContentManager.h"

// Coordinator
#import "SPCAssetUploadCoordinator.h"

// Utility
#import "ImageUtils.h"
#import "UIColor+Expanded.h"

@interface SPCCaptureMemoryViewController () <QBImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *spcImagePickerController;
@property (nonatomic, strong) QBImagePickerController *cameraRollPickerController;
@property (nonatomic, strong) SPCCustomCameraControls *customControls;
@property (nonatomic, assign) BOOL videoCaptureInProgress;
@property (nonatomic, strong) SPCAssetUploadCoordinator *assetUploadCoordinator;
@property (nonatomic, assign) NSInteger memoryType;
@property (nonatomic, assign) BOOL landscapeLeft;
@property (nonatomic, assign) BOOL portraitVid;
@property (nonatomic, assign) BOOL upsideDownPortraitVid;
@property (strong, nonatomic) PXAlertView *alertView;
@property (nonatomic, assign) BOOL isFlashOn;
@property (nonatomic, strong) SPCPickLocationViewController  *spcPickLocationViewController;
@property (nonatomic, strong) SPCPostMemoryViewController *postMemoryViewController;
@property (nonatomic, strong) SPCImageEditingController *spcImageEditingController;
@property (nonatomic, assign) NSInteger editingImageIndex;
@property (nonatomic, assign) BOOL editingExistingImage;
@property (nonatomic, assign) BOOL cameraIsLocked;
@property (nonatomic, assign) BOOL MAMWasDismissed;
@property (nonatomic, assign) BOOL cameraRollPickerIsVisible;

@property (nonatomic, strong) NSArray *previouslySelectedFriends;
@property (nonatomic, strong) NSString *textToRestore;

@property (nonatomic, assign) NSInteger numVideosProcesssing;
@property (nonatomic, strong) UIView *processingVideoView;

@property (nonatomic, strong) Venue *selectedVenue;
@property (nonatomic, strong) SPCCity *selectedTerritory;

@property (nonatomic, strong) UIImageView *precacheImgView;
@property (nonatomic, assign) BOOL hasSelectedAVenue;
@property (nonatomic, assign) float photoRollLat;
@property (nonatomic, assign) float photoRollLong;

@property (nonatomic, assign) BOOL anonSelected;

@property (nonatomic, strong) UIImageView *micPermissionImgView;

@end

@implementation SPCCaptureMemoryViewController

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_customControls];
}

- (instancetype)initWithSelectedVenue:(Venue *)venue {
    self = [super init];
    if (self) {
        self.selectedVenue = venue;
    }
    return self;
}


#pragma mark - Accessors

-(UIImagePickerController *)spcImagePickerController{
    
    if (!_spcImagePickerController) {
        
        /* This picker is used for capturing images from the camera */
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            
                _spcImagePickerController = [[UIImagePickerController alloc] init];
                _spcImagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                _spcImagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage];
                _spcImagePickerController.delegate = (id)self;
                _spcImagePickerController.showsCameraControls = NO;
                _spcImagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
                _spcImagePickerController.cameraOverlayView = self.customControls;
                _spcImagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
        } else {
            [self showNoCamAlert];
        }
    }
    
    return _spcImagePickerController;
}


-(QBImagePickerController *)cameraRollPickerController{

    /* This picker is used to support selecting multiple images from the camera roll at the same time */
    
    if (!_cameraRollPickerController) {
        
          _cameraRollPickerController = [[QBImagePickerController alloc] init];
         _cameraRollPickerController.allowsMultipleSelection = YES;
        _cameraRollPickerController.groupTypes = @[
                                             @(ALAssetsGroupSavedPhotos),
                                             @(ALAssetsGroupPhotoStream),
                                             @(ALAssetsGroupAlbum)
                                             ];
        
        _cameraRollPickerController.delegate = (id)self;
        
        if (self.memoryType == MemoryTypeImage) {
            _cameraRollPickerController.filterType = QBImagePickerControllerFilterTypePhotos;
        }
        if (self.memoryType == MemoryTypeVideo) {
            _cameraRollPickerController.filterType = QBImagePickerControllerFilterTypeVideos;
        }
        
    }
    return _cameraRollPickerController;
}

-(SPCPostMemoryViewController *)postMemoryViewController {
    if (!_postMemoryViewController) {
        _postMemoryViewController = [[SPCPostMemoryViewController alloc] init];
        _postMemoryViewController.delegate = self;
        _postMemoryViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        _postMemoryViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        _postMemoryViewController.selectedVenue = self.selectedVenue;
    }
    return _postMemoryViewController;
    
}

-(SPCImageEditingController *)spcImageEditingController {
    if (!_spcImageEditingController) {
        _spcImageEditingController = [[SPCImageEditingController alloc] init];
        _spcImageEditingController.delegate = self;
    }
    return _spcImageEditingController;
}

-(SPCPickLocationViewController *)spcPickLocationViewController {
    if (!_spcPickLocationViewController) {
        _spcPickLocationViewController = [[SPCPickLocationViewController alloc] init];
        _spcPickLocationViewController.delegate = self;
    }
    return _spcPickLocationViewController;
}

-(SPCCustomCameraControls *)customControls {
    if (!_customControls) {
        _customControls = [[SPCCustomCameraControls alloc] initWithFrame:self.view.bounds];
        _customControls.backgroundColor = [UIColor clearColor];
        _customControls.delegate = self;
        [_customControls.closeBtn addTarget:self action:@selector(dismissImagePicker) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.skipBtn addTarget:self action:@selector(handleTextMem) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.flashBtn addTarget:self action:@selector(toggleFlash) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.flipCamBtn addTarget:self action:@selector(flipCam) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.cameraRollBtn addTarget:self action:@selector(displayCameraRoll) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.takePicBtn addTarget:self action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.takeVidBtn addTarget:self action:@selector(takeVideo) forControlEvents:UIControlEventTouchUpInside];
        [_customControls.stopVidBtn addTarget:self action:@selector(stopVideoCapture) forControlEvents:UIControlEventTouchUpInside];
        
        [_customControls addSubview:self.micPermissionImgView];
    }
    
    return _customControls;
}

-(UIImageView *)micPermissionImgView {
    if (!_micPermissionImgView) {
        
        float xAdj = 130;
        float yAdj = -55;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            xAdj = 130;
            yAdj = -10;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            xAdj = 140;
            yAdj = 0;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            xAdj = 158;
            yAdj = 20;
        }
        
        
        _micPermissionImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"micPermissionBG"]];
        _micPermissionImgView.hidden = YES;
        _micPermissionImgView.userInteractionEnabled = YES;
        _micPermissionImgView.center = CGPointMake(self.view.bounds.size.width - xAdj, CGRectGetMaxY(self.customControls.thumbScrollView.frame) + yAdj);
        
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


-(UIView *)processingVideoView {
    if (!_processingVideoView) {
        _processingVideoView = [[UIView alloc] initWithFrame:self.view.bounds];
        _processingVideoView.backgroundColor = [UIColor colorWithWhite:0.0f/255.0f alpha:.7];
        _processingVideoView.hidden = YES;
        
        UILabel *tempLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
        tempLabel.backgroundColor = [UIColor clearColor];
        tempLabel.text = @"Processing video\n\n\n";
        tempLabel.textAlignment = NSTextAlignmentCenter;
        tempLabel.textColor = [UIColor whiteColor];
        tempLabel.font = [UIFont fontWithName:@"HelveticaNeue-Mediume" size:14];
        [_processingVideoView addSubview:tempLabel];
   
    }
    return _processingVideoView;
}

- (SPCAssetUploadCoordinator *)assetUploadCoordinator {
    if (!_assetUploadCoordinator) {
        //NSLog(@"create asset upload coordinator!");
        _assetUploadCoordinator = [[SPCAssetUploadCoordinator alloc] init];
        _assetUploadCoordinator.precacheImgView = self.precacheImgView;
    }
    return _assetUploadCoordinator;
}

-(UIImageView *)precacheImgView {
    if (!_precacheImgView) {
        _precacheImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 310, 310)];
        _precacheImgView.hidden = YES;
    }
    return _precacheImgView;
}

#pragma mark - UIViewController - Managing the View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Hide navigation bar
    self.navigationController.navigationBarHidden = YES;
    
    [self addChildViewController:self.spcImagePickerController];
    [self.view insertSubview:self.spcImagePickerController.view atIndex:0];
   
    
    [self.spcImagePickerController.cameraOverlayView addSubview:self.processingVideoView];
    
    NSInteger testInt = self.assetUploadCoordinator.totalAssetCount;
    NSLog(@"testInt %li",testInt);
    
    //Hide to start
    [self.view addSubview:self.spcPickLocationViewController.view];
    self.spcPickLocationViewController.view.alpha = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoStopVideo) name:@"autoStopVideo" object:nil];
    
    if (!self.selectedVenue) {
        if ([LocationManager sharedInstance].tempMemVenue) {
            self.selectedVenue = [LocationManager sharedInstance].tempMemVenue;
        } else if ([LocationManager sharedInstance].manualVenue) {
            self.selectedVenue = [LocationManager sharedInstance].manualVenue;
        } else {
            [[LocationContentManager sharedInstance] getContentFromCache:@[SPCLocationContentVenue]
                                                          resultCallback:^(NSDictionary *results) {
                                                              if (!self.selectedVenue && results[SPCLocationContentVenue]) {
                                                                  self.selectedVenue = results[SPCLocationContentVenue];
                                                              }
                                                          } faultCallback:^(NSError *fault) {
                                                              NSLog(@"Failed to determine the current user venue...");
                                                          }];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.precacheImgView.superview) {
        [self.view addSubview:self.precacheImgView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            // the user granted permission!
            NSLog(@"has micrphone permission!");
             self.micPermissionImgView.hidden = YES;
        } else {
            // show a reminder to let the user know that the app has no permission?
            NSLog(@"NO microphone permission!");
            self.micPermissionImgView.hidden = NO;
        }
    }];
   
}

#pragma mark - UIImagePickerController delegate methods

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    if (picker == self.spcImagePickerController) {
        NSLog(@"imagePickerControllerDidCancel: picker is our image picker");
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        }];
    }
    else {
        NSLog(@"imagePickerControllerDidCancel: picker is NOT our image picker");
        [self dismissCameraRoll];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    if (NO == self.MAMWasDismissed) {
        // - handle vids
        NSString *type = info[UIImagePickerControllerMediaType];
        if ([type isEqualToString:(NSString *)kUTTypeVideo] ||
            [type isEqualToString:(NSString *)kUTTypeMovie]) {
            
            NSURL *videoURL = info[UIImagePickerControllerMediaURL];
            self.numVideosProcesssing = 1;
            [self addVideoWithURL:videoURL];
            self.memoryType = MemoryTypeVideo;
            
            if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
                [assetLibrary writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error){ }];
            }
            
            [self performSelector:@selector(confirmVideoIsProcessed) withObject:nil afterDelay:.1];
        }
        // - handle photos
        if ([type isEqualToString:(NSString *)kUTTypeImage]) {
            //NSLog(@"snapped photo!");
            self.memoryType = MemoryTypeImage;
            //process image on delay to enable immediate display of post vc
            UIImage *sourceImage = info[UIImagePickerControllerOriginalImage];

            
            if (self.hasSelectedAVenue) {
                [self finishPost];
                [self performSelector:@selector(prepImage:) withObject:sourceImage afterDelay:1];
            }
            else {
                //If the user has not selected a location for this memory, we scale the image
                //And then show the pick location screen
                [self prepImage:sourceImage];
            }
        }
    }
}

#pragma mark QBImagePickerController delegate methods

- (void)imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets {
    
    BOOL vidsSelected = NO;
    
    if (self.assetUploadCoordinator.totalAssetCount == 0) {
        self.hasSelectedAVenue = NO;  //reset this in case the user has selected a venue and then returned here, and is now adding a camera roll asset as the base asset for a mem
    }
    
    //handle photo assets

    for (int i = 0; i<[assets count]; i++) {
   
        ALAsset *asset =  (ALAsset *)assets[i];
        NSString *assetType = [asset valueForProperty:ALAssetPropertyType];
        NSURL *url= (NSURL *)[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[asset valueForProperty:ALAssetPropertyURLs] allKeys][0]];
        
        if ([assetType isEqualToString:ALAssetTypePhoto]){
            ALAssetRepresentation *representation = [asset defaultRepresentation];
            CGImageRef imageRef = [representation fullResolutionImage];
            
            CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
            NSLog(@"photo metadata geotag - lat:%f long:%f",location.coordinate.latitude,location.coordinate.longitude);
            
            if (i == 0) {
                self.photoRollLat = location.coordinate.latitude;
                self.photoRollLong = location.coordinate.longitude;
                
            }
            
            if (imageRef) {
                UIImage *sourceImg = [UIImage imageWithCGImage:imageRef scale:representation.scale orientation:(int)representation.orientation];
                UIImage *scaledSourceImg = [self scaleUIImage:sourceImg];
                SPCImageToCrop *imageToCrop = [[SPCImageToCrop alloc] initWithDefaultsAndImage:scaledSourceImg];
                
                //update mem type
                self.memoryType = MemoryTypeImage;

                if ([assets count] > 1) {
                
                    //add to scroller
                    [self.customControls addImageToScrollView:imageToCrop];

                    //update controls
                    [self.customControls updateControlsForPhoto];
                    
                    //add to asset coordinator
                    [self.assetUploadCoordinator addPendingAsset:[[SPCPendingAsset alloc] initWithImageToCrop:imageToCrop]];
                }
                else {
                    //add to scroller
                    [self.customControls addImageToScrollView:imageToCrop];
                    
                    //update controls
                    [self.customControls updateControlsForPhoto];
                    
                    //add to asset coordinator
                    [self.assetUploadCoordinator addPendingAsset:[[SPCPendingAsset alloc] initWithImageToCrop:imageToCrop]];
                }
            }
            
            if (i == assets.count - 1) {
                [self dismissCameraRollAndFinishPost];
            }
        }
    
        //handle video assets
        if ([assetType isEqualToString:ALAssetTypeVideo]){
            
            CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
            NSLog(@"video metadata geotag - lat:%f long:%f",location.coordinate.latitude,location.coordinate.longitude);
            
            if (i == 0) {
                self.photoRollLat = location.coordinate.latitude;
                self.photoRollLong = location.coordinate.longitude;
            }
            
            //update vid controls
            self.videoCaptureInProgress = NO;
            [self.spcImagePickerController stopVideoCapture];
            [self.customControls resetVideoControls];
            self.numVideosProcesssing = self.numVideosProcesssing + 1;
            
            [self addVideoWithURL:url];
            vidsSelected = YES;
        }
  }
   
    if (vidsSelected) {
        [self confirmVideoIsProcessed];
    }
}

#pragma mark - SPCImageEditingControllerDelegate

- (void)cancelEditing {
    [self.spcImagePickerController dismissViewControllerAnimated:YES  completion:^{
        self.spcImageEditingController = nil;
        self.editingExistingImage = NO;
    }];
}

- (void)finishedEditingImage:(SPCImageToCrop *)newImage {
    
    NSLog(@"newImage originX %f originY %f cropSize %f",newImage.originX,newImage.originY,newImage.cropSize);
    
    //update thumb display
    [self.customControls addImageToScrollView:newImage];
    self.memoryType = MemoryTypeImage;
    
    if (self.editingExistingImage) {
        //NSLog(@"replacing existing asset");
        [self.assetUploadCoordinator removePendingAssetAtIndex:self.editingImageIndex];
        [self.assetUploadCoordinator addPendingAsset:[[SPCPendingAsset alloc] initWithImageToCrop:newImage]];
        [self.customControls updateScrollViewWithArray:self.assetUploadCoordinator.imagesToCropArray];
        //NSLog(@"done");
    }
    else {
        //add to assets array
        [self.assetUploadCoordinator addPendingAsset:[[SPCPendingAsset alloc] initWithImageToCrop:newImage]];
        [self.customControls updateControlsForPhoto];
    }
    
    [self.spcImagePickerController dismissViewControllerAnimated:YES  completion:^{
        self.spcImageEditingController = nil;
        self.editingExistingImage = NO;
    }];
}


#pragma mark SPCPickLocationViewController delegate methods

- (void)spcPickLocationViewControllerDidFinish:(id)sender withSelectedVenue:(Venue *)venue{

    self.hasSelectedAVenue = YES;
    self.selectedVenue = venue;
    [self.postMemoryViewController updateLocation:venue];
    [self finishPost];

}

- (void)spcPickLocationViewControllerDidFinish:(id)sender withSelectedTerritory:(SPCCity *)territory {
    self.hasSelectedAVenue = YES;
    self.selectedTerritory = territory;
    [self.postMemoryViewController updateLocationWithTerritory:territory];
    [self finishPost];
    
}

- (void)spcPickLocationViewControllerDidCancel:(id)sender{
    self.postMemoryViewController.selectedVenue = nil;
    self.postMemoryViewController.selectedTerritory = nil;
    self.spcPickLocationViewController.view.alpha = 0;
}

- (void)prepForVenueReset {
    self.postMemoryViewController.resetVenueIfAssetsDeleted = YES;
}

#pragma mark SPCPostMemoryViewController delegate methods

- (void)spcPostMemoryViewControllerDidCancel:(id)sender withSelectedVenue:(Venue *)venue{
 
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spc_hideStatusBar" object:nil];
    [self.spcImagePickerController dismissViewControllerAnimated:YES completion:^{
        self.postMemoryViewController = nil;
    }];
    self.selectedVenue = venue;
}

- (void)spcPostMemoryViewControllerDidCancel:(id)sender withSelectedTerritory:(SPCCity *)territory {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spc_hideStatusBar" object:nil];
    [self.spcImagePickerController dismissViewControllerAnimated:YES completion:^{
        self.postMemoryViewController = nil;
    }];
    
    if (self.assetUploadCoordinator.totalAssetCount > 0){
        self.selectedTerritory = territory;
    }
}

- (void)spcPostMemoryViewControllerDidCancelToUpdateLocation:(id)sender withSelectedVenue:(Venue *)venue {
    
    //This method is called when user taps Change Location from w/in MAM
    self.selectedVenue = venue;
    
    self.hasSelectedAVenue = NO;
    SPCImageToCrop *imageToCrop;
    
    if (self.assetUploadCoordinator.pendingAssets.count > 0) {
        SPCPendingAsset *asset = ((SPCPendingAsset *)self.assetUploadCoordinator.pendingAssets[0]);
        imageToCrop = asset.imageToCrop;
    }

    if (self.spcPickLocationViewController.fuzzedVenuesOnly) {
        [self pickLocationUsingPhotoRollAssetWithLatitude:self.photoRollLat longitude:self.photoRollLong image:imageToCrop];
    }
    else {
        [self pickLocation:imageToCrop];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spc_hideStatusBar" object:nil];
    
    [self.spcImagePickerController dismissViewControllerAnimated:YES completion:^{
        self.postMemoryViewController = nil;
    }];
}

- (void)spcPostMemoryViewControllerAnimateInChangeLocation {
    
    //hack to handle desired animation
    //1. Add the pick location view to the postMemVC view with alpha 0, set it off screen, update alpha to 1, then animate it in.
    //2. when animation is complete, restore our actual pick location view and dismiss the postMemVC via the pickLocation call 
    
    self.spcPickLocationViewController.view.alpha = 0;
    [self.postMemoryViewController.view addSubview:self.spcPickLocationViewController.view];
    self.spcPickLocationViewController.view.center = CGPointMake(self.view.bounds.size.width/2 - self.view.bounds.size.width, self.view.bounds.size.height/2);
    self.spcPickLocationViewController.view.alpha = 1;
    self.spcPickLocationViewController.view.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.spcPickLocationViewController.view.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [self.view addSubview:self.spcPickLocationViewController.view];
                             [self.postMemoryViewController pickLocation];
                             self.spcPickLocationViewController.view.userInteractionEnabled = YES;
                         }
                     }];
    
}


- (void)spcPostMemoryViewControllerDidFinish:(id)sender {
    
    NSLog(@"spcPostMemoryViewControllerDidFinish");
    
    if (self.spcPickLocationViewController.fuzzedVenuesOnly) {
        [Flurry logEvent:@"MAM_PHOTO_ROLL_MEM_POSTED"];
    }
    BOOL isIos8orGreater = NO;
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        isIos8orGreater = YES;
        NSLog("iOS 8+ handle make mem!");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"handleMakeMemAnimation" object:nil];
    }
    
    
    [self.spcImagePickerController dismissViewControllerAnimated:NO completion:^{
        NSLog(@"spcImagePickerControllerDismissed!");
        self.selectedVenue = nil;
        self.assetUploadCoordinator = nil;
        [self.precacheImgView removeFromSuperview];
        self.precacheImgView = nil;
        self.postMemoryViewController = nil;
        if (!isIos8orGreater) {
            NSLog("iOS 7 handle make mem!");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"handleMakeMemAnimation" object:nil];
        }
    }];
}

- (void)spcPostMemoryViewControllerDidUpdatePendingAssets:(SPCAssetUploadCoordinator *)assetUploadCoordinator {
    
    if (assetUploadCoordinator.totalAssetCount == 0) {
        _assetUploadCoordinator = nil;
        
        //reset location selections
        self.hasSelectedAVenue = NO;
        self.selectedTerritory = nil;
        self.selectedVenue = nil;
        self.spcPickLocationViewController.fuzzedVenuesOnly = NO;
    }
    else {
        self.assetUploadCoordinator = assetUploadCoordinator;
    }
    
    [self.customControls updateScrollViewWithArray:assetUploadCoordinator.imagesToCropArray];
    
    if (self.assetUploadCoordinator.totalAssetCount == 0){
        self.memoryType = MemoryTypeText;
       
        //reset location selections
        self.hasSelectedAVenue = NO;
        self.selectedTerritory = nil;
        self.selectedVenue = nil;
        self.spcPickLocationViewController.fuzzedVenuesOnly = NO;
        
        //reset camera capture mode to default if needed
        if (self.spcImagePickerController.cameraCaptureMode != UIImagePickerControllerCameraCaptureModePhoto){
            self.spcImagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        }
    }
    if (self.assetUploadCoordinator.hasVideos) {
        
        self.memoryType = MemoryTypeVideo;
        NSLog(@"did update controls for vid");
        //reset camera capture mode to video only if needed
        if (self.spcImagePickerController.cameraCaptureMode != UIImagePickerControllerCameraCaptureModeVideo){
            self.spcImagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            [self.customControls updateControlsForVideo];
        }
    }
}

- (void)updateSelectedVenue:(Venue *)venue {
    self.selectedVenue = venue;
}

- (void)updateSelectedTerritory:(SPCCity *)territory {
    self.selectedTerritory = territory;
}

- (void)spcPostMemoryViewControllerUpdateTaggedFriendsToRestore:(NSArray *)selectedFriends {
    self.previouslySelectedFriends = selectedFriends;
}
- (void)spcPostMemoryViewControllerUpdateMemoryTextToRestore:(NSString *)textToRestore {
    self.textToRestore = textToRestore;
}
- (void)spcPostMemoryViewControllerUpdateAnonStatusToRestore:(BOOL)isAnon {
    self.anonSelected = isAnon;
}


#pragma mark SPCCustomCameraControls delegate methods

- (void)editImage:(int)indexToEdit {
    if (self.memoryType != MemoryTypeVideo) {
        NSLog(@"edit existing image at %i",indexToEdit);
        self.editingImageIndex = indexToEdit;
        self.editingExistingImage = YES;
        
        SPCPendingAsset *pendingAsset = self.assetUploadCoordinator.pendingAssets[indexToEdit];
        SPCImageToCrop *imageToCrop = [[SPCImageToCrop alloc] initWithImageToCrop:pendingAsset.imageToCrop];
        self.spcImageEditingController.sourceImage = imageToCrop;
        
        SPCNavControllerLight *navigationController = [[SPCNavControllerLight alloc] initWithRootViewController:self.spcImageEditingController];
        navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        navigationController.navigationBar.hidden = YES;
        [self.spcImagePickerController presentViewController:navigationController animated:YES completion:NULL];
    }
}

#pragma mark - Private

-(void)showNoCamAlert {
 
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                        message:@"There is no camera available"
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
    
    [self finishPost];
}

-(void)showNoGPSAlert {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Spayce Requires Location!"
                                                        message:@"You can only post pics from the camera roll that have GPS data"
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - Image Rotation/Scaling methods

- (UIImage*)rotateUIImage:(UIImage*)sourceImage clockwise:(BOOL)clockwise
{
    CGSize size = sourceImage.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    [[UIImage imageWithCGImage:[sourceImage CGImage] scale:1.0 orientation:clockwise ? UIImageOrientationRight : UIImageOrientationLeft] drawInRect:CGRectMake(0,0,size.height ,size.width)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)scaleUIImage:(UIImage *)sourceImage
{
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

#pragma mark - Video Processing methods

-(void)addVideoWithURL:(NSURL *)videoURL {
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    CMTime duration = sourceAsset.duration;
    float seconds = CMTimeGetSeconds(duration);
    NSLog(@"video duration %f",seconds);
    
    if (seconds > 16) {
        NSLog(@"video is too long!");
        [self videoLengthAlert];
    }
    else {
        [self.customControls disableNextBtn];
        [self.customControls addLoadingImgToScrollView];
        
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
        [self convertVideoToLowQuailtyWithInputURL:videoURL outputURL:outputURL handler:^(BOOL success)
         {
             if (success) {
                 NSLog(@"completed compression\n");
                 // Place this video, with thumbnail, in our pending asset list.
                 [self.assetUploadCoordinator addPendingAsset:[[SPCPendingAsset alloc] initWithImageToCrop:imageToCrop videoURL:outputURL]];
                 
                 self.memoryType = MemoryTypeVideo;
                 self.numVideosProcesssing = self.numVideosProcesssing - 1;
                 [self.customControls performSelectorOnMainThread:@selector(enableNextBtn) withObject:nil waitUntilDone:NO];
            } else {
                 NSLog(@"compression error\n");
                [self.customControls performSelectorOnMainThread:@selector(enableNextBtn) withObject:nil waitUntilDone:NO];
            }
         }];
        
        // Create a thumbnail image to use for this video
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        AVAssetImageGenerator *imageGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        NSError *err = NULL;
        CMTime time = CMTimeMake(0, 60);
        CGImageRef imgRef = [imageGen copyCGImageAtTime:time actualTime:NULL error:&err];
        UIImage *thumb = [[UIImage alloc] initWithCGImage:imgRef];
        
        if (self.portraitVid){
            self.portraitVid = NO;
            thumb = [self rotateUIImage:thumb clockwise:YES];
        }
        if (self.upsideDownPortraitVid) {
            self.upsideDownPortraitVid = NO;
            thumb = [self rotateUIImage:thumb clockwise:NO];
        }
        
        if (self.landscapeLeft){
            thumb = [self rotateUIImage:thumb clockwise:NO];
            thumb = [self rotateUIImage:thumb clockwise:NO];
        }
        
        [self.customControls updateButtonTitle];
        
        //update thumb display
        imageToCrop = [[SPCImageToCrop alloc] initWithDefaultsAndImage:thumb];
        [self.customControls performSelector:@selector(addImageToScrollView:) withObject:imageToCrop afterDelay:.1];
    }
}

- (void)compressVideoWithInputURL:(NSURL*)inputURL
                        outputURL:(NSURL*)outputURL
                          handler:(void (^)(AVAssetExportSession*))handler
{
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

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
                                   outputURL:(NSURL*)outputURL
                                    handler:(void (^)(BOOL success))handler
{
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
    
    NSLog(@"processing video...");
    self.processingVideoView.hidden = NO;
    
    // Ensure the user cannot select/capture video while processing
    [self.customControls disableGetVideoBtns];
    
    if (self.numVideosProcesssing == 0) {
        NSLog(@"finished processing video!");
        self.processingVideoView.hidden = YES;
        if (self.cameraRollPickerIsVisible) { // dismiss the picker if it is visible
            [self dismissCameraRollAndFinishPost];
        }
        else {
            if (self.hasSelectedAVenue) {
                //NSLog(@"video processed, already selected location!");
                [self performSelector:@selector(finishPost) withObject:nil afterDelay:.1];
            }
            else {
                //NSLog(@"video processed, time to select location!");
                SPCImageToCrop *imageToCrop;
                if (self.assetUploadCoordinator.pendingAssets.count > 0) {
                    SPCPendingAsset *asset = ((SPCPendingAsset *)self.assetUploadCoordinator.pendingAssets[0]);
                    imageToCrop = asset.imageToCrop;
                }

                [self pickLocation:imageToCrop];
            }
        }
    }
    else {
        [self performSelector:@selector(confirmVideoIsProcessed) withObject:nil afterDelay:.1];
    }
}

- (void)videoLengthAlert {
    
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

- (void)dismissAlert:(id)sender {
    [self.alertView dismiss:sender];
    self.alertView = nil;
}

#pragma mark - Navigation methods

-(void)dismissImagePicker {
    self.customControls.closeBtn.userInteractionEnabled = NO;
    self.MAMWasDismissed = YES;
    self.selectedVenue = nil;
    [self.assetUploadCoordinator clearAllAssets];
    self.assetUploadCoordinator = nil;
    self.postMemoryViewController = nil;
    [self.precacheImgView removeFromSuperview];
    self.precacheImgView = nil;
    if (self.videoCaptureInProgress) {
        [self stopVideoCapture];
    }
    self.selectedTerritory = nil;
    self.selectedVenue = nil;
    self.hasSelectedAVenue = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMAM" object:nil];
}

-(void)handleTextMem {
    
    //set fuzzed device venue for a text mem (and kill territory in case we have, perhaps, deleted an image memory and returned here)
    if (self.assetUploadCoordinator.totalAssetCount == 0) {
        [self.postMemoryViewController setFuzzedDefaultForTextMem];
        self.selectedTerritory = nil;
    }


    if (!self.selectedVenue && !self.selectedTerritory) {
        //force a location choice for a cam roll pic if a location hasn't been picked user and user returned to the capture screen via back btn and has just tapped next
        if (self.assetUploadCoordinator.totalAssetCount > 0) {
            SPCImageToCrop *imageToCrop;
            SPCPendingAsset *asset = ((SPCPendingAsset *)self.assetUploadCoordinator.pendingAssets[0]);
            imageToCrop = asset.imageToCrop;
            [self pickLocationUsingPhotoRollAssetWithLatitude:self.photoRollLat longitude:self.photoRollLong image:imageToCrop];
        }
        else {
            //NSLog(@"no assets, handle as text mem");
            [self finishPost];
        }
        
    }
    else {
        [self finishPost];
    }
}

-(void)pickLocation:(SPCImageToCrop *)snappedImage {
    
    float deviceLat = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
    float deviceLong = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
    
    self.spcPickLocationViewController.fuzzedVenuesOnly = NO;
    
    [self.spcPickLocationViewController configureWithLatitude:deviceLat longitude:deviceLong image:snappedImage];
    self.spcPickLocationViewController.view.alpha = 1;
    [self.spcPickLocationViewController showLocationOptions];
}

-(void)pickLocationUsingPhotoRollAssetWithLatitude:(float)picLatitude longitude:(float)picLongitude image:(SPCImageToCrop *)camRollImage {
    
    self.spcPickLocationViewController.fuzzedVenuesOnly = YES;
    [self.spcPickLocationViewController configureWithLatitude:picLatitude longitude:picLongitude image:camRollImage];
    self.spcPickLocationViewController.view.alpha = 1;
    [self.spcPickLocationViewController showLocationOptions];
}

-(void)finishPost {
    
    NSLog(@"finishPost");

    [[NSNotificationCenter defaultCenter] postNotificationName:@"spc_showStatusBar" object:nil];
    if (self.selectedVenue) {
        [self.postMemoryViewController setSelectedVenue:self.selectedVenue];
    }
    
    if (self.selectedTerritory) {
        [self.postMemoryViewController setSelectedTerritory:self.selectedTerritory];
    }
    
    [self.spcImagePickerController presentViewController:self.postMemoryViewController animated:YES completion:^{
     
        
        //restore any content that has previously been set for this mem
        if (self.previouslySelectedFriends.count > 0) {
            [self.postMemoryViewController restoreSelectedFriends:self.previouslySelectedFriends];
        }
        
        if (self.textToRestore.length > 0) {
            [self.postMemoryViewController restoreMemoryText:self.textToRestore];
        }
        [self.postMemoryViewController restoreAnon:self.anonSelected];
        
        BOOL canEdit = NO;
        if (self.memoryType == MemoryTypeImage) {
            canEdit = YES;
        }
        [self.postMemoryViewController configureWithAssetUploadCoordinator:self.assetUploadCoordinator canEdit:canEdit];
        
        [self.customControls enableGetVideoBtns];
        
        self.spcPickLocationViewController.view.alpha = 0;
        [self.spcPickLocationViewController reset];
    }];
}

-(void)prepImage:(UIImage *)image {
    
    //handling scaling/saving of image on background thread to maintain UI responsiveness when transitioning directly to Post Mem VC

    if (!self.hasSelectedAVenue) {
        UIImage *scaledSourceImg = [self scaleUIImage:image];
        SPCImageToCrop *imageToCrop = [[SPCImageToCrop alloc] initWithDefaultsAndImage:scaledSourceImg];
        [self pickLocation:imageToCrop];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        UIImage *scaledSourceImg = [self scaleUIImage:image];

        //saving scaled image to cam roll rather that source image to reduce memory pressure
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
            UIImageWriteToSavedPhotosAlbum(scaledSourceImg, nil, nil, nil);
        }
        
        SPCImageToCrop *imageToCrop = [[SPCImageToCrop alloc] initWithDefaultsAndImage:scaledSourceImg];
    
        //finish off back on main thread
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.customControls addImageToScrollView:imageToCrop];
            [self.assetUploadCoordinator addPendingAsset:[[SPCPendingAsset alloc] initWithImageToCrop:imageToCrop]];
            [self.postMemoryViewController configureWithAssetUploadCoordinator:self.assetUploadCoordinator canEdit:YES];
        });
    });
}

#pragma mark - Custom Camera Control Actions

-(void)flipCam {
    if (self.spcImagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        self.spcImagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    else {
        self.spcImagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
}

-(void)toggleFlash {
    if (!self.isFlashOn) {
        self.isFlashOn = YES;
        self.spcImagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
         UIImage *flashImg = [UIImage imageNamed:@"camera-flash-on"];
        [self.customControls.flashBtn setBackgroundImage:flashImg forState:UIControlStateNormal];
    }
    else {
        self.isFlashOn = NO;
        self.spcImagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        UIImage *flashImg = [UIImage imageNamed:@"camera-flash-off"];
        [self.customControls.flashBtn setBackgroundImage:flashImg forState:UIControlStateNormal];
    }
}

-(void)takePicture {
    if (!self.cameraIsLocked) {
        self.micPermissionImgView.hidden = YES;
        self.cameraIsLocked = YES;
        [self.spcImagePickerController takePicture];
        [self performSelector:@selector(enableCamera) withObject:nil afterDelay:2];
        [self.customControls performSelector:@selector(updateControlsForPhoto) withObject:nil afterDelay:2];
    }
}

-(void)enableCamera {
    self.cameraIsLocked = NO;
}

-(void)takeVideo{
    self.micPermissionImgView.hidden = YES;
    if (NO == self.videoCaptureInProgress) {
        [self.customControls disableGetVideoBtns];
        self.customControls.takePicBtn.hidden = YES;
        
        if (self.spcImagePickerController.cameraCaptureMode == UIImagePickerControllerCameraCaptureModeVideo) {
            
            NSLog(@"in video capture mode!");
            //record video
            if (!self.videoCaptureInProgress) {
                [self performSelector:@selector(startVideoCapture) withObject:nil afterDelay:1.5f];
            }
        } else {
            NSLog(@"not ready for video..try again after delay..");
            self.spcImagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            [self performSelector:@selector(takeVideo) withObject:nil afterDelay:.1f]; // This can be set to a very short interval
        }
    }
}

- (void)startVideoCapture {
    if (NO == self.videoCaptureInProgress) {
        if (YES == [self.spcImagePickerController startVideoCapture]) {
            NSLog(@"start recording video!");
            [self.customControls disableNextBtn];
            self.videoCaptureInProgress = YES;
            [self.customControls updateControlsForVideo];
        } else {
            // Retry starting video capture if it fails to start
            [self performSelector:@selector(startVideoCapture) withObject:nil afterDelay:0.5f];
        }
    }
}

- (void)stopVideoCapture {
    NSLog(@"already recording video, time to stop");
    self.videoCaptureInProgress = NO;
    [self.spcImagePickerController stopVideoCapture];
    [self.customControls resetVideoControls];
}

-(void)autoStopVideo{
    self.videoCaptureInProgress = NO;
    [self.spcImagePickerController stopVideoCapture];
    [self.customControls resetVideoControls];
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
         NSLog(@"not determined!");
        self.cameraRollPickerController = nil;
        
        SPCNavControllerLight *navigationController = [[SPCNavControllerLight alloc] initWithRootViewController:self.cameraRollPickerController];
        [navigationController.navigationItem.leftBarButtonItem setTintColor:[UIColor whiteColor]];
        [self.spcImagePickerController presentViewController:navigationController animated:YES completion:^{
            self.cameraRollPickerIsVisible = YES;
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

-(void)dismissCameraRoll {
    [self.cameraRollPickerController dismissViewControllerAnimated:YES completion:^ {
        self.cameraRollPickerIsVisible = NO;
    }];
}

-(void)dismissCameraRollAndFinishPost {
    
    if (!self.hasSelectedAVenue) {
        
        //NSLog(@"dismising cam roll, time to pick location!");
        SPCImageToCrop *imageToCrop;
        
        if (self.assetUploadCoordinator.pendingAssets.count > 0) {
            SPCPendingAsset *asset = ((SPCPendingAsset *)self.assetUploadCoordinator.pendingAssets[0]);
            imageToCrop = asset.imageToCrop;
        }
        
        [self pickLocationUsingPhotoRollAssetWithLatitude:self.photoRollLat longitude:self.photoRollLong image:imageToCrop];
    }
    
    [self.cameraRollPickerController dismissViewControllerAnimated:YES completion:^ {
        self.cameraRollPickerIsVisible = NO;
        if (self.hasSelectedAVenue) {
            //NSLog(@"dismising cam roll, already picked location!");
            [self finishPost];
        }
    }
     ];
}

#pragma  mark - Orientation Methods

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if (touch.view == self.micPermissionImgView) {
        self.micPermissionImgView.hidden = YES;
    }
}

@end
