//
//  SPCVenueCodeViewController.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCVenueCodeViewController.h"

@interface SPCVenueCodeViewController ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSLayoutConstraint *actionButtonBottomConstraint;

@end

@implementation SPCVenueCodeViewController

#pragma mark - Object lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Accessors

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.font = [UIFont spc_regularSystemFontOfSize:17];
        _textField.textColor = [UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0];
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _textField;
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    // Setup views
    self.view.backgroundColor = [UIColor colorWithWhite:243.0/255.0 alpha:1.0];
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.text = NSLocalizedString(@"Enter venue code", nil);
    textLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    textLabel.textColor = [UIColor colorWithRed:139.0/255.0 green:153.0/255.0 blue:175.0/255.0 alpha:1.0];
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *separatorView = [[UIView alloc] init];
    separatorView.backgroundColor = [UIColor colorWithRed:139.0/255.0 green:154.0/255.0 blue:174.0/255.0 alpha:1.0];
    separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *actionButton = [[UIButton alloc] init];
    actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    actionButton.backgroundColor = [UIColor colorWithRed:106.0/255.0 green:179.0/255.0 blue:249.0/255.0 alpha:1.0];
    actionButton.titleLabel.font = [UIFont spc_boldSystemFontOfSize:14];
    [actionButton setTitle:NSLocalizedString(@"Enter", nil) forState:UIControlStateNormal];
    [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(enterVenueCode:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add to view hierarchy
    [self.view addSubview:self.textField];
    [self.view addSubview:separatorView];
    [self.view addSubview:textLabel];
    [self.view addSubview:actionButton];
    
    // Setup auto layout constraints
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:150]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-35]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:35]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.textField.font.lineHeight]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:separatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.textField attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:separatorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.textField attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:separatorView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.textField attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:separatorView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.5]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:separatorView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:separatorView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:5]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:textLabel.font.lineHeight]];
    
    self.actionButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:8]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-8]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44]];
    [self.view addConstraint:self.actionButtonBottomConstraint];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureNavigationBar];
    
    [self.textField becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark - Configuration

- (void)configureNavigationBar {
  // Left '<--' button
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"button-back-light-small"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
  
  // Title
  self.navigationItem.title = NSLocalizedString(@"VENUE CODE", nil);
}

#pragma mark - Keyboard

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect kbRect = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize kbSize = [self.view convertRect:kbRect toView:nil].size;
    
    self.actionButtonBottomConstraint.constant = - (kbSize.height + 8);
    
    [UIView animateWithDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)enterVenueCode:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
