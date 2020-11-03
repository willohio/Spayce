//
//  SPCProfileRecentCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-24.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileRecentCell.h"

// Model
#import "Person.h"

// Category
#import "UIImageView+WebCache.h"

@interface SPCProfileRecentCell ()

@property (nonatomic, strong) UIView *customBackgroundView;
@property (nonatomic, strong) UIImageView *customImageView;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UILabel *customDetailTextLabel;

@end

@implementation SPCProfileRecentCell

#pragma mark - Object lifecycle

- (void)dealloc {
    [self.customImageView sd_cancelCurrentImageLoad];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:241.0/255.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _customBackgroundView = [[UIView alloc] init];
        _customBackgroundView.backgroundColor = [UIColor whiteColor];
        _customBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _customBackgroundView.layer.cornerRadius = 2;
        _customBackgroundView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        _customBackgroundView.layer.shadowOpacity = 0.2;
        _customBackgroundView.layer.shadowRadius = 0.5;
        _customBackgroundView.layer.shadowOffset = CGSizeMake(0, 0.5);
        [self.contentView addSubview:_customBackgroundView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-2]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        
        _customImageView = [[UIImageView alloc] init];
        _customImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _customImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _customImageView.layer.borderWidth = 3;
        [_customBackgroundView addSubview:_customImageView];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:3]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:74]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:74]];
        
        _timestampLabel = [[UILabel alloc] init];
        _timestampLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        _timestampLabel.textColor = [UIColor colorWithRed:172.0/255.0 green:182.0/255.0 blue:198.0/255.0 alpha:1.0];
        _timestampLabel.textAlignment = NSTextAlignmentRight;
        _timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customBackgroundView addSubview:_timestampLabel];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_timestampLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_timestampLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_timestampLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:5]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_timestampLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_timestampLabel.font.lineHeight]];
        
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.numberOfLines = 0;
        _customTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customBackgroundView addSubview:_customTextLabel];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_timestampLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:5]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:2 * _customTextLabel.font.lineHeight]];
        
        _customDetailTextLabel = [[UILabel alloc] init];
        _customDetailTextLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        _customDetailTextLabel.textColor = [UIColor colorWithRed:139.0/255.0 green:153.0/255.0 blue:175.0/255.0 alpha:1.0];
        _customDetailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customBackgroundView addSubview:_customDetailTextLabel];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customDetailTextLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customTextLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customDetailTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customDetailTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:5]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customDetailTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customDetailTextLabel.font.lineHeight]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.timestampLabel.text = nil;
    self.customTextLabel.attributedText = nil;
    self.customDetailTextLabel.text = nil;
    
    [self.customImageView sd_cancelCurrentImageLoad];
    self.customImageView.image = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    self.customBackgroundView.backgroundColor = selected ? [UIColor colorWithWhite:0.98 alpha:1.0] : [UIColor whiteColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    self.customBackgroundView.backgroundColor = highlighted ? [UIColor colorWithWhite:0.98 alpha:1.0] : [UIColor whiteColor];
}

#pragma mark - Configuration

- (void)configureWithUrlString:(NSString *)urlString author:(NSString *)author friends:(NSArray *)friends timestamp:(NSString *)timestamp text:(NSString *)text detailedText:(NSString *)detailedText {
    NSMutableString *mutableText = [[NSMutableString alloc] init];
    [mutableText appendFormat:NSLocalizedString(@"%@", nil), author];
    
    NSRange authorRange = NSMakeRange(0, mutableText.length);
    NSRange friendRange = NSMakeRange(0, 0);
    
    [mutableText appendString:@" recently made a memory"];
    if (friends.count > 0) {
        Person *friend = friends[0];
        
        [mutableText appendString:@" with "];
        
        friendRange = NSMakeRange(mutableText.length, friend.displayName.length);
        
        [mutableText appendFormat:@"%@", friend.displayName];
        
        if (friends.count > 1) {
            [mutableText appendFormat:@" and %@ others", @(friends.count - 1)];
        }
    }
    [mutableText appendString:@"."];
    
    // Font
    UIColor *foregroundColor = [UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0];
    
    UIFont *normalFont = [UIFont spc_regularSystemFontOfSize:14];
    UIFont *highlightedFont = [UIFont spc_boldSystemFontOfSize:14];
    
    // Paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setMaximumLineHeight:0.9 /* magic number indeed */ * normalFont.lineHeight];
    
    // Attributed text
    NSDictionary *normalAttributes = @{
                                       NSFontAttributeName: normalFont,
                                       NSForegroundColorAttributeName: foregroundColor,
                                       NSParagraphStyleAttributeName: paragraphStyle
                                       };
    NSDictionary *highlightedAttributes = @{
                                            NSFontAttributeName: highlightedFont,
                                            NSForegroundColorAttributeName: foregroundColor
                                            };
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:mutableText attributes:nil];
    [attributedText addAttributes:normalAttributes range:NSMakeRange(0, mutableText.length)];
    [attributedText addAttributes:highlightedAttributes range:authorRange];
    [attributedText addAttributes:highlightedAttributes range:friendRange];
    
    self.timestampLabel.text = timestamp;
    self.customTextLabel.attributedText = attributedText;
    self.customDetailTextLabel.text = detailedText;
    
    if (urlString.length > 0) {
        [self.customImageView sd_setImageWithURL:[NSURL URLWithString:urlString]];
    }
}

@end
