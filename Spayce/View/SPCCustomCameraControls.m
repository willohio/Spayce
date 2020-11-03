//
//  SPCCustomCameraControls.m
//  Spayce
//
//  Created by Christopher Taylor on 5/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCCustomCameraControls.h"
#import <AssetsLibrary/AssetsLibrary.h>


@interface SPCCustomCameraControls () {
    int numImages;
}

@end

@implementation SPCCustomCameraControls

-(void)dealloc {
    [self.timer invalidate];
    self.timer = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *topOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 50)];
        topOverlay.backgroundColor = [UIColor colorWithRed:22.0f/255.0f green:24.0f/255.0f blue:28.0f/255.0f alpha:.7];
        
        self.closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 50, 50)];
        self.closeBtn.backgroundColor = [UIColor clearColor];
        [self.closeBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        self.closeBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        [self.closeBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.closeBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
        [self.closeBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        
  
        [topOverlay addSubview:self.closeBtn];
        
        self.skipBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width-80, 0, 80, 50)];
        self.skipBtn.backgroundColor = [UIColor clearColor];
        [self.skipBtn setTitle:@"Text-only" forState:UIControlStateNormal];
        self.skipBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        [self.skipBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.skipBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
        [self.skipBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        
        [topOverlay addSubview:self.skipBtn];
        
        if (([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) &&
            ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])) {
            
            self.flipCamBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            self.flipCamBtn.backgroundColor = [UIColor clearColor];
            UIImage *camImg = [UIImage imageNamed:@"camera-flip"];
            [self.flipCamBtn setBackgroundImage:camImg forState:UIControlStateNormal];
            self.flipCamBtn.center = CGPointMake(self.frame.size.width * .62, self.flipCamBtn.center.y);
            [topOverlay addSubview:self.flipCamBtn];
        }
        
        self.flashBtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 0,50, 50)];
        self.flashBtn.backgroundColor = [UIColor clearColor];
        UIImage *flashOffImg = [UIImage imageNamed:@"camera-flash-off"];
        [self.flashBtn setBackgroundImage:flashOffImg forState:UIControlStateNormal];
        self.flashBtn.center = CGPointMake(self.frame.size.width * .38, self.flashBtn.center.y);
        [topOverlay addSubview:self.flashBtn];
        
        [self addSubview:topOverlay];
        
        self.thumbScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 50 + self.bounds.size.width, self.bounds.size.width, 50)];
        self.thumbScrollView.backgroundColor = [UIColor colorWithRed:22.0f/255.0f green:24.0f/255.0f blue:28.0f/255.0f alpha:0.7f];
        self.thumbScrollView.scrollEnabled = YES;
        [self addSubview:self.thumbScrollView];
        
        
        UIView *bottomOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.thumbScrollView.frame), self.bounds.size.width, self.bounds.size.height - CGRectGetMaxY(self.thumbScrollView.frame))];
        bottomOverlay.backgroundColor = [UIColor colorWithRed:22.0f/255.0f green:24.0f/255.0f blue:28.0f/255.0f alpha:1.0f];
        [self addSubview:bottomOverlay];
        
        UIView *ovalView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 275,100)]; // Width of 275 is large enough to house all of the buttons for screen widths of 320 -> 375+pt
        ovalView.backgroundColor = [UIColor clearColor];
        ovalView.center = CGPointMake(bottomOverlay.frame.size.width/2, bottomOverlay.frame.size.height/2);
        ovalView.layer.cornerRadius = 25;
        [bottomOverlay addSubview:ovalView];
        
        self.cameraRollBtn = [[UIButton alloc] initWithFrame:CGRectMake(25, 25, 50, 50)];
        self.cameraRollBtn.backgroundColor = [UIColor clearColor];
        UIImage *photoRollImg = [UIImage imageNamed:@"camara-photo-roll"];
        [self.cameraRollBtn setBackgroundImage:photoRollImg forState:UIControlStateNormal];
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        if (status == ALAuthorizationStatusAuthorized) {
            NSLog(@"already authorized camera roll!");
            [self getLatestFromCamRoll];
        }
        [ovalView addSubview:self.cameraRollBtn];
        
        self.takePicBtn = [[UIButton alloc] initWithFrame:CGRectMake(84, 5, 90, 90)]; // Center is changed below
        self.takePicBtn.backgroundColor = [UIColor clearColor];
        UIImage *takePicImg = [UIImage imageNamed:@"jumbo-cam-btn"];
        [ovalView addSubview:self.takePicBtn];
        
        self.takeVidBtn = [[UIButton alloc] initWithFrame:CGRectMake(ovalView.frame.size.width-75, 25, 50, 50)];
        self.takeVidBtn.backgroundColor = [UIColor clearColor];
        UIImage *takeVidImg = [UIImage imageNamed:@"camera-record"];
        [ovalView addSubview:self.takeVidBtn];
        
        if ([UIScreen mainScreen].bounds.size.height <= 480) {
            self.takePicBtn.frame = CGRectMake(0, 0, 65, 65); // Center is changed below
        }
        
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            self.cameraRollBtn.frame = CGRectMake(5, 22, 55, 55);
            self.takePicBtn.frame = CGRectMake(0, 0, 100, 100); // Center is changed below
            self.takeVidBtn.frame = CGRectMake(ovalView.frame.size.width-60, 22, 55, 55);
            
            takePicImg = [UIImage imageNamed:@"jumbo6-cam-btn"];
            takeVidImg = [UIImage imageNamed:@"vid6-btn"];
        }
        
        self.stopVidBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        self.stopVidBtn.backgroundColor = [UIColor clearColor];
        self.stopVidBtn.hidden = YES;
        [ovalView addSubview:self.stopVidBtn];
        

        [self.takePicBtn setBackgroundImage:takePicImg forState:UIControlStateNormal];
        [self.takeVidBtn setBackgroundImage:takeVidImg forState:UIControlStateNormal];
        [self.stopVidBtn setBackgroundImage:[UIImage imageNamed:@"video-stop"] forState:UIControlStateNormal];
        
        
        self.takePicBtn.center = CGPointMake(ovalView.frame.size.width/2, ovalView.frame.size.height/2);
        self.stopVidBtn.center = self.takePicBtn.center;
        
        
        // We want the timer label inside of the ovalView frame, but the ovalView frame is not as wide as the entire screen
        CGFloat fullScreenMinusOvalViewWidth = self.bounds.size.width - ovalView.bounds.size.width;
        self.timerLbl = [[UILabel alloc] initWithFrame:CGRectMake(-1*fullScreenMinusOvalViewWidth / 2 + 30, 0, self.bounds.size.width - 60, ovalView.frame.size.height)];
        self.timerLbl.textAlignment = NSTextAlignmentRight;
        self.timerLbl.font = [UIFont spc_regularSystemFontOfSize:30.0f];
        self.timerLbl.text = @"0:00";
        self.timerLbl.backgroundColor = [UIColor clearColor];
        self.timerLbl.textColor = [UIColor colorWithRGBHex:0xb8c1c9];
        self.timerLbl.hidden = YES;
        self.timerLbl.userInteractionEnabled = NO;
        [ovalView addSubview:self.timerLbl];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
        
    }
    return self;
}

