//
//  SPCAccountSettingsViewController.m
//  Spayce
//
//  Created by William Santiago on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAccountSettingsViewController.h"

// Model
#import "Asset.h"
#import "ProfileDetail.h"
#import "User.h"
#import "UserProfile.h"

// View
#import "SPCAccountImageCell.h"
#import "SPCAccountTextFieldCell.h"
#import "SPCAccountRegularCell.h"
#import "SPCInitialsImageView.h"
#import "SPCAlert.h"
#import "SPCAlertAction.h"
#import "SPCAlertTransitionAnimator.h"
#import "SPCEarthquakeLoader.h"

// Controller
#import "ChangePasswordViewController.h"
#import "SPCAlertViewController.h"
#import "GKImagePicker.h"

// Category
#import "NSString+SPCAdditions.h"
#import "UIColor+SPCAdditions.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"

// Utils
#import "APIUtils.h"
#import "ImageUtils.h"

// Enums
#import "Enums.h"

static NSString *imageCellIdentifier = @"imageCellIdentifier";
static NSString *textFieldCellIdentifier = @"textFieldCellIdentifier";
static NSString *regularCellIdentifier = @"regularCellIdentifier";

@interface SPCAccountSettingsViewController () <UITextFieldDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) NSString *fullnameOriginal;
@property (nonatomic, strong) NSString *fullnameModified;

@property (nonatomic, strong) GKImagePicker *imagePicker;
@property (nonatomic, weak) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UIImage *modifiedProfilePicture;

@property (nonatomic, strong) SPCEarthquakeLoader *saveLoader;

@end

@implementation SPCAccountSettingsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureNavigationBar];
    [self configureTableView];
    
    self.fullnameOriginal = [NSString stringWithFormat:@"%@ %@", self.profile.profileDetail.firstname, self.profile.profileDetail.lastname];
    self.fullnameModified = [self.fullnameOriginal copy];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 5;
        case 1:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView imageCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCAccountImageCell *cell = [tableView dequeueReusableCellWithIdentifier:imageCellIdentifier forIndexPath:indexPath];
    [cell.customImageView configureWithText:self.profile.profileDetail.firstname.firstLetter.capitalizedString
                                        url:[NSURL URLWithString:[APIUtils imageUrlStringForUrlString:self.profile.profileDetail.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailLarge]]];
    self.customImageView = cell.customImageView;
    cell.customTextLabel.text = NSLocalizedString(@"Change profile picture", nil);
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView textFieldCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCAccountTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:textFieldCellIdentifier forIndexPath:indexPath];
    cell.customTextField.text = self.fullnameModified;
    cell.customTextField.delegate = self;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView regularCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCAccountRegularCell *cell = [tableView dequeueReusableCellWithIdentifier:regularCellIdentifier forIndexPath:indexPath];
    
    SPCGroupedStyle style = SPCGroupedStyleSingle;
    NSString *text;
    UIColor *textColor;
    UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.row) {
        case 2: {
            style = SPCGroupedStyleMiddle;
            text = [NSString stringWithFormat:@"@%@", self.profile.profileDetail.handle];
            textColor = [UIColor colorWithRed:139.0/255.0 green:153.0/255.0 blue:175.0/255.0 alpha:1.0];
            break;
        }
        case 3: {
            style = SPCGroupedStyleMiddle;
            text = [AuthenticationManager sharedInstance].currentUser.username;
            textColor = [UIColor colorWithRed:139.0/255.0 green:153.0/255.0 blue:175.0/255.0 alpha:1.0];
            break;
        }
        case 4: {
            style = SPCGroupedStyleBottom;
            text = NSLocalizedString(@"Edit password", nil);
            accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        default:
            break;
    }
    
    [cell configureWithStyle:style text:text textColor:textColor accessoryType:accessoryType];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            return [self tableView:tableView imageCellForRowAtIndexPath:indexPath];
        case 1:
            return [self tableView:tableView textFieldCellForRowAtIndexPath:indexPath];
        default:
            return [self tableView:tableView regularCellForRowAtIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            return 100;
        default:
            return 55;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [self showEditProfilePicture];
    }
    if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
        [self showEditPassword];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.fullnameModified = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    [self updateSaveButton];
    
    return YES;
}

#pragma mark - Configuration

- (void)configureNavigationBar {    
    // Left '<--' button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"button-back-light-small"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
    
    // Right 'Save' button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0x6ab1fb] } forState:UIControlStateNormal];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14], NSForegroundColorAttributeName: [UIColor lightGrayColor] } forState:UIControlStateDisabled];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // Title
    self.navigationItem.title = NSLocalizedString(@"ACCOUNT SETTINGS", nil);
}

