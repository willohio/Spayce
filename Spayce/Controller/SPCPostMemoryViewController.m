//
//  SPCPostMemoryViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 5/4/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCPostMemoryViewController.h"

//Framework
#import "Flurry.h"

// Model
#import "Friend.h"
#import "Memory.h"
#import "ProfileDetail.h"
#import "User.h"
#import "UserProfile.h"

// View
#import "CoachMarks.h"
#import "SAMLabel.h"
#import "TouchesScroller.h"
#import "SPCMapDataSource.h"
#import "SPCHashTagSuggestions.h"
#import "SPCAnonUnlockedView.h"

// Category
#import "UIApplication+SPCAdditions.h"
#import "UIImageView+WebCache.h"
#import "UIAlertView+SPCAdditions.h"
#import "UIImageEffects.h"

// General
#import "SPCLiterals.h"
#import "AppDelegate.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "LocationContentManager.h"
#import "LocationManager.h"
#import "MeetManager.h"
#import "SocialService.h"
#import "SettingsManager.h"

// Utility
#import "APIService.h"

// Controller
#import "SPCMainViewController.h"
#import "SPCCustomNavigationController.h"

// Coordinator
#import "SPCAssetUploadCoordinator.h"

//literals
#import "SPCLiterals.h"

//constants
#import "Constants.h"

#define POST_MEMORY_REFRESH_MAP_SECONDS 120
#define MINIMUM_LOCATION_MANAGER_UPTIME 1

@interface SPCPostMemoryViewController () <SPCHashTagSuggestionsDelegate>

@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UILabel *titleLbl;
@property (nonatomic, strong) UIButton *anchorBtn;
@property (nonatomic, assign) BOOL isAnchoring;

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderTextLabel;

@property (nonatomic, strong) TouchesScroller *thumbnailScroller;
@property (nonatomic, strong) SPCAssetUploadCoordinator *assetUploadCoordinator;
@property (nonatomic, assign) NSInteger progressBarUploadsComplete;
@property (nonatomic, assign) NSInteger progressBarUploadsCompleteBeforeAnchor;
@property (nonatomic, assign) BOOL canEdit;

@property (nonatomic, strong) UIView *privacyBar;
@property (nonatomic, strong) UILabel *privateLbl;
@property (nonatomic, strong) UILabel *publicLbl;
@property (nonatomic, strong) UILabel *privateSub;
@property (nonatomic, strong) UILabel *publicSub;
@property (nonatomic, strong) UIButton *privateBtn;
@property (nonatomic, strong) UIButton *publicBtn;

@property (nonatomic, strong) UIView *anonLock;
@property (nonatomic, strong) UILabel *anonStarsNeededLbl;
@property (nonatomic, assign) BOOL isAnonEnabled;
@property (nonatomic, assign) NSInteger starsNeededToEnableAnon;

@property (nonatomic, assign) BOOL isAnonMemory;

@property (nonatomic ,strong) UIView *locationBar;
@property (nonatomic, strong) UIButton *locationBtn;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UIImageView *locationPinImageView;
@property (nonatomic, assign) BOOL locationIsHidden;

@property (nonatomic, strong) NSTimer *refreshMapVenuesTimer;

@property (nonatomic, strong) UIView *tagFriendsBar;
@property (nonatomic, strong) UIButton *tagFriendsBtn;
@property (nonatomic, strong) UILabel *tagFriendsLbl;
@property (nonatomic, strong) UIImageView *tagFriendsIcon;

@property (nonatomic, strong) SPCTagFriendsViewController *tagFriendsViewController;
@property (nonatomic, strong) NSArray *selectedFriends;

@property (nonatomic, strong) NSString *includedIds;
@property (nonatomic, strong) UserProfile *profile;

@property (nonatomic, strong) UIButton *dismissKeyboardBtn;

@property (nonatomic, strong) SPCImageEditingController *spcImageEditingController;

@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *progressBar;
@property (nonatomic, strong) NSTimer *stepTimer;
@property (nonatomic, assign) CGFloat keyboardHeight;

@property (nonatomic, assign) NSTimeInterval uploadStartTime;
@property (nonatomic, assign) NSTimeInterval uploadStepStartTime;
@property (nonatomic, assign) NSTimeInterval uploadStepDurationEstimate;
@property (nonatomic, assign) CGFloat uploadProgress;
@property (nonatomic, assign) CGFloat uploadStepProgressStart;
@property (nonatomic, assign) CGFloat uploadStepProgressEnd;

@property (nonatomic, strong) SPCHashTagSuggestions *hashTagSuggestions;
@property (nonatomic, assign) BOOL hashTagIsPending;
@property (nonatomic, strong) UILabel *locationTagPrompt;
@property (nonatomic, assign) BOOL didFilterImage;
@property (nonatomic, assign) BOOL memoryPostDidFault;

//anon unlocked screen
@property (nonatomic, assign) BOOL viewIsVisible;
@property (nonatomic, strong) UIImageView *viewBlurredScreen;
@property (nonatomic) BOOL anonUnlockScreenWasShown;
@property (nonatomic) BOOL presentedAnonUnlockScreenInstance; // This instance's value
@property (nonatomic, strong) SPCAnonUnlockedView *anonUnlockScreen;


@end

@implementation SPCPostMemoryViewController

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_delegate];
    [self.refreshMapVenuesTimer invalidate];
    self.refreshMapVenuesTimer = nil;
}

#pragma mark - Setters

- (void)setSelectedVenue:(Venue *)selectedVenue {
    if (!self.isAnchoring) {
        _selectedVenue = selectedVenue;
        //NSLog(@"setting _selectedVenue to %@", _selectedVenue.displayName);

        if (_locationLabel) {
            if (_selectedVenue) {
                NSLog(@"set venue text");
                _locationLabel.text = (_selectedVenue.customName && _selectedVenue.customName.length > 0) ? _selectedVenue.customName : _selectedVenue.displayNameTitle;
                
                if (_selectedVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                    [Flurry logEvent:@"MAM_CHANGED_TO_FUZZED_VENUE"];
                    _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedVenue.neighborhood,_selectedVenue.city];
                }
                if (_selectedVenue.specificity == SPCVenueIsFuzzedToCity) {
                    [Flurry logEvent:@"MAM_CHANGED_TO_FUZZED_VENUE"];
                    _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedVenue.city,_selectedVenue.country];
                }
                [self adjustPin];
            }
            //NSLog(@"_locationLabel text for venue: %@",_locationLabel.text);
        }
    } 
}

- (void)setSelectedTerritory:(SPCCity *)selectedTerritory{
    
    _selectedTerritory = selectedTerritory;
    NSLog(@"attempt to set selected territory!");
    if (_locationLabel) {
        if (_selectedTerritory) {
            NSLog(@"set territory text");
            if (_selectedTerritory.neighborhoodName.length > 0) {
                _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedTerritory.neighborhoodName,_selectedTerritory.cityFullName];
                NSLog(@"neighobrhood?");
                NSLog(@"location label text %@",_locationLabel.text);
            }
            else {
                NSLog(@"city?");
                _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedTerritory.cityFullName,_selectedTerritory.countryAbbr];
                NSLog(@"location label text %@",self.locationLabel.text);
            }
            
            _locationLabel.textColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
            NSLog(@"location label text %@",_locationLabel.text);
            
            [self adjustPin];

        }
        NSLog(@"set territory text for _locationLabel to: %@",_locationLabel.text);
    }

    
}

#pragma mark - Accessors

-(UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 21, 54, 44)];
        [_backBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _backBtn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
        [_backBtn setTitle:@"Back" forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

-(UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 120, 50)];
        _titleLbl.backgroundColor = [UIColor clearColor];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.text = NSLocalizedString(@"MEMORY", nil);
        _titleLbl.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:17];
        _titleLbl.textColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
        _titleLbl.center = CGPointMake(self.view.bounds.size.width/2,_titleLbl.center.y);
    }
    return _titleLbl;
}

-(UIView *)tagFriendsBar {
    if (!_tagFriendsBar) {
        
        float padding = 10;
        float padTop = 5;
        float barHeight = 40;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            padTop = 10;
            barHeight = 45;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            padTop = 10;
            barHeight = 50;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            padTop = 15;
            padding = 20;
            barHeight = 60;
        }
        
        float width = self.view.frame.size.width - (2 * padding);
        
        _tagFriendsBar = [[UIView alloc] initWithFrame:CGRectMake(padding, CGRectGetMaxY(_privacyBar.frame) + padTop, width, barHeight)];
        _tagFriendsBar.layer.shadowColor = [UIColor blackColor].CGColor;
        _tagFriendsBar.layer.shadowOffset = CGSizeMake(0, .5);
        _tagFriendsBar.layer.shadowRadius = .5;
        _tagFriendsBar.layer.shadowOpacity = 0.1f;
        _tagFriendsBar.layer.masksToBounds = NO;
        _tagFriendsBar.clipsToBounds = NO;
        [_tagFriendsBar addSubview:self.tagFriendsBtn];
        [_tagFriendsBar addSubview:self.tagFriendsLbl];
        [_tagFriendsBar addSubview:self.tagFriendsIcon];
        [self adjustTaggedFriendsCentering];
    }
    return _tagFriendsBar;
}

-(UIButton *)tagFriendsBtn {
    if (!_tagFriendsBtn) {
        _tagFriendsBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _tagFriendsBar.frame.size.width, _tagFriendsBar.frame.size.height)];
        _tagFriendsBtn.backgroundColor = [UIColor colorWithRed:248.0f/255.0f green:248.0f/255.0f blue:248.0f/255.0f alpha:1.0f];
        _tagFriendsBtn.layer.cornerRadius = 1;
        _tagFriendsBtn.layer.masksToBounds = YES;
        _tagFriendsBtn.clipsToBounds = YES;
        [_tagFriendsBtn addTarget:self action:@selector(tagFriends) forControlEvents:UIControlEventTouchUpInside];
    }
    return _tagFriendsBtn;
}

-(UILabel *)tagFriendsLbl {
    if (!_tagFriendsLbl) {
        _tagFriendsLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_tagFriendsBar.frame)+70, CGRectGetMinY(_tagFriendsBar.frame), _tagFriendsBar.frame.size.width - 100, CGRectGetHeight(_tagFriendsBar.frame))];
        _tagFriendsLbl.text = NSLocalizedString(@"Tag Friends", nil);
        _tagFriendsLbl.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        _tagFriendsLbl.textAlignment = NSTextAlignmentLeft;
        _tagFriendsLbl.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
        _tagFriendsLbl.userInteractionEnabled = NO;
        
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            _tagFriendsLbl.font = [UIFont spc_mediumSystemFontOfSize:15];
        }
    }
    return _tagFriendsLbl;
}

-(UIImageView *)tagFriendsIcon {
    if (!_tagFriendsIcon) {
        _tagFriendsIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mam-tag-icon"]];
        _tagFriendsIcon.center = CGPointMake(43,_tagFriendsBar.frame.size.height/2);
    }
    return _tagFriendsIcon;
}


-(UITextView *)textView {
    
    if (!_textView) {
        
        //3.5"
        float textViewHeight = 70;
        int  fontSize = 14;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            textViewHeight = 90;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            textViewHeight = 105;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            textViewHeight = 105;
            fontSize = 16;
        }
        
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(8, 76, self.view.bounds.size.width-16, textViewHeight)];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont spc_regularSystemFontOfSize:fontSize];
        _textView.textColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
        _textView.keyboardType = UIKeyboardTypeTwitter;
        _textView.spellCheckingType  = UITextSpellCheckingTypeNo;
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textView.delegate = self;
        
    }
    return _textView;
}

-(UILabel *)placeholderTextLabel {
    if (!_placeholderTextLabel) {
        
        
        int  fontSize = 14;
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            fontSize = 16;
        }
        
        _placeholderTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeholderTextLabel.text = @"Say something...";
        _placeholderTextLabel.font = [UIFont spc_regularSystemFontOfSize:fontSize];
        _placeholderTextLabel.frame = CGRectMake(13, 84 , 300, _placeholderTextLabel.font.lineHeight);
        _placeholderTextLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
    }
    return _placeholderTextLabel;
}

