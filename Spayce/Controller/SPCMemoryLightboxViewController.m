//
//  SPCMemoryLightboxViewController.m
//  Spayce
//
//  Created by Jake Rosin on 10/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCMemoryLightboxViewController.h"
#import "SPCAdjustMemoryLocationViewController.h"
#import "SPCProfileViewController.h"
#import "SPCTagFriendsViewController.h"
#import "SPCFeedPhotoScroller.h"
#import "SPCFeedVideoScroller.h"
#import "SPCAlertViewController.h"
#import "SPCStarsViewController.h"
#import "SPCReportViewController.h"
#import "SPCAdminSockPuppetChooserViewController.h"

#import "SPCMemoryCoordinator.h"

#import "SPCAlertTransitionAnimator.h"

#import "SPCAlertAction.h"

#import "AppDelegate.h"

#import "SPCMainViewController.h"

// Framework
#import "Flurry.h"

// Category
#import "UIAlertView+SPCAdditions.h"
#import "UITabBarController+SPCAdditions.h"
#import "UIViewController+SPCAdditions.h"

// Managers
#import "SocialService.h"
#import "AuthenticationManager.h"
#import "MeetManager.h"
#import "ProfileManager.h"
#import "ContactAndProfileManager.h"
#import "AdminManager.h"

// Views
#import "PXAlertView.h"
#import "MemoryActionButton.h"
#import "SPCInitialsImageView.h"
#import "UIImageView+WebCache.h"
#import "SPCReportAlertView.h"

// Model
#import "User.h"
#import "Person.h"
#import "Memory.h"
#import "UserProfile.h"
#import "ProfileDetail.h"
#import "Asset.h"

// Utils
#import "ImageUtils.h"
#import "NSString+SPCAdditions.h"



@interface SPCMemoryLightboxViewController ()<UIViewControllerTransitioningDelegate, SPCFeedPhotoScrollerDelegate, SPCFeedVideoScrollerDelegate, SPCReportAlertViewDelegate, SPCReportViewControllerDelegate, SPCAdminSockPuppetChooserViewControllerDelegate>

@property (nonatomic, strong) Memory *memory;
@property (nonatomic, assign) NSInteger initialAssetIndex;

@property (nonatomic, strong) UIView *navigationBar;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, readonly) UIView *contentScroller;
@property (nonatomic, strong) SPCFeedPhotoScroller *photoScroller;
@property (nonatomic, strong) SPCFeedVideoScroller *videoScroller;

@property (nonatomic, strong) MemoryActionButton *starButton;
@property (nonatomic, strong) MemoryActionButton *usersToStarButton;
@property (nonatomic, strong) MemoryActionButton *commentButton;

// star animation
@property (strong, nonatomic) UIView *starAnimationBg;
@property (strong, nonatomic) UIImageView *starAnimationStar;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;

// contracted views
@property (nonatomic, strong) UILabel *memoryTextTruncated;
@property (nonatomic, strong) UIImageView *expandChevron;

// expanded views
@property (nonatomic, strong) UILabel *memoryText;
@property (nonatomic, strong) SPCInitialsImageView *authorPhotoView;
@property (nonatomic, strong) UIButton *authorPhotoButton;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIImageView *locationIcon;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UIButton *locationButton;
@property (nonatomic, strong) UIImageView *contractChevron;

@property (nonatomic, strong) UIButton *expandButton;
@property (nonatomic, strong) UIButton *contractButton;
@property (nonatomic, strong) CAGradientLayer *contractButtonGradientLayer;

@property (nonatomic, strong) PXAlertView *alertView;
@property (nonatomic, strong) SPCReportAlertView *reportAlertView;
@property (nonatomic) SPCReportType reportType;
@property (nonatomic, strong) NSArray *reportMemoryOptions;

@property (nonatomic, assign) BOOL isVisible;

// constraints
@property (nonatomic, strong) NSLayoutConstraint *authorLabelWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *locationLabelWidthConstraint;


// Coordinator
@property (nonatomic, strong) SPCMemoryCoordinator *memoryCoordinator;

@property (nonatomic, strong) SPCTagFriendsViewController *tagFriendsViewController;

// Async image loads
@property (nonatomic, strong) UIImageView *userToStarAsyncLoadView;

@end