- (void)configureTableView {
    // Register cells for reuse
    [self.tableView registerClass:[SPCAccountImageCell class] forCellReuseIdentifier:imageCellIdentifier];
    [self.tableView registerClass:[SPCAccountTextFieldCell class] forCellReuseIdentifier:textFieldCellIdentifier];
    [self.tableView registerClass:[SPCAccountRegularCell class] forCellReuseIdentifier:regularCellIdentifier];
    
    // Update appearance
    self.tableView.backgroundColor = [UIColor colorWithWhite:243.0/255.0 alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)updateSaveButton {
    self.navigationItem.rightBarButtonItem.enabled = self.fullnameModified.length > 0 && (![self.fullnameModified isEqualToString:self.fullnameOriginal] || nil != self.modifiedProfilePicture);
}

#pragma mark - Actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showEditPassword {
    ChangePasswordViewController *changePasswordViewController = [[ChangePasswordViewController alloc] init];
    [self.navigationController pushViewController:changePasswordViewController animated:YES];
}

- (void)save {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // TODO: We have to update both [AuthenticationManager sharedManager].user.firstname & lastname
    // and self.profile.profileDetail.firstname & lastname
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.view addSubview:self.saveLoader];
    [self.saveLoader startAnimating];
    
    // Now, update the name, if necessary
    if (![self.fullnameOriginal isEqualToString:self.fullnameModified]) {
        // At this point, the name must be greater than 0 characters in length
        NSArray *separatedNames = [self.fullnameModified componentsSeparatedByString:@" "];
        NSString *firstName = [separatedNames objectAtIndex:0];
        NSMutableString *lastName = [[NSMutableString alloc] initWithString:@""]; // Default
        for (int i = 1; i < [separatedNames count]; i++) {
            [lastName appendFormat:@"%@ ", (NSString *)[separatedNames objectAtIndex:i]];
        }
        if (0 < [lastName length]) {
            [lastName deleteCharactersInRange:NSMakeRange([lastName length] - 1, 1)]; // Remove the trailing space
        }
        
        self.profile.profileDetail.firstname = firstName;
        self.profile.profileDetail.lastname = lastName;
    }
    
    [[ContactAndProfileManager sharedInstance] updateProfile:self.profile profileImage:self.modifiedProfilePicture resultCallback:^{
        [self.saveLoader stopAnimating];
        [self.saveLoader removeFromSuperview];
        
        [AuthenticationManager sharedInstance].currentUser.firstName = self.profile.profileDetail.firstname;
        [AuthenticationManager sharedInstance].currentUser.lastName = self.profile.profileDetail.lastname;
        
        [self pop];
    } faultCallback:^(NSError *fault) {
        [self.saveLoader stopAnimating];
        [self.saveLoader removeFromSuperview];
        [self updateSaveButton];
        
        [[[UIAlertView alloc] initWithTitle:@"Save Failed" message:@"Your changes were not saved. Please try again." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)showEditProfilePicture {
    SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
    subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
    subAlertViewController.transitioningDelegate = self;
    subAlertViewController.alertTitle = NSLocalizedString(@"Change profile picture", nil);
    
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Take Photo", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        self.imagePicker = [[GKImagePicker alloc] initWithType:1];
        CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension);
        self.imagePicker.delegate = (id)self;
        self.imagePicker.showCircleMask = NO;
        self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.imagePickerController.view.tag = 0;
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            self.imagePicker.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
    }]];
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Choose Existing", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        self.imagePicker = [[GKImagePicker alloc] initWithType:0];
        CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension);
        self.imagePicker.showCircleMask = NO;
        self.imagePicker.delegate = (id)self;
        self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePicker.imagePickerController.view.tag = 1;
        [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
    }]];
    
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
    
    [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
}

#pragma mark - GKImagePickerDelegate

- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image{
    // Rescale to the square dimensions that the server uses
    UIImage *rescaledImage = [ImageUtils rescaleImage:image toSize:CGSizeMake(ImageCacheSizeSquare, ImageCacheSizeSquare)];
    self.modifiedProfilePicture = rescaledImage;
    self.customImageView.image = rescaledImage;
    [self updateSaveButton];
    
    [self.imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    return animator;
}

#pragma mark - Save Loader

- (SPCEarthquakeLoader *)saveLoader {
    if (!_saveLoader) {
        _saveLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _saveLoader.msgLabel.text = @"Saving changes...";
    }
    return _saveLoader;
}

@end