-(UILabel *)locationTagPrompt {
    if (!_locationTagPrompt) {
        _locationTagPrompt = [[UILabel alloc] initWithFrame:CGRectZero];
        _locationTagPrompt.text = @"";
        _locationTagPrompt.font = [UIFont spc_regularSystemFontOfSize:14];
        _locationTagPrompt.frame = CGRectMake(13, 184 , 300, _placeholderTextLabel.font.lineHeight);
        _locationTagPrompt.textColor = [UIColor colorWithRed:212.0f/255.0f green:218.0f/255.0f blue:223.0f/255.0f alpha:1.0f];
        _locationTagPrompt.hidden = YES;
    }
    return _locationTagPrompt;
}


-(TouchesScroller *)thumbnailScroller {
    if (!_thumbnailScroller) {
        
        float scrollerHeight = 75;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
           scrollerHeight = 90;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            scrollerHeight = 110;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            scrollerHeight = 125;
        }
        
        
        _thumbnailScroller = [[TouchesScroller alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.textView.frame), self.view.bounds.size.width, scrollerHeight)];
        _thumbnailScroller.backgroundColor = [UIColor clearColor];
        _thumbnailScroller.showsHorizontalScrollIndicator = NO;
        
    }
    return _thumbnailScroller;
}

-(UIView *)privacyBar {
    
    if (!_privacyBar) {
        
        float barHeight = 95;
        float padTop = 7;
        float headSpace = 22;
        float subHeadSpace = 13;
        float dividerHeight = 35;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            padTop = 10;
             barHeight = 105;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            padTop = 10;
            barHeight = 135;
            dividerHeight = 50;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            padTop = 15;
            barHeight = 150;
            headSpace = 30;
            subHeadSpace = 20;
            dividerHeight = 55;
        }
        
        
        _privacyBar = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.locationBar.frame), CGRectGetMaxY(_locationBar.frame) + padTop, CGRectGetWidth(self.locationBar.frame), barHeight)];
        _privacyBar.backgroundColor = [UIColor clearColor];
        _privacyBar.layer.shadowColor = [UIColor blackColor].CGColor;
        _privacyBar.layer.shadowOffset = CGSizeMake(0, .5);
        _privacyBar.layer.shadowRadius = .5;
        _privacyBar.layer.shadowOpacity = 0.1f;
        _privacyBar.layer.masksToBounds = NO;
        _privacyBar.clipsToBounds = NO;
        
        UIView *backgroundColorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _privacyBar.frame.size.width, _privacyBar.frame.size.height)];
        backgroundColorView.backgroundColor = [UIColor colorWithRed:248.0f/255.0f green:248.0f/255.0f blue:248.0f/255.0f alpha:1.0f];
        backgroundColorView.layer.cornerRadius = 1;
        backgroundColorView.layer.masksToBounds = YES;
        backgroundColorView.clipsToBounds = YES;
        [_privacyBar addSubview:backgroundColorView];
        
        [_privacyBar addSubview:self.privateBtn];
        [_privacyBar addSubview:self.privateLbl];
        [_privacyBar addSubview:self.privateSub];
        self.privateBtn.center = CGPointMake(.75 * CGRectGetWidth(_privacyBar.frame), self.privateBtn.center.y);
        self.privateLbl.center = CGPointMake(self.privateBtn.center.x, self.privateLbl.center.y);
        self.privateSub.center = CGPointMake(self.privateBtn.center.x, self.privateSub.center.y);
        
        
        
        [_privacyBar addSubview:self.publicBtn];
        [_privacyBar addSubview:self.publicLbl];
        [_privacyBar addSubview:self.publicSub];
        self.publicBtn.center = CGPointMake(.25 * CGRectGetWidth(_privacyBar.frame), self.publicBtn.center.y);
        self.publicLbl.center = CGPointMake(self.publicBtn.center.x, self.publicLbl.center.y);
        self.publicSub.center = CGPointMake(self.publicBtn.center.x, self.publicSub.center.y);
        
        UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(_privacyBar.frame)/2,  (_privacyBar.frame.size.height - dividerHeight)/2, 1, dividerHeight)];
        sepView.backgroundColor = [UIColor colorWithWhite:0 alpha:.05];
        [_privacyBar addSubview:sepView];
        
        UIButton *pubTapArea = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _privacyBar.frame.size.width/2, _privacyBar.frame.size.height)];
        [pubTapArea addTarget:self action:@selector(setToReal) forControlEvents:UIControlEventTouchDown];
        [_privacyBar addSubview:pubTapArea];

        UIButton *priTapArea = [[UIButton alloc] initWithFrame:CGRectMake(_locationBar.frame.size.width/2, 0, _locationBar.frame.size.width/2, _privacyBar.frame.size.height)];
        [priTapArea addTarget:self action:@selector(setToAnon) forControlEvents:UIControlEventTouchDown];
        [_privacyBar addSubview:priTapArea];
        
        [_privacyBar addSubview:self.anonLock];
        
        [self updateAnonLock];
        
    }
    return _privacyBar;
    
}

-(UIButton *)privateBtn  {
    if (!_privateBtn) {
        
        float topAnchor = 7;
        float imgSize = 35;
        
        UIImage *privateImg = [UIImage imageNamed:@"mamAnon"];
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            topAnchor = 10;
        }
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            topAnchor = 19;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            topAnchor = 21;
            privateImg = [UIImage imageNamed:@"mamAnonJumbo"];
            imgSize = 37;
        }
        
        _privateBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, topAnchor, imgSize, imgSize)];
        [_privateBtn addTarget:self action:@selector(setToPrivate) forControlEvents:UIControlEventTouchUpInside];
        [_privateBtn setBackgroundImage:privateImg forState:UIControlStateNormal];
    }
    return _privateBtn;
}

-(UIButton *)publicBtn  {
    if (!_publicBtn) {
        
        float topAnchor = 7;
        float imgSize = 35;
         UIImage *publicImg = [UIImage imageNamed:@"mamRealSelected"];
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
             topAnchor = 10;
        }
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            topAnchor = 19;
        }
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            topAnchor = 21;
            imgSize = 37;
            publicImg = [UIImage imageNamed:@"mamRealJumboSelected"];
        }
        
        _publicBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, topAnchor, imgSize, imgSize)];
        [_publicBtn addTarget:self action:@selector(setToPublic) forControlEvents:UIControlEventTouchUpInside];
       
        [_publicBtn setBackgroundImage:publicImg forState:UIControlStateNormal];
    }
    return _publicBtn;
}

-(UILabel *)privateLbl   {
    if (!_privateLbl) {
        
        int fontSize = 11;
        float height = 16;
        float originY = 43;
        float cornerRadius = 8;
        float width = 110;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            originY = 48;
            cornerRadius = 9;
            height = 18;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            originY = 60;
            cornerRadius = 12;
            height = 25;
            width = 125;
            fontSize = 14;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            originY = 65;
            cornerRadius = 13;
            fontSize = 16;
            height = 26;
            width = 140;
        }
        
        _privateLbl = [[UILabel alloc] initWithFrame:CGRectMake(0,originY, width, height)];
        _privateLbl.text = NSLocalizedString(@"ANONYMOUS", nil);
        _privateLbl.font = [UIFont spc_boldSystemFontOfSize:fontSize];
        _privateLbl.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        _privateLbl.textAlignment = NSTextAlignmentCenter;
        _privateLbl.clipsToBounds = YES;
        _privateLbl.layer.cornerRadius = cornerRadius;
    }
    
    return _privateLbl;
}

-(UILabel *)privateSub   {
    if (!_privateSub) {
        
        int fontSize = 10;
        float height = 30;
        float topPad = 0;
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            fontSize = 12;
            height = 36;
            topPad = 5;
        }
        
        _privateSub = [[UILabel alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(self.privateLbl.frame) + topPad, 120, height)];
        _privateSub.text = NSLocalizedString(@"(No one will ever\nknow this is you)", nil);
        _privateSub.font = [UIFont spc_regularSystemFontOfSize:fontSize];
        _privateSub.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        _privateSub.numberOfLines = 0;
        _privateSub.lineBreakMode = NSLineBreakByWordWrapping;
        _privateSub.textAlignment = NSTextAlignmentCenter;
    }
    
    return _privateSub;
}

-(UIView *)anonLock{
    if (!_anonLock) {
        
        float lockCenterY = 27;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            lockCenterY = 30;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            lockCenterY = 44;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            lockCenterY  = 48;
        }
        
        _anonLock = [[UIView alloc] initWithFrame:CGRectMake(self.privacyBar.frame.size.width/2, 0, self.privacyBar.frame.size.width/2, self.privacyBar.frame.size.height)];
        _anonLock.backgroundColor = [UIColor colorWithRed:42.0f/255.0f green:51.0f/255.0f blue:64.0f/255.0f alpha:0.9f];
        _anonLock.userInteractionEnabled = YES;
        
        UIImageView *lockImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mamAnonLock"]];
        [_anonLock addSubview:lockImgView];
        lockImgView.center = CGPointMake(_anonLock.frame.size.width/2, lockCenterY);
        
        [_anonLock addSubview:self.anonStarsNeededLbl];
    }
    
    return _anonLock;
}

-(UILabel *)anonStarsNeededLbl {
    
    if (!_anonStarsNeededLbl) {
        
        float yAdj = 0;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            yAdj = 5;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            yAdj = 5;
        }
        
        _anonStarsNeededLbl = [[UILabel alloc] initWithFrame:CGRectMake(10,CGRectGetMinY(self.privateLbl.frame) + yAdj,self.anonLock.frame.size.width - 20, 50)];
        _anonStarsNeededLbl.numberOfLines = 0;
        _anonStarsNeededLbl.lineBreakMode = NSLineBreakByWordWrapping;
        _anonStarsNeededLbl.textAlignment = NSTextAlignmentCenter;
        
    }
    return _anonStarsNeededLbl;
    
}

-(UILabel *)publicLbl   {
    if (!_publicLbl) {
        
        int fontSize = 11;
        float height = 16;
        float originY = 43;
        float cornerRadius = 8;
        float width = 110;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            originY = 48;
            cornerRadius = 9;
            height = 18;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            originY = 60;
            cornerRadius = 12;
            height = 25;
            width = 125;
            fontSize = 14;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            originY = 65;
            cornerRadius = 13;
            fontSize = 16;
            height = 26;
            width = 140;
        }
        
        _publicLbl = [[UILabel alloc] initWithFrame:CGRectMake(0,originY, width, height)];
        _publicLbl.text = NSLocalizedString(@"REAL PROFILE", nil);
        _publicLbl.font = [UIFont spc_boldSystemFontOfSize:fontSize];
        _publicLbl.textColor = [UIColor whiteColor];
        _publicLbl.textAlignment = NSTextAlignmentCenter;
        _publicLbl.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _publicLbl.clipsToBounds = YES;
        _publicLbl.layer.cornerRadius = cornerRadius;

    }
    
    return _publicLbl;
}

-(UILabel *)publicSub   {
    if (!_publicSub) {
        
        int fontSize = 10;
        float height = 30;
        float topPad = 0;
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            fontSize = 12;
            height = 36;
            topPad = 5;
        }
        
        _publicSub = [[UILabel alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(self.publicLbl.frame) + topPad, 120, height)];
        _publicSub.text = NSLocalizedString(@"(You will get credit\nfor this memory)", nil);
        _publicSub.font = [UIFont spc_regularSystemFontOfSize:fontSize];
        _publicSub.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _publicSub.numberOfLines = 0;
        _publicSub.lineBreakMode = NSLineBreakByWordWrapping;
        _publicSub.textAlignment = NSTextAlignmentCenter;
    }
    
    return _publicSub;
}

