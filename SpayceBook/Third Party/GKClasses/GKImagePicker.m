//
//  GKImagePicker.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImagePicker.h"
#import "GKImageCropViewController.h"
#import "LEImagePickerController.h"

@interface GKImagePicker ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, GKImageCropControllerDelegate> {
    
    BOOL quickCancelEnabled;
    BOOL fromCam;
    
}
@property (nonatomic, strong, readwrite) LEImagePickerController *imagePickerController;
- (void)_hideController;
@end

@implementation GKImagePicker

#pragma mark -
#pragma mark Getter/Setter

@synthesize cropSize, delegate, resizeableCropArea;
@synthesize imagePickerController = _imagePickerController;


#pragma mark -
#pragma mark Init Methods

-(void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (id)initWithType:(int)_sourceType {
    if (self = [super init]) {
        
        self.cropSize = CGSizeMake(320, 320);
        self.resizeableCropArea = NO;
        
        if (_sourceType==0){
            _imagePickerController = [[UIImagePickerController alloc] init];
            _imagePickerController.delegate = self;
            _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            fromCam = NO;
        }
        if (_sourceType==1){
            _imagePickerController = [[LEImagePickerController alloc] init];
            _imagePickerController.delegate = self;
            _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            fromCam = YES;
        }
        if (_sourceType == 2) {
            _imagePickerController = [[UIImagePickerController alloc] init];
            _imagePickerController.delegate = self;
            _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            _imagePickerController.view.hidden = YES;
            fromCam = NO;
            [self performSelector:@selector(editPreselectedImage) withObject:nil afterDelay:.1];
        }
        
        [self customizeNavigationController:_imagePickerController];
    }
    return self;
}

# pragma mark -
# pragma mark Private Methods

- (void)_hideController{
    
    if (![_imagePickerController.presentedViewController isKindOfClass:[UIPopoverController class]]){
        
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
        
    } 
    
}

- (void)editPreselectedImage {
    quickCancelEnabled = YES;
    _imagePickerController.view.hidden = NO;
    GKImageCropViewController *cropController = [[GKImageCropViewController alloc] init];
    cropController.contentSizeForViewInPopover = _imagePickerController.contentSizeForViewInPopover;
    cropController.sourceImage = self.adjustImage;
    cropController.resizeableCropArea = self.resizeableCropArea;
    cropController.showCircleMask = self.showCircleMask;
    cropController.venueCrop = self.venueCrop;
    cropController.cropSize = self.cropSize;
    cropController.delegate = self;
    [_imagePickerController pushViewController:cropController animated:NO];
}

- (void)customizeNavigationController:(UINavigationController *)navigationController {
    // Background and tint color
    navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    
    // Title
    navigationController.navigationBar.titleTextAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                                NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x3f5578],
                                                                NSKernAttributeName : @(1.1f) };
}

#pragma mark -
#pragma mark UIImagePickerDelegate Methods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarStyle:)]){
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
    
    if ([self.delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
      
        [self.delegate imagePickerDidCancel:self];
        
    } else {
        
        [self _hideController];
    
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{

    GKImageCropViewController *cropController = [[GKImageCropViewController alloc] init];
    cropController.contentSizeForViewInPopover = picker.contentSizeForViewInPopover;
    cropController.sourceImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    cropController.resizeableCropArea = self.resizeableCropArea;
    cropController.showCircleMask = self.showCircleMask;
    cropController.venueCrop = self.venueCrop;
    cropController.cropSize = self.cropSize;
    cropController.delegate = self;
    [picker pushViewController:cropController animated:YES];
    
}

#pragma mark -
#pragma GKImagePickerDelegate

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage{
    
    if (fromCam) {
        NSLog(@"from cam, save to photo roll");
         UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil);
    }
    
    if ([self.delegate respondsToSelector:@selector(imagePicker:pickedImage:)]) {
        [self.delegate imagePicker:self pickedImage:croppedImage];   
    }
}


- (void)quickCancel {
    
    if (quickCancelEnabled) {
        NSLog(@"quick cancel");
       _imagePickerController.view.hidden = YES;
        if ([self.delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
            
            [self.delegate imagePickerDidCancel:self];
            
        } else {
            
            [self _hideController];
            
        }
    }
}


@end
