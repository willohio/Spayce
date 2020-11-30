//
//  SignUpViewController.m
//  Spayce
//
//  Created by William Santiago on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpViewController.h"

// View
#import "DAKeyboardControl.h"
#import "LargeBlockingProgressView.h"
#import "SignUpTextField.h"
#import "SignUpProfileButton.h"
#import "SignUpTextFieldCell.h"
#import "SignUpErrorCell.h"
#import "SignUpButtonCell.h"

// Category
#import "UIScreen+Size.h"
#import "UIViewController+SPCAdditions.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "SPCColorManager.h"

// Utility
#import "EmailUtils.h"

@interface SignUpViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) LargeBlockingProgressView *progressView;
@property (nonatomic, strong) UIImagePickerController *imagePickerViewController;
@property (nonatomic, weak) SignUpTextField *emailTextField;
@property (nonatomic, weak) SignUpTextField *handleTextField;
@property (nonatomic, weak) SignUpTextField *passwordTextField;
@property (nonatomic, weak) SignUpProfileButton *profileImageButton;
@property (nonatomic, weak) SignUpTextField *firstnameTextField;
@property (nonatomic, weak) SignUpTextField *lastnameTextField;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, weak) UILabel *errorLabel;

@end

@implementation SignUpViewController

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [self spc_dealloc];
}

#pragma mark - UIViewController - Managing the View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *bgImg = [UIImage imageNamed:@"background-earth"];
    UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.frame];
    bgImgView.image = bgImg;
    [self.view addSubview:bgImgView];
    
    [self setupTableView];
    [self setupNavigationBar];
    
    [self resetSignUpButton];
}

#pragma mark - UIViewController - Responding to View Events

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // This is a first part of a hack to jumpy navigation bar on iOS 7
    // http://stackoverflow.com/questions/19136899/navigation-bar-has-wrong-position-when-modal-a-view-controller-with-flip-horizon/19265558#19265558
   [self.navigationController.navigationBar.layer removeAllAnimations];
    self.navigationController.navigationBarHidden = YES;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self addPanGestureRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removePanGestureRecognizer];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 3;
    }
    else if (section == 1) {
        return 1;
    }
    else if  (section == 2) {
        return 2;
    }
    else {
        return 0;
    }
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 100;
    }
    return 1.0;
}

-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return 35;
    }
    if (section == 1) {
        return 1;
    }
    return 1.0;
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, [self tableView:self.tableView heightForHeaderInSection:section])];
}

