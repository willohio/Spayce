//
//  SPCMamCaptureControls.h
//  Spayce
//
//  Created by Christopher Taylor on 2/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCMamCaptureControls : UIView {
    
    int recordingTimeElapsed;
    
}

@property (nonatomic, strong) UIView *topOverlay;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UIButton *skipBtn;
@property (nonatomic, strong) UIButton *flashBtn;
@property (nonatomic, strong) UIButton *flipCamBtn;

@property (nonatomic, strong) UIView *bottomOverlay;
@property (nonatomic, strong) UIButton *takePicBtn;
@property (nonatomic, strong) UIButton *cameraRollBtn;

@property (nonatomic, assign) BOOL isRecordingVideo;

@property (nonatomic, strong) NSTimer *timer;



@end
