//
//  Buttons.m
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "Buttons.h"

@implementation Buttons

#pragma mark - Private

+ (UIBarButtonItem *)negativeSpacerItem {
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSpacer.width = -10;
    return negativeSpacer;
}

+ (UIBarButtonItem *)backNavBarButtonWithTarget:(id)target action:(SEL)action {
    UIButton *res = [UIButton buttonWithType:UIButtonTypeCustom];
    res.frame = CGRectMake(0, 0, 40, 30);
    res.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f];
    res.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    [res.layer setCornerRadius:3.0f];
    [res setImage:[UIImage imageNamed:@"button-back-white-small"] forState:UIControlStateNormal];
    [res addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return [[UIBarButtonItem alloc] initWithCustomView:res];
}

+ (UIBarButtonItem *)backNavBarButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    UIButton *res = [UIButton buttonWithType:UIButtonTypeCustom];
    res.frame = CGRectMake(0, 0, 65, 30);
    [res.layer setCornerRadius:3.0f];
    res.backgroundColor = [UIColor clearColor];
    res.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    [res setTitleEdgeInsets:UIEdgeInsetsMake(0, -25, 0, 0)];
    [res setTitle:NSLocalizedString(title, nil) forState:UIControlStateNormal];
    [res setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [res setTitleColor:[UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:.7f] forState:UIControlStateHighlighted];
    [res addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return [[UIBarButtonItem alloc] initWithCustomView:res];
}

+ (UIBarButtonItem *)backNavBarCancelButtonWithTarget:(id)target action:(SEL)action {
    return [self backNavBarButtonWithTitle:NSLocalizedString(@"Cancel", nil) target:target action:action];
}

+ (UIBarButtonItem *)navBarItemWithTitle:(NSString *)title titleColor:(UIColor *)titleColor backgroundColor:(UIColor *)backgroundColor target:(id)target action:(SEL)action {
    UIButton *res = [UIButton buttonWithType:UIButtonTypeCustom];
    res.titleLabel.font = [UIFont systemFontOfSize:14];
    res.frame = CGRectMake(0, 0, 60, 29);
    res.layer.cornerRadius = 4;
    [res addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [res setBackgroundColor:backgroundColor];
    [res setTitleColor:titleColor forState:UIControlStateNormal];
    [res setTitleColor:titleColor forState:UIControlStateDisabled];
    [res setTitle:title forState:UIControlStateNormal];
    return [[UIBarButtonItem alloc] initWithCustomView:res];
}

#pragma mark - Accessors

+ (NSArray *)backNavBarButtonsWithTarget:(id)target action:(SEL)action {
    UIBarButtonItem *negativeSpacer = [[self class] negativeSpacerItem];
    UIBarButtonItem *item = [[self class] backNavBarButtonWithTarget:target action:action];
    return @[negativeSpacer, item];
}

+ (NSArray *)backNavBarButtonsWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    UIBarButtonItem *negativeSpacer = [[self class] negativeSpacerItem];
    UIBarButtonItem *item = [[self class] backNavBarButtonWithTitle:title target:target action:action];
    return @[negativeSpacer, item];
}

+ (NSArray *)backNavBarCancelButtonsWithTarget:(id)target action:(SEL)action {
    UIBarButtonItem *negativeSpacer = [[self class] negativeSpacerItem];
    UIBarButtonItem *item = [[self class] backNavBarCancelButtonWithTarget:target action:action];
    return @[negativeSpacer, item];
}

+ (NSArray *)navBarItemsWithTitle:(NSString *)title titleColor:(UIColor *)titleColor backgroundColor:(UIColor *)backgroundColor target:(id)target action:(SEL)action {
    UIBarButtonItem *negativeSpacer = [[self class] negativeSpacerItem];
    UIBarButtonItem *item = [[self class] navBarItemWithTitle:title titleColor:titleColor backgroundColor:backgroundColor target:target action:action];
    return @[negativeSpacer, item];
}

@end
