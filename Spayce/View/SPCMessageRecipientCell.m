//
//  SPCMessageRecipientCell.m
//  Spayce
//
//  Created by Christopher Taylor on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMessageRecipientCell.h"
#import "SPCInitialsImageView.h"
#import "Person.h"

// Category
#import "NSString+SPCAdditions.h"


@interface SPCMessageRecipientCell()

@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) UIButton *imageButton;

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UILabel *customDetailTextLabel;
@property (nonatomic, strong) UIImageView *isCelebBadge;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UIImageView *customCheck;

@end

@implementation SPCMessageRecipientCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        _customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(10, 15, 46, 46)];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.layer.cornerRadius = 23;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_placeholderFont];
        [self.contentView addSubview:_customImageView];
        
        _imageButton = [[UIButton alloc] initWithFrame:_customImageView.frame];
        _imageButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_imageButton];
        
        _customTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _customTextLabel.textColor = [UIColor colorWithRGBHex:0x14294b];
        _customTextLabel.font = [UIFont boldSystemFontOfSize:14];
        _customTextLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_customTextLabel];
        
        _customDetailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _customDetailTextLabel.textColor = [UIColor colorWithRGBHex:0x6ab1fb];
        _customDetailTextLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        _customDetailTextLabel.textAlignment = NSTextAlignmentLeft;
        _customDetailTextLabel.adjustsFontSizeToFitWidth = YES;
        _customDetailTextLabel.minimumScaleFactor = .75;
        [self.contentView addSubview:_customDetailTextLabel];
        
        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _separatorView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:_separatorView];
        
        _isCelebBadge = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"celebrity-check"]];
        _isCelebBadge.hidden = YES;
        [self.contentView addSubview:_isCelebBadge];
        

        _customCheck = [[ UIImageView alloc ]
                              initWithImage:[UIImage imageNamed:@"recipCheck"]];
        _customCheck.hidden = YES;
        [self.contentView addSubview:_customCheck];
    }
    return self;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
    
    // clear text
    self.customTextLabel.text = nil;
    self.customDetailTextLabel.text = nil;
    self.isCelebBadge.hidden = YES;
    
    self.imageButton.tag = 0;
    
    // Clear target action
    [self.imageButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.customTextLabel.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10, 18, self.bounds.size.width - 100, 20);
    [self.customTextLabel sizeToFit];
    
    self.customDetailTextLabel.frame =  CGRectMake(CGRectGetMinX(self.customTextLabel.frame), CGRectGetMaxY(self.customTextLabel.frame)+1, 50, 15);
    [self.customDetailTextLabel sizeToFit];
    
    if (self.customDetailTextLabel.frame.size.width > 175) {
        self.customDetailTextLabel.frame =  CGRectMake(CGRectGetMinX(self.customDetailTextLabel.frame), CGRectGetMaxY(self.customDetailTextLabel.frame)+3, 175, 15);
    }
    
    self.isCelebBadge.center = CGPointMake(CGRectGetMaxX(self.customTextLabel.frame)+8, self.customTextLabel.center.y);
    
    self.actionButton.center = CGPointMake(CGRectGetWidth(self.contentView.frame) - 10.0f - CGRectGetWidth(self.actionButton.frame) / 2, CGRectGetMidY(self.contentView.frame));
    
    CGFloat separatorHeight = 1.0f / [UIScreen mainScreen].scale;
    self.separatorView.frame = CGRectMake(0, CGRectGetHeight(self.contentView.frame) - separatorHeight, CGRectGetWidth(self.contentView.frame), separatorHeight);
    
    self.customCheck.center = CGPointMake(self.contentView.frame.size.width - 25, self.contentView.frame.size.height/2);
}

#pragma mark - Configuration

- (void)setUserName:(NSString *)name isCeleb:(BOOL)isCeleb {
    self.customTextLabel.text = name;
    self.isCelebBadge.hidden = !isCeleb;
    
    // set left position of isCeleb badge field
    //NSDictionary *attributes = @{NSFontAttributeName: self.customTextLabel.font};
    //CGRect rect = [self.customTextLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    //self.isCelebLeftConstraint.constant = rect.size.width + 17;
    
    [self setNeedsLayout];
}


- (void)configureWithPerson:(Person *)person url:(NSURL *)url {
    // Handle the name
    NSString *nameToDisplay = person.displayName;
    if (person.firstname && person.lastname) {
        nameToDisplay = [NSString stringWithFormat:@"%@ %@",person.firstname,person.lastname];
    }
    // Setting attributes here, because we need kern
    NSDictionary *nameAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Bold" size:13],
                                      NSForegroundColorAttributeName : [UIColor colorWithWhite:61.0f/255.0f alpha:1.0f],
                                      NSKernAttributeName : @(0.5) };
    self.customTextLabel.attributedText = [[NSAttributedString alloc] initWithString:nameToDisplay attributes:nameAttributes];
    
    // Handle the handle
    self.detailTextLabel.text = @"";
    if (person.handle.length > 0) {
        NSDictionary *handleAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:13],
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:187.0f/255.0f green:189.0f/255.0f blue:193.0f/255.0f alpha:1.0f],
                                            NSKernAttributeName : @(0.5) };
        self.customDetailTextLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@",person.handle] attributes:handleAttributes];
    }
    
   
    [self.customImageView configureWithText:[person.firstname firstLetter] url:url];
    
    [self setNeedsLayout];
}

- (void)displayCustomCheck:(BOOL)shouldDisplayCheck {
    if (shouldDisplayCheck) {
        self.customCheck.hidden = NO;
    }
    else {
        self.customCheck.hidden = YES;
    }
}

@end