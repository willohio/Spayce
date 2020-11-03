//
//  SPCSettingsSwitchCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCGroupedCell.h"

typedef void (^SwitchChangeHandler)(id cell, BOOL on);

@interface SPCSettingsSwitchCell : SPCGroupedCell

@property (nonatomic, assign) BOOL on;
@property (nonatomic, copy) SwitchChangeHandler switchChangeHandler;

- (void)configureWithStyle:(SPCGroupedStyle)style image:(UIImage *)image text:(NSString *)text;
- (void)configureWithStyle:(SPCGroupedStyle)style image:(UIImage *)image text:(NSString *)text description:(NSString *)description;

- (void)configureWithStyle:(SPCGroupedStyle)style offImage:(UIImage *)offImage onImage:(UIImage *)onImage text:(NSString *)text;
- (void)configureWithStyle:(SPCGroupedStyle)style offImage:(UIImage *)offImage onImage:(UIImage *)onImage text:(NSString *)text description:(NSString *)description;

@end
