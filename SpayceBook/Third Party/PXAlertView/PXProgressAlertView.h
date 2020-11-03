//
//  PXProgressAlertView.h
//  PXProgressAlertViewDemo
//
//  Created by Alex Jarvis on 25/09/2013.
//  Copyright (c) 2013 Panaxiom Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PXProgressAlertView : UIView

@property (nonatomic, getter = isVisible) BOOL visible;
@property (nonatomic) UIView *alertView;

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress;

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress;

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
                                 completion:(void(^) (BOOL cancelled))completion;

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                cancelTitle:(NSString *)cancelTitle
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
                                 completion:(void(^) (BOOL cancelled))completion;

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                cancelTitle:(NSString *)cancelTitle
                                 otherTitle:(NSString *)otherTitle
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
                                 completion:(void(^) (BOOL cancelled))completion;

+ (PXProgressAlertView *)showAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                cancelTitle:(NSString *)cancelTitle
                                 otherTitle:(NSString *)otherTitle
                                contentView:(UIView *)view
                                      ticks:(NSInteger)ticks
                                   progress:(NSInteger)progress
                                 completion:(void(^) (BOOL cancelled))completion;

@end
