//
//  SPCVenueDetailGridTransitionViewController.m
//  Spayce
//
//  Created by Jake Rosin on 1/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

// This
#import "SPCVenueDetailGridTransitionViewController.h"

// Framework
#import "Flurry.h"

// ViewControllers
#import "SPCHashTagContainerViewController.h"
#import "SPCMapViewController.h"
#import "SPCAdjustMemoryLocationViewController.h"
#import "SPCStarsViewController.h"
#import "SPCProfileViewController.h"
#import "SPCAlertViewController.h"
#import "SPCMainViewController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCLightboxViewController.h"
#import "SPCReportViewController.h"

// Managers
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "MeetManager.h"
#import "ProfileManager.h"
#import "AdminManager.h"
#import "SPCAdminSockPuppetChooserViewController.h"

// Views
#import "MemoryCell.h"
#import "PXAlertView.h"
#import "UIAlertView+SPCAdditions.h"
#import "SPCReportAlertView.h"

// Data Source and other utilities
#import "SPCBaseDataSource.h"
#import "SPCMemoryCoordinator.h"
#import "SPCAlertAction.h"
#import "ImageUtils.h"
#import "SocialService.h"
#import "AppDelegate.h"
#import "SPCAlertTransitionAnimator.h"

// Utils
#import "UIViewController+SPCAdditions.h"
#import "UIImageView+WebCache.h"

// Model
#import "Venue.h"
#import "Memory.h"
#import "Person.h"
#import "User.h"
#import "UserProfile.h"
#import "ProfileDetail.h"
#import "Location.h"
#import "Asset.h"


const CGFloat VENUE_GRID_TRANSITION_ANIMATION_LENGTH = 0.4f;
const CGFloat VENUE_GRID_TRANSITION_ALPHA_ANIMATION_DELAY = VENUE_GRID_TRANSITION_ANIMATION_LENGTH * 0.1;



@interface SPCVenueDetailGridTransitionViewController () <SPCAdjustMemoryLocationViewControllerDelegate, SPCMapViewControllerDelegate, SPCTagFriendsViewControllerDelegate, SPCVenueDetailViewControllerDelegate, UIAlertViewDelegate, UIViewControllerTransitioningDelegate, SPCReportAlertViewDelegate, SPCReportViewControllerDelegate, SPCAdminSockPuppetChooserViewControllerDelegate>

// Venue Detail View Controller
@property (nonatomic, strong) SPCVenueDetailViewController *venueDetailViewController;

// Views
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UILabel *venueNameLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *expandingImageView;
@property (nonatomic, strong) UIImageView *expandingImageViewClipped;

@property (nonatomic, strong) UIView *clippingView;

// Memory cell
@property (nonatomic, strong) MemoryCell *memoryCell;

// Other UI
@property (strong, nonatomic) PXAlertView *alertView;
@property (strong, nonatomic) SPCReportAlertView *reportAlertView;

// Helper utilities
@property (nonatomic, strong) SPCMemoryCoordinator *memoryCoordinator;

// Transition animation
@property (nonatomic, assign) BOOL viewDidAppear;
@property (nonatomic, assign) BOOL viewIsDismissed;
@property (nonatomic, assign) BOOL viewIsVisible;

// Helper accessors
@property (nonatomic, readonly) NSAttributedString *venueNameAttributedString;
@property (nonatomic) SPCReportType reportType;

@property (strong, nonatomic) NSArray *reportMemoryOptions;

@end

@implementation SPCVenueDetailGridTransitionViewController {
    NSInteger alertViewTagTwitter;
    NSInteger alertViewTagFacebook;
    NSInteger alertViewTagReport;
}

