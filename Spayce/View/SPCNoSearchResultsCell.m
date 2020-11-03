//
//  SPCNoSearchResultsCell.m
//  Spayce
//
//  Created by Christopher Taylor on 10/8/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCNoSearchResultsCell.h"
@interface SPCNoSearchResultsCell ()

@end

@implementation SPCNoSearchResultsCell

#pragma mark - NSObject - Responding to Being Loaded from a Nib File

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithRed:248.0f/255.0f green:248.0f/255.0f blue:248.0f/255.0f alpha:1.0f];
        
        self.msgLbl = [[UILabel alloc] init];
        self.msgLbl.textColor = [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f];
        self.msgLbl.font = [UIFont spc_regularSystemFontOfSize:14];
        self.msgLbl.text = @"No results. Search again.";
        self.msgLbl.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.msgLbl];

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.noFriendsResult) {
        self.msgLbl.frame = CGRectMake(0, 20, self.contentView.frame.size.width, 20);
    }
    else {
        self.msgLbl.frame = CGRectMake(0, 20+5, self.contentView.frame.size.width, 20);
    }
}

@end
