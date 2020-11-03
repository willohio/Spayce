//
//  SPCHandlePromptViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 8/12/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHandlePromptViewController.h"

// Model
#import "ProfileDetail.h"
#import "UserProfile.h"

// View
#import "LargeBlockingProgressView.h"

// Category
#import "UIScreen+Size.h"
#import "UIViewController+SPCAdditions.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"

@interface SPCHandlePromptViewController ()

@property (nonatomic, strong) UITextField *handleField;
@property (nonatomic, strong) UIButton *goBtn;
@property (nonatomic, strong) UILabel *errorMsgLbl;
@property (strong, nonatomic) LargeBlockingProgressView *progressView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, assign) BOOL readyToSubmit;
@property (nonatomic, strong) UIView *notificationContainerView;

@end

@implementation SPCHandlePromptViewController


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
        [_cancelBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:13];
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
    [self stopLoadingProgressView];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setUpNavigationBar {
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = NSLocalizedString(@"Create A Handle", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont spc_mediumSystemFontOfSize:17];
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
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(hPadding, startY, 290, (rowHeight + 1))];
    containerView.center = CGPointMake(self.view.bounds.size.width/2, containerView.center.y);
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.cornerRadius = 2;
    containerView.layer.shadowOffset = CGSizeMake(0, 2);
    containerView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:.3].CGColor;
    containerView.clipsToBounds = YES;
    containerView.layer.masksToBounds = YES;
    [self.view addSubview:containerView];
    
    
    UIImage *emailIconImg = [UIImage imageNamed:@"handle"];
    UIImageView *eIconImgView = [[UIImageView alloc] initWithImage:emailIconImg];
    eIconImgView .backgroundColor = [UIColor clearColor];
    eIconImgView.frame = CGRectMake(10, 13, 20 , 20);
    
    [containerView addSubview:eIconImgView];
    
    
    self.handleField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMinX(containerView.frame)+40, startY, CGRectGetWidth(containerView.frame)-50, rowHeight)];
    self.handleField.placeholder = @"Username";
    self.handleField.delegate = self;
    self.handleField.backgroundColor = [UIColor clearColor];
    self.handleField.font = [UIFont spc_regularSystemFontOfSize:14];
    self.handleField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.handleField.keyboardType = UIKeyboardTypeEmailAddress;
    self.handleField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.handleField];
    
    self.errorMsgLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.handleField.frame)+vPadding, 300, 20)];
    self.errorMsgLbl.center = CGPointMake(self.view.bounds.size.width/2, self.errorMsgLbl.center.y);
    self.errorMsgLbl.text = @"";
    self.errorMsgLbl.textColor = [UIColor redColor];
    self.errorMsgLbl.textAlignment = NSTextAlignmentCenter;
    self.errorMsgLbl.font = [UIFont spc_regularSystemFontOfSize:12];
    [self.view addSubview:self.errorMsgLbl];
    
    self.goBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.handleField.frame)+btnPad, 290, 50)];
    self.goBtn.center = CGPointMake(self.view.bounds.size.width/2, self.goBtn.center.y);
    self.goBtn.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
    [self.goBtn setTitle:@"Go" forState:UIControlStateNormal];
    [self.goBtn setTitle:@"Go" forState:UIControlStateSelected];
    [self.goBtn.titleLabel setFont: [UIFont spc_regularSystemFontOfSize:13]];
    [self.goBtn addTarget:self action:@selector(reserveHandle) forControlEvents:UIControlEventTouchUpInside];
    [self.goBtn addTarget:self action:@selector(showSelected:) forControlEvents:UIControlEventTouchDown];
    [self.goBtn addTarget:self action:@selector(resetBtn:) forControlEvents:UIControlEventTouchUpOutside];
    
    self.goBtn.titleLabel.textColor = [UIColor whiteColor];
    self.goBtn.layer.cornerRadius = 3;
    [self.view addSubview:self.goBtn];
    
    self.notificationContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width,self.view.bounds.size.height-20)];
    self.notificationContainerView.userInteractionEnabled = NO;
    self.notificationContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.notificationContainerView];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.handleField becomeFirstResponder];
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
    
    NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (resultString.length > 1) {
        self.errorMsgLbl.text = @"";
        self.goBtn.titleLabel.textColor = [UIColor whiteColor];
        self.goBtn.backgroundColor = [UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f];
        
        self.readyToSubmit = YES;
    }
    else  {
        self.goBtn.titleLabel.textColor = [UIColor whiteColor];
        self.goBtn.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
        
        self.readyToSubmit = NO;
    }
    
    return resultString.length <= 16;
    
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.handleField) {
        
        if (textField.text.length > 0){
            //TODO: attempt to claim handle!
            self.errorMsgLbl.text = @"";
        }
        else {
            self.errorMsgLbl.text = @"Valid Email Required";
        }
        return NO;
    }
 
    
    else {
        return NO;
    }
}

