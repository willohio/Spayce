//
//  ProfileEditViewController.m
//  Spayce
//
//  Created by Howard Cantrell on 05/20/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCEditProfileViewController.h"

// Model
#import "PersonUpdate.h"
#import "UserProfile.h"
#import "ProfileDetail.h"
#import "User.h"

// View
#import "AsyncImageView.h"
#import "Buttons.h"

// Controller
#import "SPCAlertViewController.h"
#import "SPCAlertAction.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"

// Utility
#import "ImageUtils.h"

@interface SPCEditProfileViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *txtFirstName;
@property (nonatomic, strong) UITextField *txtLastName;
@property (nonatomic, strong) UITextView *txtStatusMessage;
@property (nonatomic, strong) AsyncImageView *profileImgView;

@property (nonatomic, strong) UIBarButtonItem *rightBarButton;

@property (nonatomic, strong) GKImagePicker *imagePicker;
@property (nonatomic, strong) UIImage *pendingProfilePic;

@property (nonatomic, strong) UserProfile *profile;

@end

@implementation SPCEditProfileViewController

NSString *kStatusMessagePlaceholder = @"What's up Spayce cadet?";

#pragma mark - Object lifecycle

- (id)init {
    self = [super init];
    if (self) {
        _profile = [ContactAndProfileManager sharedInstance].profile;
    }
    return self;
}


#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];

    self.view.backgroundColor = [UIColor colorWithRGBHex:0xF6F6F6];
    
    //self.navigationController.navigationBar.tintColor = nil;
    

    [self.view addSubview:self.scrollView];

    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, CGRectGetWidth(self.view.bounds)-10, 240)];
    backView.backgroundColor = [UIColor whiteColor];

    // border radius
    [backView.layer setCornerRadius:2.0f];

    // drop shadow
    [backView.layer setShadowColor:[UIColor blackColor].CGColor];
    [backView.layer setShadowOpacity:0.2];
    [backView.layer setShadowRadius:0.5];
    [backView.layer setShadowOffset:CGSizeMake(0.0, 1.0)];

    [self.scrollView addSubview:backView];
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetMaxY(backView.frame)+5);

    self.profileImgView = [[AsyncImageView alloc] initWithFrame:CGRectMake(10, 10, 75, 75)];
    self.profileImgView.backgroundColor = [UIColor whiteColor];
    self.profileImgView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImgView.layer.cornerRadius = CGRectGetHeight(self.profileImgView.frame) / 2.0f;
    self.profileImgView.clipsToBounds = YES;
    [self.profileImgView setAsset:self.profile.profileDetail.imageAsset size:ImageCacheSizeSquareMedium];
    [backView addSubview:self.profileImgView];

    UIButton *updateProfilePicBtn = [[UIButton alloc] initWithFrame:self.profileImgView.frame];
    updateProfilePicBtn.backgroundColor = [UIColor clearColor];
    [updateProfilePicBtn addTarget:self action:@selector(updateProfilePic) forControlEvents:UIControlEventTouchUpInside];
    [backView addSubview:updateProfilePicBtn];

    UIButton *changeImgBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.profileImgView.frame)+15, 30, 160, 40)];
    [changeImgBtn setTitle:@"Change Profile Image" forState:UIControlStateNormal];
    [changeImgBtn setTitleColor:[UIColor colorWithRGBHex:0xB4BDC4] forState:UIControlStateNormal];
    changeImgBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    [changeImgBtn.layer setCornerRadius:2.0f];
    [changeImgBtn.layer setBorderColor:[UIColor colorWithRGBHex:0xEBEEF0].CGColor];
    [changeImgBtn.layer setBorderWidth:1.0f];
    [changeImgBtn addTarget:self action:@selector(updateProfilePic) forControlEvents:UIControlEventTouchUpInside];
    [backView addSubview:changeImgBtn];

    self.txtFirstName = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.profileImgView.frame)+10, (CGRectGetWidth(backView.frame)/2.0f)-10, 40.0f)];
    self.txtFirstName.delegate = self;
    self.txtFirstName.borderStyle = UITextBorderStyleNone;
    self.txtFirstName.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.txtFirstName.textAlignment = NSTextAlignmentLeft;
    self.txtFirstName.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.txtFirstName.placeholder = @"First name";
    self.txtFirstName.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    self.txtFirstName.textColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    self.txtFirstName.returnKeyType = UIReturnKeyNext;
    self.txtFirstName.text = self.profile.profileDetail.firstname;
    [backView addSubview:self.txtFirstName];

    self.txtLastName = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.txtFirstName.frame)+5, CGRectGetMinY(self.txtFirstName.frame), (CGRectGetWidth(backView.frame)/2.0f)-15, 40.0f)];
    self.txtLastName.delegate = self;
    self.txtLastName.borderStyle = UITextBorderStyleNone;
    self.txtLastName.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.txtLastName.textAlignment = NSTextAlignmentLeft;
    self.txtLastName.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.txtLastName.placeholder = @"Last name";
    self.txtLastName.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    self.txtLastName.textColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    self.txtLastName.returnKeyType = UIReturnKeyNext;
    self.txtLastName.text = self.profile.profileDetail.lastname;
    [backView addSubview:self.txtLastName];

    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.txtFirstName.frame)+5, CGRectGetWidth(backView.frame), 1.0f)];
    separatorView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:232.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
    [backView addSubview:separatorView];

    self.txtStatusMessage = [[UITextView alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(separatorView.frame)+10, CGRectGetWidth(backView.frame)-10, 70.0f)];
    self.txtStatusMessage.delegate = self;
    self.txtStatusMessage.textAlignment = NSTextAlignmentLeft;
    self.txtStatusMessage.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.txtStatusMessage.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    self.txtStatusMessage.textColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    self.txtStatusMessage.returnKeyType = UIReturnKeyDefault;
    self.txtStatusMessage.text = self.profile.profileDetail.statusMessage;
    if ([self.txtStatusMessage.text isEqualToString:@""]) {
        self.txtStatusMessage.text = kStatusMessagePlaceholder;
        self.txtStatusMessage.textColor = [UIColor lightGrayColor];
    }
    [backView addSubview:self.txtStatusMessage];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.txtFirstName becomeFirstResponder];
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
        _scrollView.backgroundColor = [UIColor clearColor];
    }

    return _scrollView;
}