-(UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, [self tableView:self.tableView heightForFooterInSection:section])];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
 
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            static NSString *CellIdentifier = @"SignUpEmailCellIdentifier";
            SignUpTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [SignUpTextFieldCell createCellWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier type:TextFieldCellTypeSingle];
                cell.iconImgView.image = [UIImage imageNamed:@"email"];
            }
            
            SignUpTextField *textField = cell.textFields[0];
            textField.tag = indexPath.row;
            textField.placeholder = NSLocalizedString(@"Email", nil);
            textField.delegate = self;
            textField.text = self.emailTextField.text;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark-green"]];
            textField.rightView.hidden = YES;
            textField.invalid = self.emailTextField.invalid;
            textField.returnKeyType = UIReturnKeyNext;
            self.emailTextField = textField;
            cell.backgroundColor = [UIColor whiteColor];
            cell.top = YES;
            return cell;
        }
        else if (indexPath.row == 1) {
            static NSString *CellIdentifier = @"SignUpHandleCellIdentifier";
            SignUpTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [SignUpTextFieldCell createCellWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier type:TextFieldCellTypeSingle];
                 cell.iconImgView.image = [UIImage imageNamed:@"handle"];
            }
            
            SignUpTextField *textField = cell.textFields[0];
            textField.tag = indexPath.row;
            textField.placeholder = NSLocalizedString(@"Username", nil);
            textField.delegate = self;
            textField.text = self.handleTextField.text;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark-green"]];
            textField.rightView.hidden = YES;
            textField.returnKeyType = UIReturnKeyNext;
            self.handleTextField = textField;
            cell.backgroundColor = [UIColor whiteColor];
            return cell;
        }
        else if (indexPath.row == 2) {
            static NSString *CellIdentifier = @"SignUpPasswordCellIdentifier";
            SignUpTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [SignUpTextFieldCell createCellWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier type:TextFieldCellTypeSingle];
                cell.iconImgView.image = [UIImage imageNamed:@"lock"];
            }
            
            SignUpTextField *textField = cell.textFields[0];
            textField.tag = indexPath.row;
            textField.placeholder = NSLocalizedString(@"Password", nil);
            textField.delegate = self;
            textField.text = self.passwordTextField.text;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.keyboardType = UIKeyboardTypeDefault;
            textField.secureTextEntry = YES;
            textField.returnKeyType = UIReturnKeyNext;
            self.passwordTextField = textField;
            cell.backgroundColor = [UIColor whiteColor];
            cell.down = YES;
            return cell;
        }
        else {
            return nil;
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
    
            static NSString *CellIdentifier = @"SignUpNameCellIdentifier";
            SignUpTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [SignUpTextFieldCell createCellWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier type:TextFieldCellTypeDouble];
                [cell.button addTarget:self action:@selector(presentImagePicker:) forControlEvents:UIControlEventTouchUpInside];
            }
            
            cell.button.tag = indexPath.row;
            cell.button.customPlaceholderImage = [UIImage imageNamed:@"spayceholder-profile"];
            cell.button.customBackgroundImage = self.profileImageButton.customBackgroundImage;
            
            self.profileImageButton = cell.button;
            SignUpTextField *textField = cell.textFields[0];
            textField.tag = indexPath.row;
            textField.placeholder = NSLocalizedString(@"First name", nil);
            textField.delegate = self;
            textField.text = self.firstnameTextField.text;
            textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.keyboardType = UIKeyboardTypeDefault;
            textField.returnKeyType = UIReturnKeyNext;
            self.firstnameTextField = textField;
            
            textField = cell.textFields[1];
            textField.tag = indexPath.row;
            textField.placeholder = NSLocalizedString(@"Last name", nil);
            textField.delegate = self;
            textField.text = self.lastnameTextField.text;
            textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.keyboardType = UIKeyboardTypeDefault;
            textField.returnKeyType = UIReturnKeyNext;
            self.lastnameTextField = textField;
            cell.backgroundColor = [UIColor whiteColor];
            cell.top = YES;
            cell.down = YES;
            return cell;

        }
        else {
            return nil;
        }
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            static NSString *CellIdentifier = @"SignUpErrorCellIdentifier";
            SignUpErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[SignUpErrorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            self.errorLabel = cell.errorLabel;
            cell.backgroundColor = [UIColor clearColor];
            return cell;
        }
        else if (indexPath.row == 1)  {
            static NSString *CellIdentifier = @"SignUpButtonCellIdentifier";
            SignUpButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[SignUpButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                [cell.button addTarget:self action:@selector(signUp:) forControlEvents:UIControlEventTouchUpInside];
            }
            cell.backgroundColor = [UIColor clearColor];
            
            [cell.button setTitle:NSLocalizedString(@"Sign Up", nil) forState:UIControlStateNormal];
            
            return cell;
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
    if (indexPath.section == 0) {
        return ([UIScreen isLegacyScreen] ? 40.0 : 44.0);
    }
    
    if (indexPath.section == 1) {
        return 88;
    }
    if (indexPath.section == 2) {
    
        if (indexPath.row == 0) {
            return 20.0;
        }
        else if (indexPath.row == 1) {
            return 80.0;
        }
        else {
            return 0;
        }
    }
    else {
        return ([UIScreen isLegacyScreen] ? 40.0 : 44.0);
    }
}