@implementation SPCMemoryLightboxViewController {
    NSInteger alertViewTagTwitter;
    NSInteger alertViewTagFacebook;
    NSInteger alertViewTagReport;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithMemory:(Memory *)memory {
    self = [self initWithMemory:memory currentAssetIndex:0];
    
    return self;
}

- (instancetype)initWithMemory:(Memory *)memory currentAssetIndex:(int)currentAssetIndex {
    self = [super init];
    if (self) {
        self.memory = memory;
        self.initialAssetIndex = currentAssetIndex;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    // load errthing
    self.view.backgroundColor = [UIColor colorWithRGBHex:0x070f1b];
    
    // Nav bar!
    self.navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.navigationBar];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:64]];
    
    // Content scroller!
    if (self.memory.type == MemoryTypeImage) {
        self.photoScroller = [[SPCFeedPhotoScroller alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
        self.photoScroller.delegate = self;
        self.photoScroller.lightbox = YES;
        
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
        _doubleTap.numberOfTapsRequired = 2;
        [self.photoScroller addGestureRecognizer:_doubleTap];
        
    } else if (self.memory.type == MemoryTypeVideo) {
        self.videoScroller = [[SPCFeedVideoScroller alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
        self.videoScroller.delegate = self;
        self.videoScroller.lightbox = YES;
        
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
        _doubleTap.numberOfTapsRequired = 2;
        [self.videoScroller addGestureRecognizer:_doubleTap];
    }
    
    // place in the exact center of the screen.
    self.contentScroller.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.contentScroller];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contentScroller attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contentScroller attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contentScroller attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contentScroller attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    
    // star animation: appears on top of the content scroller
    self.starAnimationBg = [[UIView alloc] init];
    self.starAnimationBg.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    self.starAnimationBg.hidden = YES;
    self.starAnimationBg.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.starAnimationBg];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.starAnimationBg attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentScroller attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.starAnimationBg attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentScroller attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.starAnimationBg attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentScroller attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.starAnimationBg attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentScroller attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    
    
    self.starAnimationStar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-white"]];
    self.starAnimationStar.hidden = YES;
    [self.view addSubview:self.starAnimationStar];
    
    // separator between content buttons and text
    UIView *separator = [[UIView alloc] initWithFrame:CGRectZero];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.backgroundColor = [UIColor colorWithRGBHex:0x282c33];
    [self.view addSubview:separator];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:separator attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-45]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:separator attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:separator attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:separator attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:(1.0f / [UIScreen mainScreen].scale)]];
    
    // Expand button!
    self.expandButton = [[UIButton alloc] init];
    self.expandButton.backgroundColor = [UIColor clearColor];
    [self.expandButton addTarget:self action:@selector(expand:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.expandButton];
    self.expandButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.expandButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentScroller attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.expandButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.expandButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.expandButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:separator attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    
    // Contract button!
    self.contractButton = [[UIButton alloc] init];
    self.contractButton.backgroundColor = [UIColor clearColor];
    [self.contractButton addTarget:self action:@selector(contract:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.contractButton];
    self.contractButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contractButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contractButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contractButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contractButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:separator attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    
    self.contractButtonGradientLayer = [CAGradientLayer layer];
    self.contractButtonGradientLayer.colors = @[(id)[UIColor colorWithRGBHex:0x070f1b alpha:0.4].CGColor, (id)[UIColor colorWithRGBHex:0x070f1b alpha:0.9].CGColor];
    self.contractButtonGradientLayer.startPoint = CGPointMake(0.5, 0);
    self.contractButtonGradientLayer.endPoint = CGPointMake(0.5, 1);
    [self.contractButton.layer insertSublayer:self.contractButtonGradientLayer atIndex:0];
    
    
    // Truncated view elements
    self.memoryTextTruncated = [[UILabel alloc] init];
    self.memoryTextTruncated.font = [UIFont spc_regularSystemFontOfSize:14];
    self.memoryTextTruncated.textColor = [UIColor whiteColor];
    self.memoryTextTruncated.numberOfLines = 2;
    self.memoryTextTruncated.userInteractionEnabled = NO;
    self.memoryTextTruncated.lineBreakMode = NSLineBreakByWordWrapping;
    self.memoryTextTruncated.text = [self.memory.text stringByEllipsizingWithSize:CGSizeMake(self.view.frame.size.width-30, self.memoryTextTruncated.font.lineHeight*2) attributes:@{NSFontAttributeName : self.memoryTextTruncated.font}];
    self.memoryTextTruncated.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.memoryTextTruncated];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.memoryTextTruncated attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:ceil(self.memoryTextTruncated.font.lineHeight*2)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.memoryTextTruncated attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.memoryTextTruncated attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.memoryTextTruncated attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-70]];
    
    self.expandChevron = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"memory-lightbox-expand"]];
    self.expandChevron.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.expandChevron];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.expandChevron attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.expandChevron attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:separator attribute:NSLayoutAttributeTop multiplier:1 constant:-9]];
    
    
    // Expanded view elements
    self.memoryText = [[UILabel alloc] init];
    self.memoryText.font = [UIFont spc_regularSystemFontOfSize:14];
    self.memoryText.textColor = [UIColor whiteColor];
    self.memoryText.numberOfLines = -1;
    self.memoryText.userInteractionEnabled = NO;
    self.memoryText.lineBreakMode = NSLineBreakByWordWrapping;
    self.memoryText.text = self.memory.text;
    self.memoryText.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.memoryText];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.memoryText attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:ceil([self.memory.text boundingRectWithSize:CGSizeMake(self.view.frame.size.width-30, 100000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : self.memoryText.font} context:nil].size.height)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.memoryText attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.memoryText attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.memoryText attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-70]];
    
    self.authorPhotoView = [[SPCInitialsImageView alloc] init];
    self.authorPhotoView.backgroundColor = [UIColor whiteColor];
    self.authorPhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.authorPhotoView.translatesAutoresizingMaskIntoConstraints = NO;
    self.authorPhotoView.layer.cornerRadius = 25;
    self.authorPhotoView.layer.masksToBounds = YES;
    self.authorPhotoView.textLabel.font = [UIFont spc_placeholderFont];
    [self.authorPhotoView configureWithText:self.memory.author.displayName.firstLetter url:[NSURL URLWithString:self.memory.author.imageAsset.imageUrlThumbnail]];
    [self.view addSubview:self.authorPhotoView];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorPhotoView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.memoryText attribute:NSLayoutAttributeTop multiplier:1.0 constant:-8]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorPhotoView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorPhotoView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:50]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorPhotoView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:50]];
    
    self.authorPhotoButton = [[UIButton alloc] init];
    self.authorPhotoButton.backgroundColor = [UIColor clearColor];
    self.authorPhotoButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.authorPhotoButton addTarget:self action:@selector(showTappedProfileFromButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.authorPhotoButton];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorPhotoButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorPhotoButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorPhotoButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorPhotoButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    
    
    self.authorLabel = [[UILabel alloc] init];
    self.authorLabel.font = [UIFont spc_memory_authorFont];
    self.authorLabel.textColor = [UIColor whiteColor];
    self.authorLabel.userInteractionEnabled = NO;
    self.authorLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.authorLabel.text = self.memory.author.displayName;
    self.authorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.authorLabel];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
    self.authorLabelWidthConstraint = [NSLayoutConstraint constraintWithItem:self.authorLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:[self.memory.author.displayName sizeWithAttributes:@{NSFontAttributeName : self.authorLabel.font}].width];
    [self.view addConstraint:self.authorLabelWidthConstraint];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-self.authorLabel.font.lineHeight/2]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.authorLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:self.authorLabel.font.lineHeight]];
    
    self.locationIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin-lightboxgray-xx-small"]];
    self.locationIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.locationIcon];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationIcon attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeRight multiplier:1.0 constant:9]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationIcon attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:([UIFont spc_memory_locationFont].lineHeight/2 -1)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationIcon attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:self.locationIcon.image.size.width]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationIcon attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:self.locationIcon.image.size.height]];
    
    
    NSString *locationString = self.memory.venue.displayName ? self.memory.venue.displayName : self.memory.locationName;
    self.locationLabel = [[UILabel alloc] init];
    self.locationLabel.font = [UIFont spc_memory_locationFont];
    self.locationLabel.textColor = [UIColor colorWithRGBHex:0x515456];
    self.locationLabel.userInteractionEnabled = NO;
    self.locationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.locationLabel.text = locationString;
    self.locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.locationLabel];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.locationIcon attribute:NSLayoutAttributeRight multiplier:1.0 constant:2]];
    self.locationLabelWidthConstraint = [NSLayoutConstraint constraintWithItem:self.locationLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:[locationString sizeWithAttributes:@{NSFontAttributeName : self.locationLabel.font}].width];
    [self.view addConstraint:self.locationLabelWidthConstraint];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.authorPhotoView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:self.locationLabel.font.lineHeight/2]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:self.locationLabel.font.lineHeight]];
    
    self.locationButton = [[UIButton alloc] init];
    self.locationButton.backgroundColor = [UIColor clearColor];
    [self.locationButton addTarget:self action:@selector(showLocation:) forControlEvents:UIControlEventTouchUpInside];
    self.locationButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.locationButton];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.locationLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.locationLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.locationLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.locationButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.locationLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    self.dateLabel.textColor = [UIColor colorWithRGBHex:0x515456];
    self.dateLabel.userInteractionEnabled = NO;
    self.dateLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.dateLabel.text = [NSString stringWithFormat:@" - %@", self.memory.timeElapsed];
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.dateLabel];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.dateLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.authorLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.dateLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.dateLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.authorLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.dateLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.authorLabel attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    
    
    self.contractChevron = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"memory-lightbox-contract"]];
    self.contractChevron.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.contractChevron];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contractChevron attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.expandChevron attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contractChevron attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.expandChevron attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    
    
    // Bottom buttons
    self.starButton = [[MemoryActionButton alloc] initWithFrame:CGRectZero];
    [self.starButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.starButton];
    
    self.usersToStarButton = [[MemoryActionButton alloc] initWithFrame:CGRectZero];
    [self.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.usersToStarButton];
    
    self.commentButton = [[MemoryActionButton alloc] initWithFrame:CGRectZero];
    [self.commentButton addTarget:self action:@selector(showMemoryRelatedComments:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.commentButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFailedToLoad) name:@"videoLoadFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryUpdated:) name:SPCMemoryUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPersonUpdateWithNotification:) name:kPersonUpdateNotificationName object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [Flurry logEvent:@"LIGHTBOX_VIEW"];
    if (self.photoScroller) {
        [self.photoScroller setMemoryImages:((ImageMemory *)self.memory).images withCurrentImage:(int)self.initialAssetIndex];
    } else {
        [self.videoScroller setMemoryImages:((VideoMemory *)self.memory).previewImages withCurrentImage:(int)self.initialAssetIndex];
        [self.videoScroller addVidURLs:((VideoMemory *)self.memory).videoURLs];
    }
    
    self.view.clipsToBounds = YES;
    self.contentScroller.clipsToBounds = YES;
    
    [self.view setNeedsUpdateConstraints];
    
    [self updateTitle];
    [self updateButtons];
    [self contract:self.contractButton];
    
    alertViewTagFacebook = 0;
    alertViewTagTwitter = 1;
    alertViewTagReport = 2;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.isVisible = YES;
    self.navigationController.navigationBarHidden = YES;
    
    // Update tab bar visibility
    self.tabBarController.tabBar.alpha = 0;
    self.tabBarController.tabBar.hidden = YES;
    
    // update memory timestamp
    self.dateLabel.text = [NSString stringWithFormat:@" - %@", self.memory.timeElapsed];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // adjust gradient frame
    self.contractButtonGradientLayer.frame = self.contractButton.bounds;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isVisible = NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Orientation methods

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        return orientation;
    }
    
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark Properties