#pragma mark - Private

-(void)addLoadingImgToScrollView {
    
    float originSpacer = (52 * numImages)-2;
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(originSpacer, 0, 2, 50)];
    spacerView.backgroundColor = [UIColor whiteColor];
    [self.thumbScrollView addSubview:spacerView];
    
    float originX = 52 * numImages;
    
    UILabel *loadingLbl = [[UILabel alloc] initWithFrame:CGRectMake(originX, 0, 50, 50)];
    loadingLbl.text = @"Loading";
    loadingLbl.textAlignment = NSTextAlignmentCenter;
    loadingLbl.font = [UIFont fontWithName:@"HelveticaNeue" size:8];
    loadingLbl.backgroundColor = [UIColor colorWithWhite:.5 alpha:1];
    loadingLbl.clipsToBounds = YES;
    loadingLbl.userInteractionEnabled = NO;
    [self.thumbScrollView addSubview:loadingLbl];
    
    self.thumbScrollView.contentSize = CGSizeMake((numImages+1)*52, 50);
}

-(void)addImageToScrollView:(SPCImageToCrop *)imageToCrop {
 
    self.skipBtn.frame = CGRectMake(self.bounds.size.width-50, 0, 50, 50);
    [self.skipBtn setTitle:@"Next" forState:UIControlStateNormal];
    [self.skipBtn setTitle:@"Next" forState:UIControlStateSelected];
    [self.skipBtn setTitle:@"Next" forState:UIControlStateHighlighted];
    
    float originSpacer = (52 * numImages)-2;
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(originSpacer, 0, 2, 50)];
    spacerView.backgroundColor = [UIColor whiteColor];
    [self.thumbScrollView addSubview:spacerView];
    
    float originX = 52 * numImages;
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:CGRectMake(originX, 0, 50, 50)];
    tempImageView.image = [imageToCrop cropPreviewImage];
    tempImageView.contentMode = UIViewContentModeScaleAspectFill;
    tempImageView.clipsToBounds = YES;
    [self.thumbScrollView addSubview:tempImageView];
    
    UIButton *tempBtn = [[UIButton alloc] initWithFrame:tempImageView.frame];
    tempBtn.backgroundColor = [UIColor clearColor];
    tempBtn.tag = numImages;
    [tempBtn addTarget:self action:@selector(editImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.thumbScrollView addSubview:tempBtn];
    
    numImages ++;
    
    self.thumbScrollView.contentSize = CGSizeMake(numImages*52, 50);
}

-(void)updateScrollViewWithArray:(NSArray *)assetsArray {
    
    //clear thumbs
    UIView *view;
    NSArray *subs = [self.thumbScrollView subviews];
    
    for (view in subs) {
        [view removeFromSuperview];
    }
    
    numImages = 0;
    
    //repopulate scroller
    for (int i = 0; i < assetsArray.count; i++) {
        SPCImageToCrop *image = (SPCImageToCrop *)assetsArray[i];
        [self addImageToScrollView:image];
    }
    
    if (assetsArray.count == 0) {
        [self resetControls];
        [self.skipBtn setTitle:@"Skip" forState:UIControlStateNormal];
    }
}

