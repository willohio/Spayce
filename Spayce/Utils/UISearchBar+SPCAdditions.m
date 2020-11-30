//
//  UISearchBar+SPCAdditions.m
//  Spayce
//
//  Created by William Santiago on 4/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UISearchBar+SPCAdditions.h"

@implementation UISearchBar (SPCAdditions)

- (BOOL)spc_isSearching {
    return self.isFirstResponder && self.text && ![self.text isEqualToString:@""];
}

@end