- (void)dealloc {
    [self spc_dealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // The venue detail VC we will (possibly) transition to.
    self.venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    self.venueDetailViewController.delegate = self;
    self.venueDetailViewController.venue = self.venue;
    [self.venueDetailViewController fetchMemories];
    
    // Notifications we need: memory updates and (maybe) video playback.
    // Video playback probably won't matter since we expect to only use
    // image memories, but no harm in being forward-thinking.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFailedToLoad) name:@"videoLoadFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryDeleted:) name:SPCMemoryDeleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryUpdated:) name:SPCMemoryUpdated object:nil];
    
    // Subviews
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.clippingView];
    [self.view addSubview:self.expandingImageView];
    [self.view addSubview:self.header];
    [self.view addSubview:self.scrollView];
    
    [self.scrollView addSubview:self.memoryCell];
    [self.clippingView addSubview:self.expandingImageViewClipped];
    
    // Hide those that are not visible for transition animation.
    self.header.alpha = 0;
    self.scrollView.alpha = 0;
    self.header.userInteractionEnabled = NO;
    self.scrollView.userInteractionEnabled = NO;
    
    alertViewTagFacebook = 0;
    alertViewTagTwitter = 1;
    alertViewTagReport = 2;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    [self updateMemoryViews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL firstAppearance = !self.viewDidAppear;
    self.viewDidAppear = YES;
    self.viewIsVisible = YES;
    
    if (firstAppearance) {
        [self animateIn];
    }
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    self.viewIsVisible = NO;
}


- (BOOL)prefersStatusBarHidden {
    return !self.viewIsDismissed && self.viewDidAppear;
}


#pragma mark accessors

- (UIView *)header {
    if (!_header) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 140)];
        header.backgroundColor = [UIColor colorWithRGBHex:0x6ab1fb];
        
        UIButton *leaveButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 50.0)];
        [leaveButton setTitle:@"Back" forState:UIControlStateNormal];
        [leaveButton.titleLabel setFont:[UIFont spc_regularSystemFontOfSize:14]];
        leaveButton.backgroundColor = [UIColor clearColor];
        [leaveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [leaveButton addTarget:self action:@selector(dismissViewController) forControlEvents:UIControlEventTouchUpInside];
        
        // invitation to visit
        UILabel *label = [[UILabel alloc] init];
        [label setFont:[UIFont spc_regularSystemFontOfSize:14]];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"See more memories left at:";
        label.frame = CGRectMake(0, 35, CGRectGetWidth(self.view.frame), label.font.lineHeight);
        
        // venue name
        self.venueNameLabel.frame = CGRectMake(0, CGRectGetMaxY(label.frame)-2, CGRectGetWidth(self.view.frame), self.venueNameLabel.font.lineHeight);
        
        // enter button
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 35)];
        button.center = CGPointMake(CGRectGetMidX(self.view.frame), 104);
        button.backgroundColor = [UIColor whiteColor];
        [button.titleLabel setFont:[UIFont spc_regularSystemFontOfSize:14]];
        [button setTitleColor:[UIColor colorWithRGBHex:0x6ab1fb] forState:UIControlStateNormal];
        [button setTitle:@"ENTER" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showVenueDetail) forControlEvents:UIControlEventTouchUpInside];
        button.contentEdgeInsets = UIEdgeInsetsMake(2, 0, 0, 0);
        button.layer.cornerRadius = 17.5;
        
        [header addSubview:leaveButton];
        [header addSubview:button];
        [header addSubview:self.venueNameLabel];
        [header addSubview:label];
        
        _header = header;
    }
    return _header;
}


- (UILabel *)venueNameLabel {
    if (!_venueNameLabel) {
        // venue name
        UILabel *venueLabel = [[UILabel alloc] init];
        [venueLabel setFont:[UIFont spc_boldSystemFontOfSize:16]];
        venueLabel.textColor = [UIColor whiteColor];
        venueLabel.textAlignment = NSTextAlignmentCenter;
        venueLabel.attributedText = self.venueNameAttributedString;
        
        _venueNameLabel = venueLabel;
    }
    return _venueNameLabel;
}


- (UIScrollView *)scrollView {
    if (!_scrollView) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.header.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.header.frame))];
        scrollView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        scrollView.scrollEnabled = YES;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.alwaysBounceVertical = YES;
        
        _scrollView = scrollView;
    }
    return _scrollView;
}




- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        imageView.image = self.backgroundImage;
        _backgroundImageView = imageView;
    }
    return _backgroundImageView;
}


- (UIImageView *)expandingImageView {
    if (!_expandingImageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.gridCellFrame];
        if (imageView.frame.size.width > 0) {
            imageView.image = self.gridCellImage;
            if (!imageView.image && self.gridCellAsset) {
                NSURL *url = [NSURL URLWithString:self.gridCellAsset.imageUrlThumbnail];
                [imageView sd_setImageWithURL:url];
                [imageView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    self.expandingImageViewClipped.image = image;
                    self.gridCellImage = image;
                    [self updateMemoryViews];
                }];
            }
        }
        imageView.alpha = 0;
        _expandingImageView = imageView;
    }
    return _expandingImageView;
}

- (UIImageView *)expandingImageViewClipped {
    if (!_expandingImageViewClipped) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.gridCellFrame];
        if (imageView.frame.size.width > 0) {
            if (self.gridCellImage) {
                imageView.image = self.gridCellImage;
            }
            // if not, we will set this value once the unclipped image view loads.
        }
        _expandingImageViewClipped = imageView;
    }
    return _expandingImageViewClipped;
}


- (UIView *)clippingView {
    if (!_clippingView) {
        _clippingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        
        if (self.gridClipFrame.size.height > 0) {
            // we have a clip frame
            
            // Create a mask layer
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            
            // Create a path with our clip rect in it
            CGPathRef path = CGPathCreateWithRect(self.gridClipFrame, NULL);
            maskLayer.path = path;
            
            // The path is not covered by ARC
            CGPathRelease(path);
            
            _clippingView.layer.mask = maskLayer;
        }
        
    }
    return _clippingView;
}



- (SPCMemoryCoordinator *)memoryCoordinator {
    if (!_memoryCoordinator) {
        _memoryCoordinator = [[SPCMemoryCoordinator alloc] init];
    }
    return _memoryCoordinator;
}

- (MemoryCell *)memoryCell {
    if (!_memoryCell) {
        MemoryCell *memCell = [[MemoryCell alloc] initWithMemoryType:self.memory.type style:UITableViewCellStyleDefault reuseIdentifier:@"header"];
        
        [memCell.commentsButton addTarget:self action:@selector(showMemoryRelatedComments:) forControlEvents:UIControlEventTouchUpInside];
        [memCell.starsButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
        [memCell.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
        [memCell.authorButton addTarget:self action:@selector(showAuthor:) forControlEvents:UIControlEventTouchUpInside];
        [memCell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
        
        [memCell setTaggedUserTappedBlock:^(NSString * userToken) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; //stop any video playback currently in progress
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
        }];
        
        __weak typeof(self)weakSelf = self;
        [memCell setHashTagTappedBlock:^(NSString *hashTag, Memory *mem) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; //stop any video playback currently in progress
            SPCHashTagContainerViewController *hashTagContainerViewController = [[SPCHashTagContainerViewController alloc] init];
            [hashTagContainerViewController configureWithHashTag:hashTag memory:weakSelf.memory];
            [strongSelf.navigationController pushViewController:hashTagContainerViewController animated:YES];
        }];
        [memCell setLocationTappedBlock:^(Memory *memory) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; //stop any video playback currently in progress
            [Flurry logEvent:@"MEMORY_GEOTAG_TAPPED"];
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = memory.venue;
            [venueDetailViewController fetchMemories];
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            [strongSelf.navigationController presentViewController:navController animated:YES completion:nil];
        }];
        
        _memoryCell = memCell;
    }
    
    return _memoryCell;
}



- (NSAttributedString *)venueNameAttributedString {
    // TODO: embed the location pin icon
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:@"pin-white-small"];
    NSAttributedString *attributedString = [NSAttributedString attributedStringWithAttachment:attachment];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    NSString *venueName = @"";
    switch (self.venue.specificity) {
        case SPCVenueIsReal:
            venueName = self.venue.displayNameTitle;
            break;
        case SPCVenueIsFuzzedToNeighhborhood:
            venueName = [NSString stringWithFormat:@"%@ Neighborhood", self.venue.neighborhood];
            break;
        case SPCVenueIsFuzzedToCity:
            venueName = self.venue.city;
            break;
    }
    
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", venueName]]];
    return string;
}