- (UILabel *)locationLabel {
    if (!_locationLabel) {
        
        //3.5"
        int fontSize = 15;
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            fontSize = 17;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            fontSize = 18;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            fontSize = 20;
        }
     
        _locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,_locationBar.frame.size.height/2 - 10,_locationBar.frame.size.width - 20, 20)];
        _locationLabel.font = [UIFont fontWithName:@"AvenirNext-Bold" size:fontSize];
        _locationLabel.textAlignment = NSTextAlignmentCenter;
        _locationLabel.backgroundColor = [UIColor clearColor];
        _locationLabel.textColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
        _locationLabel.numberOfLines = 1;
        _locationLabel.minimumScaleFactor = .7;
        _locationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _locationLabel.userInteractionEnabled = NO;
        
        if (self.selectedVenue) {
            NSLog(@"set venue text");
            _locationLabel.text = (_selectedVenue.customName && _selectedVenue.customName.length > 0) ? self.selectedVenue.customName : self.selectedVenue.displayNameTitle;
            
            if (_selectedVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedVenue.neighborhood,_selectedVenue.city];
            }
            if (_selectedVenue.specificity == SPCVenueIsFuzzedToCity) {
                _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedVenue.city,_selectedVenue.country];
            }
            
            [self adjustPin];
        }
        if (self.selectedTerritory) {
            if (_selectedTerritory.neighborhoodName.length > 0) {
                _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedTerritory.neighborhoodName,_selectedTerritory.cityFullName];
            }
            else {
                _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedTerritory.cityFullName,_selectedTerritory.countryAbbr];
            }
            [self adjustPin];
        }
        
        
        if ((!self.selectedVenue) && (!self.selectedTerritory)) {
            _locationLabel.text = nil;
            _locationPinImageView.alpha = 0;
        }
    }
    return _locationLabel;
}

-(UIImageView *)locationPinImageView {
    if (!_locationPinImageView) {
        _locationPinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mam-pin"]];
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            _locationPinImageView.transform = CGAffineTransformMakeScale(1.9, 1.9);
           
        }
    }
    return _locationPinImageView;
}

-(UIView *)locationBar {
    if (!_locationBar) {
       
        //3.5"
        float padding = 10;
        int fontSize = 11;
        float barHeight = 60;
        float headAdj = 0;
        float changeLocHeight = 20;
        float changeLocWidth = 160;
        int cornerRadius = 10;
        float changeAdj = 0;

        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            barHeight = 80;
            fontSize = 12;
            changeLocHeight = 25;
            changeAdj = -7;
            cornerRadius = 12;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            barHeight = 100;
            fontSize = 13;
            headAdj = 5;
            changeAdj = -5;
            changeLocHeight = 30;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            barHeight = 110;
            fontSize = 13;
            padding = 20;
            changeLocHeight = 30;
            changeLocWidth = 190;
            changeAdj = -5;
        }
 
        float width = self.view.frame.size.width - (2 * padding);
        
        _locationBar = [[UIView alloc] initWithFrame:CGRectMake(padding, CGRectGetMaxY(self.thumbnailScroller.frame), width, barHeight)];
        _locationBar.layer.shadowColor = [UIColor blackColor].CGColor;
        _locationBar.layer.shadowOffset = CGSizeMake(0, .5);
        _locationBar.layer.shadowRadius = .5;
        _locationBar.layer.shadowOpacity = 0.1f;
        _locationBar.layer.masksToBounds = NO;
        _locationBar.clipsToBounds = NO;

        [_locationBar addSubview:self.locationBtn];
        
        [_locationBar addSubview:self.locationLabel];
        [_locationBar addSubview:self.locationPinImageView];
        
        UILabel *changeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.locationLabel.frame)+3+changeAdj, changeLocWidth, changeLocHeight)];
        changeLbl.text = @"CHANGE";
        changeLbl.font = [UIFont spc_mediumSystemFontOfSize:fontSize];
        changeLbl.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        changeLbl.textAlignment = NSTextAlignmentCenter;
        changeLbl.userInteractionEnabled = NO;
        changeLbl.center = CGPointMake(_locationBar.frame.size.width/2, changeLbl.center.y);
        
        [_locationBar addSubview:changeLbl];
        
        
         [self adjustPin];
    }
    return _locationBar;
}

-(UIButton *)locationBtn  {
    if (!_locationBtn) {
        
        _locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _locationBar.frame.size.width, _locationBar.frame.size.height)];
        _locationBtn.backgroundColor = [UIColor colorWithRed:248.0f/255.0f green:248.0f/255.0f blue:248.0f/255.0f alpha:1.0f];
        [_locationBtn addTarget:self action:@selector(animateChangeLocation) forControlEvents:UIControlEventTouchUpInside];
        _locationBtn.layer.cornerRadius = 1;
        _locationBtn.layer.masksToBounds = YES;
        _locationBtn.clipsToBounds = YES;
        
    }
    return _locationBtn;
}


-(SPCTagFriendsViewController *)tagFriendsViewController {
    if (!_tagFriendsViewController) {
        _tagFriendsViewController = [[SPCTagFriendsViewController alloc] initWithSelectedFriends:self.selectedFriends];
        _tagFriendsViewController.delegate = self;
    }
    return _tagFriendsViewController;
}

-(NSArray *)selectedFriends {
    
    if (!_selectedFriends) {
        _selectedFriends = [[NSArray alloc] init];
    }
    return _selectedFriends;
}


-(UIButton *)anchorBtn  {
    if (!_anchorBtn) {
    
        float barHeight = 45;
        int fontSize = 16;
        
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            barHeight = 50;
        }
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            barHeight = 60;
        }
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
             barHeight = 65;
            fontSize = 22;
        }
        
        _anchorBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - barHeight, CGRectGetWidth(self.view.frame), barHeight)];
        _anchorBtn.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        [_anchorBtn addTarget:self action:@selector(updateVenue) forControlEvents:UIControlEventTouchUpInside];
        _anchorBtn.layer.borderWidth = 1;
        _anchorBtn.layer.cornerRadius = 1;
        _anchorBtn.titleLabel.font = [UIFont fontWithName:@"Ubuntu-Bold" size:fontSize];
        
        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment                = NSTextAlignmentCenter;
        
        NSAttributedString *attributedString   =
        [NSAttributedString.alloc initWithString:NSLocalizedString(@"SPAYCE", nil)
                                      attributes:
         @{NSParagraphStyleAttributeName:paragraphStyle}];
        
        NSMutableAttributedString *updStr = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
        
        [updStr addAttribute:NSKernAttributeName value:@2 range:NSMakeRange(0, attributedString.length)];
        [updStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attributedString.length)];
        
        [_anchorBtn setAttributedTitle:updStr forState:UIControlStateNormal];
        
        _anchorBtn.layer.borderColor = [UIColor colorWithWhite:0 alpha:.05].CGColor;
        _anchorBtn.clipsToBounds = YES;
        
    }
    return _anchorBtn;
}

-(UIButton *)dismissKeyboardBtn  {
    if (!_dismissKeyboardBtn) {
        _dismissKeyboardBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.textView.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetMaxY(self.textView.frame))];
        _dismissKeyboardBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:.7];
        [_dismissKeyboardBtn addTarget:self action:@selector(hideKeyboard) forControlEvents:UIControlEventTouchDown];
        _dismissKeyboardBtn.hidden = YES;
    }
    return _dismissKeyboardBtn;
}

-(SPCHashTagSuggestions *)hashTagSuggestions {
    if (!_hashTagSuggestions) {
        _hashTagSuggestions = [[SPCHashTagSuggestions alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.textView.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetMaxY(self.textView.frame))];
        _hashTagSuggestions.hidden = YES;
        _hashTagSuggestions.delegate = self;
    }
    
    return _hashTagSuggestions;
}

-(SPCImageEditingController *)spcImageEditingController {
    if (!_spcImageEditingController) {
        _spcImageEditingController = [[SPCImageEditingController alloc] init];
        _spcImageEditingController.delegate = self;
    }
    return _spcImageEditingController;
}

-(UIView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
        _loadingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.2];
    }
    
    return _loadingView;
}

-(UIView *)progressBar {
    if (!_progressBar) {
        _progressBar = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(self.textView.frame)-4, 20, 4)];
        _progressBar.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        NSLog(@"progress bar frame made as %@", NSStringFromCGRect(_progressBar.frame));
    }
    return _progressBar;
}


#pragma mark - UIViewController - Managing the View

- (void)loadView {
    [super loadView];
    
    self.isAnonEnabled = [SettingsManager sharedInstance].anonPostingEnabled;
    self.starsNeededToEnableAnon = [SettingsManager sharedInstance].numStarsNeeed;
    
    if (!self.isAnonEnabled && self.starsNeededToEnableAnon == 0) {
        self.starsNeededToEnableAnon = 20;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];

    self.keyboardHeight = 266;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        self.keyboardHeight = 306;
        
    }
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 65)];
    bgView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bgView];
    
    UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 64.5, self.view.frame.size.width, .5)];
    sepLine.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
    [bgView addSubview:sepLine];
    
    
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.titleLbl];
    [self.view addSubview:self.thumbnailScroller];
    [self.view addSubview:self.textView];
    [self.view addSubview:self.locationTagPrompt];
    [self.view addSubview:self.placeholderTextLabel];

    [self.view addSubview:self.locationBar];
    
    [self.view addSubview:self.privacyBar];
    
    
    [self.view addSubview:self.tagFriendsBar];
    
    [self.view addSubview:self.anchorBtn];
    
    [self.view addSubview:self.dismissKeyboardBtn];
    [self.view addSubview:self.hashTagSuggestions];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.isAnonEnabled = [SettingsManager sharedInstance].anonPostingEnabled;
    self.starsNeededToEnableAnon = [SettingsManager sharedInstance].numStarsNeeed;
    
    if (!self.isAnonEnabled && self.starsNeededToEnableAnon == 0) {
        self.starsNeededToEnableAnon = 20;
    }
    [self updateAnonLock];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.viewIsVisible = YES;
    
    // Display the Anon Unlock view if appropriate
    if ([SettingsManager sharedInstance].anonPostingEnabled && !self.anonUnlockScreenWasShown) {
        [self presentAnonUnlockScreenAfterDelay:@(2.0f)];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.viewIsVisible = NO;
}

#pragma mark - UITextViewDelegate

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.dismissKeyboardBtn.hidden = NO;

    [self.backBtn setTitle:@"Done" forState:UIControlStateNormal];
    self.hashTagSuggestions.hidden = NO;
    return YES;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *resultString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    self.placeholderTextLabel.hidden = resultString.length > 0;
    

    self.locationTagPrompt.hidden = YES;
    BOOL needsRestyling = NO;
    
    if ([text isEqualToString:@" "] || [text isEqualToString:@"\n"]){
        [self updatePendingHashTags];
        needsRestyling = YES;
    }

    NSRange hashRange = [resultString rangeOfString:@"#" options:NSBackwardsSearch];
    NSRange spaceRange = [resultString rangeOfString:@" " options:NSBackwardsSearch];
    
    if ((spaceRange.location != NSNotFound) && (hashRange.location != NSNotFound)) {
        if (spaceRange.location > hashRange.location) {
            needsRestyling = YES;
        }
    }
    
    NSRange cursorPosition = [self.textView selectedRange];
    
    if (needsRestyling) {
        [self updateHashStyling];
    }
    
    [textView setSelectedRange:cursorPosition];
    

    return resultString.length <= 141;
}


#pragma mark - SPCTagFriendsViewControllerDelegate

-(void)pickedFriends:(NSArray *)selectedFriends {
    self.selectedFriends = selectedFriends;
    [self updateHeaderWithFriendsCount:(int)self.selectedFriends.count];
    
    [self.tagFriendsViewController.view removeFromSuperview];
    self.tagFriendsViewController = nil;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)cancelTaggingFriends {
    [self.tagFriendsViewController.view removeFromSuperview];
    self.tagFriendsViewController = nil;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)restoreSelectedFriends:(NSArray *)selectedFriends {
    self.selectedFriends = selectedFriends;
    [self updateHeaderWithFriendsCount:(int)self.selectedFriends.count];
}

-(void)restoreAnon:(BOOL)isAnon {
 
    if (isAnon && [SettingsManager sharedInstance].anonPostingEnabled) {
        [self setToAnon];
    }
    else {
        [self setToReal];
    }
    
}

- (void)updateLocation:(Venue *)venue {
    [self updateLocation:venue dismissViewController:YES];
}

