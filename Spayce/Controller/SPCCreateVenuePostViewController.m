//
//  SPCCreateVenuePostViewController.m
//  Spayce
//
//  Created by Jake Rosin on 6/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCCreateVenuePostViewController.h"
#import "MeetManager.h"
#import "VenueManager.h"
#import "PXAlertView.h"
#import "ImageUtils.h"
#import "SPCVenueTypes.h"

#define TEXT_FIELD_HEIGHT 44.0f
#define DELETE_BUTTON_MARGIN 10.0f

NSString * kSPCDidPostVenue = @"kSPCDidPostVenue";
NSString * kSPCDidUpdateVenue = @"kSPCDidUpdateVenue";
NSString * kSPCDidDeleteVenue = @"kSPCDidDeleteVenue";


@interface SPCCreateVenuePostViewController ()<UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) Venue *venue;
@property (nonatomic, assign) BOOL editExisting;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;

@property (nonatomic, assign) VenueType venueType;

@property (nonatomic, assign) BOOL viewDidAppear;

// navigation
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *saveButton;

// delete
@property (nonatomic, strong) UIButton *deleteButton;

// everything in a scroll view!
@property (nonatomic, strong) UIScrollView *scrollView;

// content
@property (nonatomic, strong) UIView *contentBg;
@property (nonatomic, strong) UIView *contentBgInner;

@property (nonatomic, strong) UITextField * venueNameTextField;
@property (nonatomic, strong) UITextField *addressStreetAddressTextField;
@property (nonatomic, strong) UILabel *addressStateLabel;
@property (nonatomic, strong) UILabel *addressCityLabel;
@property (nonatomic, strong) UILabel *addressPostalCodeLabel;

@property (nonatomic, strong) UIView * venueNameContainer;
@property (nonatomic, strong) UIView * addressStreetAddressContainer;
@property (nonatomic, strong) UIView * addressStateContainer;
@property (nonatomic, strong) UIView * addressCityContainer;
@property (nonatomic, strong) UIView * addressPostalCodeContainer;

// extra content
@property (nonatomic, strong) UIView *venueTypeBg;
@property (nonatomic, strong) UIView *venueTypeBgInner;
@property (nonatomic, strong) UIImageView *venueTypeImageView;

@property (nonatomic, strong) UIView *starWarningBg;
@property (nonatomic, strong) UIView *starWarningBgInner;
@property (nonatomic, strong) UILabel *starWarningLabel;


// alert view
@property (nonatomic, strong) PXAlertView *alertView;

@end

@implementation SPCCreateVenuePostViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithVenue:(Venue *)venue {
    self = [super init];
    if (self) {
        self.venue = venue;
        self.latitude = [venue.latitude floatValue];
        self.longitude = [venue.longitude floatValue];
        self.editExisting = venue.ownerId != 0;
        self.venueType = self.editExisting ? [SPCVenueTypes typeForVenue:venue] : VenueTypeSpayce;
    }
    return self;
}

- (id) initWithLocation:(CLLocationCoordinate2D)location {
    self = [super init];
    if (self) {
        self.latitude = location.latitude;
        self.longitude = location.longitude;
        self.venueType = VenueTypeSpayce;
        [[VenueManager sharedInstance] fetchGoogleAddressVenueAtLatitude:location.latitude longitude:location.longitude resultCallback:^(Venue *venue) {
            // Got it!
            self.venue = venue;
            [self populateContentAddressWithVenue:venue animated:YES];
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            NSLog(@"TODO: update the info window (if displayed) to represent the error.");
        }];
        self.editExisting = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tabBarController.tabBar setHidden:YES];

    if (!self.viewDidAppear) {
        
        // Do any additional view loads needed
        self.view.backgroundColor = [UIColor colorWithWhite:240.0/255.0f alpha:1.0];
        [self.view addSubview:self.navBar];
        
        // Scroll view...
        [self.view addSubview:self.scrollView];
        
        // Content area
        [self.scrollView addSubview:self.contentBg];
        [self.contentBg addSubview:self.contentBgInner];
        
        // Delete button
        if (self.editExisting) {
            [self.scrollView addSubview:self.deleteButton];
        }
        
        // Other content
        [self.scrollView addSubview:self.venueTypeBg];
        [self.venueTypeBg addSubview:self.venueTypeBgInner];
        [self.scrollView addSubview:self.starWarningBg];
        [self.starWarningBg addSubview:self.starWarningBgInner];
        
        [self initializeContent];
        
        if (self.venue) {
            [self populateContentAddressWithVenue:self.venue animated:NO];
        }
        
        // register for keyboard notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowKeyboard:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
        
        
        [self.venueNameTextField becomeFirstResponder];
        
        self.viewDidAppear = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.tabBarController.tabBar setHidden:NO];
}