- (UIView *)navigationBar {
    if (!_navigationBar) {
        _navigationBar = [[UIView alloc] initWithFrame:CGRectZero];
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_navigationBar addSubview:backButton];
        [backButton setTitle:@"Back" forState:UIControlStateNormal];
        [backButton.titleLabel setFont:[UIFont spc_regularSystemFontOfSize:14]];
        backButton.backgroundColor = [UIColor clearColor];
        backButton.translatesAutoresizingMaskIntoConstraints = NO;
        [backButton setTitleColor:[UIColor colorWithRGBHex:0x6ab1fb] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchUpInside];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeTop multiplier:1.0 constant:20]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:60]];
        //[backButton sizeToFit];
        
        
        UIButton *actionButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_navigationBar addSubview:actionButton];
        actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [actionButton setImage:[UIImage imageNamed:@"button-action"] forState:UIControlStateNormal];
        actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeTop multiplier:1.0 constant:20]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_navigationBar attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:actionButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:60]];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_navigationBar addSubview:_titleLabel];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.text = NSLocalizedString(@"Title", nil);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_navigationBar attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:42]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_titleLabel.font.lineHeight]];
        [_navigationBar addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:150]];
    }
    return _navigationBar;
}

- (UIView *)contentScroller {
    if (_photoScroller) {
        return _photoScroller;
    } else {
        return _videoScroller;
    }
}


- (SPCMemoryCoordinator *)memoryCoordinator {
    if (!_memoryCoordinator) {
        _memoryCoordinator = [[SPCMemoryCoordinator alloc] init];
    }
    return _memoryCoordinator;
}


- (UIImageView *)userToStarAsyncLoadView {
    if (!_userToStarAsyncLoadView) {
        _userToStarAsyncLoadView = [[UIImageView alloc] init];
    }
    return _userToStarAsyncLoadView;
}

- (NSArray *)reportMemoryOptions {
    if (nil == _reportMemoryOptions) {
        _reportMemoryOptions = @[@"ABUSE", @"SPAM", @"PERTAINS TO ME"];
    }
    
    return _reportMemoryOptions;
}

#pragma mark private

- (void)expand:(id)sender {
    [self setExpanded:YES];
}

- (void)contract:(id)sender {
    [self setExpanded:NO];
}

- (void)setExpanded:(BOOL)expanded {
    // switch which button is active...
    self.contractButton.hidden = !expanded;
    self.contractButton.enabled = expanded;
    
    self.expandButton.hidden = expanded;
    self.expandButton.enabled = !expanded;
    
    // switch which views are visible...
    self.memoryTextTruncated.hidden = expanded;
    self.expandChevron.hidden = expanded;
    
    self.memoryText.hidden = !expanded;
    self.authorPhotoView.hidden = !expanded;
    self.authorPhotoButton.hidden = !expanded;
    self.authorPhotoButton.enabled = expanded;
    self.authorLabel.hidden = !expanded;
    self.dateLabel.hidden = !expanded;
    self.locationLabel.hidden = !expanded;
    self.locationButton.hidden = !expanded;
    self.locationButton.enabled = expanded;
    self.locationIcon.hidden = !expanded;
    self.contractChevron.hidden = !expanded;
}

- (void)memoryUpdated:(NSNotification *)notification {
    if (self.memory.recordID == ((Memory *)notification.object).recordID) {
        self.memory = ((Memory *)notification.object);
        [self updateButtons];
        [self updateText];
    }
}

