//
//  SPCInitialsImageView.h
//  Spayce
//
//  Created by William Santiago on 9/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCInitialsImageView : UIImageView

@property (nonatomic, strong) UILabel *textLabel;

- (void)prepareForReuse;

- (void)configureWithText:(NSString *)text url:(NSURL *)url;

@end
