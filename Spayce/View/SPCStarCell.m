//
//  SPCStarCell.m
//  Spayce
//
//  Created by William Santiago on 5/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCStarCell.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

@interface SPCStarCell ()

@property (weak, nonatomic) IBOutlet SPCInitialsImageView *customImageView;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UILabel *customTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *customDetailTextLabel;

@end

@implementation SPCStarCell

#pragma mark - Object lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.customImageView.textLabel.font = [UIFont spc_placeholderFont];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
    
    self.customImageView.image = nil;
    self.timestampLabel.text = nil;
    self.customTextLabel.text = nil;
    self.customDetailTextLabel.text = nil;
}

#pragma mark - Configuration

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle timestampText:(NSString *)timestampText url:(NSURL *)url {
    self.customTextLabel.text = title;
    self.customDetailTextLabel.text = subtitle;
    self.timestampLabel.text = timestampText;
    
    [self.customImageView configureWithText:[title.firstLetter capitalizedString] url:url];
}

@end