- (void)updateButtons {
    CGFloat commentsButtonPadding = 8;
    CGFloat starButtonPadding = 10;
    CGRect starFrame = CGRectMake(4.5,
                                  CGRectGetHeight(self.view.frame)-40,
                                  36+self.memory.starsCountTextWidth+starButtonPadding,
                                  35);
    
    CGRect usersToStarFrame;
    CGRect commentsFrame;
    if (self.memory.userToStarMostRecently) {
        // we inset our buttons by 4 pixels horizontally.  Compensate by shifting the usersToStar button leftwards
        // by 8, then rightward by 1 to produce a slight divider.
        CGFloat usersToStarX = CGRectGetMaxX(starFrame) - 8;
        
        usersToStarFrame = CGRectMake(usersToStarX, starFrame.origin.y, 44, 35);
    } else {
        usersToStarFrame = CGRectZero;
    }
    
    commentsFrame = CGRectMake(self.view.frame.size.width - 15 - 36 - commentsButtonPadding, CGRectGetMinY(starFrame), 36+self.memory.commentsCountTextWidth+commentsButtonPadding, 35);
    
    self.starButton.frame = starFrame;
    self.usersToStarButton.frame = usersToStarFrame;
    self.commentButton.frame = commentsFrame;
    
    
    NSInteger starsCount = self.memory.starsCount;
    
    UIImage *iconImg = [UIImage imageNamed:(self.memory.userHasStarred ? @"memory-star-gold" : @"memory-star-empty")];
    if (self.memory.type == MemoryTypeText) {
        iconImg = [UIImage imageNamed:(self.memory.userHasStarred ? @"memory-star-gold" : @"memory-star-gray")];
    }
    
    [self.starButton configureWithIconImage:iconImg count:starsCount clearBG:YES];
    self.starButton.color = [UIColor clearColor];
    (self.starButton).roundedCorners = self.memory.userToStarMostRecently ? UIRectCornerTopLeft | UIRectCornerBottomLeft : UIRectCornerAllCorners;
    
    
    
    NSInteger commentsCount = self.memory.commentsCount;
    
    iconImg = [UIImage imageNamed:(self.memory.userHasCommented ? @"memory-chat-blue" : @"memory-chat-empty")];
    if (self.memory.type == MemoryTypeText) {
        iconImg = [UIImage imageNamed:(self.memory.userHasCommented ? @"memory-chat-blue" : @"memory-chat-gray")];
    }
    
    [self.commentButton configureWithIconImage:iconImg count:commentsCount clearBG:YES];
    self.commentButton.color = [UIColor clearColor];
    
    
    if (self.memory.userToStarMostRecently) {
        // configure with the profile asset id of this user
        __weak typeof(self) weakSelf = self;
        [self.userToStarAsyncLoadView sd_setImageWithURL:[NSURL URLWithString:self.memory.userToStarMostRecently.imageAsset.imageUrlThumbnail] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.usersToStarButton configureWithIconImage:image rounded:YES clearBG:YES];
            strongSelf.usersToStarButton.color = [UIColor clearColor];
        }];
        
        (self.usersToStarButton).roundedCorners = UIRectCornerTopRight | UIRectCornerBottomRight;
        (self.usersToStarButton).imageSize = 18;
        
        self.usersToStarButton.hidden = NO;
        self.usersToStarButton.enabled = YES;
    } else {
        self.usersToStarButton.hidden = YES;
        self.usersToStarButton.enabled = NO;
    }
}

- (void)updateText {
    self.authorLabel.text = self.memory.author.displayName;
    if (self.memory.venue.specificity == SPCVenueIsReal) {
        self.locationLabel.text = self.memory.venue.displayName ? self.memory.venue.displayName : self.memory.locationName;
    }
    if (self.memory.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
        self.locationLabel.text = [NSString stringWithFormat:@"%@, %@",self.memory.venue.neighborhood,self.memory.venue.city];
    }
    if (self.memory.venue.specificity == SPCVenueIsFuzzedToCity) {
        self.locationLabel.text = [NSString stringWithFormat:@"%@, %@",self.memory.venue.city,self.memory.venue.country];
    }
        
    self.authorLabelWidthConstraint.constant = [self.authorLabel.text sizeWithAttributes:@{NSFontAttributeName : self.authorLabel.font}].width;
    self.locationLabelWidthConstraint.constant = [self.locationLabel.text sizeWithAttributes:@{NSFontAttributeName : self.locationLabel.font}].width;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)updateTitle {
    int current = 0;
    int total = 1;
    if (self.photoScroller) {
        current = (int)self.photoScroller.currentIndex;
        total = (int)self.photoScroller.total;
    } else {
        current = (int)self.videoScroller.currentIndex;
        total = (int)self.videoScroller.total;
    }
    
    self.titleLabel.text = [NSString stringWithFormat:@"%d of %d", current+1, total];
}

- (void)pop {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    // Update tab bar visibility
    self.tabBarController.tabBar.alpha = 1;
    self.tabBarController.tabBar.hidden = NO;
    
    self.navigationController.navigationBarHidden = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(hideLightbox)]) {
        [self.delegate hideLightboxAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}

-(void)videoFailedToLoad {
    if (self.isVisible) {
        [self  spc_hideNotificationBanner];
        [self spc_showNotificationBannerInParentView:self.contentScroller title:NSLocalizedString(@"Video failed to load", nil) customText:NSLocalizedString(@"Please check your network and try again.",nil)];
    }
}

- (void)showLocation:(id)sender {
    SPCAdjustMemoryLocationViewController *adjustMemoryLocationViewController = [[SPCAdjustMemoryLocationViewController alloc] initWithMemory:self.memory];
    adjustMemoryLocationViewController.delegate = self;
    [self presentViewController:adjustMemoryLocationViewController animated:YES completion:nil];
}


- (void)animateStar:(id)sender {
    self.starAnimationBg.alpha = 0.0;
    self.starAnimationBg.hidden = NO;
    [UIView animateWithDuration:0.4
                          delay:0.1
                        options: 0
                     animations:^{
                         self.starAnimationBg.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         // fade back out!
                         [UIView animateWithDuration:0.4 delay:1.0 options:0 animations:^{
                             self.starAnimationBg.alpha = 0.0;
                         }completion:^(BOOL finished) {
                             if (finished) {
                                 self.starAnimationBg.hidden = YES;
                             }
                         }
                          ];
                     }];
    self.starAnimationStar.alpha = 0.0;
    CGRect starFrame = CGRectMake(0, 0, self.starAnimationStar.image.size.width, self.starAnimationStar.image.size.height);
    starFrame = CGRectOffset(starFrame, self.starAnimationBg.center.x - starFrame.size.width/2, self.starAnimationBg.center.y - starFrame.size.height/2);
    self.starAnimationStar.frame = CGRectInset(starFrame, 30, 30);
    self.starAnimationStar.hidden = NO;
    [UIView animateWithDuration:0.4 delay:0.1 options:0 animations:^{
        self.starAnimationStar.alpha = 1.0;
        self.starAnimationStar.frame = starFrame;
    }completion:^(BOOL finished) {
        // yay!  fade out!
        
        [UIView animateWithDuration:0.4 delay:0.9 options:0 animations:^{
            self.starAnimationStar.alpha = 0.0;
            self.starAnimationStar.frame = CGRectInset(starFrame, -40, -40);
        } completion:^(BOOL finished) {
            self.starAnimationStar.hidden = YES;
        }];
        
    }];
}


# pragma mark Comments


- (void)showMemoryRelatedComments:(id)sender {
    
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];

    
    if (self.isFromComments) {
        [self pop];
    } else {
        MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemory:self.memory];
        memoryCommentsViewController.view.clipsToBounds = NO;
        memoryCommentsViewController.viewingFromLightbox = YES;
        [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
    }
}


# pragma mark Stars

- (void)handleDoubleTap {
    self.starButton.userInteractionEnabled = NO;
    [self updateUserStarForMemory:self.memory button:self.starButton];
}



- (void)showUsersThatStarred:(id)sender {

    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];

    SPCStarsViewController *starsViewController = [[SPCStarsViewController alloc] init];
    starsViewController.memory = self.memory;
    [self.navigationController pushViewController:starsViewController animated:YES];
}


- (void)updateUserStar:(id)sender {
    UIButton *button = (UIButton *)sender;
    button.userInteractionEnabled = NO;
    
    [self updateUserStarForMemory:self.memory button:button];
}


- (void)updateUserStarForMemory:(Memory *)memory button:(UIButton *)button {
    if (memory.userHasStarred) {
        [self removeStarForMemory:memory button:button sockpuppet:nil];
    }
    else if (!memory.userHasStarred) {
        [self addStarForMemory:memory button:button sockpuppet:nil];
    }
}

