//
//  SPCTerritoryMemoryCell.m
//  Spayce
//
//  Created by Jake Rosin on 11/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTerritoryMemoryCell.h"

// Utils
#import "UIImageView+WebCache.h"
#import "NSString+SPCAdditions.h"

// Model
#import "Memory.h"
#import "Person.h"
#import "Venue.h"
#import "Asset.h"

@interface SPCTerritoryMemoryCell()

@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UILabel *mostPopularLabel;
@property (nonatomic, strong) UILabel *memoryTextLabel;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UILabel *starCountLabel;
@property (nonatomic, strong) UILabel *commentCountLabel;

@property (nonatomic, strong) UIImageView *starIcon;
@property (nonatomic, strong) UIImageView *commentIcon;
@property (nonatomic, strong) UIImageView *memoryImageView;

@property (nonatomic, strong) NSLayoutConstraint *memoryTextHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *starCountWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *commentCountWidthConstraint;


@end

@implementation SPCTerritoryMemoryCell

- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.frame = frame;
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _customContentView.layer.masksToBounds = YES;
        [self.contentView addSubview:_customContentView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        _memoryImageView = [[UIImageView alloc] init];
        _memoryImageView.contentMode = UIViewContentModeScaleAspectFill;
        _memoryImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _memoryImageView.layer.masksToBounds = YES;
        _memoryImageView.backgroundColor = [UIColor colorWithRGBHex:0xacb6c6];
        [_customContentView addSubview:_memoryImageView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_memoryImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:13]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_memoryImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:13]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_memoryImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-13]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_memoryImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-26]];
        
        _mostPopularLabel = [[UILabel alloc] init];
        _mostPopularLabel.adjustsFontSizeToFitWidth = YES;
        _mostPopularLabel.minimumScaleFactor = 0.75;
        _mostPopularLabel.font = [UIFont spc_boldSystemFontOfSize:8];
        _mostPopularLabel.textAlignment = NSTextAlignmentLeft;
        _mostPopularLabel.textColor = [UIColor colorWithRGBHex:0xacb6c6];
        _mostPopularLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _mostPopularLabel.text = @"MOST POPULAR MEMORY";
        [_customContentView addSubview:_mostPopularLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_mostPopularLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:15]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_mostPopularLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_mostPopularLabel.font.lineHeight]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_mostPopularLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_memoryImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_mostPopularLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-12]];
        
        _memoryTextLabel = [[UILabel alloc] init];
        _memoryTextLabel.adjustsFontSizeToFitWidth = YES;
        _memoryTextLabel.minimumScaleFactor = 0.75;
        _memoryTextLabel.font = [UIFont spc_regularSystemFontOfSize:12];
        _memoryTextLabel.textAlignment = NSTextAlignmentLeft;
        _memoryTextLabel.textColor = [UIColor colorWithRGBHex:0x14294b];
        _memoryTextLabel.numberOfLines = 3;
        _memoryTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_memoryTextLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_memoryTextLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_mostPopularLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:_memoryTextLabel.font.lineHeight * 1.5]];
        _memoryTextHeightConstraint = [NSLayoutConstraint constraintWithItem:_memoryTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_memoryTextLabel.font.lineHeight * 3];
        [_customContentView addConstraint:_memoryTextHeightConstraint];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_memoryTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_memoryImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_memoryTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-12]];
        
        
        _locationLabel = [[UILabel alloc] init];
        _locationLabel.adjustsFontSizeToFitWidth = YES;
        _locationLabel.minimumScaleFactor = 0.75;
        _locationLabel.font = [UIFont spc_regularSystemFontOfSize:9];
        _locationLabel.textAlignment = NSTextAlignmentLeft;
        _locationLabel.textColor = [UIColor colorWithRGBHex:0xacb6c6];
        _locationLabel.numberOfLines = 1;
        _locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_locationLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_locationLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_memoryTextLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_locationLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_locationLabel.font.lineHeight]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_locationLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_memoryImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_locationLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-12]];
        
        
        _starCountLabel = [[UILabel alloc] init];
        _starCountLabel.adjustsFontSizeToFitWidth = YES;
        _starCountLabel.minimumScaleFactor = 0.75;
        _starCountLabel.font = [UIFont spc_boldSystemFontOfSize:18];
        _starCountLabel.textAlignment = NSTextAlignmentLeft;
        _starCountLabel.textColor = [UIColor colorWithRGBHex:0x14294b];
        _starCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_starCountLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starCountLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_memoryImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:2]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starCountLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_starCountLabel.font.lineHeight]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starCountLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_memoryImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        _starCountWidthConstraint = [NSLayoutConstraint constraintWithItem:_starCountLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50];
        [_customContentView addConstraint:_starCountWidthConstraint];
        
        
        _starIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"territory-memory-star"]];
        _starIcon.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_starIcon];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starIcon attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_starCountLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:3]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_starIcon attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_starCountLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:1]];
        
        
        _commentCountLabel = [[UILabel alloc] init];
        _commentCountLabel.adjustsFontSizeToFitWidth = YES;
        _commentCountLabel.minimumScaleFactor = 0.75;
        _commentCountLabel.font = [UIFont spc_boldSystemFontOfSize:18];
        _commentCountLabel.textAlignment = NSTextAlignmentLeft;
        _commentCountLabel.textColor = [UIColor colorWithRGBHex:0x14294b];
        _commentCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_commentCountLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_commentCountLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_starCountLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_commentCountLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_commentCountLabel.font.lineHeight]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_commentCountLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_starIcon attribute:NSLayoutAttributeRight multiplier:1.0 constant:15]];
        _commentCountWidthConstraint = [NSLayoutConstraint constraintWithItem:_commentCountLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50];
        [_customContentView addConstraint:_commentCountWidthConstraint];
        
        
        _commentIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"territory-memory-comment"]];
        _commentIcon.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_commentIcon];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_commentIcon attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_commentCountLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:4]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_commentIcon attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_commentCountLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:1]];
    }
    return self;
}



- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.memoryTextLabel.text = nil;
    self.locationLabel.text = nil;
    self.starCountLabel.text = nil;
    self.commentCountLabel.text = nil;
    
    [self.memoryImageView sd_cancelCurrentImageLoad];
    self.memoryImageView.image = nil;
}


#pragma mark - Configuration

- (void)configureWithMemory:(Memory *)memory {
    CGSize frameSize = CGSizeMake(self.frame.size.width-135, self.memoryTextLabel.font.lineHeight*3);
    NSString *memoryText = [memory.text stringByEllipsizingWithSize:frameSize attributes:@{NSFontAttributeName : self.memoryTextLabel.font}];
    self.memoryTextLabel.text = memoryText;
    CGRect rect = [memoryText boundingRectWithSize:frameSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : self.memoryTextLabel.font} context:nil];
    self.memoryTextHeightConstraint.constant = ceil(CGRectGetHeight(rect));
    
    self.locationLabel.text = [NSString stringWithFormat:@"- Anchored at %@", memory.venue.displayNameTitle];
    
    self.starCountLabel.text = [NSString stringWithFormat:@"%i", (int)memory.starsCount];
    self.commentCountLabel.text = [NSString stringWithFormat:@"%i", (int)memory.commentsCount];
    
    self.starCountWidthConstraint.constant = [self.starCountLabel.text sizeWithAttributes:@{NSFontAttributeName : self.starCountLabel.font}].width;
    self.commentCountWidthConstraint.constant = [self.commentCountLabel.text sizeWithAttributes:@{NSFontAttributeName : self.commentCountLabel.font}].width;
    
    Asset *asset;
    if (memory.type == MemoryTypeImage) {
        asset = ((ImageMemory *)memory).images[0];
    } else if (memory.type == MemoryTypeVideo) {
        asset = ((VideoMemory *)memory).previewImages[0];
    } else {
        asset = memory.author.imageAsset;
    }
    
    [self.memoryImageView sd_setImageWithURL:[NSURL URLWithString:[asset imageUrlHalfSquare]]];
    
    [self.contentView setNeedsUpdateConstraints];
}


@end
