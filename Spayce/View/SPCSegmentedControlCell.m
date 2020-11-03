//
//  SPCSegmentedControlCell.m
//  Spayce
//
//  Created by Arria P. Owlia on 12/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSegmentedControlCell.h"

@interface SPCSegmentedControlCell()

@property (nonatomic, strong) UIView *separatorMiddle;
@property (nonatomic, strong) UIView *separatorLeft;
@property (nonatomic, strong) UIView *separatorRight;
@property (nonatomic, strong) UIView *separatorBottom;

@end

@implementation SPCSegmentedControlCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 2;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.clipsToBounds = YES;
        
        self.segmentedControl = [[HMSegmentedControl alloc] init];
        self.segmentedControl.backgroundColor = [UIColor clearColor];
        self.segmentedControl.selectedTextColor = [UIColor colorWithRGBHex:0x4cb0fb];
        self.segmentedControl.textColor = [UIColor colorWithRGBHex:0x8b99af];
        self.segmentedControl.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        self.segmentedControl.selectionIndicatorHeight = 3.0f;
        self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRGBHex:0x4cb0fb];
        self.segmentedControl.selectionIndicatorEdgeInsets = UIEdgeInsetsMake(0, 0, -1.0f/[UIScreen mainScreen].scale, 0);
        self.segmentedControl.layer.shadowColor = [UIColor colorWithRGBHex:0xb8c1c9].CGColor;
        self.segmentedControl.layer.shadowOffset = CGSizeMake(0, 1.0f/[UIScreen mainScreen].scale);
        self.segmentedControl.layer.shadowOpacity = 0.50f;
        self.segmentedControl.layer.shadowRadius = 1.0f/[UIScreen mainScreen].scale;
        [self.contentView addSubview:_segmentedControl];
        
        self.separatorMiddle = [[UIView alloc] init];
        self.separatorMiddle.backgroundColor = [UIColor colorWithRGBHex:0xb8c1c9];
        self.separatorMiddle.hidden = YES;
        [self.contentView addSubview:_separatorMiddle];
        
        self.separatorLeft = [[UIView alloc] init];
        self.separatorLeft.backgroundColor = [UIColor colorWithRGBHex:0xb8c1c9];
        self.separatorLeft.hidden = YES;
        [self.contentView addSubview:_separatorLeft];
        
        self.separatorRight = [[UIView alloc] init];
        self.separatorRight.backgroundColor = [UIColor colorWithRGBHex:0xb8c1c9];
        self.separatorRight.hidden = YES;
        [self.contentView addSubview:_separatorRight];
        
        self.separatorBottom = [[UIView alloc] init];
        self.separatorBottom.backgroundColor = [UIColor colorWithRGBHex:0xe6e7e7];
        [self.contentView addSubview:_separatorBottom];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    self.segmentedControl.frame = self.contentView.bounds;
    
    CGFloat separatorWidth = 1.0f / [UIScreen mainScreen].scale;
    CGFloat separatorHeight = 17.0f;
    
    self.separatorMiddle.frame = CGRectMake(CGRectGetMidX(self.frame) - separatorWidth / 2, 11.5, separatorWidth, separatorHeight);
    self.separatorLeft.frame = CGRectMake(CGRectGetWidth(self.frame) / 3 - separatorWidth / 2, 11.5, separatorWidth, separatorHeight);
    self.separatorRight.frame = CGRectMake(CGRectGetWidth(self.frame) * 2 / 3 - separatorWidth / 2, 11.5, separatorWidth, separatorHeight);
    
    self.separatorBottom.frame = CGRectMake(0, CGRectGetHeight(self.frame) - separatorWidth, CGRectGetWidth(self.frame), separatorWidth); // Width -> height in this case (horizontal bottom separator)
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Remove all items
    self.segmentItems = nil;
    
    // Hide the separators
    self.separatorMiddle.hidden = YES;
    self.separatorLeft.hidden = YES;
    self.separatorRight.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

# pragma mark - Configuration

- (void)configureWithTitles:(NSArray *)titles {
    self.segmentedControl.sectionTitles = titles;
    
    if (2 == [titles count]) {
        self.separatorMiddle.hidden = NO;
    } else if (3 == [titles count]) {
        self.separatorLeft.hidden = NO;
        self.separatorRight.hidden = NO;
    }
}

@end