- (void)addStarForMemory:(Memory *)memory button:(UIButton *)button sockpuppet:(Person *)sockpuppet {
    //update locally immediately
    Person * userAsStarred = memory.userToStarMostRecently;
    if (!sockpuppet) {
        memory.userHasStarred = YES;
        Person * thisUser = [[Person alloc] init];
        thisUser.userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
        thisUser.firstname = [ContactAndProfileManager sharedInstance].profile.profileDetail.firstname;
        thisUser.imageAsset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
        thisUser.recordID = [AuthenticationManager sharedInstance].currentUser.userId;
        memory.userToStarMostRecently = thisUser;
    } else {
        memory.userToStarMostRecently = sockpuppet;
    }
    memory.starsCount = memory.starsCount + 1;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    button.userInteractionEnabled = NO;
    
    [self updateButtons];
    
    [MeetManager addStarToMemory:memory
                    asSockPuppet:sockpuppet
                  resultCallback:^(NSDictionary *result) {
                      
                      int resultInt = [result[@"number"] intValue];
                      NSLog(@"add star result %i",resultInt);
                      button.userInteractionEnabled = YES;
                      
                      if (resultInt == 1) {
                          
                      }
                      //correct local update if call failed
                      else {
                          memory.userHasStarred = NO;
                          memory.starsCount = memory.starsCount - 1;
                          memory.userToStarMostRecently = userAsStarred;
                          
                          [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                          [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                          
                          [self updateButtons];
                          
                          [[[UIAlertView alloc] initWithTitle:nil message:@"Error adding star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                      }
                      
                  }
                   faultCallback:^(NSError *fault) {
                       if (!sockpuppet) {
                           memory.userHasStarred = NO;
                       }
                       memory.starsCount = memory.starsCount - 1;
                       memory.userToStarMostRecently = userAsStarred;
                       button.userInteractionEnabled = YES;
                       
                       //correct local update if call failed
                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                       
                       [self updateButtons];
                       
                       [[[UIAlertView alloc] initWithTitle:nil message:@"Error adding star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                   }];
}

- (void)removeStarForMemory:(Memory *)memory button:(UIButton *)button sockpuppet:(Person *)sockpuppet {
    // we might need to refresh the memory cell from the server: if the user
    // was the most recent to star the memory, AND there are multiple stars,
    // we need to pull down data again to see who is the most recent afterwards.
    BOOL refreshMemoryFromServer = NO;
    Person * userAsStarred = memory.userToStarMostRecently;
    
    //update locally immediately
    if (!sockpuppet) {
        memory.userHasStarred = NO;
        if (memory.userToStarMostRecently.recordID == [AuthenticationManager sharedInstance].currentUser.userId) {
            userAsStarred = memory.userToStarMostRecently;
            if (memory.starsCount == 0) {
                memory.userToStarMostRecently = nil;
            } else {
                refreshMemoryFromServer = YES;
            }
        }
    } else {
        if (memory.userToStarMostRecently.recordID == sockpuppet.recordID) {
            userAsStarred = memory.userToStarMostRecently;
            if (memory.starsCount == 0) {
                memory.userToStarMostRecently = nil;
            } else {
                refreshMemoryFromServer = YES;
            }
        }
    }
    memory.starsCount = memory.starsCount - 1;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    button.userInteractionEnabled = NO;
    
    [self updateButtons];
    
    [MeetManager deleteStarFromMemory:memory
                         asSockPuppet:sockpuppet
                       resultCallback:^(NSDictionary *result){
                           int resultInt = [result[@"number"] intValue];
                           NSLog(@"delete star result %i",resultInt);
                           button.userInteractionEnabled = YES;
                           
                           if (resultInt == 1) {
                               if (refreshMemoryFromServer) {
                                   [MeetManager fetchMemoryWithMemoryId:memory.recordID resultCallback:^(NSDictionary *results) {
                                       [memory setWithAttributes:results];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                       
                                       [self updateButtons];
                                   } faultCallback:^(NSError *fault) {
                                       if (!sockpuppet) {
                                           memory.userHasStarred = YES;
                                       }
                                       memory.starsCount = memory.starsCount + 1;
                                       memory.userToStarMostRecently = userAsStarred;
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                       
                                       [self updateButtons];
                                       
                                       [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                   }];
                               }
                           }
                           //correct local update if call failed
                           else {
                               if (!sockpuppet) {
                                   memory.userHasStarred = YES;
                               }
                               memory.starsCount = memory.starsCount + 1;
                               memory.userToStarMostRecently = userAsStarred;
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                               [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                               
                               [self updateButtons];
                               
                               [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                           }
                           
                       }
                        faultCallback:^(NSError *error){
                            
                            //correct local update if call failed
                            if (!sockpuppet) {
                                memory.userHasStarred = YES;
                            }
                            memory.starsCount = memory.starsCount + 1;
                            memory.userToStarMostRecently = userAsStarred;
                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                            
                            [self updateButtons];
                            
                            button.userInteractionEnabled = YES;
                            [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                        }];
}


/*
- (void)updateUserStarForMemory:(Memory *)memory button:(UIButton *)button {
    if (memory.userHasStarred) {
        
        // we might need to refresh the memory cell from the server: if the user
        // was the most recent to star the memory, AND there are multiple stars,
        // we need to pull down data again to see who is the most recent afterwards.
        BOOL refreshMemoryFromServer = NO;
        Person * userAsStarred = memory.userToStarMostRecently;
        
        //update locally immediately
        memory.userHasStarred = NO;
        memory.starsCount = memory.starsCount - 1;
        if (memory.userToStarMostRecently.recordID == [AuthenticationManager sharedInstance].currentUser.userId) {
            userAsStarred = memory.userToStarMostRecently;
            if (memory.starsCount == 0) {
                memory.userToStarMostRecently = nil;
            } else {
                refreshMemoryFromServer = YES;
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
        
        [self updateButtons];
        
        __weak typeof(self) weakSelf = self;
        
        [MeetManager deleteStarFromMemory:memory
                                       resultCallback:^(NSDictionary *result){
                                           int resultInt = [result[@"number"] intValue];
                                           NSLog(@"delete star result %i",resultInt);
                                           button.userInteractionEnabled = YES;
                                           
                                           if (resultInt == 1) {
                                               if (refreshMemoryFromServer) {
                                                   [MeetManager fetchMemoryWithMemoryId:memory.recordID resultCallback:^(NSDictionary *results) {
                                                       [memory setWithAttributes:results];
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                                   } faultCallback:^(NSError *fault) {
                                                       memory.userHasStarred = YES;
                                                       memory.starsCount = memory.starsCount + 1;
                                                       memory.userToStarMostRecently = userAsStarred;
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                                       
                                                       [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                                   }];
                                               }
                                           }
                                           //correct local update if call failed
                                           else {
                                               memory.userHasStarred = YES;
                                               memory.starsCount = memory.starsCount + 1;
                                               memory.userToStarMostRecently = userAsStarred;
                                               
                                               [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                               [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                               
                                               [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                           }
                                       }
                                        faultCallback:^(NSError *error){
                                            
                                            //correct local update if call failed
                                            memory.userHasStarred = YES;
                                            memory.starsCount = memory.starsCount + 1;
                                            memory.userToStarMostRecently = userAsStarred;
                                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                            
                                            button.userInteractionEnabled = YES;
                                            [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                            
                                            __strong typeof(self) strongSelf = weakSelf;
                                            [strongSelf updateButtons];
                                        }];
        
        
    }
    else if (!memory.userHasStarred) {
        
        //update locally immediately
        memory.userHasStarred = YES;
        memory.starsCount = memory.starsCount + 1;
        Person * userAsStarred = memory.userToStarMostRecently;
        Person * thisUser = [[Person alloc] init];
        thisUser.userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
        thisUser.firstname = [ContactAndProfileManager sharedInstance].profile.profileDetail.firstname;
        thisUser.imageAsset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
        thisUser.recordID = [AuthenticationManager sharedInstance].currentUser.userId;
        memory.userToStarMostRecently = thisUser;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
        
        [self updateButtons];
        [self animateStar:button];
        
        __weak typeof(self) weakSelf = self;
        
        [MeetManager addStarToMemory:memory
                                  resultCallback:^(NSDictionary *result) {
                                      
                                      int resultInt = [result[@"number"] intValue];
                                      NSLog(@"add star result %i",resultInt);
                                      button.userInteractionEnabled = YES;
                                      
                                      if (resultInt == 1) {
                                          
                                      }
                                      //correct local update if call failed
                                      else {
                                          memory.userHasStarred = NO;
                                          memory.starsCount = memory.starsCount - 1;
                                          memory.userToStarMostRecently = userAsStarred;
                                          
                                          [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                          [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                          
                                          [[[UIAlertView alloc] initWithTitle:nil message:@"Error adding star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                      }
                                      
                                  }
                                   faultCallback:^(NSError *fault) {
                                       memory.userHasStarred = NO;
                                       memory.starsCount = memory.starsCount - 1;
                                       memory.userToStarMostRecently = userAsStarred;
                                       button.userInteractionEnabled = YES;
                                       
                                       //correct local update if call failed
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                       
                                       [[[UIAlertView alloc] initWithTitle:nil message:@"Error adding star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                       
                                       __strong typeof(self) strongSelf = weakSelf;
                                       [strongSelf updateButtons];
                                   }];
    }
}
*/



#pragma mark - Tagging

- (void)tagFriends {
    [self.navigationController presentViewController:self.tagFriendsViewController animated:YES completion:nil];
}

- (SPCTagFriendsViewController *)tagFriendsViewController {
    if (!_tagFriendsViewController && self.memory) {
        _tagFriendsViewController = [[SPCTagFriendsViewController alloc] initWithSelectedFriends:self.memory.taggedUsers];
        _tagFriendsViewController.delegate = self;
    }
    return _tagFriendsViewController;
}

#pragma mark - SPCTagFriendsViewControllerDelegate

- (void)pickedFriends:(NSArray *)selectedFriends {
    self.memory.taggedUsers = selectedFriends;
    [MeetManager updateMemoryParticipantsWithMemoryID:self.memory.recordID
                                 taggedUserIdsUserIds:self.memory.taggedUsersIDs
                                       resultCallback:^(NSDictionary *results) {
                                           [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:self.memory];
                                        }
                                        faultCallback:^(NSError *fault) {}];
    
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
        self.tagFriendsViewController = nil;
    }];
}

- (void)cancelTaggingFriends {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
        self.tagFriendsViewController = nil;
    }];
}

#pragma mark SPCMapViewController

- (void)cancelMap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didAdjustLocationForMemory:(Memory *)memory {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark = SPCAdjustMemoryViewControllerDelegate

-(void)didAdjustLocationForMemory:(Memory *)memory withViewController:(UIViewController *)viewController {
    // TODO: care about this
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{}];
}

-(void)dismissAdjustMemoryLocationViewController:(UIViewController *)viewController {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{}];
}



#pragma mark SPCFeedScroller delegates

- (void)spcFeedPhotoScroller:(SPCFeedPhotoScroller *)feedScroller onAssetScrolledTo:(int)index {
    [self updateTitle];
}

- (void)spcFeedVideoScroller:(SPCFeedVideoScroller *)feedScroller onAssetScrolledTo:(int)index videoUrl:(NSString *)url {
    [self updateTitle];
}


#pragma mark SPCTagFriendsViewControllerDelegate

- (void)tagFriendsViewController:(SPCTagFriendsViewController *)viewController finishedPickingFriends:(NSArray *)selectedFriends {
    [self.memoryCoordinator updateMemory:viewController.memory taggedUsers:viewController.memory.taggedUsersIDs completionHandler:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:viewController.memory];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (void)tagFriendsViewControllerDidCancel:(SPCTagFriendsViewController *)viewController {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{}];
}



#pragma mark - Sharing

- (void)shareMemory:(Memory *)memory serviceName:(NSString *)serviceName {
    //NSLog(@"share mem from comments to %@",serviceName);
    [MeetManager shareMemoryWithMemoryId:memory.recordID
                             serviceName:serviceName
                       completionHandler:^{
                           [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Shared to %@", nil), [serviceName capitalizedString]]
                                                       message:NSLocalizedString(@"Your memory has been successfully shared.", nil)
                                                      delegate:nil
                                             cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                             otherButtonTitles:nil] show];
                       } errorHandler:^(NSError *error) {
                           [UIAlertView showError:error];
                       }];
}

- (void)shareMemory:(Memory *)memory serviceName:(NSString *)serviceName serviceType:(SocialServiceType)serviceType {
    BOOL isServiceAvailable = [[SocialService sharedInstance] availabilityForServiceType:serviceType];
    if (isServiceAvailable) {
        [self.memoryCoordinator shareMemory:memory serviceName:serviceName completionHandler:^{
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Shared to %@", nil), [serviceName capitalizedString]]
                                        message:NSLocalizedString(@"Your memory has been successfully shared.", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Request %@ Access", nil), [serviceName capitalizedString]]
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"You have to authorize with %@ in order to invite your friends", nil), [serviceName capitalizedString]]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"Authorize", nil), nil];
        alertView.tag = serviceType;
        [alertView show];
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView.tag == alertViewTagTwitter) {
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeTwitter viewController:appDelegate.mainViewController.customTabBarController completionHandler:^{
                [self shareMemory:self.memory serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        }
        else if (alertView.tag == alertViewTagFacebook) {
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeFacebook viewController:nil completionHandler:^{
                [self shareMemory:self.memory serviceName:@"FACEBOOK" serviceType:SocialServiceTypeFacebook];
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        } else if (alertView.tag == alertViewTagReport) {
            // These buttons were configured so that buttonIndex 1 = 'Send', buttonIndex 0 = 'Add Detail'
            if (1 == buttonIndex) {
                [Flurry logEvent:@"MEM_REPORTED"];
                [self.memoryCoordinator reportMemory:self.memory withType:self.reportType text:nil completionHandler:^(BOOL success) {
                    if (success) {
                        [self showMemoryReportWithSuccess:YES];
                    } else {
                        [self showMemoryReportWithSuccess:NO];
                    }
                }];
            } else if (0 == buttonIndex) {
                SPCReportViewController *rvc = [[SPCReportViewController alloc] initWithReportObject:self.memory reportType:self.reportType andDelegate:self];
                [self.navigationController pushViewController:rvc animated:YES];
            }
        }
    }
}

#pragma mark Memory Actions

- (void)showMemoryActions:(id)sender {
    
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    // NSLog(@"show memory actions");
    // Selected memory
    Memory *memory = self.memory;
    
    BOOL isUsersMemory = memory.author.recordID == [AuthenticationManager sharedInstance].currentUser.userId;
    BOOL userIsWatching = memory.userIsWatching;
    
    // Alert view controller
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    
    if ([AuthenticationManager sharedInstance].currentUser.isAdmin) {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Promote Memory" subtitle:@"Add memory to Local and World grids" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = NSLocalizedString(@"Promote Memory?", nil);
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Promote", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                [[AdminManager sharedInstance] promoteMemory:memory completionHandler:^{
                    [[[UIAlertView alloc] initWithTitle:@"Promoted Memory" message:@"This memory has been promoted.  It should now have prominent Local and World grid placement." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Demote Memory" subtitle:@"Remove from Local and World grids" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = NSLocalizedString(@"Demote Memory?", nil);
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Demote", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                [[AdminManager sharedInstance] demoteMemory:memory completionHandler:^{
                    [[[UIAlertView alloc] initWithTitle:@"Demoted Memory" message:@"This memory has been demoted.  It should not appear on Local or World grids." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Star as Puppet" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:SPCAdminSockPuppetActionStar object:memory];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Unstar as Puppet" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:SPCAdminSockPuppetActionUnstar object:memory];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
    }
    
    // Alert view controller - alerts
    if (isUsersMemory) {
    
        alertViewController.alertTitle = NSLocalizedString(@"Edit or Share", nil);
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Change Location", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                   SPCMapViewController *mapVC = [[SPCMapViewController alloc] initForExistingMemory:memory];
                                                                   mapVC.delegate = self;
                                                                   [self.navigationController pushViewController:mapVC animated:YES];
                                                               }]];
        if (memory.type != MemoryTypeFriends) {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Tag Friends", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                   SPCTagFriendsViewController *tagUsersViewController = [[SPCTagFriendsViewController alloc] initWithMemory:memory];
                                                                   tagUsersViewController.delegate = self;
                                                                   [self presentViewController:tagUsersViewController animated:YES completion:nil];
                                                               }]];
        }
            /* TODO: implement FB memory sharing on the client using a Facebook dialog.
             * This approach does not require FB review, although sharing through the server does.
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Share to Facebook", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self shareMemory:memory serviceName:@"FACEBOOK" serviceType:SocialServiceTypeFacebook];
                                                                   }]];
             */
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Share to Twitter", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self shareMemory:memory serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
                                                                   }]];
        
        
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Delete Memory", nil)
                                                                 style:SPCAlertActionStyleDestructive
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self showDeletePromptForMemory:memory];
                                                               }]];
    }
    else {
        alertViewController.alertTitle = NSLocalizedString(@"Watch or Report", nil);
       
        if (!userIsWatching) {
            
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Watch Memory", nil)
                                                                  subtitle:NSLocalizedString(@"Get notifications of activity on this memory", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self watchMemory:memory];
                                                                   }]];
        }
        else {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Stop Watching Memory", nil)
                                                                  subtitle:NSLocalizedString(@"Stop receiving notifications about this memory", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self stopWatchingMemory:memory];
                                                                   }]];
        }
        
        
        NSString *reportString = [AuthenticationManager sharedInstance].currentUser.isAdmin ? @"Delete Memory" : @"Report Memory";
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(reportString, nil)
                                                                 style:SPCAlertActionStyleDestructive
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self showReportPromptForMemory:memory];
                                                               }]];
        
    }
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:SPCAlertActionStyleCancel
                                                           handler:nil]];
    
    // Alert view controller - show
    [self presentViewController:alertViewController animated:YES completion:nil];
}