- (NSArray *)reportMemoryOptions {
    if (nil == _reportMemoryOptions) {
        _reportMemoryOptions = @[@"ABUSE", @"SPAM", @"PERTAINS TO ME"];
    }
    
    return _reportMemoryOptions;
}


#pragma mark - Actions


- (void)animateIn {
    if (self.gridCellAsset || self.gridCellImage) {
        // we have an image set...
        [self.memoryCell layoutSubviews];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 animations:^{
            CGRect frame = self.memoryCell.mediaContentScreenRect;
            self.expandingImageView.frame = frame;
            self.expandingImageViewClipped.frame = frame;
        }];
        [UIView animateWithDuration:(VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 - VENUE_GRID_TRANSITION_ALPHA_ANIMATION_DELAY) delay:VENUE_GRID_TRANSITION_ALPHA_ANIMATION_DELAY options:0 animations:^{
            self.expandingImageView.alpha = 1;
        } completion:nil];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 delay:VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 options:0 animations:^{
            self.header.alpha = 1.0f;
            self.scrollView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            self.header.userInteractionEnabled = YES;
            self.scrollView.userInteractionEnabled = YES;
            self.expandingImageView.image = nil;
            self.expandingImageViewClipped.image = nil;
        }];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    } else {
        // fade in the rest
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH animations:^{
            self.header.alpha = 1.0f;
            self.scrollView.alpha = 1.0f;
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {
            self.header.userInteractionEnabled = YES;
            self.scrollView.userInteractionEnabled = YES;
        }];
    }
}


- (void)dismissViewController {
    // set the currently selected image!
    self.viewIsDismissed = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; //clear vids to prevent playback continuing after controller is dismissed
    
    if (self.gridCellImage || self.gridCellAsset) {
        self.expandingImageViewClipped.image = self.expandingImageView.image = self.memoryCell.mediaContentImage;
        // we have an image set...
        self.header.userInteractionEnabled = NO;
        self.scrollView.userInteractionEnabled = NO;
        CGRect frame = self.memoryCell.mediaContentScreenRect;
        self.expandingImageView.frame = frame;
        self.expandingImageViewClipped.frame = frame;
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 animations:^{
            self.header.alpha = 0;
            self.scrollView.alpha = 0;
        }];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 delay:VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 options:0 animations:^{
            self.expandingImageView.frame = self.gridCellFrame;
            self.expandingImageViewClipped.frame = self.gridCellFrame;
        } completion:^(BOOL finished) {
            [self.navigationController dismissViewControllerAnimated:NO completion:^{}];
        }];
        [UIView animateWithDuration:(VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 - VENUE_GRID_TRANSITION_ALPHA_ANIMATION_DELAY) delay:VENUE_GRID_TRANSITION_ANIMATION_LENGTH/2 options:0 animations:^{
            self.expandingImageView.alpha = 0;
        } completion:nil];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    } else if (!self.snapTransitionDismiss) {
        // fade out the rest
        self.header.userInteractionEnabled = NO;
        self.scrollView.userInteractionEnabled = NO;
        self.expandingImageView.hidden = YES;
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH animations:^{
            self.header.alpha = 0.0f;
            self.scrollView.alpha = 0.0f;
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {
            [self.navigationController dismissViewControllerAnimated:NO completion:^{}];
        }];
    } else {
        // IMMEDIATE exit.  The most likely entrance to this is from the MAM
        // animation, where our background view is an obsolete image of the map.
        // Fading to it is a worse experience that just snapping back to whatever screen
        // we end up on.
        [self.navigationController dismissViewControllerAnimated:NO completion:^{}];
    }
}

- (void)updateMemoryViews:(Memory *)memory {
    self.memory = memory;
    [self updateMemoryViews];
}

