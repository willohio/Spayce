//
//  SPCCustomCameraControls.h
//  Spayce
//
//  Created by Christopher Taylor on 5/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCImageToCrop.h"


@protocol SPCCustomCameraControlsDelegate <NSObject>

@optional

- (void)editImage:(int)indexToEdit;

@end

@interface SPCCustomCameraControls : UIView {
    
    int recordingTimeElapsed;
    
}

@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UIButton *skipBtn;
@property (nonatomic, strong) UIButton *flashBtn;
@property (nonatomic, strong) UIButton *flipCamBtn;
@property (nonatomic, strong) UIButton *takePicBtn;
@property (nonatomic, strong) UIButton *takeVidBtn;
@property (nonatomic, strong) UIButton *stopVidBtn;
@property (nonatomic, strong) UIButton *cameraRollBtn;
@property (nonatomic, strong) UIScrollView *thumbScrollView;
@property (nonatomic, strong) UILabel *timerLbl;
@property (nonatomic, assign) BOOL isRecordingVideo;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, weak) NSObject <SPCCustomCameraControlsDelegate> *delegate;


-(void)addImageToScrollView:(SPCImageToCrop *)image;
-(void)updateControlsForPhoto;
-(void)updateControlsForVideo;
-(void)resetVideoControls;
-(void)updateScrollViewWithArray:(NSArray *)assetsArray;
-(void)enableNextBtn;
-(void)disableNextBtn;
-(void)enableGetVideoBtns;
-(void)disableGetVideoBtns;
-(void)updateButtonTitle;
-(void)addLoadingImgToScrollView;
@end
