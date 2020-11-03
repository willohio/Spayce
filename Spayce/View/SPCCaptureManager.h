//
//  SPCCaptureManager.h
//  Spayce
//
//  Created by Christopher Taylor on 3/2/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>

@protocol SPCCaptureManagerDelegate <NSObject>

@optional

- (void)capturedImage:(UIImage *)stillImage;
- (void)addVideoWithURL:(NSURL *)videoURL;

@end

@interface SPCCaptureManager : NSObject <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) NSObject <SPCCaptureManagerDelegate> *delegate;

@property (nonatomic, assign) BOOL isBackCam;

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain) AVCaptureSession *captureSession;


@property (retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, retain) UIImage *stillImage;

@property (retain) AVCaptureMovieFileOutput *movieFileOutput;


//input
-(void)addInputs;
-(void)toggleInput;

//output
-(void)addOutputs;
-(void)resetOutputs;
-(void)closeSession;

//preview
-(void)addVideoPreviewLayer;

//capture
-(void)takePicture;
-(void)beginSavingVideoCapture;
-(void)endVideoCapture;
-(void)toggleFlash:(BOOL)flashOn;

@end
