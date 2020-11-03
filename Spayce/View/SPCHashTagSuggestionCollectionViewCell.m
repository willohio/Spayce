//
//  SPCHashTagSuggestionCollectionViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 12/11/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHashTagSuggestionCollectionViewCell.h"

@interface SPCHashTagSuggestionCollectionViewCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIColor *baseBGColor;
@property (nonatomic, strong) UIColor *selectedBGColor;
@property (nonatomic, strong) UIColor *baseTextColor;
@property (nonatomic, strong) UIColor *selectedTextColor;

@end

@implementation SPCHashTagSuggestionCollectionViewCell

#pragma mark - Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.baseBGColor = [UIColor colorWithRed:213.0f/255.0f green:218.0f/255.0f blue:223.0f/255.0f alpha:1.0f];
        self.baseTextColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
        self.selectedBGColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        self.selectedTextColor = [UIColor whiteColor];
        
        self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 30)];
        self.containerView.backgroundColor = self.baseBGColor;
        self.containerView.layer.cornerRadius = 14;
        self.containerView.clipsToBounds = YES;
        [self.contentView addSubview:self.containerView];
        
        self.tagLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.containerView.frame.size.width - 30, 30)];
        self.tagLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        self.tagLabel.textColor = self.baseTextColor;
        self.tagLabel.textAlignment = NSTextAlignmentCenter;
        self.tagLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.containerView addSubview:self.tagLabel];
        
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.tagLabel.text = @"";
    self.backgroundColor = [UIColor clearColor];
}


-(void)configureWithHashTag:(NSString *)hashTag selected:(BOOL)selected {
    
    self.tagLabel.text = hashTag;
    self.containerView.frame = CGRectMake(0, 0, self.bounds.size.width, 30);
    self.tagLabel.frame = CGRectMake(15, 0, self.containerView.frame.size.width - 30, 30);
    
    if (selected ) {
        self.containerView.backgroundColor = self.selectedBGColor;
        self.tagLabel.textColor = self.selectedTextColor;
    }
    else {
        self.containerView.backgroundColor = self.baseBGColor;
        self.tagLabel.textColor = self.baseTextColor;
    }
}

@end
