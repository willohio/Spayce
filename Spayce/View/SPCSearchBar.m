//
//  SPCSearchBar.m
//  Spayce
//
//  Created by William Santiago on 4/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSearchBar.h"

@interface SPCSearchBar ()

@property (nonatomic, weak) NSObject <UITextFieldDelegate> *textFieldDelegate;
@property (nonatomic, assign) UIReturnKeyType textFieldReturnKeyType;
@property (nonatomic, assign) UITextAutocorrectionType textFieldAutocorrectionType;
@property (nonatomic, assign) UITextAutocapitalizationType textFieldAutocapitalizationType;
@property (nonatomic, assign) BOOL textFieldEnablesReturnKeyAutomatically;

@end

@implementation SPCSearchBar

#pragma mark - UIView - Initializing a View Object

- (instancetype)initWithFrame:(CGRect)frame textFieldDelegate:(NSObject<UITextFieldDelegate> *)textFieldDelegate textFieldReturnKeyType:(UIReturnKeyType)textFieldReturnKeyType textFieldAutocorrectionType:(UITextAutocorrectionType)textFieldAutocorrectionType textFieldAutocapitalizationType:(UITextAutocapitalizationType)textFieldAutocapitalizationType textFieldEnablesReturnKeyAutomatically:(BOOL)textFieldEnablesReturnKeyAutomatically {
    self = [super initWithFrame:frame];
    if (self) {
        _textFieldDelegate = textFieldDelegate;
        _textFieldReturnKeyType = textFieldReturnKeyType;
        _textFieldAutocorrectionType = textFieldAutocorrectionType;
        _textFieldAutocapitalizationType = textFieldAutocapitalizationType;
        _textFieldEnablesReturnKeyAutomatically = textFieldEnablesReturnKeyAutomatically;
    }
    return self;
}

#pragma mark - UIView - Laying out Subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self configureTextFieldInView:self textFieldDelegate:self.textFieldDelegate textFieldReturnKeyType:self.textFieldReturnKeyType textFieldAutocorrectionType:self.textFieldAutocorrectionType textFieldAutocapitalizationType:self.textFieldAutocapitalizationType textFieldEnablesReturnKeyAutomatically:self.textFieldEnablesReturnKeyAutomatically];
}

#pragma mark - Private

- (void)configureTextFieldInView:(UIView *)view textFieldDelegate:(NSObject <UITextFieldDelegate> *)textFieldDelegate textFieldReturnKeyType:(UIReturnKeyType)textFieldReturnKeyType textFieldAutocorrectionType:(UITextAutocorrectionType)textFieldAutocorrectionType textFieldAutocapitalizationType:(UITextAutocapitalizationType)textFieldAutocapitalizationType textFieldEnablesReturnKeyAutomatically:(BOOL)textFieldEnablesReturnKeyAutomatically {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subview;
            textField.delegate = textFieldDelegate;
            textField.returnKeyType = textFieldReturnKeyType;
            textField.autocorrectionType = textFieldAutocorrectionType;
            textField.autocapitalizationType = textFieldAutocapitalizationType;
            textField.enablesReturnKeyAutomatically = textFieldEnablesReturnKeyAutomatically;
            
            break;
        } else {
            [self configureTextFieldInView:subview textFieldDelegate:textFieldDelegate textFieldReturnKeyType:textFieldReturnKeyType textFieldAutocorrectionType:textFieldAutocorrectionType textFieldAutocapitalizationType:textFieldAutocapitalizationType textFieldEnablesReturnKeyAutomatically:textFieldEnablesReturnKeyAutomatically];
        }
    }
}

@end
