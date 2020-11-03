//
//  SPCNoResultsCollectionViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 12/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCNoResultsCollectionViewCell.h"

@implementation SPCNoResultsCollectionViewCell



- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.msgLbl = [[UILabel alloc] init];
        self.msgLbl.textColor = [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f];
        self.msgLbl.font = [UIFont spc_regularSystemFontOfSize:14];
        self.msgLbl.text = @"No memories with #hashtags here";
        self.msgLbl.numberOfLines = 0;
        self.msgLbl.lineBreakMode = NSLineBreakByWordWrapping;
        self.msgLbl.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.msgLbl];
        
    }
    return self;
}


-(void)layoutSubviews {
    
    self.msgLbl.frame = CGRectMake(20, 0, self.contentView.bounds.size.width - 40, self.contentView.bounds.size.height/2);
    
}
@end