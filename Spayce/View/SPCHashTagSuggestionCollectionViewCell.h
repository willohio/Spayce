//
//  SPCHashTagSuggestionCollectionViewCell.h
//  Spayce
//
//  Created by Christopher Taylor on 12/11/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCHashTagSuggestionCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *tagLabel;

-(void)configureWithHashTag:(NSString *)hashTag selected:(BOOL)selected;
@end
