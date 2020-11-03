//
//  LogInViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 1/21/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "LogInViewController.h"

// View
#import "LargeBlockingProgressView.h"
#import "SPCNavControllerLight.h"

// Controller
#import "ForgotPasswordViewController.h"

// Category
#import "UIScreen+Size.h"
#import "UIViewController+SPCAdditions.h"

// Manager
#import "AuthenticationManager.h"
#import "SPCColorManager.h"

// Utility
#import "EmailUtils.h"

@interface LogInViewController ()

@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passField;
@property (nonatomic, strong) UIButton *logInBtn;
@property (nonatomic, strong) UIButton *forgotPassBtn;
@property (nonatomic, strong) UILabel *errorMsgLbl;
@property (strong, nonatomic) LargeBlockingProgressView *progressView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, assign) BOOL readyToSubmit;
@property (nonatomic, strong) UIView *notificationContainerView;

@end

@implementation LogInViewController

- (void)dealloc {
    [self spc_dealloc];
    
     [[NSNotificationCenter defaultCenter] removeObserver:self];
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
- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureSubviews];
    [self setUpNavigationBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deactivateErrorContainer)
                                                 name:@"deactivateContainerInteraction"
                                               object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[AuthenticationManager sharedInstance] addObserver:self forKeyPath:@"authenticationInProgress" options:NSKeyValueObservingOptionNew context:nil];
    self.forgotPassBtn.titleLabel.textColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
    
    [self stopLoadingProgressView];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAuthenticationDidFail:) name:kAuthenticationDidFailNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[AuthenticationManager sharedInstance] removeObserver:self forKeyPath:@"authenticationInProgress"];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationDidFailNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpNavigationBar {
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = NSLocalizedString(@"Login", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:17];
    titleLabel.frame = CGRectMake(CGRectGetMidX(self.view.frame) - 75.0, 25, 150.0, 35);
    titleLabel.textColor = [UIColor whiteColor];
    
    [self.view addSubview:titleLabel];
    [self.view addSubview:self.cancelBtn];
    [self.view bringSubviewToFront:self.notificationContainerView];
    
}