- (void)updateProfile {
    [[ContactAndProfileManager sharedInstance] updateProfile:self.profileToBeUpdated
                                                profileImage:self.pendingProfilePic
                                              resultCallback:^{
                                                  UserProfile *profile = self.profileToBeUpdated;
                                                  
                                                  [ContactAndProfileManager sharedInstance].profile = profile;
                                                  
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:ContactAndProfileManagerUserProfileDidUpdateNotification object:nil];
                                                  
                                                  if (self.pendingProfilePic) {
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:ContactAndProfileManagerUserProfilePhotoDidUpdateNotification object:nil];
                                                  }
                                                  
                                                  PersonUpdate *update = [[PersonUpdate alloc] initWithRecordID:[ContactAndProfileManager sharedInstance].profile.profileUserId
                                                                                                      userToken:[AuthenticationManager sharedInstance].currentUser.userToken
                                                                                                     imageAsset:profile.profileDetail.imageAsset
                                                                                                      firstName:profile.profileDetail.firstname
                                                                                                       lastName:profile.profileDetail.lastname];
                                                  [update postAsNotification];
                                                  
                                                  [self doCancel:nil];
                                              } faultCallback:nil];
}

- (UserProfile *)profileToBeUpdated {
    UserProfile *profile = (UserProfile *)self.profile;

    profile.profileDetail.firstname = self.txtFirstName.text;
    profile.profileDetail.lastname = self.txtLastName.text;
    profile.profileDetail.statusMessage = self.txtStatusMessage.text;

    return profile;
}

- (void)doCancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - Navigation Bar Configuration

