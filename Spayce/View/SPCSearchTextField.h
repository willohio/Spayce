//
//  SPCSearchTextField.h
//  Spayce
//
//  Created by Pavel Dusatko on 8/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCSearchTextField : UITextField

@property (nonatomic, strong) NSDictionary *placeholderAttributes;

- (BOOL)isSearching;

@end