- (void)updateLocationWithTerritory:(SPCCity *)territory {
    self.selectedVenue = nil;
    self.selectedTerritory = territory;
}

- (void)updateLocation:(Venue *)venue dismissViewController:(BOOL)dismiss {
    NSLog(@"updateLocation");
    self.selectedVenue = venue;
    
    [[LocationManager sharedInstance] updateTempLocationWithVenue:venue];
}

#pragma mark - SPCImageEditingControllerDelegate

- (void)cancelEditing {
    [self.spcImageEditingController.view removeFromSuperview];
    
    // Clear the editing asset, since we're through using it
    editingAsset = nil;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)finishedEditingImage:(SPCImageToCrop *)newImage {
 
    self.didFilterImage = YES; //used for flurry logs
    
    //update data
    [self.assetUploadCoordinator removePendingAsset:editingAsset];
    SPCPendingAsset *assetNew = [[SPCPendingAsset alloc] initWithImageToCrop:newImage];
    assetNew.tag = editingAsset.tag;
    [self.assetUploadCoordinator addPendingAsset:assetNew];
    
    //update view
    UIView *view;
    NSArray *subs = [self.thumbnailScroller subviews];
    
    for (view in subs) {
        if (view.tag == editingAsset.tag) {
            
            if ([view isKindOfClass:[UIImageView class]]) {
                UIImageView *imageView = (UIImageView *)view;
                imageView.image = [newImage cropPreviewImage];
            }
        }
    }
    
    // Clear the editing asset, since we're through using it
    editingAsset = nil;
    
    //update capture controller
    [self.delegate spcPostMemoryViewControllerDidUpdatePendingAssets:self.assetUploadCoordinator];
    
    [self.spcImageEditingController.view removeFromSuperview];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Private

- (void)configureWithAssetUploadCoordinator:(SPCAssetUploadCoordinator *)assetUploadCoordinator canEdit:(BOOL)canEdit {
    NSLog(@"configuring with %li pending assets", assetUploadCoordinator.pendingAssets.count);
    
    //3.5"
    float addSize = 45;
    float thumbSize = 60;
    float spacing = 80;
    float padTop = 0;
    float addAdj = 0;
    
    //4"
    if ([UIScreen mainScreen].bounds.size.height > 480) {
        thumbSize = 75;
        spacing = 95;
         padTop = 14;
    }
    
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width >= 375) {
        addSize = 55;
        thumbSize = 75;
        spacing = 105;
    }
    
    //5.5"
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        addSize = 60;
        thumbSize = 100;
        spacing = 120;
        padTop = 5;
        addAdj = 10;
    }
    
    float topThumbPad = (thumbSize - addSize) / 2;
    float leftPad = self.view.bounds.size.width/2 - (thumbSize/2) - spacing;
    
    //add + btn
    UIButton *addAssetBtn = [[UIButton alloc] initWithFrame:CGRectMake(leftPad + addAdj, padTop + topThumbPad, addSize, addSize)];
    addAssetBtn.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
    addAssetBtn.layer.cornerRadius = 2;
    addAssetBtn.tag = -1;
    [addAssetBtn setImage:[UIImage imageNamed:@"mam-new-asset-icon"] forState:UIControlStateNormal];
    [addAssetBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    
    [self.thumbnailScroller addSubview:addAssetBtn];
    
    if (assetUploadCoordinator.pendingAssets.count > 0) {
        
        float xPadding = leftPad + spacing;
        self.canEdit = canEdit;
        self.assetUploadCoordinator = assetUploadCoordinator;
        
        for (int i = 0; i<[assetUploadCoordinator.pendingAssets count]; i++){
            
            float originX = xPadding + i * spacing;
            
            UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:CGRectMake(originX, padTop, thumbSize, thumbSize)];
            
            SPCPendingAsset *asset = ((SPCPendingAsset *)assetUploadCoordinator.pendingAssets[i]);
            asset.tag = i;
            
            SPCImageToCrop *imageToCrop = asset.imageToCrop;
            tempImageView.image = [imageToCrop cropPreviewImage];
            
            
            tempImageView.backgroundColor = [UIColor yellowColor];
            tempImageView.contentMode = UIViewContentModeScaleAspectFill;
            tempImageView.clipsToBounds = YES;
            tempImageView.layer.cornerRadius = 2;
            tempImageView.tag = i;
            [self.thumbnailScroller addSubview:tempImageView];
            
            UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(originX + thumbSize - 23,0, 45, 45)];
            UIImage *deleteImg = [UIImage imageNamed:@"mam-delete-icon"];
            [deleteBtn setBackgroundImage:deleteImg forState:UIControlStateNormal];
            deleteBtn.tag = i;
            [deleteBtn addTarget:self action:@selector(deleteAsset:) forControlEvents:UIControlEventTouchUpInside];
            [self.thumbnailScroller addSubview:deleteBtn];
            
            if (self.canEdit) {
                UIButton *editBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, tempImageView.frame.size.height - 26, tempImageView.frame.size.height , 26)];
                editBtn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:12];
                [editBtn setTitle:@"Edit" forState:UIControlStateNormal];
                editBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.3];
                editBtn.titleLabel.textColor = [UIColor whiteColor];
                [editBtn addTarget:self action:@selector(editSourceImage:) forControlEvents:UIControlEventTouchUpInside];
                tempImageView.userInteractionEnabled = YES;
                [tempImageView addSubview:editBtn];
                editBtn.layer.cornerRadius = 1;
                editBtn.clipsToBounds = YES;
                editBtn.tag = i;
                
            }
        }
    }
    self.thumbnailScroller.contentSize = CGSizeMake(leftPad + spacing + [assetUploadCoordinator.pendingAssets count]*spacing, spacing);

}


-(void)updateHeaderWithFriendsCount:(int)taggedFriendsCount {
    if (taggedFriendsCount == 0) {
       self.tagFriendsLbl.text = NSLocalizedString(@"Tag Friends", nil);
       self.tagFriendsLbl.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
       self.tagFriendsIcon.image = [UIImage imageNamed:@"mam-tag-icon"];
    }
    else {
        self.tagFriendsLbl.text = [NSString stringWithFormat:@"Tagged Friends (%i)",taggedFriendsCount];
        self.tagFriendsLbl.textColor = [UIColor colorWithRed:114.0f/255.0f green:120.0f/255.0f blue:131.0f/255.0f alpha:1.0f];
        self.tagFriendsIcon.image = [UIImage imageNamed:@"mam-tagged-icons"];
    }
    
    [self adjustTaggedFriendsCentering];
}

-(void)restoreMemoryText:(NSString *)textToRestore {
    self.placeholderTextLabel.hidden = YES;
    self.textView.text = textToRestore;
    [self hashTagFullSweep];
}

-(void)hideKeyboard {
    self.dismissKeyboardBtn.hidden = YES;
    [self.textView resignFirstResponder];
}

-(void)adjustPin {
    //5.5"
    
    float horAdj = 0;
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        horAdj = 5;
    }
    
    [_locationLabel sizeToFit];
    
    //cap max width after size to fit
    if (_locationLabel.frame.size.width > self.locationBar.frame.size.width - 50) {
        _locationLabel.frame = CGRectMake(0, 0, self.locationBar.frame.size.width - 50, _locationLabel.frame.size.height);
    }
    
    _locationLabel.center = CGPointMake(self.locationBar.frame.size.width/2, -15 + self.locationBar.frame.size.height/2);
    _locationPinImageView.center = CGPointMake(horAdj + _locationLabel.center.x - _locationLabel.frame.size.width/2 - 2 - _locationPinImageView.frame.size.width/2, _locationLabel.center.y - 1);
    _locationPinImageView.alpha = 1;
 }

-(void)adjustTaggedFriendsCentering {
    [self.tagFriendsLbl sizeToFit];
    self.tagFriendsLbl.center = CGPointMake(self.tagFriendsBar.frame.size.width/2 + self.tagFriendsIcon.frame.size.width/2, self.tagFriendsBar.frame.size.height/2);
    self.tagFriendsIcon.center = CGPointMake(CGRectGetMinX(self.tagFriendsLbl.frame) - self.tagFriendsIcon.frame.size.width/2 - 5, self.tagFriendsIcon.center.y);
}

-(void)setFuzzedDefaultForTextMem {
    [[LocationContentManager sharedInstance] getContent:@[SPCLocationContentFuzzedVenue] resultCallback:^(NSDictionary *results) {
        if (!self.selectedVenue && results[SPCLocationContentFuzzedVenue]) {
            self.selectedVenue = results[SPCLocationContentFuzzedVenue];
            [self.delegate updateSelectedVenue:self.selectedVenue];
            
            if (_selectedVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                [Flurry logEvent:@"MAM_CHANGED_TO_FUZZED_VENUE"];
                _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedVenue.neighborhood,_selectedVenue.city];
            }
            if (_selectedVenue.specificity == SPCVenueIsFuzzedToCity) {
                [Flurry logEvent:@"MAM_CHANGED_TO_FUZZED_VENUE"];
                _locationLabel.text = [NSString stringWithFormat:@"%@, %@",_selectedVenue.city,_selectedVenue.country];
            }
        }
    }
          faultCallback:^(NSError *fault) {
              // TODO: Show error table view cell
              // No nearby locations found
              NSLog(@"error fetching nearby locations: %@", fault);
              
          }];
}

-(void)updateAnonLock {
    
    if (self.isAnonEnabled) {
        self.anonLock.hidden = YES;
    }
    else {
        self.anonLock.hidden = NO;
        
        NSString *unlockMsg;
    
        int fontSize = 10;
        
        //4"
        if ([UIScreen mainScreen].bounds.size.height > 480) {
            fontSize = 12;
        }
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            fontSize = 12;
        }
    
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            fontSize = 13;
        }
        
        if (self.starsNeededToEnableAnon == 20) {
            unlockMsg = [NSString stringWithFormat:@"Earn %li stars to\nunlock anonymous\nmemories", self.starsNeededToEnableAnon];
        }
        else {
            unlockMsg = [NSString stringWithFormat:@"Earn %li more stars to\nunlock anonymous\nmemories", self.starsNeededToEnableAnon];
        }
        
        NSMutableAttributedString *styledUnlockMsg = [[NSMutableAttributedString alloc] initWithString:unlockMsg];
        NSRange fullRange = NSMakeRange(0, unlockMsg.length);
        NSRange anonRange = [unlockMsg rangeOfString:@"anonymous"];
       
        [styledUnlockMsg addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
        [styledUnlockMsg addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Regular" size:fontSize] range:fullRange];
        [styledUnlockMsg addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:fontSize] range:anonRange];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.maximumLineHeight = fontSize * 1.1;
        [paragraphStyle setAlignment:NSTextAlignmentCenter];
        [styledUnlockMsg addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, styledUnlockMsg.length)];
        
        
        self.anonStarsNeededLbl.attributedText = styledUnlockMsg;
    }
}

#pragma mark - Helper Methods to prep params when posting a memory

-(NSString *)createIdList {
    //get user ids
    NSString *includedUserIds = @"";
    
    if (!self.isAnonMemory) {
    
        NSMutableArray *userIds = [[NSMutableArray alloc] init];
        for (int i = 0; i<[self.selectedFriends count]; i++) {
            Person *tempFriend = (Person *)self.selectedFriends[i];
            NSString *friendID = [NSString stringWithFormat:@"%i",(int)tempFriend.recordID];
            [userIds addObject:friendID];
        }
        
        //add current user id to list of included friends
        User *tempMe = [AuthenticationManager sharedInstance].currentUser;
        int myID = (int)tempMe.userId;
        NSString *currUserId = [NSString stringWithFormat:@"%i",myID];
        [userIds addObject:currUserId];
        
        includedUserIds = [(NSArray *)userIds componentsJoinedByString:@","];
    }
    
    return includedUserIds;
}

-(NSString *)getPrivacy {
 
    NSString *accessType = @"PUBLIC";
    return accessType;
}

