//
//  SPCSearchBar.h
//  Spayce
//
//  Created by William Santiago on 4/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCSearchBar : UISearchBar

- (instancetype)initWithFrame:(CGRect)frame textFieldDelegate:(NSObject<UITextFieldDelegate> *)textFieldDelegate textFieldReturnKeyType:(UIReturnKeyType)textFieldReturnKeyType textFieldAutocorrectionType:(UITextAutocorrectionType)textFieldAutocorrectionType textFieldAutocapitalizationType:(UITextAutocapitalizationType)textFieldAutocapitalizationType textFieldEnablesReturnKeyAutomatically:(BOOL)textFieldEnablesReturnKeyAutomatically;

@end