#pragma mark - Scroll view delegation

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    /*
    // Fades in top cell in table view as it enters / leaves the screen
    NSArray *visibleCells = [self.tableView visibleCells];
    
    if (visibleCells != nil  &&  [visibleCells count] != 0) {       // Don't do anything for empty table view
        
        // Get top and bottom cells
        UITableViewCell *topCell = [visibleCells objectAtIndex:0];
        
        // Make sure other cells stay opaque
        // Avoids issues with skipped method calls during rapid scrolling
        for (UITableViewCell *cell in visibleCells) {
            cell.alpha = 1.0;
        }
        
        // Set necessary constants
        NSInteger cellHeight = topCell.frame.size.height - 1;   // -1 To allow for typical separator line height
        NSInteger tableViewTopPosition = self.tableView.frame.origin.y;
        
        // Get content offset to set opacity
        CGRect topCellPositionInTableView = [self.tableView rectForRowAtIndexPath:[self.tableView indexPathForCell:topCell]];
        CGFloat topCellPosition = [self.tableView convertRect:topCellPositionInTableView toView:[self.tableView superview]].origin.y;
     
        
        // Set opacity based on amount of cell that is outside of view
        CGFloat modifier = 3.0;     // Increases the speed of fading (1.0 for fully transparent when the cell is entirely off the screen,
                                    // 2.0 for fully transparent when the cell is half off the screen, etc)
        CGFloat topCellOpacity = (1.0f - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier);
        
        // Set cell opacity
        if (topCell) {
            topCell.alpha = topCellOpacity;
        }
    }
     */
    
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollToView:) object:textField];
    [self performSelector:@selector(scrollToView:) withObject:textField afterDelay:0.4];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.handleTextField becomeFirstResponder];
    }
    else if (textField == self.handleTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField) {
        [self.firstnameTextField becomeFirstResponder];
    }
    else if (textField == self.firstnameTextField) {
        [self.lastnameTextField becomeFirstResponder];
    }
    else if (textField == self.lastnameTextField) {
        [self.lastnameTextField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self performSelector:@selector(textDidChange) withObject:nil afterDelay:.1];
    
    if (textField == self.firstnameTextField) {
        if (resultString.length > 0) {
            [self discardTextFieldError:textField];
        }
        return resultString.length <= 13;
    } else if (textField == self.lastnameTextField) {
        if (resultString.length > 0) {
            [self discardTextFieldError:textField];
        }
        
        return resultString.length <= 13;
    } else if (textField == self.emailTextField) {
        if (resultString.length > 0) {
            [self discardTextFieldError:textField];
        }
        
        BOOL shouldChange = resultString.length <= 100;
        if (shouldChange) {
            // Perform after the string is changed
            [self performSelector:@selector(emailTextFieldChanged) withObject:nil afterDelay:0.05f];
        }
        
        return shouldChange;
    } else if (textField == self.handleTextField) {
        if (resultString.length > 0) {
            [self discardTextFieldError:textField];
        }
        
        BOOL shouldChange = resultString.length <= 16;
        if (shouldChange) {
            // Perform after the string is changed
            [self performSelector:@selector(handleTextFieldChanged) withObject:nil afterDelay:0.05f];
        }
        
        return shouldChange;
    } else if (textField == self.passwordTextField) {
        if (resultString.length > 0) {
            [self discardTextFieldError:textField];
        }
        
        return resultString.length <= 13;
    }
    
    return YES;
}

- (void)emailTextFieldChanged {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkEmailAvailability) object:nil];
    self.emailTextField.rightView.hidden = YES;
    self.emailTextField.invalid = NO;
    
    // If this is a valid email, perform the query in one second, i.e. after the user has stopped typing
    if ([EmailUtils isEmailValid:self.emailTextField.text]) {
        [self performSelector:@selector(checkEmailAvailability) withObject:nil afterDelay:1.0f];
    }
}

- (void)handleTextFieldChanged {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkHandleAvailability) object:nil];
    self.handleTextField.rightView.hidden = YES;
    self.handleTextField.invalid = NO;
    
    // If this is a valid handle, perform the query in one second, i.e. after the user has stopped typing
    if (2 <= self.handleTextField.text.length) { // Must match the value in '[self precheckInputValues]'
        [self performSelector:@selector(checkHandleAvailability) withObject:nil afterDelay:1.0f];
    }
}