#pragma mark - Properties

- (void)setVenueType:(VenueType)venueType {
    _venueType = venueType;
    if (_venueTypeImageView) {
        _venueTypeImageView.image = [SPCVenueTypes largeImageForVenueType:venueType withIconType:VenueIconTypeIconWhite];
        _venueTypeImageView.backgroundColor = [SPCVenueTypes colorForVenueType:venueType];
    }
}

- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 65)];
        _navBar.backgroundColor = [UIColor whiteColor];
        _navBar.hidden = NO;
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        closeButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        closeButton.layer.cornerRadius = 2;
        closeButton.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : closeButton.titleLabel.font,
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Back" attributes:backStringAttributes];
        [closeButton setAttributedTitle:backString forState:UIControlStateNormal];
        closeButton.frame = CGRectMake(0, CGRectGetHeight(_navBar.frame) - 44.0f, 60, 44);
        [closeButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        titleLabel.text = NSLocalizedString(self.editExisting ? @"Edit Location" : @"Create Location", nil);
        CGSize sizeOfTitle = [titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : titleLabel.font }];
        titleLabel.frame = CGRectMake(0, 0, sizeOfTitle.width, sizeOfTitle.height);
        titleLabel.center = CGPointMake(CGRectGetMidX(_navBar.frame), CGRectGetMidY(closeButton.frame) - 1);
        titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
        
        _saveButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _saveButton.backgroundColor = [UIColor colorWithRed:106.0/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _saveButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        _saveButton.layer.cornerRadius = 2;
        _saveButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_saveButton setTitle:@"Save" forState:UIControlStateNormal];
        CGSize sizeOfSaveButtonText = [_saveButton.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : _saveButton.titleLabel.font }];
        _saveButton.frame = CGRectMake(0, 0, sizeOfSaveButtonText.width + 30, sizeOfSaveButtonText.height + 16); // 11f padding on all four sides
        _saveButton.center = CGPointMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(_saveButton.frame) / 2 - 10, CGRectGetMidY(titleLabel.frame));
        [_saveButton addTarget:self action:@selector(postVenue:) forControlEvents:UIControlEventTouchUpInside];
        _saveButton.enabled = NO;
        _saveButton.alpha = 0.5;
        
        [_navBar addSubview:closeButton];
        [_navBar addSubview:titleLabel];
        [_navBar addSubview:_saveButton];
    }
    return _navBar;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.navBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navBar.frame))];
        _scrollView.backgroundColor = [UIColor colorWithWhite:240.0/255.0f alpha:1.0];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
    }
    return _scrollView;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(self.venueTypeBg.frame), CGRectGetWidth(self.view.frame) - 10, 45)];
        CGRect frame = _deleteButton.frame;
        frame.origin.y = CGRectGetMaxY(self.contentBg.frame) + DELETE_BUTTON_MARGIN;
        _deleteButton.frame = frame;
        _deleteButton.backgroundColor = [UIColor colorWithRGBHex:0xd2625d alpha:1.0f];
        _deleteButton.titleLabel.font = [UIFont spc_mediumFont];
        _deleteButton.layer.cornerRadius = 1.5;
        [_deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_deleteButton setTitle:@"Delete Location" forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(showDeleteVenuePrompt:) forControlEvents:UIControlEventTouchUpInside];
        _deleteButton.enabled = self.editExisting;
        _deleteButton.hidden = !self.editExisting;
    }
    return _deleteButton;
}