- (void)configureSubviews {
    
    float hPadding = 15;
    float vPadding = 0;
    float startY = 110;
    float btnPad = 25;
    float rowHeight = 45;
    
    
    if ([UIScreen isLegacyScreen]) {
        btnPad = 25;
        rowHeight = 35;
        startY = 70;
    }
    
    UIImage *bgImg = [UIImage imageNamed:@"background-earth"];
    UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.frame];
    bgImgView.image = bgImg;
    [self.view addSubview:bgImgView];
    
    CGFloat containerWidth = [[UIScreen mainScreen] bounds].size.width - (2 * hPadding);
    //Container height is 2 rows (email and password) + separator line (1px)
    CGFloat containerHeight = (2 * rowHeight) + 1;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(hPadding, startY, containerWidth, containerHeight)];
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.cornerRadius = 2;
    containerView.layer.shadowOffset = CGSizeMake(0, 2);
    containerView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:.3].CGColor;
    containerView.clipsToBounds = YES;
    containerView.layer.masksToBounds = YES;
    [self.view addSubview:containerView];
    
    //Icon offset calculated based on rowHeight and icon height
    float iconOffset = ((rowHeight-20) / 2);
    
    UIImage *emailIconImg = [UIImage imageNamed:@"email"];
    UIImageView *eIconImgView = [[UIImageView alloc] initWithImage:emailIconImg];
    eIconImgView .backgroundColor = [UIColor clearColor];
    eIconImgView.frame = CGRectMake(hPadding+10, startY+iconOffset, 20 , 20);
    
    [self.view addSubview:eIconImgView];
    
    
    self.emailField = [[UITextField alloc] initWithFrame:CGRectMake(hPadding + 40, startY, containerWidth - (hPadding + 10 + 20), rowHeight)];
    self.emailField.placeholder = @"Email";
    self.emailField.delegate = self;
    self.emailField.backgroundColor = [UIColor clearColor];
    self.emailField.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.emailField];
    
    UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(hPadding, CGRectGetMaxY(self.emailField.frame), self.view.bounds.size.width-hPadding*2, 1)];
    sepLine.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:232.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
    [self.view addSubview:sepLine];
    
    UIImage *passIconImg = [UIImage imageNamed:@"lock"];
    UIImageView *pIconImgView = [[UIImageView alloc] initWithImage:passIconImg];
    pIconImgView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:pIconImgView];
    pIconImgView.frame = CGRectMake(hPadding+10, CGRectGetMaxY(sepLine.frame)+iconOffset, 20 , 20);

    
    self.passField = [[UITextField alloc] initWithFrame:CGRectMake(hPadding + 40, CGRectGetMaxY(sepLine.frame), CGRectGetWidth(self.emailField.frame), rowHeight)];
    self.passField.placeholder = @"Password";
    self.passField.delegate = self;
    self.passField.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
    self.passField.backgroundColor = [UIColor clearColor];
    self.passField.secureTextEntry = YES;
    self.passField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.passField];
    
    self.errorMsgLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.passField.frame)+vPadding, 300, 20)];
    self.errorMsgLbl.center = CGPointMake(self.view.bounds.size.width/2, self.errorMsgLbl.center.y);
    self.errorMsgLbl.text = @"";
    self.errorMsgLbl.textColor = [UIColor redColor];
    self.errorMsgLbl.textAlignment = NSTextAlignmentCenter;
    self.errorMsgLbl.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12];
    [self.view addSubview:self.errorMsgLbl];
    
    self.logInBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.passField.frame)+btnPad, 250, 50)];
    self.logInBtn.center = CGPointMake(self.view.bounds.size.width/2, self.logInBtn.center.y);
    self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
    [self.logInBtn setTitle:@"Login" forState:UIControlStateNormal];
    [self.logInBtn setTitle:@"Login" forState:UIControlStateSelected];
    [self.logInBtn.titleLabel setFont: [UIFont fontWithName:@"AvenirNext-Regular" size:14]];
    [self.logInBtn addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    [self.logInBtn addTarget:self action:@selector(showSelected:) forControlEvents:UIControlEventTouchDown];
    [self.logInBtn addTarget:self action:@selector(resetBtn:) forControlEvents:UIControlEventTouchUpOutside];

    self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
    self.logInBtn.layer.cornerRadius = 3;
    [self.view addSubview:self.logInBtn];
    
    self.forgotPassBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.logInBtn.frame)+10,100, 20)];
    self.forgotPassBtn.center = CGPointMake(self.view.bounds.size.width/2, self.forgotPassBtn.center.y);
    [self.forgotPassBtn setTitle:@"Forgot Password?" forState:UIControlStateNormal];
    [self.forgotPassBtn addTarget:self action:@selector(handleForgotPasswordButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.forgotPassBtn setTitleColor:[UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    self.forgotPassBtn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12];
    [self.view addSubview:self.forgotPassBtn];
 
    self.notificationContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width,self.view.bounds.size.height-20)];
    self.notificationContainerView.userInteractionEnabled = NO;
    self.notificationContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.notificationContainerView];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.emailField becomeFirstResponder];
}

- (LargeBlockingProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[LargeBlockingProgressView alloc] initWithFrame:self.navigationController.view.frame];
        _progressView.label.text = @"Connecting ...";
        _progressView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.8];
    }
    return _progressView;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITextViewDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField == self.passField) {
        NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if ((resultString.length > 5) && ([EmailUtils isEmailValid:self.emailField.text])) {
            self.errorMsgLbl.text = @"";
            self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
            self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonEnabledColor;
          
            self.readyToSubmit = YES;
        }
        if (resultString.length < 6)  {
            self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
            self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
          
            self.readyToSubmit = NO;
        }
        
        return resultString.length <= 13;
    }
    else {
        NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if ([EmailUtils isEmailValid:resultString]){
            self.errorMsgLbl.text = @"";
            
            if (self.passField.text.length > 5) {
                self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
                self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonEnabledColor;
              
                self.readyToSubmit = YES;
            }
            else {
                self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
                self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
              
                self.readyToSubmit = NO;
            }
            
        }
        else {
            self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
            self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
          
            self.readyToSubmit = NO;
        }
        return resultString.length <= 100;
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.emailField) {
        
        if ([EmailUtils isEmailValid:textField.text]){
            [self.emailField resignFirstResponder];
            [self.passField becomeFirstResponder];
            self.errorMsgLbl.text = @"";
        }
        else {
            self.errorMsgLbl.text = @"Valid Email Required";
        }
        return NO;
    }
    else if (textField == self.passField) {
        if (textField.text.length > 5){
            [self.passField resignFirstResponder];
            
            if ([EmailUtils isEmailValid:self.emailField.text]) {
                [self validateEmailAndPass];
                self.errorMsgLbl.text = @"";
            } else {
                [self.emailField becomeFirstResponder];
                self.errorMsgLbl.text = @"Valid Email Required";
            }
            

        }
        else {
            self.errorMsgLbl.text = @"Passwords must be at least 6 characters";
        }
        return NO;
    }
    
    else {
        return NO;
    }
}