- (void)updateMemoryViews {
    CGSize constraint = CGSizeMake([UIScreen mainScreen].bounds.size.width, 20000);
    self.memoryCell.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [MemoryCell measureHeightWithMemory:self.memory constrainedToSize:constraint]);
    [self.memoryCell configureWithMemory:self.memory tag:0 dateFormatter:nil placeholder:self.gridCellImage];
    
    CGSize size = CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.memoryCell.frame) - 20);
    [self.scrollView setContentSize:size];
}


- (void)showVenueDetail {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; //stop any video playback currently in progress
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:self.venueDetailViewController];
    [self presentViewController:navController animated:YES completion:^{
        if (self.exitBackgroundImage) {
            //During the MAM animation we want to use a different BG image during the exit from venue detail than we did when entering it
            self.backgroundImageView.image = self.exitBackgroundImage;
        }
    
    }];
}


- (void)showMemoryRelatedComments:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemory:self.memory];
    memoryCommentsViewController.view.clipsToBounds = NO;
    [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
}

- (void)showAuthor:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    if (self.memory.realAuthor && self.memory.realAuthor.userToken) {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:self.memory.realAuthor.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    } else if (self.memory.author.recordID == -2) {
        //Show anon alert!
        [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    }
    else {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:self.memory.author.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}


- (void)showUsersThatStarred:(id)sender {
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
    
    [self updateMemoryViews:memory];
    
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
                          
                          [self updateMemoryViews:memory];
                          
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
                       
                       [self updateMemoryViews:memory];
                       
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
    
    [self updateMemoryViews:memory];
    
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
                                       
                                       [self updateMemoryViews:memory];
                                   } faultCallback:^(NSError *fault) {
                                       if (!sockpuppet) {
                                           memory.userHasStarred = YES;
                                       }
                                       memory.starsCount = memory.starsCount + 1;
                                       memory.userToStarMostRecently = userAsStarred;
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                       
                                       [self updateMemoryViews:memory];
                                       
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
                               
                               [self updateMemoryViews:memory];
                               
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
                            
                            [self updateMemoryViews:memory];
                            
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
        [self updateMemoryViews];
        button.userInteractionEnabled = NO;
        
        [MeetManager deleteStarFromMemory:memory
                           resultCallback:^(NSDictionary *result){
                               int resultInt = [result[@"number"] intValue];
                               NSLog(@"delete star result %i",resultInt);
                               button.userInteractionEnabled = YES;
                               
                               if (resultInt == 1) {
                                   if (refreshMemoryFromServer) {
                                       [MeetManager fetchMemoryWithMemoryId:memory.recordID resultCallback:^(NSDictionary *results) {
                                           [memory setWithAttributes:results];
                                           [self updateMemoryViews:memory];
                                       } faultCallback:^(NSError *fault) {
                                           memory.userHasStarred = YES;
                                           memory.starsCount = memory.starsCount + 1;
                                           memory.userToStarMostRecently = userAsStarred;
                                           [self updateMemoryViews:memory];
                                           
                                           [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                       }];
                                   }
                               }
                               //correct local update if call failed
                               else {
                                   memory.userHasStarred = YES;
                                   memory.starsCount = memory.starsCount + 1;
                                   memory.userToStarMostRecently = userAsStarred;
                                   
                                   [self updateMemoryViews:memory];
                                   
                                   [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                               }
                               
                           }
                            faultCallback:^(NSError *error){
                                
                                //correct local update if call failed
                                memory.userHasStarred = YES;
                                memory.starsCount = memory.starsCount + 1;
                                memory.userToStarMostRecently = userAsStarred;
                                [self updateMemoryViews:memory];
                                
                                button.userInteractionEnabled = YES;
                                [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                            }];
        
        
    } else if (!memory.userHasStarred) {
        
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
        [self updateMemoryViews:memory];
        button.userInteractionEnabled = NO;
        
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
                       }];
    }
}
 */


- (void)showMemoryActions:(id)sender {
    // Selected memory index
    [Flurry logEvent:@"MEMORY_ACTION_BUTTON_TAPPED"];
    
    BOOL isUsersMemory = self.memory.author.recordID == [AuthenticationManager sharedInstance].currentUser.userId;
    BOOL userIsWatching = self.memory.userIsWatching;
    
    // Alert view controller
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    
    NSLog(@"self.memory.key %@",self.memory.key);
    
    if ([AuthenticationManager sharedInstance].currentUser.isAdmin) {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Promote Memory" subtitle:@"Add memory to Local and World grids" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = NSLocalizedString(@"Promote Memory?", nil);
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Promote", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                [[AdminManager sharedInstance] promoteMemory:self.memory completionHandler:^{
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
                [[AdminManager sharedInstance] demoteMemory:self.memory completionHandler:^{
                    [[[UIAlertView alloc] initWithTitle:@"Demoted Memory" message:@"This memory has been demoted.  It should not appear on Local or World grids." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Star as Puppet" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:SPCAdminSockPuppetActionStar object:self.memory];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Unstar as Puppet" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:SPCAdminSockPuppetActionUnstar object:self.memory];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
    }
    
    
    // Alert view controller - alerts
    if (isUsersMemory) {
        alertViewController.alertTitle = NSLocalizedString(@"Edit or Share", nil);
        
        if (nil != self.memory.location && nil != self.memory.venue && self.memory.venue.addressId && SPCVenueIsReal == self.memory.venue.specificity && (0 != [self.memory.location.latitude floatValue] || 0 != [self.memory.location.longitude floatValue])) {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Change Location", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [Flurry logEvent:@"MEM_UPDATED_LOCATION"];
                                                                       SPCMapViewController *mapVC = [[SPCMapViewController alloc] initForExistingMemory:self.memory];
                                                                       mapVC.delegate = self;
                                                                       [self.navigationController presentViewController:mapVC animated:YES completion:nil];
                                                                   }]];
        }
        if (self.memory.type != MemoryTypeFriends) {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Tag Friends", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       SPCTagFriendsViewController *tagUsersViewController = [[SPCTagFriendsViewController alloc] initWithMemory:self.memory];
                                                                       tagUsersViewController.delegate = self;
                                                                       [self.navigationController presentViewController:tagUsersViewController animated:YES completion:nil];
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
                                                                   [Flurry logEvent:@"MEM_SHARED_TO_TWITTER"];
                                                                   [self shareMemory:self.memory serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
                                                               }]];
    
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Delete Memory", nil)
                                                                 style:SPCAlertActionStyleDestructive
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self showDeletePromptForMemory:self.memory];
                                                               }]];
    }
    else {
       
        alertViewController.alertTitle = NSLocalizedString(@"Watch or Report", nil);
        
        if (!userIsWatching) {
            
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Watch Memory", nil)
                                                                  subtitle:NSLocalizedString(@"Get notifications of activity on this memory", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self watchMemory:self.memory];
                                                                   }]];
        }
        else {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Stop Watching Memory", nil)
                                                                  subtitle:NSLocalizedString(@"Stop receiving notifications about this memory", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self stopWatchingMemory:self.memory];
                                                                   }]];
        }
        
        NSString *reportString = [AuthenticationManager sharedInstance].currentUser.isAdmin ? @"Delete Memory" : @"Report Memory";
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(reportString, nil)
                                                                 style:SPCAlertActionStyleDestructive
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self showReportPromptForMemory:self.memory];
                                                               }]];

    }
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:SPCAlertActionStyleCancel
                                                           handler:nil]];
    
    // Alert view controller - show
    [self.navigationController presentViewController:alertViewController animated:YES completion:nil];
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
                               
                               NSLog(@"block failed, please try again");
                               
                           }
             ];
        }
    }];
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
    
    
    CGRect cancelFrame = CGRectMake(70, 205, 130, 40);
    
    self.alertView = [PXAlertView showAlertWithView:demoView cancelTitle:@"Cancel" cancelBgColor:[UIColor darkGrayColor] cancelTextColor:[UIColor whiteColor] cancelFrame:cancelFrame completion:^(BOOL cancelled) {
        self.alertView = nil;
    }];
}

