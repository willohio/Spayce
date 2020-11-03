//
//  SPCProfileTitleView.h
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-20.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileTitleView : UIView

- (void)configureWithName:(NSString *)name handle:(NSString *)handle isCeleb:(BOOL)isCeleb useLightContent:(BOOL)useLightContent;

@end