- (UIView *)contentBg {
    if (!_contentBg) {
        _contentBg = [[UIView alloc] initWithFrame:CGRectMake(5, 10, CGRectGetWidth(self.view.frame)-10, 45)];
        _contentBg.backgroundColor = [UIColor colorWithWhite:204.0f/255.0f alpha:1.0];
        _contentBg.layer.cornerRadius = 1.5f;
    }
    return _contentBg;
}

- (UIView *)contentBgInner {
    if (!_contentBgInner) {
        _contentBgInner = [[UIView alloc] initWithFrame:CGRectMake(0.5, 0, CGRectGetWidth(self.contentBg.frame)-1, CGRectGetHeight(self.contentBg.frame)-1)];
        _contentBgInner.backgroundColor = [UIColor colorWithWhite:240.0f/255.0f alpha:1.0];
        _contentBgInner.layer.cornerRadius = 1.5f;
        _contentBgInner.clipsToBounds = YES;
    }
    return _contentBgInner;
}

- (UIView *)venueTypeBg {
    if (!_venueTypeBg) {
        _venueTypeBg = [[UIView alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(self.contentBg.frame) + 10, 100, 100)];
        _venueTypeBg.backgroundColor = [UIColor colorWithWhite:204.0f/255.0f alpha:1.0];
        _venueTypeBg.layer.cornerRadius = 1.5f;
    }
    return _venueTypeBg;
}

- (UIView *)venueTypeBgInner {
    if (!_venueTypeBgInner) {
        _venueTypeBgInner = [[UIView alloc] initWithFrame:CGRectMake(0.5, 0, CGRectGetWidth(self.venueTypeBg.frame)-1, CGRectGetHeight(self.venueTypeBg.frame)-1)];
        _venueTypeBgInner.backgroundColor = [UIColor whiteColor];
        _venueTypeBgInner.layer.cornerRadius = 1.5f;
        _venueTypeBgInner.clipsToBounds = YES;
    }
    return _venueTypeBgInner;
}

- (UIView *)starWarningBg {
    if (!_starWarningBg) {
        _starWarningBg = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.venueTypeBg.frame) + 10, CGRectGetMaxY(self.contentBg.frame) + 10, CGRectGetWidth(self.view.frame) - CGRectGetMaxX(self.venueTypeBg.frame) - 15, 100)];
        _starWarningBg.backgroundColor = [UIColor colorWithWhite:204.0f/255.0f alpha:1.0];
        _starWarningBg.layer.cornerRadius = 1.5f;
    }
    return _starWarningBg;
}

- (UIView *)starWarningBgInner {
    if (!_starWarningBgInner) {
        _starWarningBgInner = [[UIView alloc] initWithFrame:CGRectMake(0.5, 0, CGRectGetWidth(self.starWarningBg.frame)-1, CGRectGetHeight(self.starWarningBg.frame)-1)];
        _starWarningBgInner.backgroundColor = [UIColor whiteColor];
        _starWarningBgInner.layer.cornerRadius = 1.5f;
        _starWarningBgInner.clipsToBounds = YES;
    }
    return _starWarningBgInner;
}

- (UIImageView *)venueTypeImageView {
    if (!_venueTypeImageView) {
        _venueTypeImageView = [[UIImageView alloc] initWithFrame:self.venueTypeBgInner.bounds];
        _venueTypeImageView.center = self.venueTypeBgInner.center;
        _venueTypeImageView.backgroundColor = [UIColor clearColor];
        _venueTypeImageView.image = [SPCVenueTypes largeImageForVenueType:self.venueType withIconType:VenueIconTypeIconNewColor];
        _venueTypeImageView.contentMode = UIViewContentModeCenter; // current SPCVenueTypes image is low-res/does not scale well to its superview's size
    }
    return _venueTypeImageView;
}

- (UILabel *)starWarningLabel {
    if (!_starWarningLabel) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectInset(self.starWarningBgInner.frame, 10.0f, 10.0f)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:139.0/255.0 green:153.0/255.0 blue:175.0/255.0 alpha:1.0];
        label.font = [UIFont spc_regularSystemFontOfSize:15.0f];
        NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:@"This location is public. Anyone can leave memories here."];
        label.attributedText = styledText;
        label.numberOfLines = 0;
        [label sizeToFit];
        label.center = self.starWarningBgInner.center;
        _starWarningLabel = label;
    }
    return _starWarningLabel;
}

