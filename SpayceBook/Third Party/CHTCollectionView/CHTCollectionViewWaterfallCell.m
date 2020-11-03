//
//  UICollectionViewWaterfallCell.m
//  Demo
//
//  Created by Nelson on 12/11/27.
//  Copyright (c) 2012年 Nelson. All rights reserved.
//

#import "CHTCollectionViewWaterfallCell.h"
#import "UIImageView+WebCache.h"
#import "Asset.h"

@implementation CHTCollectionViewWaterfallCell

#pragma mark - Accessors

- (UILabel *)displayLabel {
	if (!_displayLabel) {
        CGRect textFrame = CGRectMake(5.f, 5.f, CGRectGetMaxX(self.contentView.bounds)-10, CGRectGetMaxY(self.contentView.bounds)-10);
        
        _displayLabel = [[UILabel alloc] initWithFrame:textFrame];
		_displayLabel.backgroundColor = [UIColor clearColor];
		_displayLabel.textColor = [UIColor colorWithWhite:187.0f/255.0f alpha:1.0f];
		_displayLabel.textAlignment = NSTextAlignmentLeft;
        _displayLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
        _displayLabel.numberOfLines = 0;
        _displayLabel.lineBreakMode = NSLineBreakByWordWrapping;
	}
	return _displayLabel;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        CGRect imageViewFrame = CGRectMake(0.f, 0.f, CGRectGetMaxX(self.contentView.bounds), CGRectGetMaxY(self.contentView.bounds));
        _imageView.frame = imageViewFrame;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.backgroundColor = [UIColor colorWithWhite:105.0f/255.0f alpha:1.0f];
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}

- (UIImageView *)vidBtn {
 
    if (!_vidBtn) {
        UIImage *vidBtnImg = [UIImage imageNamed:@"lookBack-vidBtn"];
        _vidBtn = [[UIImageView alloc] initWithImage:vidBtnImg];
    }
    return _vidBtn;
}

- (UIImage *)gradientImage
{
    CGFloat width = 156;
    CGFloat height = self.displayLabel.frame.size.height;
    
    // create a new bitmap image context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // push context to make it current (need to do this manually because we are not drawing in a UIView)
    UIGraphicsPushContext(context);
    
    //draw gradient
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 121.0f/255.0f, 191.0f/255.0f, 221.0f/255.0f, 1.0,  // Start color
        180.0f/255.0f, 187.0f/255.0f, 190.0f/255.0f, 1.0 }; // End color
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    CGPoint topCenter = CGPointMake(0, 0);
    CGPoint bottomCenter = CGPointMake(0, height);
    CGContextDrawLinearGradient(context, glossGradient, topCenter, bottomCenter, 0);
    
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
    
    // pop context
    UIGraphicsPopContext();
    
    // get a UIImage from the image context
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return  gradientImage;
}

- (void)setDisplayString:(NSString *)displayString {
	if (![_displayString isEqualToString:displayString]) {
		_displayString = [displayString copy];
		self.displayLabel.text = _displayString;
	}
}

#pragma mark - Life Cycle

-(void)prepareForReuse {
    [_imageView sd_cancelCurrentImageLoad];
    _imageView.image = nil;
    _displayLabel.text = @"";
    self.contentView.layer.borderWidth = 0;
    self.contentView.bounds = self.bounds;
}

- (void)dealloc {
    [_imageView sd_cancelCurrentImageLoad];
    _imageView.image = nil;
    
	[_displayLabel removeFromSuperview];
    [_imageView removeFromSuperview];
    _imageView = nil;
	_displayLabel = nil;

}


- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.displayLabel];
        [self.contentView addSubview:self.vidBtn];
	}
	return self;
}

-(void)configureWithAsset:(SPCMemoryAsset *)asset {

    if (asset.type != MemoryTypeText) {
        self.imageView.hidden = NO;
        self.imageView.frame = CGRectMake(0.f, 0.f, CGRectGetMaxX(self.contentView.bounds), CGRectGetMaxY(self.contentView.bounds));
        self.vidBtn.center = CGPointMake(self.contentView.bounds.size.width/2, self.contentView.bounds.size.width/2);
        self.vidBtn.hidden = YES;
        
        [self.imageView sd_cancelCurrentImageLoad];
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:asset.asset.imageUrlHalfSquare]];
        
        self.displayLabel.text = @"";
        self.contentView.layer.borderWidth = 0;
    }
    if (asset.type == MemoryTypeVideo) {
        self.vidBtn.hidden = NO;
    }
    if (asset.type == MemoryTypeText) {
        self.imageView.hidden = YES;
        self.vidBtn.hidden = YES;
        self.displayLabel.frame = CGRectMake(5.f, 5.f, CGRectGetMaxX(self.contentView.bounds)-10, CGRectGetMaxY(self.contentView.bounds)-10);
    
        //handle spaycing
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:2];
        NSDictionary *attributes = @{  NSParagraphStyleAttributeName: paragraphStyle };
      
        NSMutableAttributedString *styledStr = [[NSMutableAttributedString alloc] initWithString:asset.memText attributes:attributes];
        
        //handle gradient
        UIColor *gradientColor = [UIColor colorWithPatternImage:[self gradientImage]];
        NSRange textRange = NSMakeRange(0, asset.memText.length);
        [styledStr addAttribute:NSForegroundColorAttributeName value:gradientColor range:textRange];
        
        self.displayLabel.attributedText = styledStr;
        self.contentView.layer.borderColor = [UIColor colorWithWhite:239.0f/255.0f alpha:1.0f].CGColor;
        self.contentView.layer.borderWidth = 1;
        
    }
}


@end
