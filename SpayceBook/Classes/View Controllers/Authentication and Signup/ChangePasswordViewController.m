//
//  ChangePasswordViewController.m
//  Spayce
//
//  Created by Pavel Dušátko on 11/11/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "Buttons.h"
#import "AuthenticationManager.h"
#import "User.h"
#import "SignUpTextFieldCell.h"
#import "SignUpButtonCell.h"
#import "UIScreen+Size.h"

@interface ChangePasswordViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) UITextField *oldPasswordTextField;
@property (nonatomic, weak) UITextField *passwordTextField;
@property (nonatomic, weak) UITextField *verifyPasswordTextField;

@end

@implementation ChangePasswordViewController

#pragma mark - UIViewController - Managing the View

- (void)loadView {
    [super loadView];
    
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Navigation Bar Configuration
    self.navigationItem.title = NSLocalizedString(@"CHANGE PASSWORD", nil);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"button-back-light-small"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
}

#pragma mark - Accessors

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 2) {
        static NSString *CellIdentifier = @"TextFieldCell";
        
        SignUpTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (!cell) {
            cell = [SignUpTextFieldCell createCellWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier type:TextFieldCellTypeSingle];
        }
        
        NSString *text;
        NSString *placeholder;
        UIReturnKeyType returnKeyType = UIReturnKeyDefault;
        UITextField *textField = cell.textFields[0];
        
        if (indexPath.row == 0) {
            text = self.oldPasswordTextField.text;
            placeholder = NSLocalizedString(@"Old password", nil);
            returnKeyType = UIReturnKeyNext;
            
            self.oldPasswordTextField = textField;
        } else if (indexPath.row == 1) {
            text = self.passwordTextField.text;
            placeholder = NSLocalizedString(@"New password", nil);
            returnKeyType = UIReturnKeyNext;
            
            self.passwordTextField = textField;
        } else if (indexPath.row == 2) {
            text = self.verifyPasswordTextField.text;
            placeholder = NSLocalizedString(@"Verify password", nil);
            returnKeyType = UIReturnKeyDone;
            
            self.verifyPasswordTextField = textField;
        }
        
        textField.text = text;
        textField.placeholder = placeholder;
        textField.delegate = self;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.secureTextEntry = YES;
        textField.returnKeyType = returnKeyType;
        
        return cell;
    } else if (indexPath.row == 3) {
        static NSString *CellIdentifier = @"ButtonCellIdentifier";
        SignUpButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[SignUpButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.isResetPassBtn = YES;
            [cell.button addTarget:self action:@selector(changePassword:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [cell.button setTitle:NSLocalizedString(@"Change password", nil) forState:UIControlStateNormal];
        
        return cell;
    } else {
        return nil;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 3) {
        return ([UIScreen isLegacyScreen] ? 70.0 : 150.0);
    } else {
        return 44.0;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        [self selectNextTextField:textField];
    } else if (textField.returnKeyType == UIReturnKeyDone) {
        [self changePassword:nil];
    }
    
    return YES;
}

#pragma mark - Private

- (void)selectNextTextField:(UITextField *)textField {
    if (textField == self.oldPasswordTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self.verifyPasswordTextField becomeFirstResponder];
    }
}

#pragma mark - Actions

- (void)changePassword:(id)sender {
    [self tryChangingPasswordWithOldPassword:self.oldPasswordTextField.text
                                    password:self.passwordTextField.text
                              verifyPassword:self.verifyPasswordTextField.text];
}

- (void)tryChangingPasswordWithOldPassword:(NSString *)oldPassword password:(NSString *)password verifyPassword:(NSString *)verifyPassword {
    if (oldPassword && ![oldPassword isEqualToString:@""] &&
        password && ![password isEqualToString:@""] &&
        verifyPassword && ![verifyPassword isEqualToString:@""]) {
        if (![password isEqualToString:verifyPassword]) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New password", nil)
                                        message:NSLocalizedString(@"Please make sure you've retyped your new password correctly!", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
            
            return;
        }
        
        NSString *email = [AuthenticationManager sharedInstance].currentUser.username;
        
        self.navigationController.view.userInteractionEnabled = NO;
        
        __weak typeof(self)weakSelf = self;
        
        [[AuthenticationManager sharedInstance] resetOldPassword:oldPassword
                                                        forEmail:email
                                         passwordWithNewPassword:password
                                               completionHandler:^(BOOL result) {
                                                   __strong typeof(weakSelf)strongSelf = weakSelf;
                                                   
                                                   strongSelf.navigationController.view.userInteractionEnabled = YES;
                                                   
                                                   if (result) {
                                                       [strongSelf.verifyPasswordTextField resignFirstResponder];
                                                       
                                                       [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Reset password", nil)
                                                                                   message:NSLocalizedString(@"Password successfully changed.", nil)
                                                                                  delegate:strongSelf
                                                                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                         otherButtonTitles:nil] show];
                                                   }
                                                   
                                               } errorHandler:^(NSError *error) {
                                                   weakSelf.navigationController.view.userInteractionEnabled = YES;
                                               }];
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Input", nil)
                                    message:NSLocalizedString(@"Please fill in all fields!", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