- (UITextField *)venueNameTextField {
    if (!_venueNameTextField) {
        _venueNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(12, 0, CGRectGetWidth(self.view.frame)-18, TEXT_FIELD_HEIGHT)];
        _venueNameTextField.backgroundColor = [UIColor clearColor];
        _venueNameTextField.textAlignment = NSTextAlignmentLeft;
        _venueNameTextField.textColor = [UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0];
        _venueNameTextField.font = [UIFont spc_regularSystemFontOfSize:14.0f];
        
        _venueNameTextField.placeholder = @"Venue Name";
        _venueNameTextField.delegate = self;
        
        if (self.editExisting) {
            _venueNameTextField.text = self.venue.venueName;
        }
        
        [self.venueNameContainer addSubview:_venueNameTextField];
    }
    return _venueNameTextField;
}

- (UITextField *)addressStreetAddressTextField {
    if (!_addressStreetAddressTextField) {
        _addressStreetAddressTextField = [[UITextField alloc] initWithFrame:CGRectMake(12, 0, CGRectGetWidth(self.view.frame)-18, TEXT_FIELD_HEIGHT)];
        _addressStreetAddressTextField.backgroundColor = [UIColor clearColor];
        _addressStreetAddressTextField.textAlignment = NSTextAlignmentLeft;
        _addressStreetAddressTextField.textColor = [UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0];
        _addressStreetAddressTextField.font = [UIFont spc_regularSystemFontOfSize:14.0f];
        _addressStreetAddressTextField.userInteractionEnabled = NO; // Remove this in the future when allowing users to edit a venue's street address
        
        _addressStreetAddressTextField.placeholder = @"Street Address";
        _addressStreetAddressTextField.delegate = self;
        [self.addressStreetAddressContainer addSubview:_addressStreetAddressTextField];
    }
    return _addressStreetAddressTextField;
}

- (UILabel *)addressCityLabel {
    if (!_addressCityLabel) {
        _addressCityLabel = [self makeContentLabel];
        [self.addressCityContainer addSubview:_addressCityLabel];
    }
    return _addressCityLabel;
}

- (UILabel *)addressStateLabel {
    if (!_addressStateLabel) {
        _addressStateLabel = [self makeContentLabel];
        [self.addressStateContainer addSubview:_addressStateLabel];
    }
    return _addressStateLabel;
}

- (UILabel *)addressPostalCodeLabel {
    if (!_addressPostalCodeLabel) {
        _addressPostalCodeLabel = [self makeContentLabel];
        [self.addressPostalCodeContainer addSubview:_addressPostalCodeLabel];
    }
    return _addressPostalCodeLabel;
}

   
- (UILabel *)makeContentLabel {
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, CGRectGetWidth(self.view.frame)-18, TEXT_FIELD_HEIGHT)];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = [UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0];
    label.font = [UIFont spc_regularSystemFontOfSize:14.0f];
    label.numberOfLines = 1;
    return label;
}


- (UIView *) venueNameContainer {
    if (!_venueNameContainer) {
        _venueNameContainer = [self makeLabelContainer];
    }
    return _venueNameContainer;
}

- (UIView *) addressStreetAddressContainer {
    if (!_addressStreetAddressContainer) {
        _addressStreetAddressContainer = [self makeLabelContainer];
    }
    return _addressStreetAddressContainer;
}

- (UIView *) addressStateContainer {
    if (!_addressStateContainer) {
        _addressStateContainer = [self makeLabelContainer];
    }
    return _addressStateContainer;
}

- (UIView *) addressCityContainer {
    if (!_addressCityContainer) {
        _addressCityContainer = [self makeLabelContainer];
    }
    return _addressCityContainer;
}

- (UIView *) addressPostalCodeContainer {
    if (!_addressPostalCodeContainer) {
        _addressPostalCodeContainer = [self makeLabelContainer];
    }
    return _addressPostalCodeContainer;
}