- (void)checkEmailAvailability {
    __weak typeof(self)weakSelf = self;
    [[AuthenticationManager sharedInstance] isEmailAddressAvailable:self.emailTextField.text completionHandler:^(BOOL result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf.emailTextField.rightView.hidden = !result;
            strongSelf.emailTextField.invalid = !result;
        });
    } errorHandler:^(NSError *error) {
        NSLog( @"SignUpVC.isEmailAddressAvailable returned error: %@", [error description] );
    }];
}

- (void)checkHandleAvailability {
    __weak typeof(self)weakSelf = self;
    [[AuthenticationManager sharedInstance] isHandleAvailable:self.handleTextField.text completionHandler:^(BOOL result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf.handleTextField.rightView.hidden = !result;
            strongSelf.handleTextField.invalid = !result;
        });
    } errorHandler:^(NSError *error) {
        NSLog( @"SignUpVC.isHandleAvailable returned error: %@", [error description] );
    }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            self.profileImageButton.customBackgroundImage = nil;
            
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        } else if (buttonIndex == actionSheet.destructiveButtonIndex+1) {
            self.imagePickerViewController = [[UIImagePickerController alloc] init];
            self.imagePickerViewController.delegate = (id)self;
            self.imagePickerViewController.sourceType = UIImagePickerControllerSourceTypeCamera;
            self.imagePickerViewController.allowsEditing = YES;
            
            if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
                self.imagePickerViewController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
            
            [self presentViewController:self.imagePickerViewController animated:YES completion:nil];
        } else if (buttonIndex == actionSheet.destructiveButtonIndex+2) {
            self.imagePickerViewController = [[UIImagePickerController alloc] init];
            self.imagePickerViewController.delegate = (id)self;
            self.imagePickerViewController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.imagePickerViewController.allowsEditing = YES;
            
            [self presentViewController:self.imagePickerViewController animated:YES completion:nil];
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // Store the image
    self.profileImageButton.customBackgroundImage = info[UIImagePickerControllerEditedImage];
    
    // Reload cell
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    
    if ([self precheckInputValues]) {
        [self updateSignUpButtonForSubmission];
    }
    else {
        [self resetSignUpButton];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Accessors

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(15, 0, self.view.bounds.size.width-30, self.view.bounds.size.height)
                                                  style:UITableViewStyleGrouped];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.clipsToBounds = NO;
    }
    return _tableView;
}

- (LargeBlockingProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[LargeBlockingProgressView alloc] initWithFrame:self.navigationController.view.bounds];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _progressView.label.text = @"Registering..";
        _progressView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    }
    return _progressView;
}

-(UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn =  [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.frame = CGRectMake(15, 29, 65, 30);
        _cancelBtn.layer.cornerRadius = 2;
        [_cancelBtn setBackgroundColor:[UIColor clearColor]];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
        [_cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cancel:)forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

#pragma mark - View setup

- (void)setupNavigationBar {
    
    UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
    baseView.backgroundColor = [UIColor colorWithRed:0 green:36.0f/255.0f blue:88.0f/255.0f alpha:1.0];
    baseView.userInteractionEnabled = NO;
    [self.view addSubview:baseView];
    
    UIView *gradView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 80)];
    gradView.backgroundColor = [UIColor clearColor];
    gradView.userInteractionEnabled = NO;
    [self.view addSubview:gradView];
    
    CAGradientLayer *l = [CAGradientLayer layer];
    l.frame = gradView.bounds;
    l.name = @"Gradient";
    
    l.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:1.0f/255.0f green:68.0f/255.0f blue:146.0f/255.0f alpha:0] CGColor], (id)[[UIColor colorWithRed:0 green:36.0f/255.0f blue:88.0f/255.0f alpha:1.0] CGColor], nil];
    l.startPoint = CGPointMake(0.5, 1.0f);
    l.endPoint = CGPointMake(0.5f, 0.0f);
    [gradView.layer addSublayer:l];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = NSLocalizedString(@"Sign Up", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:17];
    titleLabel.frame = CGRectMake(CGRectGetMidX(self.view.frame) - 75.0, 25, 150.0, 35);
    titleLabel.textColor = [UIColor whiteColor];
    
    [self.view addSubview:titleLabel];
    [self.view addSubview:self.cancelBtn];
    
   
}

