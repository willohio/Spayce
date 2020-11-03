//
//  SPCVenueSegmentedControlCell.m
//  Spayce
//
//  Created by Jake Rosin on 4/9/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCVenueSegmentedControlCell.h"

NSString *SPCVenueSegmentedControlCellIdentifier = @"SPCVenueSegmentedControlCellIdentifier";

@interface SPCVenueSegmentedControlCell()

// UI
// # of memories
@property (nonatomic, strong) UIButton *btnNumMemories; // Button captures the touches, rather than the cell
// Grid segment
@property (nonatomic, strong) UILabel *lblGrid;
@property (nonatomic, strong) UIImageView *ivGrid;
@property (nonatomic, strong) UIButton *btnGrid;
// List segment
@property (nonatomic, strong) UILabel *lblList;
@property (nonatomic, strong) UIImageView *ivList;
@property (nonatomic, strong) UIButton *btnList;
// Separators
@property (nonatomic, strong) UIView *separatorLeft;
@property (nonatomic, strong) UIView *separatorRight;

@end

@implementation SPCVenueSegmentedControlCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.contentView.backgroundColor = [UIColor colorWithRGBHex:0xf8f8f8];
        
        // Separators
        _separatorLeft = [[UIView alloc] init];
        _separatorLeft.backgroundColor = [UIColor colorWithRGBHex:0xdddddd];
        [self.contentView addSubview:_separatorLeft];
        _separatorRight = [[UIView alloc] init];
        _separatorRight.backgroundColor = [UIColor colorWithRGBHex:0xdddddd];
        [self.contentView addSubview:_separatorRight];
        
        // # of memories label
        _btnNumMemories = [[UIButton alloc] init];
        [_btnNumMemories setTitleColor:[UIColor colorWithRGBHex:0xbbbdc1] forState:UIControlStateNormal];
        [self.contentView addSubview:_btnNumMemories];
        
        // Grid
        _lblGrid = [[UILabel alloc] init];
        _lblGrid.textAlignment = NSTextAlignmentCenter;
        _lblGrid.font = [UIFont fontWithName:@"OpenSans-Semibold" size:8.0f];
        _lblGrid.text = @"TILE";
        [self.contentView addSubview:_lblGrid];
        _ivGrid = [[UIImageView alloc] init];
        _ivGrid.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_ivGrid];
        _btnGrid = [[UIButton alloc] init];
        _btnGrid.backgroundColor = [UIColor clearColor];
        [_btnGrid addTarget:self action:@selector(tappedGridButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_btnGrid];
        
        // List
        _lblList = [[UILabel alloc] init];
        _lblList.textAlignment = NSTextAlignmentCenter;
        _lblList.font = [UIFont fontWithName:@"OpenSans-Semibold" size:8.0f];
        _lblList.text = @"LIST";
        [self.contentView addSubview:_lblList];
        _ivList = [[UIImageView alloc] init];
        _ivList.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_ivList];
        _btnList = [[UIButton alloc] init];
        _btnList.backgroundColor = [UIColor clearColor];
        [_btnList addTarget:self action:@selector(tappedListButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_btnList];
        
        self.memoryCellDisplayType = MemoryCellDisplayTypeGrid;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Content View
    self.contentView.frame = self.bounds;
    
    CGFloat PSD_WIDTH = 750.0f;
    CGFloat PSD_HEIGHT = 90.0f;
    CGFloat viewWidth = CGRectGetWidth(self.contentView.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.contentView.bounds);
    
    // Separators
    CGFloat separatorWidth = 1.0f / [UIScreen mainScreen].scale;
    CGFloat separatorHeight = 34.0f/90.0f * CGRectGetHeight(self.bounds);
    self.separatorLeft.frame = CGRectMake(CGRectGetWidth(self.bounds) / 3 - separatorWidth / 2, 28.0f/90.0f * viewHeight, separatorWidth, separatorHeight);
    self.separatorRight.frame = CGRectMake(CGRectGetWidth(self.bounds) * 2 / 3 - separatorWidth / 2, 28.0f/90.0f * viewHeight, separatorWidth, separatorHeight);
    
    // # Memories segment - placed in the center of the first 1/3 of the segment
    self.btnNumMemories.frame = CGRectMake(0, 0, viewWidth/3.0f, viewHeight);
    self.btnNumMemories.center = CGPointMake(viewWidth/6.0f, viewHeight/2.0f);
    
    // Grid segment
    self.btnGrid.frame = CGRectMake(0, 0, viewWidth/3.0f, viewHeight);
    self.btnGrid.center = self.contentView.center;
    [self.lblGrid sizeToFit];
    self.lblGrid.center = CGPointMake(self.contentView.center.x, 65.0f/PSD_HEIGHT * viewHeight);
    self.ivGrid.frame = CGRectMake(0, 0, 34.0f/PSD_WIDTH * viewWidth, 22.0f/PSD_HEIGHT * viewHeight);
    self.ivGrid.center = CGPointMake(self.contentView.center.x, 37.0f/PSD_HEIGHT * viewHeight);
    
    // List segment
    self.btnList.frame = CGRectMake(0, 0, viewWidth/3.0f, viewHeight);
    self.btnList.center = CGPointMake(viewWidth * 5.0f/6.0f, self.contentView.center.y);
    [self.lblList sizeToFit];
    self.lblList.center = CGPointMake(viewWidth * 5.0f/6.0f, 65.0f/PSD_HEIGHT * viewHeight);
    self.ivList.frame = CGRectMake(0, 0, 32.0f/PSD_WIDTH * viewWidth, 22.0f/PSD_HEIGHT * viewHeight);
    self.ivList.center = CGPointMake(viewWidth * 5.0f/6.0f, 36.0f/PSD_HEIGHT * viewHeight);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear the # of memories label
    [self.btnNumMemories setTitle:@"" forState:UIControlStateNormal];
    
    // Let's not edit the MemoryCellDisplayType state, as we don't want the state to change if this cell mvoes off-screen, then comes back on-screen (is re-used)
}