-(double)getMemoryLatitude {
    
    double memLat = 0;
    
    if (self.selectedVenue) {
    
        if ([LocationManager sharedInstance].userHasTempSelectedLocation){
            memLat = [LocationManager sharedInstance].tempMemLocation.coordinate.latitude;
        }
        else {
            if ([LocationManager sharedInstance].userHasManuallySelectedLocation) {
                memLat = [LocationManager sharedInstance].manualLocation.coordinate.latitude;
            }
            else {
                memLat = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
            }
        }
    }
    
    return memLat;
}

-(double)getMemoryLongitude {
    
    double memLong = 0;
    
    if (self.selectedVenue) {
    
        if ([LocationManager sharedInstance].userHasTempSelectedLocation){
            memLong = [LocationManager sharedInstance].tempMemLocation.coordinate.longitude;
        }
        else {
            if ([LocationManager sharedInstance].userHasManuallySelectedLocation) {
                memLong = [LocationManager sharedInstance].manualLocation.coordinate.longitude;
            }
            else {
                memLong = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
            }
        }
    }
    
    return memLong;
}

-(void)updateVenue {
    self.anchorBtn.backgroundColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:0.7f];
    [self.anchorBtn setTitle:NSLocalizedString(@"Spaycing", nil) forState:UIControlStateNormal];

    if (!self.isAnchoring) {
    
        self.isAnchoring = YES;
        
        if (self.selectedVenue) {
            [self prepPost];
        } else if ([LocationManager sharedInstance].userHasTempSelectedLocation) {
            self.selectedVenue = [LocationManager sharedInstance].tempMemVenue;
            [self prepPost];
        }
        else {
            [[LocationContentManager sharedInstance] getContent:@[SPCLocationContentVenue] resultCallback:^(NSDictionary *results) {
                self.selectedVenue = results[SPCLocationContentVenue];
                [self prepPost];
            } faultCallback:^(NSError *fault) {
                self.isAnchoring = NO;
                self.anchorBtn.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
                [self.anchorBtn setTitle:NSLocalizedString(@"Spayce", nil) forState:UIControlStateNormal];
                
                NSLog(@"Fault retrieving address id... %@", fault);
            }];
        }
    }
}

-(int)getMemoryType {
    
    int currType = 1;
    
    if (self.assetUploadCoordinator.hasImages) {
        currType = 2;
    }
    if (self.assetUploadCoordinator.hasVideos) {
        currType = 3;
    }
    
    return currType;
}

-(NSString *)getAssetIds {
    NSString *assetIds = @"";
    NSArray *assetIdStrs = self.assetUploadCoordinator.uploadedAssetIdStrings;
    
    if ([assetIdStrs count] > 0) {
        assetIds = [assetIdStrs componentsJoinedByString:@","];
    }
    
    return assetIds;
}

-(NSString *)getHashTags {

    //turn our array of selected hash tags into a " " separated string with all #'s stripped out
    NSMutableArray *hashTagsArray = [NSMutableArray arrayWithArray:[self.hashTagSuggestions getSelectedHashTags]];
    NSMutableString *fullHashTagString = [[NSMutableString alloc] initWithString:@""];
    
    while (hashTagsArray.count > 0) {

        //get the next hash tag
        NSString *hashedTag = [hashTagsArray objectAtIndex:0];
        
        // sanity check
        if (hashedTag.length > 1) {
        
            //strip out the #s
            NSString *cleanTag = [hashedTag substringFromIndex:1];
            //NSLog(@"cleanTag %@",cleanTag);

            //append to our full string with a trailing space
            if (hashTagsArray.count > 1) {
                [fullHashTagString appendString:[NSString stringWithFormat:@"%@ ",cleanTag]];
                //NSLog(@"updated full string %@",fullHashTagString);
            }
            //add just the tag to our full string (it's the last one)
            else {
                [fullHashTagString appendString:[NSString stringWithFormat:@"%@",cleanTag]];
                //NSLog(@"updated full string %@",fullHashTagString);
            }
        }
        
        //update our data
        [hashTagsArray removeObjectAtIndex:0];
    }
    
    //NSLog(@"full hash tag string :%@",fullHashTagString);
    return fullHashTagString;
}

#pragma mark - Memory Configuration Actions

-(void)setToReal {
    
    self.isAnonMemory = NO;
    
    self.tagFriendsBar.hidden = NO;
    
    UIImage *anonOff = [UIImage imageNamed:@"mamAnon"];
    UIImage *realOn = [UIImage imageNamed:@"mamRealSelected"];
    
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        anonOff = [UIImage imageNamed:@"mamAnonJumbo"];
        realOn = [UIImage imageNamed:@"mamRealJumboSelected"];
    }
    
    
    [self.publicBtn setBackgroundImage:realOn forState:UIControlStateNormal];
    self.publicLbl.textColor = [UIColor whiteColor];
    self.publicLbl.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
    
    self.publicSub.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
    
    
    [self.privateBtn setBackgroundImage:anonOff forState:UIControlStateNormal];
    self.privateLbl.textColor =  [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
    self.privateLbl.backgroundColor = [UIColor clearColor];
    self.privateSub.textColor =  [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];

}

-(void)setToAnon {
    self.isAnonMemory = YES;
    [Flurry logEvent:@"MAM_SET_TO_ANON"];
    
    self.tagFriendsBar.hidden = YES;
    
    UIImage *anonOn = [UIImage imageNamed:@"mamAnonSelected"];
    UIImage *realOff = [UIImage imageNamed:@"mamReal"];
    
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        anonOn = [UIImage imageNamed:@"mamAnonJumboSelected"];
        realOff = [UIImage imageNamed:@"mamRealJumbo"];
    }
    
    
    [self.privateBtn setBackgroundImage:anonOn forState:UIControlStateNormal];
    self.privateLbl.textColor = [UIColor whiteColor];
    self.privateLbl.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
    self.privateSub.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
    
    
    [self.publicBtn setBackgroundImage:realOff forState:UIControlStateNormal];
    self.publicLbl.textColor =  [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
    self.publicSub.textColor =  [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
    self.publicLbl.backgroundColor = [UIColor clearColor];
}

-(void)deleteAsset:(id)sender {
    
    UIButton *delBtn = (UIButton *)sender;
    int deleteIndex = (int)delBtn.tag;
    
    [self.assetUploadCoordinator removePendingAssetAtIndex:deleteIndex];
    
    if (self.assetUploadCoordinator.totalAssetCount == 0) {
        self.selectedTerritory = nil;
        if (self.resetVenueIfAssetsDeleted) {
            self.selectedVenue = nil;
        }
    
        [self setFuzzedDefaultForTextMem];
        [self.delegate updateSelectedVenue:self.selectedVenue];
        [self.delegate updateSelectedTerritory:nil];
    }
    
    //update capture controller
    [self.delegate spcPostMemoryViewControllerDidUpdatePendingAssets:self.assetUploadCoordinator];
    
    
    //update display
    UIView *view;
    NSArray *subs = [self.thumbnailScroller subviews];
    
    
    //3.5"
    float spacing = 80;
    
    //4"
    if ([UIScreen mainScreen].bounds.size.height > 480) {
        spacing = 95;
    }
    
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width >= 375) {
        spacing = 105;
    }
    
    //5.5"
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        spacing = 110;
    }
    
   
    for (view in subs) {
        
        if (view.tag == deleteIndex) {
            [view removeFromSuperview];
        }
        if (view.tag > deleteIndex){
            view.center = CGPointMake(view.center.x - spacing, view.center.y);
            view.tag = view.tag - 1;
        }
    }
    
    self.thumbnailScroller.contentSize = CGSizeMake(self.thumbnailScroller.contentSize.width - spacing, self.thumbnailScroller.contentSize.height);
}

-(void)tagFriends {
    [Flurry logEvent:@"MAM_TAGGED_FRIENDS_TAPPPED"];
    [self.view addSubview:self.tagFriendsViewController.view];
}

-(void)animateChangeLocation {
    [self.delegate spcPostMemoryViewControllerAnimateInChangeLocation];
}

-(void)pickLocation {
    
    [Flurry logEvent:@"MAM_CHANGE_LOCATION_VIEWED"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerDidCancel:withSelectedVenue:)]) {
        [self.textView resignFirstResponder];
        [[LocationManager sharedInstance] cancelTempLocation];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerUpdateTaggedFriendsToRestore:)]) {
            if (self.selectedFriends.count > 0) {
                [self.delegate spcPostMemoryViewControllerUpdateTaggedFriendsToRestore:self.selectedFriends];
            }
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerUpdateMemoryTextToRestore:)]) {
            if (self.textView.text.length > 0) {
                [self.delegate spcPostMemoryViewControllerUpdateMemoryTextToRestore:self.textView.text];
            }
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerUpdateAnonStatusToRestore:)]) {
            [self.delegate spcPostMemoryViewControllerUpdateAnonStatusToRestore:self.isAnonMemory];
        }
        
        [self.delegate spcPostMemoryViewControllerDidCancelToUpdateLocation:self withSelectedVenue:self.selectedVenue];
    }
    
}


#pragma mark - Memory Posting Actions

-(void)prepPost {
    
    NSLog(@"prepPost");
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [self.view addSubview:self.loadingView];
    [self.view addSubview:self.progressBar];
    
    self.progressBarUploadsComplete = -1;
    self.progressBarUploadsCompleteBeforeAnchor = self.assetUploadCoordinator.uploadedAssetCount;
    
    self.uploadStartTime = [[NSDate date] timeIntervalSince1970];
    self.uploadProgress = 0;
    self.uploadStepProgressStart = 0;
    
    [self updateProgressBar:self.assetUploadCoordinator.uploadedAssetCount];
    
    //determine if we need to upload image/video assets before we can post the mem
    int memType = [self getMemoryType];
    
    if (memType == 1) {
        //text mem - cleared to send to server
        [self savePost];
    } else {
        //[self.view addSubview:self.loadingView];
        //[self.view addSubview:self.progressBar];
        //img mem - upload assets first
        __weak typeof(self) weakSelf = self;
        [self.assetUploadCoordinator uploadAssetsWithProgressHandler:^(SPCAssetUploadCoordinator *coordinator, NSInteger assetsUploaded, NSInteger totalAssets) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf updateProgressBar:assetsUploaded];
        } completionHander:^(SPCAssetUploadCoordinator *coordinator) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf updateProgressBar:coordinator.uploadedAssetCount];
            [strongSelf savePost];
        } failureHandler:^(SPCAssetUploadCoordinator *coordinator, NSError *error) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf stopLoadingProgressView];
            self.progressBarUploadsComplete = 0;
            
            NSString *message = (strongSelf.assetUploadCoordinator.hasVideos
                                 ? @"There was an error saving your videos for this memory. Please try again"
                                 : @"There was an error saving your images for this memory. Please try again");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
            [alertView show];
            
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            
            self.isAnchoring = NO;
        }];
    }
}

