//
//  SPCCaptureManager.m
//  Spayce
//
//  Created by Christopher Taylor on 3/2/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCCaptureManager.h"
#import "ImageUtils.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

@interface SPCCaptureManager ()

@property (nonatomic, weak) AVCaptureDevice *currentDevice;

@end

@implementation SPCCaptureManager

-(void)dealloc {
    NSLog(@"----------- capture manager dealloc?");
    _previewLayer = nil;
    if ([_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _captureSession = nil;
}

-(id)init {
    if ((self = [super init])) {
        NSLog(@"------------ capture manager init!");
        //create av capture session
        [self setCaptureSession:[[AVCaptureSession alloc] init]];
       
        NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
        [notify addObserver: self selector: @selector(onVideoError:) name: AVCaptureSessionRuntimeErrorNotification object: self.captureSession];
        [notify addObserver: self selector: @selector(onVideoInterrupted:) name: AVCaptureSessionWasInterruptedNotification object: self.captureSession];
        [notify addObserver: self selector: @selector(onVideoEnded:) name: AVCaptureSessionInterruptionEndedNotification object: self.captureSession];
        [notify addObserver: self selector: @selector(onVideoDidStopRunning:) name: AVCaptureSessionDidStopRunningNotification object: self.captureSession];
        [notify addObserver: self selector: @selector(onVideoStart:) name: AVCaptureSessionDidStartRunningNotification object: self.captureSession];
    }
    return self;
}

-(void)addVideoPreviewLayer {
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession]];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

-(void)addInputs {

    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (videoDevice) {
        NSError *error;
        AVCaptureDeviceInput *videoIn = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (!error) {
            if ([self.captureSession canAddInput:videoIn]) {
                NSLog(@"video input added!");
                if (videoDevice.position == AVCaptureDevicePositionFront) {
                    self.isBackCam = NO;
                }
                else {
                    self.isBackCam = YES;
                }
                
                [self.captureSession addInput:videoIn];
            }
            else{
                NSLog(@"Couldn't add video input");
            }
        }
        else {
            NSLog(@"Couldn't create video input");
        }
    }
    else {
        NSLog(@"Couldn't create video capture device");
    }
    
    //ADD AUDIO INPUT
    
    if (![self isOnPhoneCall]) {

        AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
        NSError *error = nil;
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
        if (audioInput) {
            if ([self.captureSession canAddInput:audioInput]) {
                NSLog(@"adding audio input");
                [self.captureSession addInput:audioInput];
            }
            else {
                NSLog(@"error adding audio %@",error);
            }
        }
        if (error) {
            NSLog(@"error adding audio %@",error);
        }
    
    }
    
    if (![self.captureSession isRunning]) {
        NSLog(@"start running capture!");
        [self.captureSession startRunning];
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

-(void)toggleInput {
    //Change camera source
    if(_captureSession) {
        //Indicate that some changes will be made to the session
        [_captureSession beginConfiguration];
        
        //Remove existing input
        AVCaptureInput* currentCameraInput;
        
        for (currentCameraInput in _captureSession.inputs) {
            [_captureSession removeInput:currentCameraInput];
        }
        
        //Get new input
        AVCaptureDevice *newCamera = nil;
        if (self.isBackCam) {
            self.isBackCam = NO;
            NSLog(@"switch to front cam");
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        else {
            self.isBackCam = YES;
            NSLog(@"switch to rear cam");
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
        self.currentDevice = newCamera;
        
        //Add input to session
        NSError *err = nil;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
        if(!newVideoInput || err) {
            NSLog(@"Error creating capture device input: %@", err.localizedDescription);
        }
        else
        {
            [_captureSession addInput:newVideoInput];
            
            AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            NSError *error = nil;
            
            if (![self isOnPhoneCall]) {
                AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
                if (audioInput) {
                    if ([_captureSession canAddInput:audioInput]) {
                        [_captureSession addInput:audioInput];
                    }
                }
                if (error){
                    NSLog(@"erorr %@",error);
                }
            }
            
            AVCaptureInput* currentCameraInput;
            for (currentCameraInput in _captureSession.inputs) {
                NSLog(@"updated input %@",currentCameraInput.description);
            }
        }
        
        //Commit all the configuration changes at once
        [_captureSession commitConfiguration];
    }
}

-(void)toggleFlash:(BOOL)flashOn {

    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (flashOn) {
                [device setFlashMode:AVCaptureFlashModeOn];
                NSLog(@"flash should be on!");
            } else {
                NSLog(@"flash is off!");
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) return device;
    }
    return nil;
}

-(void)stopVideoCapture {
    NSLog(@"-  -  -  --  stop captureSession????");
    //stop session??
    [self.captureSession stopRunning];
}


-(void)takePicture {
    NSLog(@"take picture?");

    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                             
                                                             if (!error) {
                                                             
                                                                 //CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                                                                 
                                                                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                                 UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                                 
                                                                 if (!self.isBackCam) {
                                                                     
                                                                     UIImageOrientation imageOrientation;
                                                                     
                                                                     switch (image.imageOrientation) {
                                                                         case UIImageOrientationDown:
                                                                             NSLog(@"UIImageOrientationDown");
                                                                             imageOrientation = UIImageOrientationDownMirrored;
                                                                             break;
                                                                             
                                                                         case UIImageOrientationDownMirrored:
                                                                              NSLog(@"UIImageOrientationDownMirrored");
                                                                             imageOrientation = UIImageOrientationDown;
                                                                             break;
                                                                             
                                                                         case UIImageOrientationLeft:
                                                                              NSLog(@"UIImageOrientationLeft");
                                                                             imageOrientation = UIImageOrientationLeftMirrored;
                                                                             break;
                                                                             
                                                                         case UIImageOrientationLeftMirrored:
                                                                              NSLog(@"UIImageOrientationLeftMirrored");
                                                                             imageOrientation = UIImageOrientationLeft;
                                                                             
                                                                             break;
                                                                             
                                                                         case UIImageOrientationRight:
                                                                              NSLog(@"UIImageOrientationRight");
                                                                             imageOrientation = UIImageOrientationLeftMirrored;
                                                                             
                                                                             break;
                                                                             
                                                                         case UIImageOrientationRightMirrored:
                                                                              NSLog(@"UIImageOrientationRightMirrored");
                                                                             imageOrientation = UIImageOrientationRight;
                                                                             
                                                                             break;
                                                                             
                                                                         case UIImageOrientationUp:
                                                                              NSLog(@"UIImageOrientationUp");
                                                                             imageOrientation = UIImageOrientationUpMirrored;
                                                                             break;
                                                                             
                                                                         case UIImageOrientationUpMirrored:
                                                                              NSLog(@"UIImageOrientationUpMirrored");
                                                                             imageOrientation = UIImageOrientationUp;
                                                                             break;
                                                                         default:
                                                                             break;
                                                                     }
                                                                     
                                                                     UIImage *flippedImage = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:imageOrientation];
                                                                     
                                                                     [self.delegate capturedImage:flippedImage];
                                                                     
                                                                 } else {
                                                                     [self.delegate capturedImage:image];
                                                                 }
                                                             }
                                                        
                                                         }];
}

-(void)addOutputs {
  
    [self.captureSession beginConfiguration];
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        NSLog(@"Adding still image output");
        [self.captureSession addOutput:[self stillImageOutput]];
    }
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 TotalSeconds = 16;			//Total seconds
    int32_t preferredTimeScale = 30;	//Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
    self.movieFileOutput.maxRecordedDuration = maxDuration;
    
    self.movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;						//<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
    if ([self.captureSession canAddOutput:self.movieFileOutput]) {
        NSLog(@"movie output added!");
        [self.captureSession addOutput:self.movieFileOutput];
    }
    else {
        NSLog(@"UH OH!!!!  -- no movie output added");
    }
    
    //----- SET THE IMAGE QUALITY / RESOLUTION -----
    //Options:
    //	AVCaptureSessionPresetHigh - Highest recording quality (varies per device)
    //	AVCaptureSessionPresetMedium - Suitable for WiFi sharing (actual values may change)
    //	AVCaptureSessionPresetLow - Suitable for 3G sharing (actual values may change)
    //	AVCaptureSessionPreset640x480 - 640x480 VGA (check its supported before setting it)
    //	AVCaptureSessionPreset1280x720 - 1280x720 720p HD (check its supported before setting it)
    //	AVCaptureSessionPresetPhoto - Full photo resolution (not supported for video output)
    //NSLog(@"Setting image quality");
    [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720] &&
        [self.currentDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]) {
        //Check size based configs are supported before setting them
        [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    [self.captureSession commitConfiguration];
    
    NSLog(@"captureSession outputs %@",self.captureSession.outputs);
}

-(void)resetOutputs {
    
    NSLog(@"------reset outputs--------");
    
    [self.captureSession beginConfiguration];

    //Clean-up and remove existing outputs
    AVCaptureOutput* camOutput;
    
    if ([self.movieFileOutput isRecording]) {
        NSLog(@"fallback stop movie file output!");
        [self.movieFileOutput stopRecording];
    }
    
    for (camOutput in self.captureSession.outputs) {
        NSLog(@"remove camOutput %@",camOutput.description);
        [self.captureSession removeOutput:camOutput];
    }
    
    [self.captureSession commitConfiguration];

    self.stillImageOutput = nil;
    self.movieFileOutput = nil;
    
    //Add fresh outputs
    [self addOutputs];
}

-(void)closeSession {
    
    [self.captureSession beginConfiguration];
    
    //Clean-up and remove existing outputs
    AVCaptureOutput* camOutput;
    
    if ([self.movieFileOutput isRecording]) {
        NSLog(@"fallback stop movie file output!");
        [self.movieFileOutput stopRecording];
    }
    
    AVCaptureInput* currentCameraInput;
    
    for (currentCameraInput in _captureSession.inputs) {
        NSLog(@"remove input %@",currentCameraInput);
        [_captureSession removeInput:currentCameraInput];
    }
    
    for (camOutput in self.captureSession.outputs) {
        NSLog(@"remove camOutput %@",camOutput.description);
        [self.captureSession removeOutput:camOutput];
    }
    
    [self.captureSession commitConfiguration];
    
    self.stillImageOutput = nil;
    self.movieFileOutput = nil;
    
    [self.captureSession stopRunning];
    
    
}

//********** START STOP RECORDING BUTTON **********
- (void)beginSavingVideoCapture {
    
    //----- START RECORDING -----
    BOOL fileExists = NO;
    
    //Create temporary URL to record to
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:outputPath]) {
        NSLog(@"file exists at path?");
        fileExists = YES;
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
    } else {
        NSLog(@"path is ready for file");
    }
    
    //Start recording
    if (!fileExists) {

        if (![self.movieFileOutput isRecording]) {
            NSLog(@"START RECORDING - no file exists and we're not yet recording");
            [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
            NSLog(@"movieFileOutPut description: %@",self.movieFileOutput.description);
            NSLog(@"movieFileOutPut debugDescription: %@",self.movieFileOutput.debugDescription);
            NSLog(@"movieFileOutPut outputFileURL: %@",self.movieFileOutput.outputFileURL);
            NSLog(@"movieFileOutPut initial recordedDuration = %f", CMTimeGetSeconds(self.movieFileOutput.recordedDuration));
            NSLog(@"movieFileOutPut initial recordedFileSize: %lld",self.movieFileOutput.recordedFileSize);
        }
        else {
            NSLog(@"already recording!  uh oh!");
        }
    }
    else {
        NSLog(@"TRY AGAIN, now that file is gone");
        [self beginSavingVideoCapture];
    }
}

