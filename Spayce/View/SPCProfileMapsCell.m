//
//  SPCProfileMapsCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-23.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileMapsCell.h"

// Model
#import "SPCCity.h"
#import "SPCNeighborhood.h"

// View
#import "SPCProfileMapCell.h"

static NSString *CellIdentifier = @"SPCProfileMapCellIdentifier";

@interface SPCProfileMapsCell ()

@property (nonatomic, strong) UILabel *lblCities;
@property (nonatomic, strong) UIImageView *ivPin;

@end

@implementation SPCProfileMapsCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _lblCities = [[UILabel alloc] init];
        _lblCities.font = [UIFont fontWithName:@"OpenSans" size:11.0f];
        _lblCities.textAlignment = NSTextAlignmentLeft;
        _lblCities.textColor = [UIColor colorWithRGBHex:0x3d3d3d];
        [self addSubview:_lblCities];
        
        _ivPin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin-dark-x-small"]];
        _ivPin.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_ivPin];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.lblCities.text = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat leftRightPadding = 10.0f;
    CGFloat topBottomPadding = 7.5f;
    
    // So we have the label's size up front
    [self.lblCities sizeToFit];
    
    CGFloat lblMinX = CGRectGetWidth(self.ivPin.frame) + leftRightPadding + 2.0f;
    self.lblCities.frame = CGRectMake(lblMinX, topBottomPadding, CGRectGetWidth(self.lblCities.frame), CGRectGetHeight(self.lblCities.frame));
    
    self.ivPin.center = CGPointMake(leftRightPadding + self.ivPin.image.size.width/2.0f, CGRectGetMidY(self.lblCities.frame));
}

#pragma mark - Configuration

- (void)configureWithDataSource:(id)dataSource cities:(NSArray *)cities neightborhoods:(NSArray *)neighborhoods name:(NSString *)name isCurrentUser:(BOOL)isCurrentUser {
    
    NSMutableArray *cityStrings = [NSMutableArray arrayWithCapacity:cities.count];
    for (SPCCity *city in cities) {
        if (nil != city.cityName) {
            NSString *cityName = city.cityFullName;
            if (0 < cityName.length) {
                [cityStrings addObject:city.cityFullName];
            }
        }
    }
    
    NSMutableString *strCitiesText = [[NSMutableString alloc] init];
    if (0 == cityStrings.count) {
        [strCitiesText appendString:@"No cities yet!"];
    } else if (1 == cityStrings.count) {
        [strCitiesText appendFormat:@"%@.", [cityStrings objectAtIndex:0]];
    } else if (2 == cityStrings.count) {
        NSString *cityOne = [cityStrings objectAtIndex:0];
        NSString *cityTwo = [cityStrings objectAtIndex:1];
        [strCitiesText appendFormat:@"%@ and %@.", cityOne, cityTwo];
    } else if (3 <= cityStrings.count) {
        NSString *cityOne = [cityStrings objectAtIndex:0];
        NSString *cityTwo = [cityStrings objectAtIndex:1];
        NSString *cityThree = [cityStrings objectAtIndex:2];
        if (3 == cityStrings.count) {
            [strCitiesText appendFormat:@"%@, %@, and %@.", cityOne, cityTwo, cityThree];
        } else { // 3 < cities.count
            NSString *othersString = 4 == cities.count ? @"other" : @"others";
            [strCitiesText appendFormat:@"%@, %@, %@, and %lu %@.", cityOne, cityTwo, cityThree, cityStrings.count - 3, othersString];
        }
    }
    
    NSMutableAttributedString *strAttrCitiesText = [[NSMutableAttributedString alloc] initWithString:strCitiesText attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:11.0f], NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x3d3d3d]}];
    if (3 < cityStrings.count) {
        NSInteger startIndexOfBoldText = [strAttrCitiesText.string rangeOfString:@" and "].location + 5;
        NSInteger lengthOfBoldText = strAttrCitiesText.length - startIndexOfBoldText;
        [strAttrCitiesText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Semibold" size:11.0f] range:NSMakeRange(startIndexOfBoldText, lengthOfBoldText)];
    }
    
    self.lblCities.attributedText = strAttrCitiesText;
}

@end