-(void)savePost {

    NSLog(@"save post!");
    
    //MEMORY TEXT
    NSString *memText = self.textView.text;
    
    //TAGGED FRIENDS
    self.includedIds = [self createIdList];
    
    //PUBLIC/PRIVATE
    NSString *access = [self getPrivacy];
 
    //LOCATION
    double memLat = [self getMemoryLatitude];
    double memLong = [self getMemoryLongitude];
    
    //LOCATION NAME
    NSString *locationName = self.locationLabel.text;
    
    //MEMORY TYPE
    int memType = [self getMemoryType];

    //ASSET IDS
    NSString *assetIds = [self getAssetIds];
    
    //HASHTAGS
    NSString *hashtags = [self getHashTags];
    
    //Venue Address ID
    NSInteger addyId = self.selectedVenue.addressId;
    
    if (self.locationIsHidden) {
        addyId = 0;
        memLat = 0;
        memLong = 0;
    }
    
    __weak typeof(self)weakSelf = self;

    self.memoryPostDidFault = NO;
    
    [MeetManager postMemoryWithUserIds:self.includedIds
                                  text:memText
                              assetIds:assetIds
                             addressId:(int)addyId
                              latitude:memLat
                             longitude:memLong
                            accessType:access
                              hashtags:hashtags
                        fbShareEnabled:NO
                      twitShareEnabled:NO
                                isAnon:self.isAnonMemory
                             territory:self.selectedTerritory
                                  type:memType
                        resultCallback:^(NSInteger memId, Venue *memVenue, NSString *memoryKey) {
                            __strong typeof(weakSelf)strongSelf = weakSelf;
                            
                            //[strongSelf stopLoadingProgressView];
                            if (strongSelf.didFilterImage) {
                                [Flurry logEvent:@"MAM_FILTERED_MEM_POSTED"];
                            }
                           
                            //populate memory object to pass back to the MemoriesViewController
                            NSDictionary *locationDict;
                            
                            NSDictionary *venueDict;
                            
                            if (memVenue) {
                                locationDict = @{@"latitude" : memVenue.latitude,
                                                 @"longitude" : memVenue.longitude};
                                
                                if (memVenue.specificity == SPCVenueIsFuzzedToCity) {
                                    venueDict = @{@"name" : locationName,
                                                  @"latitude" : memVenue.latitude,
                                                  @"longitude" : memVenue.longitude,
                                                  @"addressId" : @(memVenue.addressId),
                                                  @"city" : memVenue.city,
                                                  @"specificity" : @"CITY" };
                                }
                                else if (memVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                                    venueDict = @{@"name" : locationName,
                                                  @"latitude" : memVenue.latitude,
                                                  @"longitude" : memVenue.longitude,
                                                  @"addressId" : @(memVenue.addressId),
                                                  @"neighborhood" : memVenue.neighborhood,
                                                  @"specificity" : @"NEIGHBORHOOD"  };
                                }
                                else {
                                    venueDict = @{@"name" : locationName,
                                                  @"latitude" : memVenue.latitude,
                                                  @"longitude" : memVenue.longitude,
                                                  @"addressId" : @(memVenue.addressId) };
                                }
                                
                            }
                            else {
                                locationDict = @{@"latitude" : @(memLat),
                                                @"longitude" : @(memLong)};
                                
                                venueDict = @{@"name" : locationName,
                                              @"latitude" : @(memLat),
                                              @"longitude" : @(memLong),
                                              @"addressId" : @(addyId) };
                                
                            }
                            
                            NSLog(@"location dict %@",locationDict);
                            NSLog(@"venue dict %@",venueDict);
                            
                            
                            strongSelf.profile = [ContactAndProfileManager sharedInstance].profile;
                            User *tempMe = [AuthenticationManager sharedInstance].currentUser;
                            int authorId = (int)tempMe.userId;
                            
                            NSString *myFirstName =  self.profile.profileDetail.firstname;
                            NSString *myId = [NSString stringWithFormat:@"%i",authorId];
                            NSDictionary *myPhoto = self.profile.profileDetail.imageAsset.attributes;
                            NSString *userToken = tempMe.userToken;
                            NSDictionary *authorDict;
                            
                            int isAnonymousPost = 0;
                            
                            if (strongSelf.isAnonMemory) {
                                NSLog(@"is anon memory!");
                                myFirstName = @"Anonymous";
                                authorId = -2;
                                myId = [NSString stringWithFormat:@"%i",authorId];
                                
                                userToken = @"";
                                myPhoto = [ContactAndProfileManager sharedInstance].profile.profileDetail.anonImageAsset.attributes;
                                isAnonymousPost = 1;
                                strongSelf.selectedFriends = nil;
                            }
                        
                            
                            if (myPhoto) {
                            
                                            authorDict = @{
                                                         @"firstname" : myFirstName,
                                                         @"id" : myId,
                                                         @"profilePhotoAssetInfo" : myPhoto,
                                                         @"userToken" : userToken,
                                                         };
                            } else {
                                            authorDict = @{
                                                             @"firstname" : myFirstName,
                                                             @"id" : myId,
                                                             @"userToken" : userToken,
                                                             };
                            }
                            
                            
                            NSTimeInterval interval = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate])*1000;
                            NSNumber *dateNum = @(interval);
                            
                            int friendsCount = (int)[self.selectedFriends count];
                            NSNumber *fCount = @(friendsCount);
                            
                            NSLog(@"posted mem & callback mem id: %i",(int)memId);
                            NSNumber *memIdNum = @(memId);
                            
                     
                            
                            NSNumber *typeNum = @(memType);
                            
                            NSDictionary *memAttributes;
                            Memory *newMemory;
                            
                            if (memType == 1){
                                
                                NSString *adjMemText = memText;
                                
                                //adjust local copy of wordless text mems
                                if (adjMemText.length == 0) {
                                    adjMemText = @"is here.";
                                }
                                
                                memAttributes = @{
                                                  @"author" : authorDict,
                                                  @"dateCreated" : dateNum,
                                                  @"friends_count" : fCount,
                                                  @"id" : memIdNum,
                                                  @"locationName" : locationName,
                                                  @"location" : locationDict,
                                                  @"text" : adjMemText,
                                                  @"type" : typeNum,
                                                  @"accessType" : access,
                                                  @"localTaggedUsers" : self.selectedFriends,
                                                  @"venue" : venueDict,
                                                  @"isAnonMem" : @(isAnonymousPost)
                                                  };
                                
                                newMemory = [[Memory alloc] initWithAttributes:memAttributes];
                            }
                            
                            if (memType == 2) {
                                memAttributes = @{
                                                  @"author" : authorDict,
                                                  @"dateCreated" : dateNum,
                                                  @"friends_count" : fCount,
                                                  @"id" : memIdNum,
                                                  @"locationName" : locationName,
                                                  @"location" : locationDict,
                                                  @"text" : memText,
                                                  @"type" : typeNum,
                                                  @"assetsInfo" : [Asset arrayOfAttributesWithAssets:self.assetUploadCoordinator.uploadedAssets],
                                                  @"assets" : self.assetUploadCoordinator.uploadedAssetIdStrings,
                                                  @"accessType" : access,
                                                  @"localTaggedUsers" : self.selectedFriends,
                                                  @"venue" : venueDict,
                                                  @"isAnonMem" : @(isAnonymousPost)
                                                  };
                                
                                newMemory = [[ImageMemory alloc] initWithAttributes:memAttributes];
                            }
                            
                            if (memType == 3) {
                                memAttributes = @{
                                                  @"author" : authorDict,
                                                  @"dateCreated" : dateNum,
                                                  @"friends_count" : fCount,
                                                  @"id" : memIdNum,
                                                  @"locationName" : locationName,
                                                  @"location" : locationDict,
                                                  @"text" : memText,
                                                  @"type" : typeNum,
                                                  @"assetsInfo" : [Asset arrayOfAttributesWithAssets:self.assetUploadCoordinator.uploadedAssets],
                                                  @"assets" : self.assetUploadCoordinator.uploadedAssetIdStrings,
                                                  @"accessType" : access,
                                                  @"localTaggedUsers" : self.selectedFriends,
                                                  @"venue" : venueDict,
                                                  @"isAnonMem" : @(isAnonymousPost)
                                                  };
                                
                                newMemory = [[VideoMemory alloc] initWithAttributes:memAttributes];
                            }
                            
                            if (memoryKey) {
                                newMemory.key = memoryKey;
                            }
                            if (newMemory.isAnonMem) {
                                newMemory.userIsWatching = YES;
                            }
                            
                            if (memVenue) {
                                newMemory.venue = memVenue;
                                [strongSelf saveMemoryAndAddToFeed:newMemory withVenue:memVenue];
                            }
                            else {
                                [strongSelf saveMemoryAndAddToFeed:newMemory withVenue:self.selectedVenue];
                            }
                            
                            [strongSelf updateProgressBar:self.assetUploadCoordinator.uploadedAssetCount + 1];
                            
                            // 'isAnchoring' is still true; we will set it to false AFTER
                            // taking a screenshot, which happens in saveScreenshotAndFinish
                        }
                         faultCallback:^(NSError *fault) {
                             NSLog(@"post mem faultCallback: %@", fault);
                             self.memoryPostDidFault = YES;
                             
                             self.isAnchoring = NO;
                             self.anchorBtn.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
                             [self.anchorBtn setTitle:NSLocalizedString(@"Spayce", nil) forState:UIControlStateNormal];
                             
                             [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                             self.progressBarUploadsComplete = -1;
                             [weakSelf stopLoadingProgressView];
                        
                         }
     ];

}


#pragma mark - Loading Screen Helper Methods

- (void)stopLoadingProgressView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.loadingView removeFromSuperview];
    [self.progressBar removeFromSuperview];
    self.view.userInteractionEnabled = YES;
}

- (void)updateProgressBar:(NSInteger)operationsCompleted {
    NSLog(@"updateProgressBar: %i", (int)operationsCompleted);
    if (self.progressBarUploadsComplete == -1 || operationsCompleted != self.progressBarUploadsComplete) {
        float fullWidth = self.view.bounds.size.width;
        
        self.progressBarUploadsComplete = operationsCompleted;
        float numUploadsComplete = operationsCompleted - self.progressBarUploadsCompleteBeforeAnchor;
        float totalUploads = self.assetUploadCoordinator.totalAssetCount - self.progressBarUploadsCompleteBeforeAnchor + 1;
        
        self.uploadStepProgressEnd = numUploadsComplete == totalUploads ? 1.0 : (numUploadsComplete + 1) / totalUploads;
        self.uploadStepProgressStart = self.uploadProgress;
        while (self.uploadStepProgressStart >= self.uploadStepProgressEnd && self.uploadStepProgressEnd < 1) {
            self.uploadStepProgressEnd += 1.0 / totalUploads;
        }
        self.uploadStepStartTime = [[NSDate date] timeIntervalSince1970];
        
        //if (numUploadsComplete == totalUploads) {
        //    self.uploadProgress = 1;
        //}
        
        float currWidth = fullWidth * self.uploadProgress;
        self.progressBar.frame = CGRectMake(0, self.progressBar.frame.origin.y, currWidth, self.progressBar.frame.size.height);
        
        NSTimeInterval loopTicker = 1.0 / 30.0;
        
        if (operationsCompleted == 0) {
            self.uploadStepDurationEstimate = (totalUploads <= 1 ? 1 : 3.0);    // estimate 3 seconds to upload an image, 1 to post the mem.
        } else if (operationsCompleted == totalUploads - 1) {
            // one left: the final post animation.  Estimate just a second.
            self.uploadStepDurationEstimate = 1;
        } else if (operationsCompleted == totalUploads) {
            // finished!  Zip to the finish line.
            if (self.uploadStepProgressStart < self.uploadStepProgressEnd) {
                self.uploadStepDurationEstimate = 0.3;
            }
        } else {
            // normal: use previous uploads as a guide.
            self.uploadStepDurationEstimate = ([[NSDate date] timeIntervalSince1970] - self.uploadStartTime) / numUploadsComplete;
        }
        
        [self.stepTimer invalidate];
        
        //NSLog(@"updating progress bar with progress %f, step estimate %f", self.uploadProgress, self.uploadStepDurationEstimate);
        
        self.stepTimer = [NSTimer scheduledTimerWithTimeInterval:loopTicker target:self selector:@selector(stepProgress:) userInfo:nil repeats:YES];
    }
}

