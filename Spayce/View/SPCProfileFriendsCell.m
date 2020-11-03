//
//  SPCProfileFriendsCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 8/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileFriendsCell.h"

@interface SPCProfileFriendsCell ()

@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation SPCProfileFriendsCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:230.0/255.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _customContentView.layer.masksToBounds = NO;
        _customContentView.layer.cornerRadius = 2;
        _customContentView.layer.shadowColor = [UIColor blackColor].CGColor;
        _customContentView.layer.shadowOpacity = 0.2;
        _customContentView.layer.shadowRadius = 0.5;
        _customContentView.layer.shadowOffset = CGSizeMake(0, 1);
        [self.contentView addSubview:_customContentView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont spc_profileInfo_boldSectionFont];
        _valueLabel.textColor = [UIColor colorWithWhite:159.0/255.0 alpha:1.0];
        _valueLabel.textAlignment = NSTextAlignmentLeft;
        _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_valueLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_valueLabel.font.lineHeight]];
        
        UICollectionViewFlowLayout *collectionLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_collectionView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:63]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    self.valueLabel.text = nil;
    self.valueLabel.attributedText = nil;
}

#pragma mark - Configuration

- (void)configureWithFriendsCount:(NSInteger)friendsCount mutualFriendsCount:(NSInteger)mutualFriendsCount showsMutualFriends:(BOOL)showsMutualFriends {
    if (showsMutualFriends) {
        NSString *regularText = [NSString stringWithFormat:NSLocalizedString(@"(%@ mutual friends)", nil), @(mutualFriendsCount)];
        NSString *text = [NSString stringWithFormat:NSLocalizedString(@"%@ Friends %@", nil), @(friendsCount), regularText];
        NSDictionary *attributes = @{ NSFontAttributeName: [UIFont spc_profileInfo_boldSectionFont] };
        NSDictionary *subAttributes = @{ NSFontAttributeName: [UIFont spc_profileInfo_regularSectionFont] };
        NSRange range = [text rangeOfString:regularText];
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
        [attributedText setAttributes:subAttributes range:range];
        self.valueLabel.attributedText = attributedText;
    }
    else {
        self.valueLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Friends", nil), @(friendsCount)];
    }
}

@end
