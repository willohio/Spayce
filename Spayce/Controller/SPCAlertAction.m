//
//  SPCAlertAction.m
//  Spayce
//
//  Created by William Santiago on 10/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAlertAction.h"

@interface SPCAlertAction ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic) SPCAlertActionStyle style;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) void (^handler)(SPCAlertAction *action);

@end

@implementation SPCAlertAction

+ (instancetype)actionWithTitle:(NSString *)title
                          style:(SPCAlertActionStyle)style
                        handler:(void (^)(SPCAlertAction *action))handler {
    return [SPCAlertAction actionWithTitle:title
                                  subtitle:nil
                                     style:style
                                     image:nil
                                   handler:handler];
}

+ (instancetype)actionWithTitle:(NSString *)title
                          style:(SPCAlertActionStyle)style
                          image:(UIImage *)image
                        handler:(void (^)(SPCAlertAction *action))handler {
    return [SPCAlertAction actionWithTitle:title
                                  subtitle:nil
                                     style:style
                                     image:image
                                   handler:handler];
}


+ (instancetype)actionWithTitle:(NSString *)title
                       subtitle:(NSString *)subtitle
                          style:(SPCAlertActionStyle)style
                        handler:(void (^)(SPCAlertAction *action))handler {
    return [SPCAlertAction actionWithTitle:title
                                  subtitle:subtitle
                                     style:style
                                     image:nil
                                   handler:handler];
}

+ (instancetype)actionWithTitle:(NSString *)title
                       subtitle:(NSString *)subtitle
                          style:(SPCAlertActionStyle)style
                          image:(UIImage *)image
                        handler:(void (^)(SPCAlertAction *action))handler {
    SPCAlertAction *action = [[SPCAlertAction alloc] init];
    if (action) {
        action.title = title;
        action.subtitle = subtitle;
        action.style = style;
        action.image = image;
        action.handler = handler;
    }
    return action;
}

@end
