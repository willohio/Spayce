//
//  ForgotPasswordViewController.m
//  Spayce
//
//  Created by Pavel Dušátko on 11/11/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "ForgotPasswordViewController.h"

// View
#import "EmailTableCell.h"

// Manager
#import "AuthenticationManager.h"

@interface ForgotPasswordViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UITextField *emailTextField;

@property (nonatomic, strong) UIButton *cancelBtn;

@end

@implementation ForgotPasswordViewController {
    BOOL hasAppeared;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImage *bgImg = [UIImage imageNamed:@"background-earth"];
    UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.frame];
    bgImgView.image = bgImg;
    [self.view addSubview:bgImgView];
    
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = NSLocalizedString(@"Forgot Password", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont spc_mediumSystemFontOfSize:17];
    titleLabel.frame = CGRectMake(CGRectGetMidX(self.view.frame) - 75.0, 25, 150.0, 35);
    titleLabel.textColor = [UIColor whiteColor];
    
    [self.view addSubview:titleLabel];
    [self.view addSubview:self.cancelBtn];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!hasAppeared) {
        hasAppeared = YES;
        
        [self becomeFirstResponderForSubviews];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    hasAppeared = NO;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.tableView.frame = CGRectMake(15, 110, self.view.frame.size.width-30, self.view.frame.size.height-110);
}

#pragma mark - Private

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
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
        [_cancelBtn addTarget:self action:@selector(cancel)forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView emailCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EmailCell";
    
    EmailTableCell *cell = (EmailTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[EmailTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UIImage *emailIconImg = [UIImage imageNamed:@"email"];
        UIImageView *eIconImgView = [[UIImageView alloc] initWithImage:emailIconImg];
        eIconImgView .backgroundColor = [UIColor clearColor];
        eIconImgView.frame = CGRectMake(10, 13, 20 , 20);
        [cell addSubview:eIconImgView];
    }
    
    cell.textField.placeholder = @"Enter your email";
    cell.textField.tag = indexPath.row;
    cell.textField.delegate = self;
    cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    cell.textField.returnKeyType = UIReturnKeyDone;
    cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
    
    self.emailTextField = cell.textField;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        return [self tableView:tableView emailCellForRowAtIndexPath:indexPath];
    }
    else if  (indexPath.row == 1) {
        
        static NSString *CellIdentifier = @"SubmitCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.backgroundColor = [UIColor clearColor];
        
        UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 250, 50)];
        submitBtn.center = CGPointMake(self.tableView.bounds.size.width/2, submitBtn.center.y);
        submitBtn.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
        [submitBtn setTitle:@"Submit" forState:UIControlStateNormal];
        [submitBtn setTitle:@"Submit" forState:UIControlStateSelected];
        [submitBtn addTarget:self action:@selector(attemptToSubmit) forControlEvents:UIControlEventTouchUpInside];
        [submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [submitBtn.titleLabel setFont: [UIFont spc_regularSystemFontOfSize:13]];
        submitBtn.layer.cornerRadius = 2;
        [cell addSubview:submitBtn];
 
        return cell;
        

    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        return 45;
    }
    else if (indexPath.row == 1) {
        return 70;
    }
    else return 35;
}

#pragma mark - Text field delegation

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyDone) {
        [self tryRequestingForgottenPasswordForEmail:textField.text];
    }
    
    return YES;
}

#pragma mark - Actions

- (void)becomeFirstResponderForSubviews {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[EmailTableCell class]]) {
        [[(EmailTableCell *)cell textField] becomeFirstResponder];
    }
}

- (BOOL)validateEmail:(NSString *)emailCandidate
{
    // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailCandidate];
}

- (void)attemptToSubmit {
    [self tryRequestingForgottenPasswordForEmail:self.emailTextField.text];
}

- (void)tryRequestingForgottenPasswordForEmail:(NSString *)email
{
    if (email && ![email isEqualToString:@""]) {
        if (![self validateEmail:email]) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email", nil)
                                        message:NSLocalizedString(@"Please make sure you enter a valid email address!", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
            
            return;
        }
        
        self.navigationController.view.userInteractionEnabled = NO;
        
        __weak typeof(self)weakSelf = self;
        
        [[AuthenticationManager sharedInstance] forgotPasswordWithEmail:email
                                                      completionHandler:^(BOOL result) {
                                                          __strong typeof(weakSelf)strongSelf = weakSelf;
                                                          
                                                          strongSelf.navigationController.view.userInteractionEnabled = YES;
                                                          
                                                          if (result) {
                                                              [strongSelf.emailTextField resignFirstResponder];
                                                              
                                                              [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Forgot password", nil)
                                                                                          message:NSLocalizedString(@"Please check your mailbox for more instructions.", nil)
                                                                                         delegate:strongSelf
                                                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                                otherButtonTitles:nil] show];
                                                          }

                                                      } errorHandler:^(NSError *error) {
                                                          weakSelf.navigationController.view.userInteractionEnabled = YES;

                                                          [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Forgot password", nil)
                                                                                      message:NSLocalizedString(@"Email not found, please try again.", nil)
                                                                                     delegate:nil
                                                                            cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                            otherButtonTitles:nil] show];
                                                      }];
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email", nil)
                                    message:NSLocalizedString(@"Please fill in your email address!", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

- (void)pop
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancel {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
