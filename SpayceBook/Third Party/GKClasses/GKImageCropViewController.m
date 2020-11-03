//
//  GKImageCropViewController.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImageCropViewController.h"
#import "GKImageCropView.h"

@interface GKImageCropViewController ()

@property (nonatomic, strong) GKImageCropView *imageCropView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *useButton;

- (void)_actionCancel;
- (void)_actionUse;
- (void)_setupNavigationBar;
- (void)_setupCropView;

@end

@implementation GKImageCropViewController

#pragma mark -
#pragma mark Getter/Setter

@synthesize sourceImage, cropSize, delegate;
@synthesize imageCropView;
@synthesize toolbar;
@synthesize cancelButton, useButton, resizeableCropArea,showCircleMask;

#pragma mark -
#pragma Private Methods


- (void)_actionCancel{
    [self.navigationController popViewControllerAnimated:YES];
    [self.delegate quickCancel];
}


- (void)_actionUse{
    _croppedImage = [self.imageCropView croppedImage];
    [self.delegate imageCropController:self didFinishWithCroppedImage:_croppedImage];
}


- (void)_setupNavigationBar{
    
    NSLog(@"GKIImageCropViewController");

    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                          target:self 
                                                                                          action:@selector(_actionCancel)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
                                                                              style:UIBarButtonItemStyleBordered 
                                                                             target:self 
                                                                             action:@selector(_actionUse)];
}


- (void)_setupCropView{
    
    NSLog(@"set up crop view");
    if (self.showCircleMask){
    NSLog(@"circle mask on in cropViewContoller");
    }
    self.imageCropView = [[GKImageCropView alloc] initWithFrame:self.view.bounds];
    [self.imageCropView setImageToCrop:sourceImage];
    [self.imageCropView setResizableCropArea:self.resizeableCropArea];
    self.imageCropView.showCircleMask = self.showCircleMask;
    self.imageCropView.venueCrop = self.venueCrop;
    [self.imageCropView setCropSize:cropSize];
    self.imageCropView.center = CGPointMake(self.imageCropView.center.x, self.imageCropView.center.y);
    [self.view addSubview:self.imageCropView];
}

- (void)_setupCancelButton{
    NSDictionary *buttonAttributes = @{ NSFontAttributeName : [UIFont spc_regularSystemFontOfSize: 14],
                                        NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 10, 58, 30)];
    cancelButton.backgroundColor = [UIColor clearColor];
    NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Back" attributes:buttonAttributes];
    [cancelButton setAttributedTitle:backString forState:UIControlStateNormal];
    CGSize sizeOfBackButton = [cancelButton.titleLabel.text sizeWithAttributes:buttonAttributes];
    [cancelButton addTarget:self action:@selector(_actionCancel) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton = cancelButton;
    
    [self.view addSubview:self.cancelButton];
}

- (void)_setupUseButton{
    NSDictionary *buttonAttributes = @{ NSFontAttributeName : [UIFont spc_regularSystemFontOfSize: 14],
                                        NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
    
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - 58, 10, 58, 30)];
    saveButton.backgroundColor = [UIColor clearColor];
    NSAttributedString *saveString = [[NSAttributedString alloc] initWithString:@"Save" attributes:buttonAttributes];
    [saveButton setAttributedTitle:saveString forState:UIControlStateNormal];
    CGSize sizeOfSaveButton = [saveButton.titleLabel.text sizeWithAttributes:buttonAttributes];
    [saveButton addTarget:self action:@selector(_actionUse) forControlEvents:UIControlEventTouchUpInside];
    self.useButton = saveButton;
    
    [self.view addSubview:self.useButton];
}

- (UIImage *)_toolbarBackgroundImage{
    CGFloat components[] = {
        1., 1., 1., 1.,
        123./255., 125/255., 132./255., 1.
    };
	
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(320, 54), YES, 0.0);
	
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, NULL, 2);
	
    CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0, 0), CGPointMake(0, 54), kCGImageAlphaNoneSkipFirst);
	
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
	
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
	
    return viewImage;
}

#pragma mark -
#pragma Super Class Methods

- (id)init{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"", @"");

    
    [self _setupNavigationBar];
    [self _setupCropView];
    [self _setupCancelButton];
    [self _setupUseButton];
    
//    Hidden status and nav bar
//    if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarStyle:)]){
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//    }
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
//    } else {
//        [self.navigationController setNavigationBarHidden:NO];
//    }
    
    [self.navigationController setNavigationBarHidden:YES];
  
    // Edit from: https://github.com/gekitz/GKImagePicker/issues/29
    self.view.clipsToBounds = YES;
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    self.imageCropView.frame = self.view.bounds;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