# pragma mark - Configuration

- (void)configureWithNumberOfMemories:(NSInteger)numberOfMemories {
    NSString *strNumMemories = nil;
    if (0 == numberOfMemories) {
        strNumMemories = NSLocalizedString(@"No Moments", nil);
    } else if (1 == numberOfMemories) {
        strNumMemories = [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"moment", nil)];
    } else {
        strNumMemories = [NSString stringWithFormat:@"%lu %@", (long)numberOfMemories, NSLocalizedString(@"moments", nil)];
    }
    
    [self.btnNumMemories setAttributedTitle:[[NSAttributedString alloc] initWithString:strNumMemories attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:11.0f], NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0xbbbdc1]}] forState:UIControlStateNormal];
}

#pragma mark - Target-Actions

- (void)tappedGridButton:(id)sender {
    self.memoryCellDisplayType = MemoryCellDisplayTypeGrid;
}

- (void)tappedListButton:(id)sender {
    self.memoryCellDisplayType = MemoryCellDisplayTypeList;
}

#pragma mark - Segmented Control

- (void)setMemoryCellDisplayType:(MemoryCellDisplayType)memoryCellDisplayType {
    if (memoryCellDisplayType != self.memoryCellDisplayType) {
        if (MemoryCellDisplayTypeGrid == memoryCellDisplayType) {
            // 'Select' grid segment
            self.lblGrid.textColor = [UIColor colorWithRGBHex:0x4cb0fb];
            self.ivGrid.image = [UIImage imageNamed:@"profile-grid-blue-icon"];
            
            // Deselect list segment
            self.lblList.textColor = [UIColor colorWithRGBHex:0x898989];
            self.ivList.image = [UIImage imageNamed:@"profile-list-gray-icon"];
        } else if (MemoryCellDisplayTypeList == memoryCellDisplayType) {
            // 'Select list segment
            self.lblList.textColor = [UIColor colorWithRGBHex:0x4cb0fb];
            self.ivList.image = [UIImage imageNamed:@"profile-list-blue-icon"];
            
            // Deselect grid segment
            self.lblGrid.textColor = [UIColor colorWithRGBHex:0x898989];
            self.ivGrid.image = [UIImage imageNamed:@"profile-grid-gray-icon"];
        }
        
        _memoryCellDisplayType = memoryCellDisplayType;
        
        if ([self.delegate respondsToSelector:@selector(tappedMemoryCellDisplayType:onVenueSegmentedControl:)]) {
            [self.delegate tappedMemoryCellDisplayType:memoryCellDisplayType onVenueSegmentedControl:self];
        }
    }
}

@end