-(void)updateControlsForVideo {
    NSLog(@"updateControlsForVideo");
    self.cameraRollBtn.hidden = YES;
    self.takePicBtn.hidden = YES;
    recordingTimeElapsed = 0;
    self.isRecordingVideo = YES;
    self.timerLbl.hidden = NO;
    self.takeVidBtn.hidden = YES;
    self.stopVidBtn.hidden = NO;
}

-(void)resetVideoControls {
    NSLog(@"reset video controls");
    recordingTimeElapsed = 0;
    self.timerLbl.text = @"0:00";
    self.timerLbl.hidden = YES;
    self.isRecordingVideo = NO;
    self.cameraRollBtn.hidden = NO;
    self.takePicBtn.hidden = YES;
    self.takeVidBtn.hidden = NO;
    self.stopVidBtn.hidden = YES;
}

-(void)updateControlsForPhoto {
    NSLog(@"update controls for photo");
    self.stopVidBtn.hidden = YES;
    self.takeVidBtn.hidden = YES;
    UIImage *takePicImg = [UIImage imageNamed:@"jumbo-cam-btn"];
    [self.takePicBtn setBackgroundImage:takePicImg forState:UIControlStateNormal];
}

-(void)resetControls {
    NSLog(@"reset controls");
    self.timerLbl.hidden = YES;
    self.cameraRollBtn.hidden = NO;
    self.takePicBtn.hidden = NO;
    self.cameraRollBtn.hidden = NO;
    self.takeVidBtn.hidden = NO;
    self.stopVidBtn.hidden = YES;
    
    self.takePicBtn.center = CGPointMake([self.takePicBtn superview].frame.size.width/2, self.takePicBtn.center.y);
    UIImage *takePicImg = [UIImage imageNamed:@"jumbo-cam-btn"];
    [self.takePicBtn setBackgroundImage:takePicImg forState:UIControlStateNormal];
}

-(void)updateTime {
    if (self.isRecordingVideo){
        NSLog(@"isRecordingVideo!");
        recordingTimeElapsed++;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timerLbl.text = [NSString stringWithFormat:@"0:%02d",recordingTimeElapsed];
        });

        if (recordingTimeElapsed>15){
            self.isRecordingVideo = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"autoStopVideo" object:nil];
            NSLog(@"stop video!");
        }
    }
}

-(void)disableNextBtn {
    self.skipBtn.enabled = NO;
    self.skipBtn.alpha = .2;
}

-(void)enableNextBtn {
    self.skipBtn.enabled = YES;
    self.skipBtn.alpha = 1;
}

-(void)enableGetVideoBtns {
  self.takeVidBtn.enabled = YES;
  self.cameraRollBtn.enabled = YES;
}

-(void)disableGetVideoBtns {
  self.takeVidBtn.enabled = NO;
  self.cameraRollBtn.enabled = NO;
}

-(void)updateButtonTitle{
    [self.skipBtn setTitle:@"Next" forState:UIControlStateNormal];
    [self.skipBtn setTitle:@"Next" forState:UIControlStateSelected];
    [self.skipBtn setTitle:@"Next" forState:UIControlStateHighlighted];
    
}

-(void)getLatestFromCamRoll {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
     
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        // Chooses the photo at the last index
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
            
            // The end of the enumeration is signaled by asset == nil.
            if (alAsset) {
                CGImageRef thumbnailImageRef = [alAsset thumbnail];
                
                if (thumbnailImageRef) {
                    UIImage *latestPhoto = [UIImage imageWithCGImage:thumbnailImageRef];
                    
                    if (latestPhoto){
                    
                        // Stop the enumerations
                        *stop = YES; *innerStop = YES;
                        
                        // Do something interesting with the AV asset.
                        [self.cameraRollBtn setBackgroundImage:latestPhoto forState:UIControlStateNormal];
                        self.cameraRollBtn.layer.cornerRadius = self.cameraRollBtn.frame.size.height/2;
                        self.cameraRollBtn.layer.borderColor = [UIColor whiteColor].CGColor;
                        self.cameraRollBtn.layer.borderWidth = 2;
                        if ([UIScreen mainScreen].bounds.size.width >= 375) {
                            self.cameraRollBtn.layer.borderWidth = 3;
                        }
                        
                        self.cameraRollBtn.clipsToBounds = YES;
                    }
                    else {
                        NSLog(@"no image avail??");
                    }
                }
                else {
                    NSLog(@"no thumbnailImageRef avail!");
                }
            }
        }];
    } failureBlock: ^(NSError *error) {
    }];
}

-(void)editImage:(id)sender {
    UIButton *btn = (UIButton *)sender;
    int indexToEdit = (int)btn.tag;

    if (self.delegate && [self.delegate respondsToSelector:@selector(editImage:)]) {
        [self.delegate editImage:indexToEdit];
    }

}

@end
