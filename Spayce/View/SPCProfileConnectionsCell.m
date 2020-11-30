//
//  SPCProfileConnectionsCell.m
//  Spayce
//
//  Created by William Santiago on 2014-10-22.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileConnectionsCell.h"

// View
#import "SPCProfileConnectionCell.h"

NSString * SPCProfileDidSelectConnectionNotification = @"SPCProfileDidSelectConnectionNotification";

static NSString *CellIdentifier = @"SPCProfileConnectionCellIdentifier";

static CGFloat cornerRadii = 2;

@interface SPCProfileConnectionsCell () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

// Data
@property (nonatomic) BOOL isCeleb;

@property (nonatomic) NSInteger friendsCount;

@property (nonatomic) NSInteger friendsCellIndex;

// UI
@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation SPCProfileConnectionsCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:241.0/255.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
      
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _customContentView.layer.masksToBounds = YES;
        [self.contentView addSubview:_customContentView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-0]];
        
        UICollectionViewFlowLayout *collectionLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.scrollEnabled = NO;
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [_collectionView registerClass:[SPCProfileConnectionCell class] forCellWithReuseIdentifier:CellIdentifier];
        [_customContentView addSubview:_collectionView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        self.friendsCellIndex = -1;
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.friendsCellIndex = -1;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.customContentView layoutIfNeeded];
    
    // Update corner radiuses
    UIRectCorner cornerStyle = [self cornerForStyle:SPCCellStyleTop];
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.customContentView.bounds byRoundingCorners:cornerStyle cornerRadii:CGSizeMake(cornerRadii, cornerRadii)];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.customContentView.bounds;
    maskLayer.path = maskPath.CGPath;
  
    self.customContentView.layer.mask = maskLayer;
}

#pragma mark - Private

- (void)reloadData {
    NSInteger index = 0;
    // Friends
    self.friendsCellIndex = index++;
  
    [self.collectionView reloadData];
}

- (UIRectCorner)cornerForStyle:(SPCCellStyle)style {
    UIRectCorner corner = 0;
    if (style == SPCCellStyleTop) {
        corner = UIRectCornerTopLeft | UIRectCornerTopRight;
    }
    else if (style == SPCCellStyleBottom) {
        corner = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }
    else if (style == SPCCellStyleSingle) {
        corner = UIRectCornerAllCorners;
    }
    return corner;
}

#pragma mark - Configuration

- (void)configureWithDataSource:(id)dataSource friendsCount:(NSInteger)friendsCount isCeleb:(BOOL)isCeleb {
    self.dataSource = dataSource;
    self.isCeleb = isCeleb;
    self.friendsCount = friendsCount;
    
    [self reloadData];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.frame) / [self collectionView:collectionView numberOfItemsInSection:indexPath.section];
    CGFloat height = CGRectGetHeight(collectionView.frame);
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0.5);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.5;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section; {
    return (self.friendsCellIndex > -1 ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCProfileConnectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    if (indexPath.row == self.friendsCellIndex) {
        cell.tag = SPCProfileConnectionTypeFriends;
        cell.userInteractionEnabled = self.friendsCount > 0;
        cell.valueLabel.text = [NSString stringWithFormat:@"%@", @(self.friendsCount)];
        if (1 == self.friendsCount) {
            cell.titleLabel.text = NSLocalizedString(@"Friend", nil);
        } else {
            cell.titleLabel.text = NSLocalizedString(@"Friends", nil);
        }
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger type = -1;
    
    if (indexPath.row == self.friendsCellIndex) {
        type = SPCProfileConnectionTypeFriends;
    }
    
    if (type >= 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCProfileDidSelectConnectionNotification object:self.dataSource userInfo:@{ @"connectionType": @(type) }];
    }
}

@end