-(void)validateEmailAndPass {
    if ([self.emailField isFirstResponder]) {
        [self.emailField resignFirstResponder];
    }
    if ([self.passField isFirstResponder]) {
        [self.passField resignFirstResponder];
    }
    
    self.view.userInteractionEnabled = NO;
    [self startLoadingProgressView];
    
    [[AuthenticationManager sharedInstance] loginWithEmail:self.emailField.text password:self.passField.text];
}

-(void)login:(id)sender {
    
    if ((self.passField.text.length > 5) && ([EmailUtils isEmailValid:self.emailField.text])) {
        self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
        self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonEnabledColor;
        [self validateEmailAndPass];
    }
    else  {
        self.logInBtn.selected = NO;
        self.logInBtn.highlighted = NO;
        self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
        self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
        self.readyToSubmit = NO;
        
        if (![EmailUtils isEmailValid:self.emailField.text]){
            self.errorMsgLbl.text = @"Valid Email Required";
        }
        else if (self.passField.text.length < 6){
            self.errorMsgLbl.text = @"Passwords must be at least 6 characters";
        }
    }
}

- (void)cancel {
    [self dismissViewController:self animated:YES];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    self.navigationController.view.userInteractionEnabled = ![AuthenticationManager sharedInstance].authenticationInProgress;
}

#pragma mark - Notifications

- (void)handleAuthenticationDidFail:(NSNotification *)notification {
    self.emailField.text= nil;
    self.passField.text= nil;
    self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
    self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
    
    self.view.userInteractionEnabled = YES;
    
    self.notificationContainerView.userInteractionEnabled = YES;
    [self spc_showNotificationBannerInParentView:self.notificationContainerView title:NSLocalizedString(@"Signing In Failed", nil) error:notification.object];
    
    [self stopLoadingProgressView];
}

- (void)handleForgotPasswordButtonTapped:(id)sender
{
    self.forgotPassBtn.titleLabel.textColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:.7f];
    ForgotPasswordViewController *forgotPasswordViewController = [[ForgotPasswordViewController alloc] init];
    [self.navigationController pushViewController:forgotPasswordViewController animated:YES];
}

- (void)resetBtn:(id)sender {
    self.logInBtn.selected = NO;
    if (self.readyToSubmit){
        self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
        self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonEnabledColor;
    }
    else {
        self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
        self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
    }
}

- (void)showSelected:(id)sender {
    if (!self.readyToSubmit){
        self.logInBtn.titleLabel.textColor = [UIColor whiteColor];
        self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonDisabledColor;
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateReserved];
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    }
    else {
        self.logInBtn.titleLabel.textColor = [UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f];
        self.logInBtn.backgroundColor = [SPCColorManager sharedInstance].buttonEnabledColor;
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateReserved];
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [self.logInBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    }
}

- (void)startLoadingProgressView
{
    [self.navigationController.view addSubview:self.progressView];
    self.logInBtn.alpha = 0;
    [self.progressView.activityIndicator startAnimating];
}

- (void)stopLoadingProgressView
{
    [self.progressView.activityIndicator stopAnimating];
    self.logInBtn.alpha = 1;
    [self.progressView removeFromSuperview];
}

#pragma mark - SignUpViewControllerDelegate

- (void)dismissViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.navigationController popToRootViewControllerAnimated:animated];
}

#pragma mark - Private 

- (void)deactivateErrorContainer {
    self.notificationContainerView.userInteractionEnabled = NO;
    [self.emailField becomeFirstResponder];
    
}

@end