- (void)showBlockPromptForMemory:(Memory *)memory {
    NSString *msgText = [NSString stringWithFormat:@"You are about to block %@. This means that you will both be permanently invisible to each other.", memory.author.displayName];
    
    UIView *alertView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 235)];
    alertView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 20, 270, 42);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.center=CGPointMake(alertView.bounds.size.width/2, imageView.center.y);
    [alertView addSubview:imageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, 270, 30)];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = [NSString stringWithFormat:@"Block %@?", memory.author.displayName];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [alertView addSubview:titleLabel];
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 205, 100)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.center = CGPointMake(alertView.center.x, messageLabel.center.y);
    messageLabel.text = msgText;
    messageLabel.numberOfLines = 0;
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [alertView addSubview:messageLabel];
    
    UIColor *cancelBgColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    UIColor *cancelTextColor = [UIColor colorWithRed:145.0f/255.0f green:167.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
    CGRect cancelBtnFrame = CGRectMake(25,180,100,40);
    
    UIColor *otherBgColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    UIColor *otherTextColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    CGRect otherBtnFrame = CGRectMake(145,180,100,40);
    
    NSString *targetUserName = memory.author.displayName;
    
    [PXAlertView showAlertWithView:alertView cancelTitle:@"Cancel" cancelBgColor:cancelBgColor cancelTextColor:cancelTextColor cancelFrame:cancelBtnFrame otherTitle:@"Block" otherBgColor:otherBgColor otherTextColor:otherTextColor otherFrame:otherBtnFrame completion:^(BOOL cancelled) {
        
        if (!cancelled) {
            //NSLog(@"block userId %i",memory.author.recordID);
            
            [MeetManager blockUserWithId:memory.author.recordID
                          resultCallback:^(NSDictionary *result)  {
                              
                              UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 165)];
                              contentView.backgroundColor = [UIColor whiteColor];
                              
                              UILabel *contentTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 270, 30)];
                              contentTitleLabel.font = [UIFont boldSystemFontOfSize:20];
                              contentTitleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
                              contentTitleLabel.backgroundColor = [UIColor clearColor];
                              contentTitleLabel.text = NSLocalizedString(@"Blocked!",nil);
                              contentTitleLabel.textAlignment = NSTextAlignmentCenter;
                              [contentView addSubview:contentTitleLabel];
                              
                              UILabel *contentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 250, 60)];
                              contentMessageLabel.font = [UIFont systemFontOfSize:16];
                              contentMessageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
                              contentMessageLabel.backgroundColor = [UIColor clearColor];
                              contentMessageLabel.center=CGPointMake(contentView.center.x, contentMessageLabel.center.y);
                              contentMessageLabel.text = [NSString stringWithFormat:@"You have blocked %@.",targetUserName];
                              contentMessageLabel.numberOfLines=0;
                              contentMessageLabel.lineBreakMode=NSLineBreakByWordWrapping;
                              contentMessageLabel.textAlignment = NSTextAlignmentCenter;
                              [contentView addSubview:contentMessageLabel];
                              
                              UIColor *contentCancelBgColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
                              UIColor *contentCancelTextColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
                              CGRect contentCancelBtnFrame = CGRectMake(70,100,130,40);
                              
                              [PXAlertView showAlertWithView:contentView cancelTitle:@"OK" cancelBgColor:contentCancelBgColor
                                             cancelTextColor:contentCancelTextColor
                                                 cancelFrame:contentCancelBtnFrame
                                                  completion:^(BOOL cancelled) {
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                                      [ProfileManager fetchProfileWithUserToken:[AuthenticationManager sharedInstance].currentUser.userToken
                                                                                 resultCallback:nil
                                                                                  faultCallback:nil];
                                                  }];
                          }
                           faultCallback:^(NSError *error){
                               
                               //NSLog(@"block failed, please try again");
                               
                           }
             ];
        }
    }];
}