-(void)endVideoCapture {
    //----- STOP RECORDING -----
       NSLog(@"are we recording?");

    if ([self.movieFileOutput isRecording]) {
        NSLog(@"STOP RECORDING");
        [self.movieFileOutput stopRecording];
    }

}


-(void)captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
     fromConnections:(NSArray *)connections {
    NSLog(@"didStartRecordingToOutputFileAtURL - enter %@",fileURL);
    
}

//********** DID FINISH RECORDING TO OUTPUT FILE AT URL **********
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    
    NSLog(@"didFinishRecordingToOutputFileAtURL - enter");
    
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        NSLog(@"error %@",error.description);
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    if (recordedSuccessfully) {

        //----- RECORDED SUCESSFULLY -----
        NSLog(@"didFinishRecordingToOutputFileAtURL - success");
        
        NSLog(@"movieFileOutPut outputFileURL: %@",self.movieFileOutput.outputFileURL);
        NSLog(@"movieFileOutPut recordedDuration = %f", CMTimeGetSeconds(self.movieFileOutput.recordedDuration));
        NSLog(@"movieFileOutPut recordedFileSize: %lld",self.movieFileOutput.recordedFileSize);
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                        completionBlock:^(NSURL *assetURL, NSError *error) {
                                            if (!error) {
                                                NSLog(@"video complete at url %@",outputFileURL);
                                                [self.delegate addVideoWithURL:outputFileURL];
                                            }
                                            else {
                                                NSLog(@"error %@",error.description);
                                            }
                                        }];
        }
    }
}


-(void)onVideoError:(NSNotification *)object {
    NSLog(@"AVCaptureSessionRuntimeErrorNotification %@",object.description);
}

-(void)onVideoInterrupted:(NSNotification *)object {
    NSLog(@"AVCaptureSessionWasInterruptedNotification %@",object.description);
}
-(void)onVideoEnded:(NSNotification *)object {
    NSLog(@"AVCaptureSessionInterruptionEndedNotification %@",object.description);
}

-(void)onVideoStart:(NSNotification *)object {
    NSLog(@"AVCaptureSessionDidStartRunningNotification %@",object.description);
}

-(void)onVideoDidStopRunning:(NSNotification *)object {
    NSLog(@"AVCaptureSessionDidStopRunningNotification %@",object.description);
}


@end
