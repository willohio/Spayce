//
//  MemoryActionButton.h
//  Spayce
//
//  Created by Pavel Dušátko on 12/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemoryActionButton : UIButton {

}

@property (nonatomic, assign) CGFloat imageSize;
@property (nonatomic, assign) UIRectCorner roundedCorners;
@property (nonatomic, strong) UIColor *color;
@property (assign, nonatomic) BOOL clearBg;

- (void)configureWithIconImage:(UIImage *)iconImage clearBG:(BOOL)clearBG;
- (void)configureWithIconImage:(UIImage *)iconImage rounded:(BOOL)rounded clearBG:(BOOL)clearBG;
- (void)configureWithIconImage:(UIImage *)iconImage count:(NSInteger)count clearBG:(BOOL)clearBG;
- (void)configureWithIconImage:(UIImage *)iconImage count:(NSInteger)count rounded:(BOOL)rounded clearBG:(BOOL)clearBG;

@end