- (void)stepProgress:(NSTimer *)timer {
    
    long numUploadsComplete = self.progressBarUploadsComplete - self.progressBarUploadsCompleteBeforeAnchor;
    long totalUploads = self.assetUploadCoordinator.totalAssetCount - self.progressBarUploadsCompleteBeforeAnchor + 1;
    
    CGFloat stepProportion = ([[NSDate date] timeIntervalSince1970] - self.uploadStepStartTime) / self.uploadStepDurationEstimate;
    self.uploadProgress = self.uploadStepProgressStart + (self.uploadStepProgressEnd - self.uploadStepProgressStart) * stepProportion;
    if (numUploadsComplete < totalUploads) {

        // not the final step.  Smooth out the progress by applying Zeno's paradox,
        // so the progress bar never actually reaches the end point, and never fully stops.
        CGFloat maxStepProportion = (totalUploads - numUploadsComplete);
        
        // the first 0.X step covers the first 0.X of distance.  The next
        // 0.X covers the next 0.X of the REMAINING distance, and so on.
        // In so doing the arrow never reaches its target.
        CGFloat stepRemaining = stepProportion / maxStepProportion;
        CGFloat scale = 1;
        stepProportion = 0;
        
        CGFloat scaleStep = 0.1;        // 0.5 in the original paradox
        while (stepRemaining > 0) {
            // take 0.X of the distance remaining...
            stepProportion += maxStepProportion * scale * MIN(scaleStep, stepRemaining);
            scale *= (1 - scaleStep);
            stepRemaining -= scaleStep;
        }
        
        self.uploadProgress = self.uploadStepProgressStart + (self.uploadStepProgressEnd - self.uploadStepProgressStart) * stepProportion;
        
        //NSLog(@"Zeno-scaled the step proportion %f to %f", originalStepProportion, stepProportion);
    }
    
    if (self.uploadProgress > 1) {
        self.uploadProgress = 1;
        if (numUploadsComplete >= totalUploads) {
            [timer invalidate];
        }
    }
    
    float fullWidth = self.view.bounds.size.width;
    float currWidth = fullWidth * self.uploadProgress;
    
    //NSLog(@"step progress with progress %f, step proportion %f", self.uploadProgress, stepProportion);
    //NSLog(@"step proportion was formed by time-since-start %f, estimated duration %f", ([[NSDate date] timeIntervalSince1970] - self.uploadStepStartTime), self.uploadStepDurationEstimate);
    
    CGRect frame = self.progressBar.frame;
    frame = CGRectMake(0, CGRectGetMinY(frame), currWidth, CGRectGetHeight(frame));
    self.progressBar.frame = frame;
    
    if (self.uploadProgress >= 1 && !self.memoryPostDidFault && numUploadsComplete >= totalUploads) {
        if (self.stepTimer) {
            [self.stepTimer invalidate];
        }
        [self saveScreenshotAndFinish];
    }
}


#pragma mark - Image Editing Methods

-(void)editSourceImage:(id)sender {
    UIButton *editBtn = (UIButton *)sender;
    
    editingAsset = [self.assetUploadCoordinator getPendingAssetWithTag:editBtn.tag];
    [self editImage:editingAsset.imageToCrop];
}

-(void)editImage:(SPCImageToCrop *)sourceImage {
    self.spcImageEditingController = nil;
    self.spcImageEditingController.sourceImage = [[SPCImageToCrop alloc] initWithImageToCrop:sourceImage];
    [self.view addSubview:self.spcImageEditingController.view];
}


#pragma mark - Navigation Methods

- (void)saveMemoryAndAddToFeed:(Memory *)m withVenue:(Venue *)venue {
    m.addressID = venue.addressId;
    m.venue = venue;
    if (!m.isAnonMem){
        m.author.firstname = self.profile.profileDetail.firstname;
        m.author.userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
        if (m.type == MemoryTypeText && [m.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
            m.text = @"is here.";
        }
    }
    // count memories posted
    NSString * numMemoriesPostedKey = [SPCLiterals literal:kSPCNumMemoriesPosted forUser:[AuthenticationManager sharedInstance].currentUser];
    NSInteger numMemoriesPosted = [[NSUserDefaults standardUserDefaults] integerForKey:numMemoriesPostedKey];
    numMemoriesPosted++;
    [[NSUserDefaults standardUserDefaults] setInteger:numMemoriesPosted forKey:numMemoriesPostedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"addMemoryLocally" object:m];
    [[LocationManager sharedInstance] cancelTempLocation];
    
    // 'isAnchoring' is still true; we will set it to false AFTER
    // taking a screenshot, which happens in saveScreenshotAndFinish
}


-(void)saveScreenshotAndFinish {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    //NSLog(@"saveScreenshotAndFinish");
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerDidFinish:)]) {
        self.view.userInteractionEnabled = YES;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        //capture image of screen to use in MAM completion animation
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [self.view.layer renderInContext:context];
        UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *dataForMaMAnimationImage = UIImagePNGRepresentation(currentScreenImg);
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *mamPath = [documentsDirectory stringByAppendingPathComponent:@"mamAnimationImg.png"];
        [dataForMaMAnimationImage writeToFile:mamPath atomically:YES];
        
        [self.view endEditing:YES];
        [self.delegate performSelector:@selector(spcPostMemoryViewControllerDidFinish:) withObject:self afterDelay:0.4];;
    }
    
    self.isAnchoring = NO;
}

-(void)cancel {
    
    BOOL allDone = NO;
    
  if (!self.hashTagSuggestions.hidden) {
      [self hashTagFullSweep];
        self.hashTagSuggestions.hidden = YES;
        self.dismissKeyboardBtn.hidden = YES;
        [self.backBtn setTitle:@"Back" forState:UIControlStateNormal];
        
        if ([self.textView isFirstResponder]) {
            [self.textView resignFirstResponder];
        }
    }
    else {
        allDone = YES;
    }

    
    if (allDone) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerDidCancel:withSelectedVenue:)]) {
            [self.textView resignFirstResponder];
            [[LocationManager sharedInstance] cancelTempLocation];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerUpdateTaggedFriendsToRestore:)]) {
                if (self.selectedFriends.count > 0) {
                    [self.delegate spcPostMemoryViewControllerUpdateTaggedFriendsToRestore:self.selectedFriends];
                }
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerUpdateMemoryTextToRestore:)]) {
                if (self.textView.text.length > 0) {
                    [self.delegate spcPostMemoryViewControllerUpdateMemoryTextToRestore:self.textView.text];
                }
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(spcPostMemoryViewControllerUpdateAnonStatusToRestore:)]) {
                [self.delegate spcPostMemoryViewControllerUpdateAnonStatusToRestore:self.isAnonMemory];
            }
            
            if (self.selectedTerritory) {
                [self.delegate spcPostMemoryViewControllerDidCancel:self withSelectedTerritory:self.selectedTerritory]; 
            }
            else {
                [self.delegate spcPostMemoryViewControllerDidCancel:self withSelectedVenue:self.selectedVenue];
            }

        }
    }
}

#pragma  mark - Orientation Methods

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    UIStatusBarStyle statusBarStyle = UIStatusBarStyleDefault;
    
    return statusBarStyle;
}


#pragma mark - Text Styling Helper Methods

-(void)updatePendingHashTags {

    //NSLog(@" --- update pending hash tags ----");
    
    //get range of any pending hash tags
    NSRange recentHashRange = NSMakeRange(0, 0);
    NSString *lastWord;
    NSString *newHashTag;
    
    if (self.textView.attributedText.length > 0) {
        
        //NSLog(@"updatePendingHashTags from text:%@",self.textView.attributedText.string);
        
        NSRange cursorPosition = [self.textView selectedRange];
        NSString *stringFromCursor = [self.textView.attributedText.string substringToIndex:cursorPosition.location];
        
        NSRange lastWordRange = [stringFromCursor rangeOfString:@" " options:NSBackwardsSearch];

         if (lastWordRange.location != NSNotFound) {
             //just check the last full word from the current cursor position
             lastWord = [stringFromCursor substringFromIndex:lastWordRange.location+1];
             //NSLog(@"last word from cursor position %@",lastWord);
         }
         else {
             //no spaces before the last current word from the cursor position
             //check to see if we should scan the full text for hashtags
             //(only do this if there are no spaces in the whole string; i.e. the first word)
             
             NSString *fullText = self.textView.attributedText.string;
             NSRange fullRange = [fullText rangeOfString:@" " options:NSBackwardsSearch];
             
             if (fullRange.location == NSNotFound) {
                 //no spaces at all so far - this is the only word, see if there is a hashtag
                 lastWord = self.textView.attributedText.string;
                 //NSLog(@"only word %@",lastWord);
             }
         }
        
        //NSLog(@"last word? %@",lastWord);
        
        recentHashRange = [lastWord rangeOfString:@"#" options:NSBackwardsSearch];

        if (recentHashRange.location != NSNotFound) {
            //look like we've got a hashtag?
            newHashTag = [lastWord substringFromIndex:recentHashRange.location];
        }
        else {
        
        }
        
        self.textView.selectedRange = NSMakeRange(cursorPosition.location, 0);
    }
    
    if (newHashTag.length > 0) {
        //NSLog(@"new hashTag %@",newHashTag);
        [self.hashTagSuggestions addedHashTagViaKeyboard:newHashTag];
    }
    
    self.hashTagIsPending = NO;
}

-(BOOL)updateHashTagsAfterDelete {
    
    //get range of any pending hash tags
    NSRange recentHashRange = NSMakeRange(0, 0);
    NSString *lastWord;
    NSString *removeHashTag;
    BOOL deletedHashTag = NO;
    
    NSRange cursorPosition = [self.textView selectedRange];
    
    NSString *stringBeforeCursor = [self.textView.attributedText.string substringToIndex:cursorPosition.location];
    NSString *stringAfterCursor = [self.textView.attributedText.string substringFromIndex:cursorPosition.location];
    
    NSLog(@"string before cursor %@",stringBeforeCursor);
    NSLog(@"string after cursor %@",stringAfterCursor);
    
    if (stringBeforeCursor > 0) {
        
        //NSLog(@"updateHashTagsAfterDelete from text:%@",self.textView.attributedText.string);
        
        NSRange lastWordRange = [stringBeforeCursor rangeOfString:@" " options:NSBackwardsSearch];
        
        if (lastWordRange.location != NSNotFound) {
            //just check the last word
            lastWord = [stringBeforeCursor substringFromIndex:lastWordRange.location+1];
        }
        else {
            //no spaces yet, use full text
            lastWord = stringBeforeCursor;
        }
        
        //NSLog(@"last word? %@",lastWord);
        
        recentHashRange = [lastWord rangeOfString:@"#" options:NSBackwardsSearch];
        
        if (recentHashRange.location != NSNotFound) {
            //look like we've got a hashtag?
            
            removeHashTag = [lastWord substringFromIndex:recentHashRange.location];
            NSLog(@"remove hash tag %@",removeHashTag);
            
            NSInteger remainingTextLength = lastWordRange.location + recentHashRange.location + 1;
            if (remainingTextLength > self.textView.attributedText.string.length) {
                remainingTextLength = 0;
            }
            
            NSString *remainingTextBeforeCursor = [stringBeforeCursor substringWithRange:NSMakeRange(0, remainingTextLength)];
            NSLog(@"remaining text %@",remainingTextBeforeCursor);
            if (remainingTextBeforeCursor.length > 0) {
                NSString *remainingText = [NSString stringWithFormat:@"%@%@",remainingTextBeforeCursor,stringAfterCursor];
                NSMutableAttributedString *remText = [[NSMutableAttributedString alloc] initWithString:remainingText];
                self.textView.attributedText = remText;
            }
            else {
                self.textView.text = stringAfterCursor;
            }
        }
    }
    
    if (removeHashTag.length > 0) {
        //NSLog(@"remove hashTag %@",removeHashTag);
        [self.hashTagSuggestions deletedHashTagViaKeyboard:removeHashTag];
        deletedHashTag = YES;
    }
    
    self.hashTagIsPending = NO;
    return deletedHashTag;
}

- (void)updateHashStyling {
    
    NSString *memText = [NSString stringWithFormat:@"%@",self.textView.text];
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:memText];
    
    //base styling
    [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f] range:NSMakeRange(0, attStr.length)];
    [attStr addAttribute:NSFontAttributeName value:[UIFont spc_regularSystemFontOfSize:14] range:NSMakeRange(0, attStr.length)];
    
    //get updated list of included hash tags
    NSArray *tempArray = [self.hashTagSuggestions getSelectedHashTags];
    //NSLog(@"currently selected hash tags %@",tempArray);
    
    //style any included hash tags
    for (int i = 0; i < tempArray.count; i++) {
        NSString *hashTag = [tempArray objectAtIndex:i];

        //get range(s) of hashtag in current text
     
        NSRange hashRange = [attStr.string rangeOfString:hashTag options:NSBackwardsSearch];
      
        while(hashRange.location != NSNotFound)
        {
            //NSRange hashRange = [attStr.string rangeOfString:hashTag];
            //NSLog(@"style hash %@", hashTag);
            
            [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] range:hashRange];
            [attStr addAttribute:NSFontAttributeName value:[UIFont spc_mediumSystemFontOfSize:14] range:hashRange];
            
            hashRange = [attStr.string rangeOfString:hashTag options:NSBackwardsSearch range:NSMakeRange(0, hashRange.location)];
        }
        
    }

    self.textView.attributedText = attStr;
}