-(void)showTappedProfileFromButton:(id)sender {
    NSString *userToken = self.memory.author.userToken;
    if (self.memory.author.recordID == -2) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    }
    else {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}

-(void)showTappedProfileFromHeader:(NSNotification *)notification {
    
    NSString *userToken = (NSString *)[notification object];
    
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

-(void)applyPersonUpdateWithNotification:(NSNotification *)note {
    PersonUpdate *personUpdate = [note object];
    BOOL changed = [personUpdate applyToMemory:self.memory];
    if (changed) {
        // update displayed stuff
        [self updateButtons];
        [self updateText];
    }
}

-(void)showMemAuthorProfile:(id)sender {
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:self.memory.author.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)showDeletePromptForMemory:(Memory *)memory {
    
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 280)];
    demoView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 10, 270, 40);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [demoView addSubview:imageView];
    
    NSString *title = @"Delete this memory?";
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 270, 20)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:titleLabel];
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 230, 40)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.numberOfLines = 2;
    messageLabel.text = @"Once you delete this memory it will be gone forever!";
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:messageLabel];
    
    UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    okBtn.frame = CGRectMake(70, 145, 130, 40);
    
    [okBtn setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    okBtn.backgroundColor = [UIColor colorWithRGBHex:0x4ACBEB];
    okBtn.layer.cornerRadius = 4.0;
    okBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    
    UIImage *selectedImage = [ImageUtils roundedRectImageWithColor:[UIColor colorWithRGBHex:0x4795AC] size:okBtn.frame.size corners:4.0f];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
    
    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okBtn addTarget:self action:@selector(deleteConfirmed:) forControlEvents:UIControlEventTouchUpInside];
    [demoView addSubview:okBtn];
    
    
    CGRect cancelFrame = CGRectMake(70, 205, 130, 40);
    
    self.alertView = [PXAlertView showAlertWithView:demoView cancelTitle:@"Cancel" cancelBgColor:[UIColor darkGrayColor] cancelTextColor:[UIColor whiteColor] cancelFrame:cancelFrame completion:^(BOOL cancelled) {
        self.alertView = nil;
    }];
}