- (UIView *) makeLabelContainer {
    UIView * view = [[UIView alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    view.clipsToBounds = YES;
    return view;
}


- (void)initializeContent {
    CGFloat top = 0;
    self.venueNameContainer.frame = CGRectMake(0, top, CGRectGetWidth(self.contentBgInner.frame), TEXT_FIELD_HEIGHT);
    
    top += TEXT_FIELD_HEIGHT + 1;
    self.addressStreetAddressContainer.frame = CGRectMake(0, top, CGRectGetWidth(self.contentBgInner.frame), TEXT_FIELD_HEIGHT);
    
    top += TEXT_FIELD_HEIGHT + 1;
    self.addressCityContainer.frame = CGRectMake(0, top, 166, TEXT_FIELD_HEIGHT);
    self.addressStateContainer.frame = CGRectMake(167, top, 55, TEXT_FIELD_HEIGHT);
    self.addressPostalCodeContainer.frame = CGRectMake(CGRectGetMaxX(self.addressStateContainer.frame) +1, top, CGRectGetWidth(self.contentBgInner.frame) - (CGRectGetMaxX(self.addressStateContainer.frame) +1), TEXT_FIELD_HEIGHT);
    
    [self resizeView:self.venueNameTextField toWidth:self.venueNameContainer.frame.size.width - 24];
    [self resizeView:self.addressStreetAddressTextField toWidth:self.addressStreetAddressContainer.frame.size.width - 24];
    [self resizeView:self.addressCityLabel toWidth:self.addressCityContainer.frame.size.width - 24];
    [self resizeView:self.addressStateLabel toWidth:self.addressStateContainer.frame.size.width - 24];
    [self resizeView:self.addressPostalCodeLabel toWidth:self.addressPostalCodeContainer.frame.size.width - 24];
    
    [self.contentBgInner addSubview:self.venueNameContainer];
    [self.contentBgInner addSubview:self.addressStreetAddressContainer];
    [self.contentBgInner addSubview:self.addressCityContainer];
    [self.contentBgInner addSubview:self.addressStateContainer];
    [self.contentBgInner addSubview:self.addressPostalCodeContainer];
    
    [self.venueTypeBgInner addSubview:self.venueTypeImageView];
    [self.starWarningBgInner addSubview:self.starWarningLabel];
    
    // set size to cover down to the text field.
    self.contentBgInner.frame = CGRectMake(0.5, 0, CGRectGetWidth(self.contentBg.frame)-1, CGRectGetMaxY(self.venueNameContainer.frame));
    self.contentBg.frame = CGRectMake(5, 10, CGRectGetWidth(self.view.frame)-10, CGRectGetHeight(self.contentBgInner.frame)+1);
    CGFloat venueTop = CGRectGetMaxY(self.contentBg.frame) + 10;
    self.venueTypeBg.frame = CGRectMake(5, venueTop, 100, 100);
    self.venueTypeBgInner.frame = CGRectMake(0.5, 0, 99, 99);
    self.starWarningBg.frame = CGRectMake(115, venueTop, self.starWarningBg.frame.size.width, 100);
    self.starWarningBgInner.frame = CGRectMake(0.5, 0, self.starWarningBgInner.frame.size.width, 99);
    [_deleteButton setFrame:CGRectMake(5, venueTop + 110, CGRectGetWidth(self.view.frame)-10, 45)];
    
    [self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.scrollView.frame), venueTop + (self.editExisting ? 165 : 120))];
}

-(void) resizeView:(UIView *)view toWidth:(CGFloat)width {
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, width, view.frame.size.height);
}

