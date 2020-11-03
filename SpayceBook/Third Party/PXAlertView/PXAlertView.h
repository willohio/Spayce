//
//  PXAlertView.h
//  PXAlertViewDemo
//
//  Created by Alex Jarvis on 25/09/2013.
//  Copyright (c) 2013 Panaxiom Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PXAlertView : UIView

@property (nonatomic, getter = isVisible) BOOL visible;

+ (PXAlertView *)showAlertWithTitle:(NSString *)title;

+ (PXAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message;

+ (PXAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                         completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                        cancelTitle:(NSString *)cancelTitle
                         completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                        cancelTitle:(NSString *)cancelTitle
                         otherTitle:(NSString *)otherTitle
                         completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                        cancelTitle:(NSString *)cancelTitle
                         otherTitle:(NSString *)otherTitle
                        contentView:(UIView *)view
                         completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showAlertWithView:(UIView *)view
                        completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showAlertWithView:(UIView *)view
                       cancelTitle:(NSString *)cancelTitle
                        completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showAlertWithView:(UIView *)view
                       cancelTitle:(NSString *)cancelTitle
                     cancelBgColor:(UIColor *)cancelBgColor
                   cancelTextColor:(UIColor *)cancelTextColor
                       cancelFrame:(CGRect)frame
                        completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showAlertWithView:(UIView *)view
                       cancelTitle:(NSString *)cancelTitle
                     cancelBgColor:(UIColor *)cancelBgColor
                   cancelTextColor:(UIColor *)cancelTextColor
                       cancelFrame:(CGRect)frame
                        otherTitle:(NSString *)otherlTitle
                      otherBgColor:(UIColor *)otherBgColor
                    otherTextColor:(UIColor *)otherTextColor
                        otherFrame:(CGRect)otherFrame
                        completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showBottomAlertWithView:(UIView *)view
                             cancelTitle:(NSString *)cancelTitle
                           cancelBgColor:(UIColor *)cancelBgColor
                         cancelTextColor:(UIColor *)cancelTextColor
                             cancelFrame:(CGRect)frame
                              completion:(void(^) (BOOL cancelled))completion;

+ (PXAlertView *)showAlertWithView:(UIView *)view
                 dismissAfterDelay:(NSTimeInterval)delay
                        completion:(void (^)(BOOL))completion;

- (void)dismiss:(id)sender;
- (void)setCanDismiss:(BOOL)canDismiss;

@end
