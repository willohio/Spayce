//
//  SPCAlertAction.h
//  Spayce
//
//  Created by William Santiago on 10/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SPCAlertActionStyle) {
    SPCAlertActionStyleNormal = 0,
    SPCAlertActionStyleDestructive = 1,
    SPCAlertActionStyleCancel = 2
};

@interface SPCAlertAction : NSObject

+ (instancetype)actionWithTitle:(NSString *)title
                          style:(SPCAlertActionStyle)style
                        handler:(void (^)(SPCAlertAction *action))handler;

+ (instancetype)actionWithTitle:(NSString *)title
                          style:(SPCAlertActionStyle)style
                          image:(UIImage *)image
                        handler:(void (^)(SPCAlertAction *action))handler;

+ (instancetype)actionWithTitle:(NSString *)title
                       subtitle:(NSString *)subtitle
                          style:(SPCAlertActionStyle)style
                        handler:(void (^)(SPCAlertAction *action))handler;

+ (instancetype)actionWithTitle:(NSString *)title
                       subtitle:(NSString *)subtitle
                          style:(SPCAlertActionStyle)style
                          image:(UIImage *)image
                        handler:(void (^)(SPCAlertAction *action))handler;

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *subtitle;
@property (nonatomic, readonly) SPCAlertActionStyle style;
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, copy, readonly) void (^handler)(SPCAlertAction *action);

@end