- (void)populateContentAddressWithVenue:(Venue *)venue animated:(BOOL)animated {
    if (!_contentBg || !_contentBgInner || !venue) {
        return;
    }
    
    self.addressStreetAddressTextField.text = venue.streetAddress;
    self.addressCityLabel.text = venue.city;
    self.addressStateLabel.text = venue.state;
    self.addressPostalCodeLabel.text = venue.postalCode;
    
    CGRect bgRect;
    CGRect bgInnerRect;
    CGRect buttonDeleteRect;
    
    if (self.addressStreetAddressTextField.text.length == 0) {
        bgRect = self.contentBg.frame;
        bgInnerRect = self.contentBgInner.frame;
    } else if (self.addressCityLabel.text.length == 0) {
        bgRect = CGRectMake(self.contentBg.frame.origin.x, self.contentBg.frame.origin.y, self.contentBg.frame.size.width, CGRectGetMaxY(self.addressStreetAddressContainer.frame) + 1);
        bgInnerRect = CGRectMake(self.contentBgInner.frame.origin.x, self.contentBgInner.frame.origin.y, self.contentBgInner.frame.size.width, CGRectGetMaxY(self.addressStreetAddressContainer.frame));
    } else {
        bgRect = CGRectMake(self.contentBg.frame.origin.x, self.contentBg.frame.origin.y, self.contentBg.frame.size.width, CGRectGetMaxY(self.addressCityContainer.frame) + 1);
        bgInnerRect = CGRectMake(self.contentBgInner.frame.origin.x, self.contentBgInner.frame.origin.y, self.contentBgInner.frame.size.width, CGRectGetMaxY(self.addressCityContainer.frame));
    }
    
    buttonDeleteRect = self.deleteButton.frame;
    buttonDeleteRect.origin.y = CGRectGetMaxY(bgRect) + DELETE_BUTTON_MARGIN;
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.contentBg.frame = bgRect;
            self.contentBgInner.frame = bgInnerRect;
            self.deleteButton.frame = buttonDeleteRect;
            
            CGFloat venueTop = CGRectGetMaxY(bgRect) + 10;
            self.venueTypeBg.frame = CGRectMake(5, venueTop, 100, 100);
            self.venueTypeBgInner.frame = CGRectMake(0.5, 0, 99, 99);
            self.starWarningBg.frame = CGRectMake(115, venueTop, self.starWarningBg.frame.size.width, 100);
            self.starWarningBgInner.frame = CGRectMake(0.5, 0, self.starWarningBgInner.frame.size.width, 99);
            
            [_deleteButton setFrame:CGRectMake(5, venueTop + 110, CGRectGetWidth(self.view.frame)-10, 45)];
            
            [self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.scrollView.frame), venueTop + (self.editExisting ? 165 : 120))];
        }];
    } else {
        self.contentBg.frame = bgRect;
        self.contentBgInner.frame = bgInnerRect;
        self.deleteButton.frame = buttonDeleteRect;
        
        CGFloat venueTop = CGRectGetMaxY(bgRect) + 10;
        self.venueTypeBg.frame = CGRectMake(5, venueTop, 100, 100);
        self.venueTypeBgInner.frame = CGRectMake(0.5, 0, 99, 99);
        self.starWarningBg.frame = CGRectMake(115, venueTop, self.starWarningBg.frame.size.width, 100);
        self.starWarningBgInner.frame = CGRectMake(0.5, 0, self.starWarningBgInner.frame.size.width, 99);
        
        [_deleteButton setFrame:CGRectMake(5, venueTop + 110, CGRectGetWidth(self.view.frame)-10, 45)];
        
        [self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.scrollView.frame), venueTop + (self.editExisting ? 165 : 120))];
    }
}

- (void)cancel:(id)sender {
    NSLog(@"cancel");
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showDeleteVenuePrompt:(id)sender {
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 300)];
    demoView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 10, 270, 40);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [demoView addSubview:imageView];
    
    NSString *title = @"Delete this location?";
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 270, 20)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:titleLabel];
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 230, 60)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.numberOfLines = 3;
    messageLabel.text = @"Memories made here will still exist, but they may end up in different places nearby.";
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:messageLabel];
    
    UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    okBtn.frame = CGRectMake(70, 165, 130, 40);
    
    [okBtn setTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
    okBtn.backgroundColor = [UIColor colorWithRGBHex:0x4ACBEB];
    okBtn.layer.cornerRadius = 4.0;
    okBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    
    UIImage *selectedImage = [ImageUtils roundedRectImageWithColor:[UIColor colorWithRGBHex:0x4795AC] size:okBtn.frame.size corners:4.0f];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
    
    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okBtn addTarget:self action:@selector(deleteConfirmed:) forControlEvents:UIControlEventTouchUpInside];
    [demoView addSubview:okBtn];
    
    
    CGRect cancelFrame = CGRectMake(70, 225, 130, 40);
    
    self.alertView = [PXAlertView showAlertWithView:demoView cancelTitle:@"Cancel" cancelBgColor:[UIColor darkGrayColor] cancelTextColor:[UIColor whiteColor] cancelFrame:cancelFrame completion:^(BOOL cancelled) {
        self.alertView = nil;
    }];
}