- (void)setupTableView {
    // Set table's dataSource & delegate
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // Reload table
    [self.tableView reloadData];
    
    // Add table to view hierarchy
    if (!self.tableView.superview) {
        [self.view addSubview:self.tableView];
    }
}

#pragma mark - Gesture recognizers

- (void)addPanGestureRecognizer {
    __weak UITableView *weakTableView = self.tableView;
    
    [self.view setKeyboardTriggerOffset:44.0];
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        CGRect frame = weakTableView.frame;
        frame.size.height = keyboardFrameInView.origin.y;
        weakTableView.frame = frame;
    }];
}

- (void)removePanGestureRecognizer {
    [self.view removeKeyboardControl];
}

- (BOOL)validateInputValues {
    
    //validate email
    NSString *email = [self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (email.length == 0) {
        SignUpTextField *textField = (SignUpTextField *)self.emailTextField;
        textField.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"Email is required", nil);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:textField selector:@selector(becomeFirstResponder) object:nil];
        [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }
    if (![EmailUtils isEmailValid:email]) {
        SignUpTextField *textField = (SignUpTextField *)self.emailTextField;
        textField.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"Invalid email", nil);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:textField selector:@selector(becomeFirstResponder) object:nil];
        [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }

    //validate handle
    NSString *handle = [self.handleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (handle.length == 0) {
        SignUpTextField *textField = (SignUpTextField *)self.handleTextField;
        textField.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"Username is required", nil);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:textField selector:@selector(becomeFirstResponder) object:nil];
        [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }
    if (handle.length < 2) {
        SignUpTextField *textField = (SignUpTextField *)self.handleTextField;
        textField.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"Usernames must be at least 2 characters", nil);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:textField selector:@selector(becomeFirstResponder) object:nil];
        [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }

    //validate pass
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (password.length == 0) {
        SignUpTextField *textField = (SignUpTextField *)self.passwordTextField;
        textField.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"Password is required", nil);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:textField selector:@selector(becomeFirstResponder) object:nil];
        [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }
    if (password.length < 6) {
        SignUpTextField *textField = (SignUpTextField *)self.passwordTextField;
        textField.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"Passwords must be at least 6 characters", nil);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:textField selector:@selector(becomeFirstResponder) object:nil];
        [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }
    
    //validate image
    //Profile pic not required
    /*
    UIImage *profileImage = self.profileImageButton.customBackgroundImage;
    if (!profileImage) {
        SignUpProfileButton *button = (SignUpProfileButton *)self.profileImageButton;
        button.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"Profile image is required", nil);
        
        [self.view hideKeyboard];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:button selector:@selector(becomeFirstResponder) object:nil];
        [button performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }*/
    
    //validate fname
    NSString *firstname = [self.firstnameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (firstname.length == 0) {
        SignUpTextField *textField = (SignUpTextField *)self.firstnameTextField;
        textField.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"First name is required", nil);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:1];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:textField selector:@selector(becomeFirstResponder) object:nil];
        [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }

    //validate lname
    NSString *lastname = [self.lastnameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (lastname.length == 0) {
        SignUpTextField *textField = (SignUpTextField *)self.lastnameTextField;
        textField.invalid = YES;
        
        UILabel *label = self.errorLabel;
        label.text = NSLocalizedString(@"Last name is required", nil);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:1];
        [self scrollToRowAtIndexPath:indexPath];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:textField selector:@selector(becomeFirstResponder) object:nil];
        [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4];
        
        return NO;
    }
    
    return YES;
}