- (void)deleteConfirmed:(id)sender {
    
    //NSLog(@"report memory!");
    [self.alertView dismiss:sender];
    self.alertView = nil;
    
    // Delete memory
    [self.memoryCoordinator deleteMemory:self.memory completionHandler:^(BOOL success) {
        if (success) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(memoryDeletedFromLightbox:)]) {
                [self.delegate memoryDeletedFromLightbox:self.memory];
            }
            [self pop];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:NSLocalizedString(@"Error deleting memory. Please try again later.", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                              otherButtonTitles:nil] show];
        }
    }];
}


- (void)showReportPromptForMemory:(Memory *)memory {
    self.reportAlertView = [[SPCReportAlertView alloc] initWithTitle:@"Choose type of report" stringOptions:self.reportMemoryOptions dismissTitles:@[@"CANCEL"] andDelegate:self];
    
    [self.reportAlertView showAnimated:YES];
}

- (void)watchMemory:(Memory *)memory {
    
    memory.userIsWatching = YES;
    
    [MeetManager watchMemoryWithMemoryKey:memory.key
                           resultCallback:^(NSDictionary *result) {
                               NSLog(@"watching mem!");
                           }
                            faultCallback:nil];
    
}

- (void)stopWatchingMemory:(Memory *)memory {
    
    memory.userIsWatching = NO;
    
    [MeetManager unwatchMemoryWithMemoryKey:memory.key
                           resultCallback:^(NSDictionary *result) {
                               NSLog(@"unwatching mem!");
                           }
                            faultCallback:nil];
    
}

#pragma mark - SPCReportAlertViewDelegate

- (void)tappedOption:(NSString *)option onSPCReportAlertView:(SPCReportAlertView *)reportView {
    if ([reportView isEqual:self.reportAlertView]) {
        self.reportType = [self.reportMemoryOptions indexOfObject:option] + 1;
        
        [reportView hideAnimated:YES];
        
        // Now, we need to show an alert view asking the user if they want to "Add Detail" or "Send"
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Send Report Immediately?" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Add Detail", @"Send", nil];
        alertView.tag = alertViewTagReport;
        [alertView show];
        
        self.reportAlertView = nil;
    }
}

- (void)tappedDismissTitle:(NSString *)dismissTitle onSPCReportAlertView:(SPCReportAlertView *)reportView {
    // We only have one dismiss option, so go ahead and remove the view
    [self.reportAlertView hideAnimated:YES];
    
    self.reportAlertView = nil;
}

#pragma mark - SPCReportViewControllerDelegate

- (void)invalidReportObjectOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:NO];
}

- (void)canceledReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
}

- (void)sendFailedOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:NO];
}

- (void)sentReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:YES];
}

#pragma mark - Report/Flagging Results

- (void)showMemoryReportWithSuccess:(BOOL)succeeded {
    if (succeeded) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"This memory has been reported. Thank you.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                          otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"Error reporting issue. Please try again later.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                          otherButtonTitles:nil] show];
    }
}



#pragma mark SPCAdminSockPuppetChooserViewControllerDelegate

- (void)adminSockPuppetChooserViewController:(UIViewController *)vc didChoosePuppet:(Person *)puppet forAction:(SPCAdminSockPuppetAction)action object:(NSObject *)object {
    
    [self.navigationController popViewControllerAnimated:YES];
    
    switch(action) {
        case SPCAdminSockPuppetActionStar:
            NSLog(@"Star action as %@", puppet.firstname);
            [self addStarForMemory:(Memory *)object button:nil sockpuppet:puppet];
            break;
            
        case SPCAdminSockPuppetActionUnstar:
            NSLog(@"Unstar action as %@", puppet.firstname);
            [self removeStarForMemory:(Memory *)object button:nil sockpuppet:puppet];
            break;
            
        default:
            NSLog(@"WOULD HAVE perfomed action %d with sock puppet %@", action, puppet.firstname);
            break;
    }
}

- (void)adminSockPuppetChooserViewControllerDidCancel:(UIViewController *)vc {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    return animator;
}


@end