- (void)postVenue:(id)sender {
    // TODO: put up a dialog or in some way disable the UI...?
    self.saveButton.enabled = NO;
    self.venueNameTextField.enabled = NO;
    
    NSString * name = [self.venueNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (self.editExisting) {
        [MeetManager updateVenueWithLocationId:self.venue.locationId name:name locationMainPhotoId:0 resultCallback:^(Venue *venue) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSPCDidUpdateVenue object:venue];
            
            if ([self.delegate respondsToSelector:@selector(spcCreateVenuePostViewControllerDidFinish:)]) {
                [self.delegate spcCreateVenuePostViewControllerDidFinish:self];
            }
        } faultCallback:^(NSError *fault) {
            NSLog(@"TODO: handle failure %@", fault);
        }];
    } else {
        [MeetManager postVenueWithLat:self.latitude longitude:self.longitude name:name locationMainPhotoId:0 resultCallback:^(Venue * venue) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSPCDidPostVenue object:venue];
            
            if ([self.delegate respondsToSelector:@selector(spcCreateVenuePostViewControllerDidFinish:)]) {
                [self.delegate spcCreateVenuePostViewControllerDidFinish:self];
            }
        } faultCallback:^(NSError *fault) {
            NSLog(@"TODO: handle failure");
        }];
    }
}

- (void)deleteConfirmed:(id)sender {
    [self.alertView dismiss:sender];
    self.alertView = nil;
    
    // TODO put up a dialog or in some way disable the UI...?
    self.saveButton.enabled = NO;
    self.venueNameTextField.enabled = NO;
    
    [MeetManager deleteVenueWithLocationId:self.venue.locationId resultCallback:^(Venue *venue) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSPCDidDeleteVenue object:venue];
        
        if ([self.delegate respondsToSelector:@selector(spcCreateVenuePostViewControllerDidFinish:)]) {
            [self.delegate spcCreateVenuePostViewControllerDidFinish:self];
        }
    } faultCallback:^(NSError *fault) {
        NSLog(@"TODO: handle failure %@", fault);
    }];
}


#pragma mark - TextField delegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString * result = [textField.text stringByReplacingCharactersInRange:range withString:string];
    // enable / disable save button?
    NSInteger thisTextFieldLen = result.length;
    
    BOOL saveable = 0 < self.venueNameTextField.text.length;
    if (self.editExisting) { 
        saveable &= ![self.venue.venueName isEqualToString:result];
    } else { // Test if this text field is also populated
        saveable &= thisTextFieldLen > 0;
    }
    
    if (saveable) {
        self.saveButton.enabled = YES;
        self.saveButton.alpha = 1.0f;
    } else {
        self.saveButton.enabled = NO;
        self.saveButton.alpha = 0.5f;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.venueNameTextField == textField) {
        [self.addressStreetAddressTextField becomeFirstResponder];
    }

    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - Notification responses

-(void)willShowKeyboard:(NSNotification *)notification {
    // nothing
}

-(void)didShowKeyboard:(NSNotification *)notification {
    CGFloat keyboardHeight = CGRectGetHeight([((NSValue *)[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey]) CGRectValue]);
    self.scrollView.frame = CGRectMake(0, CGRectGetHeight(self.navBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navBar.frame) - keyboardHeight);
}

-(void)willHideKeyboard:(NSNotification *)notification {
    self.scrollView.frame = CGRectMake(0, CGRectGetHeight(self.navBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navBar.frame));
}

-(void)didHideKeyboard:(NSNotification *)notification {
    // nothing
}

@end