- (void)configureNavigationBar {
    // Background and tint color
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    
    // Cancel button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(doCancel:)];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0x6ab1fb] } forState:UIControlStateNormal];
    
    // Right 'Save' button
    self.rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(updateProfile)];
    self.navigationItem.rightBarButtonItem = self.rightBarButton;
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0x6ab1fb] } forState:UIControlStateNormal];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0x6ab1fb alpha:0.5f] } forState:UIControlStateDisabled];
    self.rightBarButton.enabled = NO;
    
    // Title
    self.navigationItem.title = NSLocalizedString(@"PROFILE", nil);
    self.navigationController.navigationBar.titleTextAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                                     NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x3f5578],
                                                                     NSKernAttributeName : @(1.1f) };
    
    // Removing the shadow image. To do this, we must also set the background image
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,[[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:img forBarMetrics:UIBarMetricsDefault];
    
    // Adding the bottom separator
    CGFloat separatorSize = 1.0f / [UIScreen mainScreen].scale;
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.navigationController.navigationBar.frame) - separatorSize, CGRectGetWidth(self.navigationController.navigationBar.frame), separatorSize)];
    [separator setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f]];
    [self.navigationController.navigationBar addSubview:separator];
}

#pragma mark - Photo update methods

- (void)updateProfilePic {
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.alertTitle = @"Change Profile Image";
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Take Photo", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        [self takePhoto];
    }]];
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Choose Existing", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        [self chooseExistingImage];
    }]];
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertViewController animated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)takePhoto {
    self.imagePicker = [[GKImagePicker alloc] initWithType:1];
    CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension);
    self.imagePicker.delegate = (id)self;
    self.imagePicker.showCircleMask = YES;
    self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        self.imagePicker.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
}

- (void)chooseExistingImage {
    self.imagePicker = [[GKImagePicker alloc] initWithType:0];
    CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension);
    self.imagePicker.showCircleMask = YES;
    self.imagePicker.delegate = (id)self;
    self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
}

#pragma mark - GKImagePickerDelegate

- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image{
    self.pendingProfilePic = [ImageUtils rescaleImageToScreenBounds:image];
    self.profileImgView.image = self.pendingProfilePic;
    [self hideImagePicker];
    
    //Image changed, enable save button
    [(UIButton *)[[self rightBarButton] customView] setBackgroundColor:[UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f]];
    self.rightBarButton.enabled = YES;
}

- (void)hideImagePicker {
    [self.imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    

    if (textField == self.txtFirstName) {
        [self setSaveButtonWithFirstName:newString lastName:self.txtLastName.text statusMessage:self.txtStatusMessage.text];
        return newString.length <= 40;
    }
    else if (textField == self.txtLastName) {
        [self setSaveButtonWithFirstName:self.txtFirstName.text lastName:newString statusMessage:self.txtStatusMessage.text];
        return newString.length <= 40;
    }

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.txtFirstName) {
        [self.txtFirstName resignFirstResponder];
        [self.txtLastName becomeFirstResponder];
    }
    else if (textField == self.txtLastName) {
        [self.txtLastName resignFirstResponder];
        [self.txtStatusMessage becomeFirstResponder];
    }

    return YES;
}


#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];

    if (textView == self.txtStatusMessage) {
        [self setSaveButtonWithFirstName:self.txtFirstName.text lastName:self.txtLastName.text statusMessage:newString];
        return newString.length <= 100;
    }

    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:kStatusMessagePlaceholder]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    }

    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        textView.text = kStatusMessagePlaceholder;
        textView.textColor = [UIColor lightGrayColor];
    }

    [textView resignFirstResponder];
}

#pragma mark - Private

-(void)setSaveButtonWithFirstName:(NSString *)first lastName:(NSString *)last statusMessage:(NSString *)message{
    if([first isEqualToString:self.profile.profileDetail.firstname] &&
       [last isEqualToString:self.profile.profileDetail.lastname] &&
       [message isEqualToString:self.profile.profileDetail.statusMessage])
    {
        [(UIButton *)[[self rightBarButton] customView] setBackgroundColor:[UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:0.5f]];
        self.rightBarButton.enabled = NO;
    }
    else{
        [(UIButton *)[[self rightBarButton] customView] setBackgroundColor:[UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f]];
        self.rightBarButton.enabled = YES;
    }


}

@end