- (void)textDidChange {
    
    if ([self precheckInputValues]) {
        [self updateSignUpButtonForSubmission];
    }
    else {
        [self resetSignUpButton];
    }
}

- (BOOL)precheckInputValues {
    
    //precheck email
    NSString *email = [self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (email.length == 0) {
        return NO;
    }
    if (![EmailUtils isEmailValid:email]) {
         return NO;
    }
    
    //precheck handle
    NSString *handle = [self.handleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (handle.length == 0) {
       return NO;
    }
    if (handle.length < 2) { // Must match the value in '[self precheckInputValues]'
         return NO;
    }
    
    //precheck pass
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (password.length == 0) {
         return NO;
    }
    if (password.length < 6) {
       return NO;
    }
    
    //precheck image
    //Profile image not mandatory
    /*UIImage *profileImage = self.profileImageButton.customBackgroundImage;
    if (!profileImage) {
        return NO;
    }*/
    
    //precheck fname
    NSString *firstname = [self.firstnameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (firstname.length == 0) {
        return NO;
    }
    
    //precheck lname
    NSString *lastname = [self.lastnameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return lastname.length != 0;
}



- (void)clearInputValues {
    self.passwordTextField.text = nil;
    self.errorLabel.text = nil;
    
    [self.tableView reloadData];
}

#pragma mark - Private

- (UITableViewCell *)cellForView:(UIView *)view {
    return (UITableViewCell *)view.superview.superview.superview;
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        float aniOffset = 30 + (40 * (int)indexPath.row);
        [self.tableView setContentOffset:CGPointMake(0, aniOffset) animated:YES];
    }
    if (indexPath.section == 1) {
        float aniOffset = 145 + (40 * (int)indexPath.row);
        [self.tableView setContentOffset:CGPointMake(0, aniOffset) animated:YES];
    }
}

- (void)scrollToView:(UIView *)view {
    UITableView *tableView = self.tableView;
    UITableViewCell *cell = [self cellForView:view];
    NSIndexPath *indexPath = [tableView indexPathForCell:cell];
    [self scrollToRowAtIndexPath:indexPath];
}

- (void)discardProfileButtonError:(UIButton *)button {
    SignUpProfileButton *aButton = (SignUpProfileButton *)button;
    aButton.invalid = NO;
    
    UILabel *label = self.errorLabel;
    label.text = nil;
}

- (void)discardTextFieldError:(UITextField *)textField {
    SignUpTextField *aTextField = (SignUpTextField *)textField;
    aTextField.invalid = NO;
    
    UILabel *label = self.errorLabel;
    label.text = nil;
}

- (void)_presentImagePicker:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:((self.profileImageButton.customBackgroundImage) ? NSLocalizedString(@"Delete", nil) : nil)
                                                    otherButtonTitles:NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Choose existing", nil), nil];
    [actionSheet showInView:self.navigationController.view];
}

- (void)startLoading {
    if (!self.progressView.superview) {
        [self.progressView.activityIndicator startAnimating];
        [self.navigationController.view addSubview:self.progressView];
        [self.navigationController.view setUserInteractionEnabled:NO];
    }
}

- (void)stopLoading {
    if (self.progressView.superview) {
        [self.progressView removeFromSuperview];
        [self.progressView.activityIndicator stopAnimating];
        [self.navigationController.view setUserInteractionEnabled:YES];
    }
}

- (void)updateSignUpButtonForSubmission {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:2];
    SignUpButtonCell *cell = (SignUpButtonCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.button.backgroundColor = [SPCColorManager sharedInstance].buttonEnabledColor;
    
}

- (void)resetSignUpButton {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:2];
    SignUpButtonCell *cell = (SignUpButtonCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.button.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
    cell.button.highlightedBackgroundColor = [SPCColorManager sharedInstance].buttonEnabledColor;
    cell.button.normalBackgroundColor = [SPCColorManager sharedInstance].buttonEnabledColor;

}

#pragma mark - Actions

- (void)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)done:(id)sender {
    if ([self.delegate respondsToSelector:@selector(dismissViewController:animated:)]) {
        [self.delegate dismissViewController:self animated:NO];
    }
    
    // Set default transition style
    [self.navigationController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    // Dismiss modal view controller
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)presentImagePicker:(id)sender {
    // Present action sheet with a reasonable delay
    // Also discard any visible validation errors
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_presentImagePicker:) object:sender];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(discardProfileButtonError:) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(discardTextFieldError:) object:nil];
    
    [self performSelector:@selector(_presentImagePicker:) withObject:sender afterDelay:0.4];
    [self performSelector:@selector(discardProfileButtonError:) withObject:sender afterDelay:0.4];
    [self performSelector:@selector(discardTextFieldError:) withObject:nil afterDelay:0.4];
    
    // Hide keyboard for a better user experience
    [self.view hideKeyboard];
}

