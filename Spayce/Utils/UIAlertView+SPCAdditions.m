//
//  UIAlertView+SPCAdditions.m
//  Spayce
//
//  Created by William Santiago on 5/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UIAlertView+SPCAdditions.h"

@implementation UIAlertView (SPCAdditions)

#pragma mark - Private

+ (NSString *)titleWithError:(NSError *)error {
    NSString *title = error.userInfo[@"title"];
    
    if (title == nil) {
        title = NSLocalizedString(@"Ooops", nil);
    }
    
    return title;
}

+ (NSString *)messageWithError:(NSError *)error {
    NSString *message = error.userInfo[@"description"];
    
    if (message == nil) {
        message = NSLocalizedString(@"An error has occurred", nil);
    }
    
    return message;
}

#pragma mark - Show

+ (void)showError:(NSError *)error {
    [[[self alloc] initWithTitle:[self titleWithError:error]
                         message:[self messageWithError:error]
                        delegate:nil
               cancelButtonTitle:NSLocalizedString(@"OK", nil)
               otherButtonTitles:nil] show];
}

@end
