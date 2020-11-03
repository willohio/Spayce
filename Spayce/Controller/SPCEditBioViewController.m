//
//  SPCEditBioViewController.m
//  Spayce
//
//  Created by Manuel Vidonis on 11/03/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCEditBioViewController.h"

// Model
#import "PersonUpdate.h"
#import "UserProfile.h"
#import "ProfileDetail.h"
#import "User.h"

// View
#import "Buttons.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"

// Utility
#import "ImageUtils.h"

@interface SPCEditBioViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextView *txtStatusMessage;
@property (nonatomic, strong) UIButton *saveButton;

@property (nonatomic, strong) UserProfile *profile;

@end

@implementation SPCEditBioViewController

NSString *kBioMessagePlaceholder = @"What's up Spayce cadet?";
#define SPC_BIO_TEXT_PERC 0.30

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
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:0.94f];
    

    [self.view addSubview:self.scrollView];

    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, CGRectGetWidth(self.view.bounds)-10, CGRectGetHeight(self.view.bounds) * SPC_BIO_TEXT_PERC)];
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


    self.txtStatusMessage = [[UITextView alloc] initWithFrame:CGRectMake(5, 10, CGRectGetWidth(backView.frame)-10, CGRectGetHeight(backView.frame)-15)];
    self.txtStatusMessage.delegate = self;
    self.txtStatusMessage.textAlignment = NSTextAlignmentLeft;
    self.txtStatusMessage.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.txtStatusMessage.font = [UIFont spc_regularSystemFontOfSize:14];
    self.txtStatusMessage.textColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    self.txtStatusMessage.returnKeyType = UIReturnKeyDefault;
    self.txtStatusMessage.text = self.profile.profileDetail.statusMessage;
    if ([self.txtStatusMessage.text isEqualToString:@""]) {
        self.txtStatusMessage.text = kBioMessagePlaceholder;
        self.txtStatusMessage.textColor = [UIColor lightGrayColor];
    }
    [backView addSubview:self.txtStatusMessage];
    
    _saveButton = [[UIButton alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(backView.frame) + 10, CGRectGetWidth(self.view.bounds)-10, 45)];
    _saveButton.backgroundColor = [UIColor colorWithRed:106.0/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
    _saveButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    _saveButton.layer.cornerRadius = 2;
    _saveButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [_saveButton addTarget:self action:@selector(updateProfile:) forControlEvents:UIControlEventTouchUpInside];
    _saveButton.enabled = NO;
    _saveButton.alpha = 0.5;
    
    [self.view addSubview:self.saveButton];
    
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

    [self.txtStatusMessage becomeFirstResponder];
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
        _scrollView.backgroundColor = [UIColor clearColor];
    }

    return _scrollView;
}

- (void)updateProfile:(id)sender {
    [[ContactAndProfileManager sharedInstance] updateProfile:self.profileToBeUpdated
                                                profileImage:nil
                                              resultCallback:^{
                                                  UserProfile *profile = self.profileToBeUpdated;
                                                  
                                                  [ContactAndProfileManager sharedInstance].profile = profile;
                                                  
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:ContactAndProfileManagerUserProfileDidUpdateNotification object:nil];
                                                  
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

    profile.profileDetail.statusMessage = self.txtStatusMessage.text;

    return profile;
}

- (void)doCancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - Navigation Bar

- (void)configureNavigationBar {
    // Background/tint color
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    
    // Cancel button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(doCancel:)];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0x6ab1fb] } forState:UIControlStateNormal];
    
    // Title
    self.navigationItem.title = NSLocalizedString(@"Edit Bio", nil);
    self.navigationController.navigationBar.titleTextAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                                     NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x292929],
                                                                     NSKernAttributeName : @(1.1) };
    
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Choose Existing", nil), nil];

    [actionSheet showInView:self.navigationController.view];
}


#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];

    if (textView == self.txtStatusMessage) {
        [self setSaveButtonWithStatusMessage:newString];
        return newString.length <= 100;
    }

    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:kBioMessagePlaceholder]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    }

    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        textView.text = kBioMessagePlaceholder;
        textView.textColor = [UIColor lightGrayColor];
    }

    [textView resignFirstResponder];
}

#pragma mark - Private

-(void)setSaveButtonWithStatusMessage:(NSString *)message{
    if([message isEqualToString:self.profile.profileDetail.statusMessage])
    {
        self.saveButton.alpha = 0.5;
        self.saveButton.enabled = NO;
    }
    else{
        self.saveButton.alpha = 1.0;
        self.saveButton.enabled = YES;
    }


}

@end
