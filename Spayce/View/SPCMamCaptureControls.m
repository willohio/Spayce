//
//  SPCMamCaptureControls.m
//  Spayce
//
//  Created by Christopher Taylor on 2/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMamCaptureControls.h"

@implementation SPCMamCaptureControls

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.topOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 60)];
        self.topOverlay.backgroundColor = [UIColor colorWithRed:22.0f/255.0f green:24.0f/255.0f blue:28.0f/255.0f alpha:.7];
        
        self.closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        self.closeBtn.backgroundColor = [UIColor clearColor];
        UIImage *closeBtnImg = [UIImage imageNamed:@"mamClose"];
        [self.closeBtn setBackgroundImage:closeBtnImg forState:UIControlStateNormal];
        self.closeBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        [self.closeBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.closeBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
        [self.closeBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        
        
        [self.topOverlay addSubview:self.closeBtn];
        
        self.skipBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width-90, 12, 80, 35)];
        self.skipBtn.backgroundColor = [UIColor clearColor];
        UIImage *skipImg = [UIImage imageNamed:@"mamTextBtn"];
        [self.skipBtn setBackgroundImage:skipImg forState:UIControlStateNormal];
        self.skipBtn.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        [self.skipBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
        [self.skipBtn setTitle:@"TEXT" forState:UIControlStateNormal];
        [self.skipBtn setTitleColor:[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.skipBtn setTitleColor:[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f]  forState:UIControlStateSelected];
        [self.skipBtn setTitleColor:[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f]  forState:UIControlStateHighlighted];
        
        [self.topOverlay addSubview:self.skipBtn];
        
        if (([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) &&
            ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])) {
            
            self.flipCamBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 5, 50, 50)];
            self.flipCamBtn.backgroundColor = [UIColor clearColor];
            UIImage *camImg = [UIImage imageNamed:@"camera-flip"];
            [self.flipCamBtn setBackgroundImage:camImg forState:UIControlStateNormal];
            self.flipCamBtn.center = CGPointMake(self.frame.size.width * .62, self.flipCamBtn.center.y);
            [self.topOverlay addSubview:self.flipCamBtn];
        }
        
        self.flashBtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 5,50, 50)];
        self.flashBtn.backgroundColor = [UIColor clearColor];
        UIImage *flashOffImg = [UIImage imageNamed:@"camera-flash-off"];
        [self.flashBtn setBackgroundImage:flashOffImg forState:UIControlStateNormal];
        self.flashBtn.center = CGPointMake(self.frame.size.width * .38, self.flashBtn.center.y);
        [self.topOverlay addSubview:self.flashBtn];
        
        [self addSubview:self.topOverlay];
        
        
        float bottomOverlayYOrigin = 60 + self.bounds.size.width;
        self.bottomOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, bottomOverlayYOrigin, self.bounds.size.width, self.bounds.size.height - bottomOverlayYOrigin)];
        self.bottomOverlay.backgroundColor = [UIColor colorWithRed:14.0f/255.0f green:23.0f/255.0f blue:40.0f/255.0f alpha:1];
        [self addSubview:self.bottomOverlay];
        
        self.cameraRollBtn = [[UIButton alloc] initWithFrame:CGRectMake(25, 25, 50, 50)];
        self.cameraRollBtn.backgroundColor = [UIColor clearColor];
        UIImage *photoRollImg = [UIImage imageNamed:@"mamCamRoll"];
        [self.cameraRollBtn setBackgroundImage:photoRollImg forState:UIControlStateNormal];
        [self.bottomOverlay addSubview:self.cameraRollBtn];
        
        self.takePicBtn = [[UIButton alloc] initWithFrame:CGRectMake(84, 5, 120, 120)]; // Center is changed below
        self.takePicBtn.backgroundColor = [UIColor clearColor];
        UIImage *takePicImg = [UIImage imageNamed:@"mamCapture"];
        [self.bottomOverlay addSubview:self.takePicBtn];
        
        [self.takePicBtn setBackgroundImage:takePicImg forState:UIControlStateNormal];
        self.takePicBtn.center = CGPointMake(self.bottomOverlay.frame.size.width/2, self.bottomOverlay.frame.size.height/2);
        
        float camRollCenter = self.takePicBtn.frame.origin.x / 2;
        self.cameraRollBtn.center = CGPointMake(camRollCenter, self.bottomOverlay.frame.size.height/2);

    }
    return self;
}

@end