- (void)deleteConfirmed:(id)sender {
    // Dismiss alert
    [self dismissAlert:sender];
    [Flurry logEvent:@"MEM_DELETED"];
    // Delete memory
    [self.memoryCoordinator deleteMemory:self.memory completionHandler:^(BOOL success) {
        if (success) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryDeleted object:self.memory];
            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
            
            [self dismissViewController];
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
   
    [MeetManager watchMemoryWithMemoryKey:self.memory.key
                           resultCallback:^(NSDictionary *result) {
                               NSLog(@"watching mem!");
                           }
                            faultCallback:nil];
    
}

- (void)stopWatchingMemory:(Memory *)memory {
    
    memory.userIsWatching = NO;
    
    [MeetManager unwatchMemoryWithMemoryKey:self.memory.key
                           resultCallback:^(NSDictionary *result) {
                               NSLog(@"unwatching mem!");
                           }
                            faultCallback:nil];

}


- (void)dismissAlert:(id)sender {
    [self.alertView dismiss:sender];
    self.alertView = nil;
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
}

- (void)cancelTaggingFriends {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // nothing
    }];
}



#pragma mark - Memories - Sharing

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



#pragma mark SPCMapViewControllerDelegate

- (void)cancelMap {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didAdjustLocationForMemory:(Memory *)memory {
    [self updateMemoryViews:memory];
    self.venue = memory.venue;
    self.venueNameLabel.attributedText = self.venueNameAttributedString;
    
    // refetch for the venue...
    self.venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    self.venueDetailViewController.delegate = self;
    self.venueDetailViewController.venue = self.venue;
    [self.venueDetailViewController fetchMemories];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark = SPCAdjustMemoryViewControllerDelegate

-(void)didAdjustLocationForMemory:(Memory *)memory withViewController:(UIViewController *)viewController {
    [self updateMemoryViews:memory];
    [self updateMemoryViews:memory];
    self.venue = memory.venue;
    self.venueNameLabel.attributedText = self.venueNameAttributedString;
    
    // refetch for the venue...
    self.venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    self.venueDetailViewController.delegate = self;
    self.venueDetailViewController.venue = self.venue;
    [self.venueDetailViewController fetchMemories];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

-(void)dismissAdjustMemoryLocationViewController:(UIViewController *)viewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}


#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView.tag == SocialServiceTypeTwitter) {
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeTwitter viewController:appDelegate.mainViewController.customTabBarController completionHandler:^{
                [self shareMemory:self.memory serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        }
        else if (alertView.tag == SocialServiceTypeFacebook) {
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

#pragma mark Notifications


-(void)videoFailedToLoad {
    if (self.viewIsVisible) {
        [self spc_hideNotificationBanner];
        [self spc_showNotificationBannerInParentView:self.view title:NSLocalizedString(@"Video failed to load", nil) customText:NSLocalizedString(@"Please check your network and try again.",nil)];
    }
}


- (void)spc_localMemoryDeleted:(NSNotification *)note {
    Memory *memory = (Memory *)note.object;
    
    if (memory.recordID == self.memory.recordID) {
        [self updateMemoryViews:memory];
    }
}

- (void)spc_localMemoryUpdated:(NSNotification *)note {
    Memory *memory = (Memory *)note.object;
    
    if (memory.recordID == self.memory.recordID) {
        if (self.venue.addressId != memory.venue.addressId) {
            self.venue = memory.venue;
            self.venueNameLabel.attributedText = self.venueNameAttributedString;
            
            // refetch for the venue...
            self.venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            self.venueDetailViewController.delegate = self;
            self.venueDetailViewController.venue = self.venue;
            [self.venueDetailViewController fetchMemories];
        }
        [self updateMemoryViews:memory];
    }
}


#pragma mark SPCVenueDetailViewControllerDelegate

- (void)spcVenueDetailViewControllerDidFinish:(UIViewController *)viewController {
    // double dismiss
    self.header.alpha = 0;
    self.scrollView.alpha = 0;
    self.viewIsDismissed = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    }];
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
