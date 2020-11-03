//
//  SignUpTextFieldCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignUpProfileButton.h"

typedef NS_ENUM(NSInteger, TextFieldCellType) {
    TextFieldCellTypeSingle,
    TextFieldCellTypeDouble
};

// Factory class for SignUpSingleTextFieldCell and SignUpDoubleTextFieldCell
@interface SignUpTextFieldCell : UITableViewCell

+ (id)createCellWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier type:(NSInteger)type;

@property (nonatomic, strong) NSArray *textFields;
@property(nonatomic,assign) BOOL top,down;
@property(nonatomic,strong) UIImageView *iconImgView;
@property (nonatomic, strong) SignUpProfileButton *button;
@end