- (void)reserveHandle {
    [self.handleField resignFirstResponder];
    [self startLoadingProgressView];
    [[AuthenticationManager sharedInstance] reserveHandle:self.handleField.text
                                        completionHandler:^(BOOL result){
                                            [self stopLoadingProgressView];
                                           
                                            if ([ContactAndProfileManager sharedInstance].profile.profileDetail) {
                                                [ContactAndProfileManager sharedInstance].profile.profileDetail.handle = self.handleField.text;
                                            }
                                            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shouldChangeHandle"];
                                            [self.navigationController dismissViewControllerAnimated:NO completion:^{}];
                                            [self performSelector:@selector(restoreFeed) withObject:nil afterDelay:.5];
                                        }
                                             errorHandler:^(NSError *error) {
                                                 [self stopLoadingProgressView];
                                                 [self.handleField becomeFirstResponder];
                                                 
                                                 if (error.code == -2800) {
                                                     
                                                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Not Available!", nil)]
                                                                                                     message:[NSString stringWithFormat:NSLocalizedString(@"The handle '%@' is already in use.  Please try something else.", nil), self.handleField.text]
                                                                                                    delegate:self
                                                                                           cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                                           otherButtonTitles:nil, nil];
                                                     [alertView show];
                                                 } else {
                                                     [self spc_showNotificationBannerInParentView:self.notificationContainerView title:NSLocalizedString(@"Error Reserving Handle", nil) error:error];
                                                     
                                                 }
    }];
}

- (void)cancel {
    [self dismissViewController:self animated:YES];
}


#pragma mark - Notifications

- (void)resetBtn:(id)sender {
    self.goBtn.selected = NO;
    if (self.readyToSubmit){
        self.goBtn.titleLabel.textColor = [UIColor whiteColor];
        self.goBtn.backgroundColor = [UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f];
    }
    else {
        self.goBtn.titleLabel.textColor = [UIColor whiteColor];
        self.goBtn.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];;
    }
}

- (void)showSelected:(id)sender {
    if (!self.readyToSubmit){
        self.goBtn.titleLabel.textColor = [UIColor whiteColor];
        self.goBtn.backgroundColor = [UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateReserved];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    }
    else {
        self.goBtn.titleLabel.textColor = [UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f];
        self.goBtn.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateReserved];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [self.goBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    }
}

- (void)startLoadingProgressView
{
    [self.navigationController.view addSubview:self.progressView];
    self.goBtn.alpha = 0;
    [self.progressView.activityIndicator startAnimating];
}

- (void)stopLoadingProgressView
{
    [self.progressView.activityIndicator stopAnimating];
    self.goBtn.alpha = 1;
    [self.progressView removeFromSuperview];
}

-(void)restoreFeed {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"displayFeedAfterHandleSelection" object:nil];
}

#pragma mark - SignUpViewControllerDelegate

- (void)dismissViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[AuthenticationManager sharedInstance] logout];
    [self.navigationController dismissViewControllerAnimated:NO completion:^{
    }];
}

#pragma mark - Private

- (void)deactivateErrorContainer {
    self.notificationContainerView.userInteractionEnabled = NO;
    [self.handleField becomeFirstResponder];
    
}

@end