- (void)signUp:(id)sender {
    BOOL success = [self validateInputValues];
    if (success) {
        [self startLoading];
        
        __weak typeof(self)weakSelf = self;
        
        [[AuthenticationManager sharedInstance] registerWithEmail:self.emailTextField.text
                                                           handle:self.handleTextField.text
                                                         password:self.passwordTextField.text
                                                        firstName:self.firstnameTextField.text
                                                         lastName:self.lastnameTextField.text
                                                        promoCode:nil
                                                completionHandler:^(BOOL codeValidated) {
                                                    __strong typeof(weakSelf)strongSelf = weakSelf;
                                                    
                                                    [strongSelf stopLoading];
                                                    [strongSelf done:nil];
                                                    
                                                    //SKIP THE INTRO
                                                    //[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"justSignedUp"];
                                                    
                                                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"justSignedUp"];
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateForNewUser" object:self];
                                                    
                                                    [[ContactAndProfileManager sharedInstance] updateProfileImage:strongSelf.profileImageButton.customBackgroundImage isProfilePhoto:YES];
                                                } errorHandler:^(NSError *error) {
                                                    __strong typeof(weakSelf)strongSelf = weakSelf;
                                                    
                                                    [strongSelf clearInputValues];
                                                    [strongSelf stopLoading];
                                                    
                                                    [strongSelf spc_showNotificationBannerInParentView:strongSelf.view title:NSLocalizedString(@"Signing Up Failed", nil) error:error];
                                                }];
        [self.view hideKeyboard];
    }
}

-(void)fadeTopCellIfNeeded {
    
    /*
    // Fades in top cell in table view as it enters / leaves the screen
    NSArray *visibleCells = [self.tableView visibleCells];
    
    if (visibleCells != nil  &&  [visibleCells count] != 0) {       // Don't do anything for empty table view
        
        // Get top and bottom cells
        UITableViewCell *topCell = [visibleCells objectAtIndex:0];
        
        // Make sure other cells stay opaque
        // Avoids issues with skipped method calls during rapid scrolling
        for (UITableViewCell *cell in visibleCells) {
            cell.alpha = 1.0;
        }
        
        // Set necessary constants
        NSInteger cellHeight = topCell.frame.size.height - 1;   // -1 To allow for typical separator line height
        NSInteger tableViewTopPosition = self.tableView.frame.origin.y;
        
        // Get content offset to set opacity
        CGRect topCellPositionInTableView = [self.tableView rectForRowAtIndexPath:[self.tableView indexPathForCell:topCell]];
        CGFloat topCellPosition = [self.tableView convertRect:topCellPositionInTableView toView:[self.tableView superview]].origin.y;
        
        
        // Set opacity based on amount of cell that is outside of view
        CGFloat modifier = 3.0;     // Increases the speed of fading (1.0 for fully transparent when the cell is entirely off the screen,
                                    // 2.0 for fully transparent when the cell is half off the screen, etc)
        CGFloat topCellOpacity = (1.0f - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier);
        
        // Set cell opacity
        if (topCell) {
            topCell.alpha = topCellOpacity;
        }
    }
     */
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