- (void)hashTagFullSweep {
    
    NSString *workingString = [NSString stringWithFormat:@"%@",self.textView.text];
    NSLog(@"working string %@",workingString);
    
    NSRange range = [workingString rangeOfString:@"#"];
    NSMutableArray *updatedHashArray = [[NSMutableArray alloc] init];
    
    while(range.location != NSNotFound) {

        //found a #, get the hashtag
        NSRange currRange = [workingString rangeOfString:@"#"];
        
        if  (currRange.location != NSNotFound) {
            NSString *hashSearchString = [workingString substringFromIndex:currRange.location];
            NSLog(@"hash search string %@",hashSearchString);
            
            NSRange hashEndRange = [hashSearchString rangeOfString:@" "];
            NSString *hashTag;
            
            //this is the last word in our text
            if (hashEndRange.location == NSNotFound) {
                NSLog(@"looks like the last word is a hashtag!");
                hashTag = hashSearchString;
            }
            //just get the chunk between the '#' and the ' '
            else {
                hashTag = [hashSearchString substringWithRange:NSMakeRange(0, hashEndRange.location)];
            }
            
            NSLog(@"found hashTag:%@", hashTag);
            if (hashTag.length > 1){
                [updatedHashArray addObject:hashTag];
            }
            
            NSInteger lastHashEndLocation = currRange.location + hashTag.length;

            //continue on our our search
            if (workingString.length > lastHashEndLocation && workingString.length > 0) {
                workingString = [workingString substringFromIndex:lastHashEndLocation];
                NSLog(@"updated working string %@",workingString);
                if (workingString.length == 0) {
                    break;
                }
            }
            else  {
                NSLog(@"string all done!");
                break;
            }
        }
        else {
            NSLog(@"no more hashtags!");
            break;
        }
    }
    
    for (int i = 0; i < updatedHashArray.count; i ++) {
        NSLog(@"%@",updatedHashArray[i]);
    }
    
    //update our array!
    [self.hashTagSuggestions updateAllSelectedHashTags:updatedHashArray];
    
    //now that we've updated our list of hashtags, update our styling
    [self updateHashStyling];
}


#pragma mark - SPCHashTagSuggestionsDelegate

- (void)tappedToAddHashTag:(NSString *)hashTag {
    
    if (self.hashTagIsPending) {
        [self updatePendingHashTags];
    }
    
    [self updateHashStyling];
    self.locationTagPrompt.text = @"";
    self.locationTagPrompt.hidden = YES;
    
    NSMutableAttributedString *attStr;
    
    if (self.textView.attributedText.length > 0) {
        //NSLog(@"hash tag tapped and string is already styled");
        attStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
        
        //append styled hashtag with spacing
        NSMutableAttributedString *newHashStr;
        
        //add spacing if needed
        unichar last = [attStr.string characterAtIndex:[attStr.string length] - 1];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:last]) {
            //new hashtag is preceded by a space, we are ok
            newHashStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",hashTag]];
        }
        else {
            //we need to add a space before (and after) the hashtag!
            newHashStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ ",hashTag]];
        }
        
        [newHashStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] range:NSMakeRange(0, newHashStr.length-1)];
        [newHashStr addAttribute:NSFontAttributeName value:[UIFont spc_mediumSystemFontOfSize:14] range:NSMakeRange(0, newHashStr.length-1)];
        [attStr appendAttributedString:newHashStr];
        
        self.textView.attributedText = attStr;
    }
    else {
        //NSLog(@"hash tag tapped and string is not yet styled");
        attStr = [[NSMutableAttributedString alloc] initWithString:self.textView.text];
        [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f] range:NSMakeRange(0, attStr.length)];
        [attStr addAttribute:NSFontAttributeName value:[UIFont spc_regularSystemFontOfSize:14] range:NSMakeRange(0, attStr.length)];
        
        //append styled hashtag with spacing
        NSMutableAttributedString *newHashStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",hashTag]];
        [newHashStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] range:NSMakeRange(0, newHashStr.length-1)];
        [newHashStr addAttribute:NSFontAttributeName value:[UIFont spc_mediumSystemFontOfSize:14] range:NSMakeRange(0, newHashStr.length-1)];
        [attStr appendAttributedString:newHashStr];
        
        self.textView.attributedText = attStr;
    }
    
    self.placeholderTextLabel.hidden = YES;
}

- (void)tappedToAddLocationHashTag:(NSString *)hashTag {
    
    //NSLog(@" --- tappedToAddLocationHashTag:%@ ----", hashTag);
    
    if (self.hashTagIsPending) {
        [self updatePendingHashTags];
    }
    
    [self updateHashStyling];
    
    NSMutableAttributedString *attStr;
    
    if (self.textView.attributedText.length > 0) {
        //NSLog(@"loc tag tapped and string is already styled");
        attStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
        
        //add base-styled pending hashtag
        NSMutableAttributedString *newHashStr;
        
        //add spacing if needed
        unichar last = [attStr.string characterAtIndex:[attStr.string length] - 1];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:last]) {
            //new hashtag is preceded by a space, we are ok
            newHashStr = [[NSMutableAttributedString alloc] initWithString:hashTag];
        }
        else {
            //we need to add a space before the hashtag!
            newHashStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",hashTag]];
        }
        
        [newHashStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f] range:NSMakeRange(0, newHashStr.length)];
        [newHashStr addAttribute:NSFontAttributeName value:[UIFont spc_regularSystemFontOfSize:14] range:NSMakeRange(0, newHashStr.length)];

        [attStr appendAttributedString:newHashStr];
        self.textView.attributedText = attStr;
    }
    else {
        //NSLog(@"loc tag tapped and string is not yet styled");
        //create base styled text with pending hash tag
        NSString *newText = [NSString stringWithFormat:@"%@ %@",self.textView.text,hashTag];
        attStr = [[NSMutableAttributedString alloc] initWithString:newText];
        [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f] range:NSMakeRange(0, attStr.length)];
        [attStr addAttribute:NSFontAttributeName value:[UIFont spc_regularSystemFontOfSize:14] range:NSMakeRange(0, attStr.length)];

        self.textView.attributedText = attStr;
    }
    
    self.placeholderTextLabel.hidden = YES;
    
    CGPoint cursorPosition = [self.textView caretRectForPosition:self.textView.selectedTextRange.start].origin;
    //NSLog(@"cursor position x: %f y : %f",cursorPosition.x,cursorPosition.y);
    
    if ([hashTag isEqualToString:@"#floor"] || [hashTag isEqualToString:@"#apartment"] || [hashTag isEqualToString:@"#seat"] || [hashTag isEqualToString:@"#room"]) {
        self.locationTagPrompt.text = @"number";
    }
    if ([hashTag isEqualToString:@"#class"] || [hashTag isEqualToString:@"#office"]) {
        self.locationTagPrompt.text = @"name";
    }
    
    [self.locationTagPrompt sizeToFit];
    self.locationTagPrompt.frame = CGRectMake(cursorPosition.x + 12, 1 + cursorPosition.y + CGRectGetMinY(self.textView.frame), self.locationTagPrompt.frame.size.width, self.locationTagPrompt.frame.size.height);
    
    if (CGRectGetMaxX(self.locationTagPrompt.frame) > self.view.bounds.size.width) {
        self.locationTagPrompt.frame = CGRectMake(8, 1  + cursorPosition.y + self.textView.font.lineHeight + CGRectGetMinY(self.textView.frame), self.locationTagPrompt.frame.size.width, self.locationTagPrompt.frame.size.height);
    }
    
    //NSLog(@"loc tag prompt origin x%f y%f w%f h%f",self.locationTagPrompt.frame.origin.x,self.locationTagPrompt.frame.origin.y,self.locationTagPrompt.frame.size.width,self.locationTagPrompt.frame.size.height);
    
    self.locationTagPrompt.hidden = NO;
    self.hashTagIsPending = YES;
}

- (void)tappedToRemoveHashTag:(NSString *)hashTag {
    
    //traverse text to remove and then restyle everything
    NSString *originalString = self.textView.attributedText.string;
    
    NSString *placeholder = @"%(?<!\\S)%@(?!\\S)";
    NSString *pattern = [NSString stringWithFormat:placeholder, hashTag];
    NSError* regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&regexError];
    
    NSLog(@"pattern %@",pattern);

    NSString *modifiedString = [regex stringByReplacingMatchesInString:originalString
                                    options:0
                                      range:NSMakeRange(0, [originalString length])
                               withTemplate:@""];
    
    NSString *twiceUpdatedString = [modifiedString stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    
    NSLog(@"modified string %@",modifiedString);
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:twiceUpdatedString];
    
    self.textView.attributedText = attString;
    [self updateHashStyling];
    
}

-(void)hashTagsDidScroll {
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}


#pragma mark = Anon Education Screen


- (void)presentAnonUnlockScreenAfterDelay:(NSNumber *)delayInSeconds {
    __weak typeof(self) weakSelf = self;
    
    if (self.viewIsVisible) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delayInSeconds floatValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf.viewIsVisible && !strongSelf.presentedAnonUnlockScreenInstance) {
                
                if ([strongSelf.textView isFirstResponder]) {
                    [strongSelf.textView resignFirstResponder];
                }
                
                strongSelf.presentedAnonUnlockScreenInstance = YES;
                UIImage *imageBlurred = [UIImageEffects takeSnapshotOfView:strongSelf.view];
                imageBlurred = [UIImageEffects imageByApplyingBlurToImage:imageBlurred withRadius:5.0 tintColor:[UIColor colorWithWhite:0 alpha:0.4] saturationDeltaFactor:2.0 maskImage:nil];
                strongSelf.viewBlurredScreen = [[UIImageView alloc] initWithImage:imageBlurred];
                
                CGRect frameToPresent = CGRectMake(10, 50, CGRectGetWidth(strongSelf.view.bounds) - 20, CGRectGetHeight(strongSelf.view.frame) - 100 - 45); // 45pt for toolbar height
                strongSelf.anonUnlockScreen = [[SPCAnonUnlockedView alloc] initWithFrame:frameToPresent];
                [strongSelf.anonUnlockScreen.btnFinished addTarget:strongSelf action:@selector(dismissAnonUnlockScreen:) forControlEvents:UIControlEventTouchUpInside];
                
                [UIView transitionWithView:strongSelf.view
                                  duration:0.6f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    [strongSelf.view addSubview:strongSelf.viewBlurredScreen];
                                    [strongSelf.view addSubview:strongSelf.anonUnlockScreen];
                                }
                                completion:nil];
            }
        });
    }
}

- (void)dismissAnonUnlockScreen:(id)sender {
    [UIView transitionWithView:self.view
                      duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ {
                        [self.anonUnlockScreen removeFromSuperview];
                        [self.viewBlurredScreen removeFromSuperview];
                    }
                    completion:^(BOOL completed) {
                        self.anonUnlockScreen = nil;
                        self.viewBlurredScreen = nil;
                    }];
    
    // Set shown on dismissal
    [self setAnonUnlockScreenWasShown:YES];
}

- (void)setAnonUnlockScreenWasShown:(BOOL)anonUnlockScreenWasShown {
    NSString *strAnonUnlockStringUserLiteralKey = [SPCLiterals literal:kSPCAnonUnlockScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    [[NSUserDefaults standardUserDefaults] setBool:anonUnlockScreenWasShown forKey:strAnonUnlockStringUserLiteralKey];
}

- (BOOL)anonUnlockScreenWasShown {
    BOOL wasShown = NO;
    
    NSString *strAnonUnlockStringUserLiteralKey = [SPCLiterals literal:kSPCAnonUnlockScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:strAnonUnlockStringUserLiteralKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strAnonUnlockStringUserLiteralKey];
    }
    
    return wasShown;
}

@end
