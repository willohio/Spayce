//
//  MemoryCommentsViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 12/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "MemoryCommentsViewController.h"
#import "Flurry.h"

// Model
#import "Asset.h"
#import "Friend.h"
#import "ProfileDetail.h"
#import "SPCAlertAction.h"
#import "SPCBaseDataSource.h"
#import "User.h"
#import "UserProfile.h"

// View
#import "DAKeyboardControl.h"
#import "MemoryCell.h"
#import "PXAlertView.h"
#import "SWCommentsCell.h"
#import "SPCView.h"
#import "SPCTableView.h"
#import "SPCReportAlertView.h"

// Controller
#import "SPCAlertViewController.h"
#import "SPCMainViewController.h"
#import "SPCProfileViewController.h"
#import "SPCStarsViewController.h"
#import "SPCHashTagContainerViewController.h"
#import "SPCReportViewController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCAdminSockPuppetChooserViewController.h"

// Category
#import "UIAlertView+SPCAdditions.h"
#import "UIColor+CrossFade.h"
#import "UIViewController+SPCAdditions.h"
#import "UITableView+SPXRevealAdditions.h"

// Coordinator
#import "SPCMemoryCoordinator.h"

// General
#import "AppDelegate.h"
#import "SPCServerResponses.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "MeetManager.h"
#import "ProfileManager.h"
#import "AdminManager.h"

// Transitions
#import "SPCAlertTransitionAnimator.h"

// Utility
#import "ImageUtils.h"
#import "SocialService.h"
#import "APIUtils.h"
#import "UIImageView+WebCache.h"

static NSString *CommentCellIdentifier = @"CommentCell";

static NSString *ATTRIBUTE_USER_TOKEN = @"ATTRIBUTE_USER_TOKEN";
static NSString *ATTRIBUTE_USER_ID = @"ATTRIBUTE_USER_ID";
static NSString *ATTRIBUTE_USER_NAME = @"ATTRIBUTE_USER_NAME";

const CGFloat VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC = 0.4f;
const CGFloat VENUE_GRID_TRANSITION_ALPHA_ANIMATION_DELAY_MCVC = VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC * 0.1;

@interface MemoryCommentsViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIViewControllerTransitioningDelegate, SWTableViewCellDelegate, UIAlertViewDelegate, SPCReportAlertViewDelegate, SPCReportViewControllerDelegate, SPCAdminSockPuppetChooserViewControllerDelegate> {
    BOOL hasAppeared;
    int memoryId;
    int taggedUserCount;
}

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *optionsBtn;
@property (nonatomic, strong) UIView *tableViewContainer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *whiteHeaderView;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSArray *includedVidURLs;
@property (nonatomic, strong) NSArray *includedAudioURLs;
@property (nonatomic, strong) UIView *composeBarView;
@property (nonatomic, strong) UITextView *commentInput;
@property (nonatomic, strong) NSMutableAttributedString *commentTextWithMarkup;
@property (nonatomic, strong) NSDictionary *commentTextPrefixMarkup;
@property (nonatomic, strong) UIButton *sendCommentButton;
@property (nonatomic, strong) UserProfile *profile;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) Memory *mem;
@property (strong, nonatomic) PXAlertView *alertView;
@property (nonatomic, strong) SPCReportAlertView *reportAlertView;
@property (nonatomic) SPCReportType reportType;
@property (nonatomic, strong) NSArray *reportMemoryOrCommentsOptions;
@property (nonatomic, strong) id reportObject;
@property (nonatomic, assign) NSInteger reportIndex;
@property (nonatomic, strong) MemoryCell *memCell;
@property (nonatomic, strong) UIView *tableHeaderView;
@property (nonatomic, assign) CGFloat tableHeaderHeight;
@property (nonatomic, assign) BOOL tableBeingDragged;
@property (nonatomic, strong) HMSegmentedControl *hmSegmentedControl;
@property (nonatomic, strong) SPCTagFriendsViewController *tagFriendsViewController;
@property (nonatomic, strong) SPCFriendPicker *friendPicker;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL commentsFetchComplete;

@property (nonatomic, assign) BOOL keyboardControlAdded;
@property (nonatomic, assign) BOOL selectingAFriend;
// Transition views and recordkeeping
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *expandingImageView;
@property (nonatomic, strong) UIImageView *expandingImageViewClipped;

@property (nonatomic, strong) UIView *clippingView;

@property (nonatomic, assign) BOOL viewDidAppear;
@property (nonatomic, assign) BOOL viewIsDismissed;
@property (nonatomic, assign) BOOL revealNavigationBarOnPop;

// Coordinator
@property (nonatomic, strong) SPCMemoryCoordinator *memoryCoordinator;

@end

@implementation MemoryCommentsViewController {
    NSInteger alertViewTagTwitter;
    NSInteger alertViewTagFacebook;
    NSInteger alertViewTagReport;
    NSInteger alertViewTagBlock;
}

-(void)dealloc {
    if (self.keyboardControlAdded) {
        NSLog(@"removing key control");
        self.keyboardControlAdded = NO;
        [self.view removeKeyboardControl];
    }
    NSLog(@"comments dealloc %@",self);
    
    _tableView.delegate = nil;
    _friendPicker.delegate = nil;
    _tagFriendsViewController.delegate = nil;
    [_memCell clearContent];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithMemory:(Memory *)m {
    
    self = [super init];
    
    if (self) {
        self.comments = [[NSMutableArray alloc] init];
        self.mem = m;
        self.memoryType = m.type;
        
        memoryId = (int)m.recordID;
        
        
         NSLog(@"memID %i",memoryId);
         NSLog(@"authorID %li",self.mem.author.recordID);
         NSLog(@"author userToken %@",self.mem.author.userToken);
         NSLog(@"addressName %@",self.mem.locationName);
         NSLog(@"mem star count %i",(int)self.mem.starsCount);
         NSLog(@"mem type %i",(int)self.mem.type);
        
        if (self.memoryType == MemoryTypeVideo) {
            VideoMemory *memory = (VideoMemory *)m;
            self.includedVidURLs = memory.videoURLs;
        }
        if (self.memoryType == MemoryTypeAudio) {
            AudioMemory *memory = (AudioMemory *)m;
            self.includedAudioURLs = memory.audioURLs;
        }
        
        [self loadComments];
    }
    return self;
}


- (id) initWithMemoryId:(NSInteger)memId {
    
    self = [super init];
    
    if (self) {
        self.comments = [[NSMutableArray alloc] init];
        [self fetchMemoryWithId:memId];
        self.viewingFromNotification = YES;
    }
    return self;
}

- (void)loadView {
    [Flurry logEvent:@"COMMENTS_VIEW"];
    [super loadView];
    NSLog(@"comments did load %@",self);
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    if (self.viewingFromGrid) {
        [self.view addSubview:self.backgroundImageView];
        [self.view addSubview:self.clippingView];
        [self.view addSubview:self.expandingImageView];
        [self.clippingView addSubview:self.expandingImageViewClipped];
    }
    
    [self.view addSubview:self.tableViewContainer];
    
    [self.tableViewContainer addSubview:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doneShowingDetail)
                                                 name:@"doneShowingDetail"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showTappedProfileFromHeader:)
                                                 name:@"showTappedProfile"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPersonUpdateWithNotification:) name:kPersonUpdateNotificationName object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.mem) {
        [self setupTableView];
    }
    
    [self setupComposeBar];
    if (!self.mem ) {
        // Hiding the compose bar entirely results in a visual glitch at
        // the bottom of the screen while the memory loads -- for an example,
        // check the transition from Notifications.
        //self.composeBarView.alpha = 0;
        self.composeBarView.backgroundColor = [UIColor colorWithRGBHex:0xf3f3f3];
        self.commentInput.alpha = 0;
        self.sendCommentButton.alpha = 0;
        self.placeholderLabel.alpha = 0;
    }
    
    [self updateForManualNav];
    self.profile = [ContactAndProfileManager sharedInstance].profile;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFailedToLoad) name:@"videoLoadFailed" object:nil];
    
    if (self.animateTransition) {
        // Hide those that are not visible for transition animation.
        self.tableViewContainer.alpha = 0;
        self.navBar.alpha = 0;
        self.composeBarView.alpha = 0;
        self.navBar.userInteractionEnabled = NO;
        self.tableView.userInteractionEnabled = NO;
        self.composeBarView.userInteractionEnabled = NO;
    }
    
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    alertViewTagFacebook = 0;
    alertViewTagTwitter = 1;
    alertViewTagReport = 2;
    alertViewTagBlock = 3;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    if (!self.viewDidAppear) {
        self.revealNavigationBarOnPop = !self.navigationController.navigationBarHidden && !self.viewingFromGrid;
    }
    
    self.navigationController.navigationBarHidden = YES;
    if (!self.viewingFromGrid || self.animateTransition) {
        self.tabBarController.tabBar.alpha = 0.0;
    }
    
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    [self.memCell updateTimestamp];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isVisible = YES;
    if (!self.viewingFromGrid || self.animateTransition) {
        self.tabBarController.tabBar.alpha = 0.0;
    }
    
    BOOL firstAppearance = !self.viewDidAppear;
    self.viewDidAppear = YES;
    self.isVisible = YES;
    
    if (firstAppearance && self.animateTransition) {
        // The animation relies on an accurate measurement of the memory cell's
        // "content area", so we can match its position with the expanding image.
        // For unknown reasons, we will get an error of about +1 pixel in Y origin if
        // we perform this measurement right here.  Delaying by 0.001 resolves this.
        // Your guess is as good as mine.
        [self performSelector:@selector(animateIn) withObject:nil afterDelay:0.001];
        //[self animateIn];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isVisible = NO;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (!hasAppeared && !self.keyboardControlAdded) {
        hasAppeared = YES;
        self.keyboardControlAdded = YES;
        self.tableView.frame = CGRectMake(0, self.tableStart, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-self.composeBarView.frame.size.height-self.tableStart);
        [self.view addSubview:self.friendPicker];
        self.composeBarView.frame =  CGRectMake(0.0f, CGRectGetHeight(self.view.frame)-46, self.view.frame.size.width, 46);
        
        self.view.keyboardTriggerOffset = 46.0f;
        float startOffset = self.tableStart;
        
        
        UIView *tempCompose = self.composeBarView;
        UITableView *tempTable = self.tableView;
        UIView *pickerView = self.friendPicker;
        UICollectionView *pickerCollectionView = self.friendPicker.collectionView;
        
        [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
            
            CGRect toolBarFrame = tempCompose.frame;
            toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
            tempCompose.frame = toolBarFrame;
            
            CGRect tableViewFrame = tempTable.frame;
            tableViewFrame.size.height = toolBarFrame.origin.y - startOffset;
            tempTable.frame = tableViewFrame;
            pickerView.frame = CGRectMake(tableViewFrame.origin.x, tableViewFrame.origin.y, tableViewFrame.size.width, tableViewFrame.size.height);
            pickerCollectionView.frame = CGRectMake(0, 0, pickerView.frame.size.width, pickerView.frame.size.height);
        }];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark view lifecyle

- (void)setupNavigationBar
{
    
}

- (void)setupTableView {
    CGFloat memoryHeight;
    CGSize constraint = CGSizeMake([UIScreen mainScreen].bounds.size.width, 20000);
    memoryHeight = [MemoryCell measureHeightWithMemory:self.mem constrainedToSize:constraint];
    self.tableHeaderHeight = memoryHeight - self.mem.heightForCommentText - 20;
    
    SPCView *header = [[SPCView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), self.tableHeaderHeight)];
    header.clipsToBounds = NO;
    header.clipsHitsToBounds = NO;
    self.tableHeaderView = header;
    header.backgroundColor = [UIColor whiteColor];
    
    [self.tableView registerClass:[SWCommentsCell class] forCellReuseIdentifier:CommentCellIdentifier];
    
    self.memCell = [[MemoryCell alloc] initWithMemoryType:self.memoryType style:UITableViewCellStyleDefault reuseIdentifier:@"header"];
    self.memCell.frame = CGRectMake(0, 0,[[UIScreen mainScreen] bounds].size.width, memoryHeight - self.mem.heightForCommentText);
    self.memCell.viewingInComments = YES;
    [self.memCell.followButton addTarget:self action:@selector(followOrUnfollowPersonWithCompletion:) forControlEvents:UIControlEventTouchUpInside];
    [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
    [self.memCell updateForCommentDisplay];
    
    
    [self.memCell.starsButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
    [self.memCell.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
    [self.memCell.authorButton addTarget:self action:@selector(showMemAuthorProfile:) forControlEvents:UIControlEventTouchUpInside];
    //[self.memCell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.memCell setTaggedUserTappedBlock:^(NSString * userToken) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showTappedProfile" object:userToken];
    }];
    
    __weak typeof(self)weakSelf = self;
    [self.memCell setHashTagTappedBlock:^(NSString *hashTag, Memory *mem) {
        //stop video playback if needed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        SPCHashTagContainerViewController *hashTagContainerViewController = [[SPCHashTagContainerViewController alloc] init];
        [hashTagContainerViewController configureWithHashTag:hashTag memory:weakSelf.mem];
        [strongSelf.navigationController pushViewController:hashTagContainerViewController animated:YES];
    }];
    
    [self.memCell setLocationTappedBlock:^(Memory * memory) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        //stop video playback if needed
        if (!strongSelf.viewingFromVenueDetail) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
            [Flurry logEvent:@"MEMORY_GEOTAG_TAPPED"];
            
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = strongSelf.mem.venue;
            [venueDetailViewController fetchMemories];
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            [strongSelf.navigationController presentViewController:navController animated:YES completion:nil];
        }
    }];
    
    [self.memCell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect m = self.memCell.frame;
    self.whiteHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, m.origin.y - m.size.height*2, m.size.width, m.size.height*2)];
    self.whiteHeaderView.backgroundColor = [UIColor whiteColor];
    [self.tableHeaderView addSubview:self.whiteHeaderView];
    
    [self.tableHeaderView addSubview:self.memCell];
    
    self.tableView.tableHeaderView = self.tableHeaderView;
    
    self.tableViewContainer.frame = self.view.bounds;
}

-(void)setupComposeBar
{
    //NSLog(@"setupComposeBar");
    CGRect frame = CGRectMake(0.0f, CGRectGetHeight(self.view.frame)-46, self.view.frame.size.width, 46);
    self.composeBarView = [[UIView alloc] initWithFrame:frame];
    self.composeBarView.backgroundColor = [UIColor whiteColor];
    self.composeBarView.userInteractionEnabled = YES;
    [self.view addSubview:self.composeBarView];
    
    UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.composeBarView.frame.size.width, (1.0f / [UIScreen mainScreen].scale))];
    sepLine.backgroundColor = [UIColor colorWithWhite:.85 alpha:1.0f];
    [self.composeBarView addSubview:sepLine];
    
    self.sendCommentButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-53, 8, 51, 30)];
    self.sendCommentButton.backgroundColor = [UIColor clearColor];
    self.sendCommentButton.layer.cornerRadius = 5;
    self.sendCommentButton.alpha = .5;
    self.sendCommentButton.enabled = NO;
    [self.sendCommentButton setTitle:@"Send" forState:UIControlStateNormal];
    self.sendCommentButton.titleLabel.font = [UIFont spc_boldSystemFontOfSize:14];
    self.sendCommentButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.sendCommentButton setTitleColor:[UIColor colorWithRed:106/255.0f green:177/255.0f blue:251/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.sendCommentButton addTarget:self action:@selector(postComment:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendCommentButton addTarget:self action:@selector(buttonCancel:) forControlEvents:UIControlEventTouchUpOutside];
    [self.sendCommentButton addTarget:self action:@selector(buttonHighlight:) forControlEvents:UIControlEventTouchDown];
    [self.composeBarView addSubview:self.sendCommentButton];
    
    self.commentInput = [[UITextView alloc] initWithFrame:CGRectMake(13, 8, CGRectGetWidth(self.view.frame)-68, 30)];
    self.commentInput.keyboardType = UIKeyboardTypeTwitter;
    self.commentInput.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    self.commentInput.delegate = self;
    self.commentInput.font = [UIFont spc_regularSystemFontOfSize:14];
    self.commentInput.textContainerInset = UIEdgeInsetsMake(6.0, 6.0, 6.0, 6.0);
    self.commentInput.layer.cornerRadius = 5;
    self.commentInput.textColor = [UIColor colorWithRGBHex:0x14294b];
    self.commentInput.layer.borderColor = [UIColor colorWithRed:172/255.0f green:182/255.0f blue:198/255.0f alpha:1.0f].CGColor;
    self.commentInput.layer.borderWidth = 1;
    self.commentInput.spellCheckingType  = UITextSpellCheckingTypeYes;
    self.commentInput.autocorrectionType = UITextAutocorrectionTypeYes;
    self.commentInput.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [self.composeBarView addSubview:self.commentInput];
    self.commentTextPrefixMarkup = @{NSFontAttributeName : [UIFont spc_regularSystemFontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x14294b] };
    self.commentTextWithMarkup = [[NSMutableAttributedString alloc] initWithString:@"" attributes:self.commentTextPrefixMarkup];
    
    self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 8, CGRectGetWidth(self.view.frame)-73, 30)];
    self.placeholderLabel.userInteractionEnabled = NO;
    self.placeholderLabel.text = @"Say something";
    self.placeholderLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
    self.placeholderLabel.backgroundColor = [UIColor clearColor];
    self.placeholderLabel.textColor = [UIColor grayColor];
    [self.composeBarView addSubview:self.placeholderLabel];
    
    //NSLog(@"compose bar is %@, comment input is %@", NSStringFromCGRect(self.composeBarView.frame), NSStringFromCGRect(self.commentInput.frame));
}

#pragma mark - Accessors

-(SPCFriendPicker *)friendPicker {
    if (!_friendPicker) {
        _friendPicker = [[SPCFriendPicker alloc] initWithFrame:self.tableView.frame];
        _friendPicker.delegate = self;
        _friendPicker.hidden = YES;
    }
    
    return _friendPicker;
}

- (SPCMemoryCoordinator *)memoryCoordinator {
    if (!_memoryCoordinator) {
        _memoryCoordinator = [[SPCMemoryCoordinator alloc] init];
    }
    return _memoryCoordinator;
}

- (HMSegmentedControl *)hmSegmentedControl {
    if (!_hmSegmentedControl) {
        
        _hmSegmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"RECENT", @"POPULAR"]];
        _hmSegmentedControl.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, [self tableView:self.tableView heightForHeaderInSection:0]);
        [_hmSegmentedControl addTarget:self action:@selector(selectedSegment:) forControlEvents:UIControlEventValueChanged];
        _hmSegmentedControl.backgroundColor = [UIColor whiteColor];
        _hmSegmentedControl.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        _hmSegmentedControl.textColor = [UIColor colorWithRed:139.0f/255.0f  green:153.0f/255.0f  blue:175.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectedTextColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectionIndicatorColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStripe;
        _hmSegmentedControl.selectionIndicatorHeight = 3.0f;
        _hmSegmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        _hmSegmentedControl.shouldAnimateUserSelection = YES;
        _hmSegmentedControl.selectedSegmentIndex = 0;
        
    }
    
    return _hmSegmentedControl;
}

-(UIActivityIndicatorView *)spinner {
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _spinner.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        _spinner.color = [UIColor darkGrayColor];
        _spinner.alpha = 1;
    }
    return _spinner;
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

- (CGFloat)tableStart {
    return 64.0f;
}

-(UIButton *)optionsBtn {
    if (!_optionsBtn) {
        _optionsBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 45, 20, 45, 50)];
        [_optionsBtn addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchDown];
        [_optionsBtn setBackgroundImage:[UIImage imageNamed:@"chatOptions"] forState:UIControlStateNormal];
        [_optionsBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return _optionsBtn;
}


#pragma mark - Transition Accessors

- (void)setNavBarAlpha:(CGFloat)alpha {
    self.navBar.alpha = alpha;
}

- (void)setWhiteHeaderViewAlpha:(CGFloat)alpha {
    self.whiteHeaderView.alpha = alpha;
}

- (void)setTableHeaderViewAlpha:(CGFloat)alpha {
    self.tableHeaderView.alpha = alpha;
}

- (void)setTableViewAlpha:(CGFloat)alpha {
    self.tableView.alpha = alpha;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.comments.count == 0){
        return 1;
    } else {
        return self.comments.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.comments.count == 0){
        float tempHeight = self.tableView.frame.size.height - self.tableView.tableHeaderView.frame.size.height;
        if (tempHeight < 0) {
            tempHeight = 0;
        }
        return tempHeight;
    }
    else {
        Comment *comment = self.comments[indexPath.row];
        NSString *commentText = comment.text;
        
        //NSLog(@"cell height %f",[SWCommentsCell cellHeightForCommentText:commentText]);
        
        return [SWCommentsCell cellHeightForCommentText:commentText];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView commentCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SWCommentsCell *cell = [tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier forIndexPath:indexPath];
    
    Comment *cleanComment = (Comment *)self.comments[indexPath.row];
    
    float cellH = [SWCommentsCell cellHeightForCommentText:cleanComment.text];
    
    cell.cellH = cellH;
    cell.delegate = self;
    
    [cell.imageButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
    [cell.imageButton setTag:indexPath.row];
    
    [cell setTaggedUserTappedBlock:^(NSString * userToken) {
        //stop video playback if needed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }];
    
    [cell setHashTagTappedBlock:^(NSString *hashTag) {
        //stop video playback if needed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
        SPCHashTagContainerViewController *hashTagContainerViewController = [[SPCHashTagContainerViewController alloc] init];
        [hashTagContainerViewController configureWithHashTag:hashTag memory:self.mem];
        [self.navigationController pushViewController:hashTagContainerViewController animated:YES];
    }];
    
    cell.containingTableView = tableView;
    
    cell.tag = indexPath.row;
    
    //NSLog(@"comment token %@",cleanComment.userToken);
    //NSLog(@"curr user token %@", [AuthenticationManager sharedInstance].currentUser.userToken);
    
    BOOL isCurrentUsersComment = NO;
    if ([[AuthenticationManager sharedInstance].currentUser.userToken isEqualToString:cleanComment.userToken]) {
        isCurrentUsersComment = YES;
    }
    BOOL userCanDelete = isCurrentUsersComment
            || [AuthenticationManager sharedInstance].currentUser.isAdmin
    || [[AuthenticationManager sharedInstance].currentUser.userToken isEqualToString:self.mem.author.userToken];
    
    [cell configureWithCleanComment:cleanComment tag:indexPath.row isCurrentUser:isCurrentUsersComment];
    
    cell.separatorLine.frame = CGRectMake(0, cellH-(1.0f / [UIScreen mainScreen].scale), tableView.frame.size.width, (1.0f / [UIScreen mainScreen].scale));
    
    if (userCanDelete) {
        cell.rightUtilityButtons = [self rightDeleteButton];
    } else {
        cell.rightUtilityButtons = [self rightReportButton];
    }
    
    cell.backgroundColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView placeHolderCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"PlaceHolder";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = @"";
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12.0f];
    cell.textLabel.textColor = [UIColor grayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.comments.count == 0){
        return [self tableView:tableView placeHolderCellForRowAtIndexPath:indexPath];
    } else {
        return [self tableView:tableView commentCellForRowAtIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(tableView.frame), [self tableView:tableView heightForHeaderInSection:section]);
    view.backgroundColor = [UIColor clearColor];
    [view addSubview:self.hmSegmentedControl];
    
    UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(0, view.frame.size.height - 1, self.view.bounds.size.width, 1)];
    sepView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
    [view addSubview:sepView];
    
    UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - .5, 11.5, 1, 17)];
    sepLine.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
    [view addSubview:sepLine];
    
    [self updateSegmentedControlWithScrollView:tableView];
    
    return view;
}

#pragma mark - UITextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.2];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(scrollToLastComment)];
    self.placeholderLabel.alpha = 0;
    [UIView setAnimationDelegate:self];
    [UIView commitAnimations];
    
    [self textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@""];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    self.selectingAFriend = NO;
    BOOL justDeletedUser = NO;
    NSArray *currentlyTaggedUserNames = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_NAME];
    taggedUserCount = (int)currentlyTaggedUserNames.count;
    
    //hide tagged friends view @ has been deleted
    NSString *textToChange  = [textView.text substringWithRange:range];
    NSRange rangeOld = [textToChange rangeOfString:@"@" options:NSBackwardsSearch];
    NSRange rangeNew = [text rangeOfString:@"@" options:NSBackwardsSearch];
    if (rangeOld.location != NSNotFound && rangeNew.location == NSNotFound) {
        self.friendPicker.isSearching = NO;
        self.friendPicker.hidden = YES;
        [self updateNavBarWithScrollView:self.tableView];
        justDeletedUser = YES;
    }
    
    //show tagged friends view if @ has been typed
    if ([text isEqualToString:@"@"]){
        //NSLog(@"@ was type, show friend picker");
        self.friendPicker.hidden = NO;
         self.selectingAFriend = YES;
        self.friendPicker.isSearching = NO;
        [self.friendPicker reloadData];
        self.friendPicker.collectionView.frame = CGRectMake(0, 0, self.friendPicker.frame.size.width, self.friendPicker.frame.size.height);
        [self updateNavBarWithScrollView:self.tableView];
    }
    
    //update tagged friends search string if @ has previously been typed
    if (!self.friendPicker.hidden) {
        //NSLog(@"@ was previously typed");
        self.selectingAFriend = YES;
        NSString *resultString = [self.commentInput.text stringByReplacingCharactersInRange:range withString:text];
     
        //find search string to use for @username autocompletion/filtering
        NSString *searchString;
        NSRange searchRangeStart = [resultString rangeOfString:@"@" options:NSBackwardsSearch];
        NSString *stringFromAt = [resultString substringFromIndex:searchRangeStart.location+1];
        NSRange endOfWordRange = [stringFromAt rangeOfString:@" " options:NSCaseInsensitiveSearch];
        
        if (endOfWordRange.location != NSNotFound) {
            //get the range for the first full word from the current @ position
            searchString = [stringFromAt substringToIndex:endOfWordRange.location];
        }
        else {
            //no spaces from the @ position
            searchString = stringFromAt;
        }
        
        //NSLog(@"searchString %@",searchString);
    
        if (searchString.length > 0) {
            [self.friendPicker updateFilterString:searchString];
        }
    }
    
 
    
    //attempt to autocomplete
    if ([text isEqualToString:@" "]){
        //NSLog(@"_ _ was typed, attempt to manually autocomplete an exact match for a tagged friend");
        [self performSelector:@selector(findExactMatch) withObject:nil afterDelay:.1];
    }
    
    NSString *resultString = [self.commentInput.text stringByReplacingCharactersInRange:range withString:text];
    
    if (resultString.length > 0) {
        self.placeholderLabel.alpha = 0;
        self.sendCommentButton.alpha = 1.0f;
        self.sendCommentButton.enabled = YES;
    } else {
        self.placeholderLabel.alpha = 1;
        self.sendCommentButton.alpha = 0.5f;
        self.sendCommentButton.enabled = NO;
    }
    
    CGSize maximumLabelSize = CGSizeMake(CGRectGetWidth(self.commentInput.frame) - self.commentInput.textContainerInset.left - self.commentInput.textContainerInset.right - 10, FLT_MAX);
    CGSize newCommentLabelSize = [resultString boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: self.commentInput.font } context:NULL].size;
    NSInteger totalLines = round(newCommentLabelSize.height/([UIFont spc_regularSystemFontOfSize:14].lineHeight));
    if (totalLines<1) {
        totalLines = 1;
    }
    
    self.commentInput.frame = CGRectMake(13, 8, CGRectGetWidth(self.view.frame)-68, 12+18*totalLines);
    self.composeBarView.frame = CGRectMake(0, CGRectGetMaxY(self.composeBarView.frame) - (CGRectGetHeight(self.commentInput.frame)+16), self.view.frame.size.width,CGRectGetHeight(self.commentInput.frame)+16);
    self.sendCommentButton.frame = CGRectMake(self.sendCommentButton.frame.origin.x,CGRectGetHeight(self.composeBarView.frame) - 38, self.sendCommentButton.frame.size.width, self.sendCommentButton.frame.size.height);
    
    
    if (self.selectingAFriend && resultString.length <= 141) {
        //NSLog(@"selecting friend, handle text update manually!");
        // if any attributed range would be disrupted or altered by this change,
        // remove all attributes around it.
        [self replaceCharactersOfMarkupString:self.commentTextWithMarkup inRange:range withString:text];
        //NSLog(@"Comment text is %@", self.commentTextWithMarkup);
        self.commentInput.attributedText = self.commentTextWithMarkup;
        [self selectTextForInput:self.commentInput atRange:NSMakeRange(range.location + text.length, 0)];
    }

    
    //NSLog(@"compose bar is %@, comment input is %@", NSStringFromCGRect(self.composeBarView.frame), NSStringFromCGRect(self.commentInput.frame));
    if (self.selectingAFriend) {
        //NSLog(@"selecting Friend?");
        return NO;
    }
    else {
        NSLog(@"not selecting Friend?");
        
        if (justDeletedUser) {
            //NSLog(@"just deleted a user?");
            [self replaceCharactersOfMarkupString:self.commentTextWithMarkup inRange:range withString:text];
            //NSLog(@"Comment text is %@", self.commentTextWithMarkup);
            self.commentInput.attributedText = self.commentTextWithMarkup;
            [self selectTextForInput:self.commentInput atRange:NSMakeRange(range.location + text.length, 0)];
            return NO;
        }
        else {
            //only do this if our range works, if it doesn't work here it will be fixed in the didChangeMethod
            if (range.location + range.length <= self.commentTextWithMarkup.string.length) {
                //NSLog(@"replace text!");
                [self replaceCharactersOfMarkupString:self.commentTextWithMarkup inRange:range withString:text];
                return resultString.length <= 141;
            }
            else {
                //NSLog(@"we have a range problem?");
                return NO;
            }
        }
    

    }
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    self.composeBarView.frame =  CGRectMake(0.0f, CGRectGetHeight(self.view.frame)-46, self.view.frame.size.width, 46);
    self.commentInput.frame = CGRectMake(13, 8, CGRectGetWidth(self.view.frame)-68, 30);
    self.sendCommentButton.frame = CGRectMake(CGRectGetWidth(self.view.frame)-53, 8, 51, 30);
    self.tableView.contentOffset = CGPointMake(0, 0);
    self.tableView.frame = CGRectMake(0, self.tableStart, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-self.composeBarView.frame.size.height-self.tableStart);
    
    //NSLog(@"compose bar is %@, comment input is %@", NSStringFromCGRect(self.composeBarView.frame), NSStringFromCGRect(self.commentInput.frame));
    
    self.friendPicker.hidden = YES;
    self.selectingAFriend = NO;
    [self updateNavBarWithScrollView:self.tableView];
}

-(void)textViewDidChange:(UITextView *)textView {
    //NSLog(@"textViewDidChange and text is:%@",textView.text);
    //NSLog(@"commentTextWithMarkup: %@", self.commentTextWithMarkup);
    //NSLog(@"commentTextWithMarkup string %@",self.commentTextWithMarkup.string);
    //NSLog(@"commentTextWithMarkup length %li",self.commentTextWithMarkup.string.length);
    
    if (self.commentTextWithMarkup.string.length == 0) {
        //NSLog(@"no comment text yet?");
        self.commentTextWithMarkup = [[NSMutableAttributedString alloc] initWithString:textView.text];
    }
    
    BOOL restylingNeeded = NO;
    if (![textView.text isEqualToString:self.commentTextWithMarkup.string]) {
        restylingNeeded = YES;
    }
    
    //check our tagged user count?  has it changed since we typed the last characcter?
    //if so, restyling is needed
    NSArray *currentlyTaggedUserNames = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_NAME];
    if (taggedUserCount != (int)currentlyTaggedUserNames.count) {
        restylingNeeded = YES;
    }
   
    if (restylingNeeded && !self.selectingAFriend) {
        //NSLog(@"restyling needed!");
        [self restyleText:textView.text];
    }
        
    //NSLog(@"updated - commentTextWithMarkup: %@", self.commentTextWithMarkup);
    
    if (textView.text.length > 0) {
        self.placeholderLabel.alpha = 0;
        self.sendCommentButton.alpha = 1.0f;
        self.sendCommentButton.enabled = YES;
    } else {
        self.placeholderLabel.alpha = 1;
        self.sendCommentButton.alpha = 0.5f;
        self.sendCommentButton.enabled = NO;
    }
}

-(void)restyleText:(NSString *)textToRestyle {
    
    NSArray *currentlyTaggedUserNames = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_NAME];
    NSArray *currentlyTaggedUserIds = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_ID];
    NSArray *currentlyTaggedUserTokens = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_TOKEN];

    
    
    //NSLog(@"textToRestyle %@",textToRestyle);
    //NSLog(@"currently tagged users %@",currentlyTaggedUserNames);
    

    self.commentTextWithMarkup = [[NSMutableAttributedString alloc] initWithString:textToRestyle];

    // create an attributed (with no attributes) string, to terminate any previous attribution.
    NSRange fullRange = NSMakeRange(0, textToRestyle.length);
    fullRange = NSMakeRange(0, self.commentTextWithMarkup.length);
    [self.commentTextWithMarkup addAttributes:self.commentTextPrefixMarkup range:fullRange];
    
    for (int i = 0; i < currentlyTaggedUserNames.count; i++)  {
        NSString *taggedUser = currentlyTaggedUserNames[i];
        //NSLog(@"search for %@",taggedUser);
        
        NSRange tagguedUserRange = [textToRestyle rangeOfString:taggedUser options:NSCaseInsensitiveSearch];
        
        if (tagguedUserRange.location == NSNotFound) {
            
            //remove this tagged user?
            //NSLog(@"%@ not found!!",taggedUser);
        }
        
        else {
            //NSLog(@"restyle for tagged user %@",taggedUser);
        
            NSString *userToken = currentlyTaggedUserTokens[i];
            NSString *userId = currentlyTaggedUserIds[i];
            
            NSDictionary *attributes = @{ ATTRIBUTE_USER_TOKEN : userToken,
                                          ATTRIBUTE_USER_NAME : taggedUser,
                                          ATTRIBUTE_USER_ID : userId };
            NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:taggedUser attributes:attributes];
            [self replaceCharactersOfMarkupString:self.commentTextWithMarkup inRange:tagguedUserRange withAttributedString:attributedName];
            //NSLog(@"markup string is %@", self.commentTextWithMarkup);
            

        }
    }

    self.commentInput.attributedText = self.commentTextWithMarkup;
    
    NSLog(@"restyled text and now self.commentTextWithMarkup is: %@",self.commentTextWithMarkup);
}

#pragma mark - SPCFriendPicker delegate

- (void)selectedFriend:(Friend *)f {
    
    self.friendPicker.hidden = YES;
    self.friendPicker.isSearching = NO;
    
    //update text view text with name of selected friend
    
    
    //find the begining of our range to replace
    NSRange searchRangeStart = [self.commentInput.text rangeOfString:@"@" options:NSBackwardsSearch];
    NSString *stringFromAt = [self.commentInput.attributedText.string substringFromIndex:searchRangeStart.location];
    
    //NSLog(@"searchRangeStart.location %li",searchRangeStart.location);
    //NSLog(@"stringFromAt %@",stringFromAt);
    
    NSRange endOfWordRange = [stringFromAt rangeOfString:@" " options:NSCaseInsensitiveSearch];
    NSRange removedRange; // = NSMakeRange(searchRangeEnd.location, self.commentInput.text.length - searchRangeEnd.location);
    
    if (endOfWordRange.location != NSNotFound) {
        //get the range for the first full word from the current @ position
         NSString *wordToSwap = [stringFromAt substringToIndex:endOfWordRange.location];
        //NSLog(@"wordToSwap %@",wordToSwap);
        removedRange = NSMakeRange(searchRangeStart.location, wordToSwap.length);
    }
    else {
        //no spaces from the @ position
        removedRange = NSMakeRange(searchRangeStart.location, stringFromAt.length);
    }
    
    // add the username (w/ annotation markup)
    NSDictionary *attributes = @{ ATTRIBUTE_USER_TOKEN : f.userToken,
                                  ATTRIBUTE_USER_NAME : f.firstname,
                                  ATTRIBUTE_USER_ID : [NSString stringWithFormat:@"%@", @(f.recordID)] };
    NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:f.firstname attributes:attributes];
    [attributedName appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [self replaceCharactersOfMarkupString:self.commentTextWithMarkup inRange:removedRange withAttributedString:attributedName];
    //NSLog(@"markup string is %@", self.commentTextWithMarkup);
    
    self.commentInput.attributedText = self.commentTextWithMarkup;
   
    [self selectTextForInput:self.commentInput atRange:NSMakeRange(removedRange.location + attributedName.length, 0)];
    
    [self updateNavBarWithScrollView:self.tableView];
}

-(void)replaceCharactersOfMarkupString:(NSMutableAttributedString *)markupString inRange:(NSRange)range withString:(NSString *)string {
    [self replaceCharactersOfMarkupString:markupString inRange:range withAttributedString:[[NSAttributedString alloc] initWithString:string]];
}

-(void)selectTextForInput:(UITextView *)input atRange:(NSRange)range {
    UITextPosition *start = [input positionFromPosition:[input beginningOfDocument]
                                                 offset:range.location];
    UITextPosition *end = [input positionFromPosition:start
                                               offset:range.length];
    [input setSelectedTextRange:[input textRangeFromPosition:start toPosition:end]];
}

-(void)replaceCharactersOfMarkupString:(NSMutableAttributedString *)markupString inRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString {
    NSRange fullRange = NSMakeRange(0, markupString.length);
    [markupString enumerateAttributesInRange:fullRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attrs, NSRange attrRange, BOOL *stop) {
        if (NSIntersectionRange(range, attrRange).length > 0) {
            [attrs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [markupString removeAttribute:key range:attrRange];
            }];
        }
    }];
    // create an attributed (with no attributes) string, to terminate any previous attribution.
    [self.commentTextWithMarkup replaceCharactersInRange:range withAttributedString:attributedString];
    fullRange = NSMakeRange(0, self.commentTextWithMarkup.length);
    [markupString addAttributes:self.commentTextPrefixMarkup range:fullRange];
    [markupString enumerateAttribute:ATTRIBUTE_USER_ID inRange:fullRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange attrRange, BOOL *stop) {
        if (value) {
            [markupString addAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:97.0f/255.0f green:166.0f/255.0f blue:244.0f/255.0f alpha:1.0] } range:attrRange];
        }
    }];
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView  {
    [self updateNavBarWithScrollView:scrollView];
    [self updateSegmentedControlWithScrollView:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.tableBeingDragged = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.tableBeingDragged = NO;
}

#pragma mark - SPCReportAlertViewDelegate

- (void)tappedOption:(NSString *)option onSPCReportAlertView:(SPCReportAlertView *)reportView {
    if ([reportView isEqual:self.reportAlertView]) {
        self.reportType = [self.reportMemoryOrCommentsOptions indexOfObject:option] + 1;
        
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

#pragma mark - Actions

- (void)updateLocallyWithSockPuppet:(Person *)puppet {
    NSString *instaCommentStr = self.commentInput.text;
    NSString *markupString = self.markupString;
    
    NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate])*1000;
    NSNumber *nowNum = @(nowIntervalMS);
    Asset *picAss;
    NSString *picIdStr;
    NSString *userNameStr;
    NSString *userTokenStr;
    
    if (!puppet) {
        picAss = self.profile.profileDetail.imageAsset;
        
        userNameStr = self.profile.profileDetail.firstname;
        userTokenStr = [AuthenticationManager sharedInstance].currentUser.userToken;
        
        if (!userNameStr) {
            userNameStr = self.profile.profileDetail.displayName;
        }
        if (!userNameStr) {
            // TODO: @JR - Please review with b00aa1c9fe52
            //           - It should be an illegal operation to assign 0 (int) to a string variable
            userTokenStr = nil;
        }
    } else {
        picAss = puppet.imageAsset;
        userNameStr = puppet.firstname;
        userTokenStr = puppet.userToken;
    }
    picIdStr = [APIUtils imageUrlStringForUrlString:picAss.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium];
    
    //NSLog(@"user name string? %@",userNameStr);
    //NSLog(@"token %@",userTokenStr);
    // TODO: @JR - NSDictionary will crash if you try to add a nil value
    //           - Is it OK to ommit instaCommentStr, markupString & userTokenStr that could potentially be 'nil'?
    
    NSMutableDictionary *mutableAuthorDictionary = [NSMutableDictionary dictionary];
    if (userNameStr) {
        mutableAuthorDictionary[@"firstname"] = userNameStr;
    }
    if (userTokenStr) {
        mutableAuthorDictionary[@"userToken"] = userTokenStr;
    }
    
    NSMutableDictionary *mutablePostedCommentDictionary = [NSMutableDictionary dictionary];
    if (nowNum) {
        mutablePostedCommentDictionary[@"dateCreated"] = nowNum;
    }
    if (instaCommentStr) {
        mutablePostedCommentDictionary[@"text"] = instaCommentStr;
    }
    if (markupString) {
        mutablePostedCommentDictionary[@"markupText"] = markupString;
    }
    if (picIdStr) {
        mutablePostedCommentDictionary[@"localPicUrl"] = picIdStr;
    }
    
    if (mutableAuthorDictionary) {
        mutablePostedCommentDictionary[@"author"] = [NSDictionary dictionaryWithDictionary:mutableAuthorDictionary];
    }
    
    Comment *newComment = [[Comment alloc] initWithAttributes:[NSDictionary dictionaryWithDictionary:mutablePostedCommentDictionary]];
    
    newComment.taggedUserNames = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_NAME];
    newComment.taggedUserTokens = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_TOKEN];
    newComment.taggedUserIds = [self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_ID];
    
    [self.comments addObject:newComment];
    [self reloadData];
}

- (void)postComment:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    [SPCAdminSockPuppetChooserViewController allowSockPuppetSelectionIfAdminForAction:SPCAdminSockPuppetActionComment object:nil withNavigationController:self.navigationController transitioningDelegate:self delegate:self defaultBlock:^{
        [self postCommentWithButton:btn sockPuppet:nil];
    }];
}

- (void)postCommentWithButton:(UIButton *)btn sockPuppet:(Person *)puppet {
    
    btn.alpha = 0.5f;
    btn.enabled = NO;
    
    if (self.commentInput.text.length > 0) {
        
        NSString *foundHashTags = [self getHashTagsForComment];
        
        self.friendPicker.hidden = YES;
        [self updateNavBarWithScrollView:self.tableView];
        
        //update locally immediately
        [self updateLocallyWithSockPuppet:puppet];
        
        NSString *userIDs = [[self uniqueAttributeValuesForAttribute:ATTRIBUTE_USER_ID] componentsJoinedByString:@","];
        // process the text to post.  First escape all instances of "@" to "@\" (yes, we escape AFTER the
        // character.  It makes parsing easier on the server).  Then replace all attributed names with
        // @{userId}.
        
        NSString *markup = self.markupString;
        
        //NSLog(@"posting comment with real text %@, markup text %@", self.commentInput.text, markup);
        
        __weak typeof(self) weakSelf = self;
        [MeetManager postCommentWithMemoryID:memoryId
                                        text:markup
                               taggedUserIDs:userIDs
                                    hashtags:foundHashTags
                                asSockPuppet:puppet
                              resultCallback:^(NSInteger commentId) {
                                  __strong typeof(weakSelf) strongSelf = weakSelf;
                                  Comment *tempComment = strongSelf.comments[self.comments.count - 1];
                                  tempComment.recordID = commentId;
                                  [strongSelf reloadData];
                              }
                               faultCallback:^(NSError *fault) {
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   
                                   //correct local update if call fails
                                   if (strongSelf.comments.count > 0){
                                       [strongSelf.comments removeObjectAtIndex:self.comments.count-1];
                                       [strongSelf reloadData];
                                   }
                                   
                                   // Process the error/message
                                   NSString *errorMessage = @"There was an error posting your comment. Please try again.";
                                   if (CANNOT_POST_COMMENT_YOU_ARE_BLOCKED == [fault code] || CANNOT_POST_COMMENT_THEY_ARE_BLOCKED == [fault code] || CANNOT_POST_COMMENT_YOU_ARE_MUTED == [fault code]) {
                                       errorMessage = fault.userInfo[@"description"];
                                   }
                                   
                                   [[[UIAlertView alloc] initWithTitle:nil message:errorMessage delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                               }
         ];
        
        
        self.commentInput.text = nil;
        self.commentTextWithMarkup = [[NSMutableAttributedString alloc] initWithString:@"" attributes:self.commentTextPrefixMarkup];
        self.placeholderLabel.alpha = 1;
        
        //[self.commentInput resignFirstResponder];
        
        //reset view
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:.5];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(scrollToLastComment)];
        self.placeholderLabel.alpha = 1;
        [UIView commitAnimations];
    }
    
}

-(NSArray *)uniqueAttributeValuesForAttribute:(NSString *)attribute {
    __block NSMutableArray *values = [[NSMutableArray alloc] init];
    [self.commentTextWithMarkup enumerateAttribute:attribute inRange:NSMakeRange(0, self.commentTextWithMarkup.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (range.length > 0 && value) {
            if (![values containsObject:value]) {
                [values addObject:value];
            }
        }
    }];
    return [NSArray arrayWithArray:values];
}

-(NSString *)markupString {
    // Prepare a plaintext markup string from our attributed string.
    // First replace all instances of '@' in the string with the escaped version
    // '@\' (yes, we escape after the character.  This makes parsing easier on the
    // server).
    // Second, for any attributed string with a user id, replace the entire range
    // with @{userId}.
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.commentTextWithMarkup];
    NSRange rangeOfAt = [[attributedString string] rangeOfString:@"@" options:0 range:NSMakeRange(0, attributedString.length)];
    while (rangeOfAt.location != NSNotFound) {
        // replace...
        [attributedString replaceCharactersInRange:rangeOfAt withString:@"@\\"];
        rangeOfAt = [[attributedString string] rangeOfString:@"@" options:0 range:NSMakeRange(rangeOfAt.location + 1, attributedString.length - rangeOfAt.location - 1)];
    }
    
    [attributedString enumerateAttribute:ATTRIBUTE_USER_ID inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [attributedString replaceCharactersInRange:range withString:[NSString stringWithFormat:@"@{%@}", value]];
        }
    }];
    
    return [attributedString string];
}

-(void)scrollToLastComment {
    NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:([self.comments count] - 1) inSection:0];
    [self.tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
}

- (void)updateUserStar:(id)sender {
    UIButton *button = (UIButton *)sender;
    button.userInteractionEnabled = NO;
    
    [self updateUserStarForMemory:self.mem button:button];
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
    
    self.memCell.viewingInComments = YES;
    [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
    [self.memCell updateForCommentDisplay];
    
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
                          
                          self.memCell.viewingInComments = YES;
                          [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
                          [self.memCell updateForCommentDisplay];
                          
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
                       
                       self.memCell.viewingInComments = YES;
                       [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
                       [self.memCell updateForCommentDisplay];
                       
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
    
    self.memCell.viewingInComments = YES;
    [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
    [self.memCell updateForCommentDisplay];
    
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
                                       
                                       self.memCell.viewingInComments = YES;
                                       [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
                                       [self.memCell updateForCommentDisplay];
                                   } faultCallback:^(NSError *fault) {
                                       if (!sockpuppet) {
                                           memory.userHasStarred = YES;
                                       }
                                       memory.starsCount = memory.starsCount + 1;
                                       memory.userToStarMostRecently = userAsStarred;
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                       
                                       self.memCell.viewingInComments = YES;
                                       [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
                                       [self.memCell updateForCommentDisplay];
                                       
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
                               
                               self.memCell.viewingInComments = YES;
                               [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
                               [self.memCell updateForCommentDisplay];
                               
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
                            
                            self.memCell.viewingInComments = YES;
                            [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
                            [self.memCell updateForCommentDisplay];
                            
                            button.userInteractionEnabled = YES;
                            [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                        }];
}

-(void)showUsersThatStarred:(id)sender {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    SPCStarsViewController *starsViewController = [[SPCStarsViewController alloc] init];
    starsViewController.memory = self.mem;
    [self.navigationController pushViewController:starsViewController animated:YES];
}

- (void)followOrUnfollowPersonWithCompletion:(id)sender {
    
    Person *person = self.mem.author;
    
    if (person.followingStatus == FollowingStatusFollowing) {

        __weak typeof(self) weakSelf = self;
        [MeetManager unfollowWithUserToken:person.userToken
                         completionHandler:^{
                             [Flurry logEvent:@"UNFOLLOW_IN_COMMENTS"];
                             NSLog(@"unfollowed!");
                             __strong typeof(weakSelf) strongSelf = weakSelf;
                             person.followingStatus = FollowingStatusNotFollowing;
                             [strongSelf.memCell.followButton setImage:[UIImage imageNamed:@"friendship-follow"] forState:UIControlStateNormal];
                         } errorHandler:^(NSError *error) {
                             NSLog(@"error %@",error);
                         }];
    } else {
        
        __weak typeof(self) weakSelf = self;
        [MeetManager sendFollowRequestWithUserToken:person.userToken
                                  completionHandler:^(BOOL followingNow) {
                                      
                                      [Flurry logEvent:@"FOLLOW_REQ_IN_COMMENTS"];
                                      
                                      __strong typeof(weakSelf) strongSelf = weakSelf;
                                      person.followingStatus = followingNow ? FollowingStatusFollowing : FollowingStatusRequested;
                                      
                                      if (person.followingStatus == FollowingStatusFollowing) {
                                           NSLog(@"following!");
                                          [strongSelf.memCell.followButton setImage:[UIImage imageNamed:@"friendship-following"] forState:UIControlStateNormal];
                                      }
                                      
                                      if (person.followingStatus == FollowingStatusRequested) {
                                          NSLog(@"requested!");
                                          [strongSelf.memCell.followButton setImage:[UIImage imageNamed:@"following-requested"] forState:UIControlStateNormal];
                                      }
                                  } errorHandler:^(NSError *error) {
                                      NSLog(@"error %@",error);
                                  }];
    }
}

- (void)showBlockReportedPromptForComment:(Comment *)comment {
    NSString *msgText = [NSString stringWithFormat:@"You have sent a report about %@'s comment.  Do you also want to block them?", comment.userName];
    [self showBlockPromptForPerson:comment.author messageText:msgText];
}

- (void)showBlockPromptForPerson:(Person *)person {
    NSString *msgText = [NSString stringWithFormat:@"You are about to block %@. This means that you will both be permanently invisible to each other.", person.displayName];
    [self showBlockPromptForPerson:person messageText:msgText];
}

- (void)showBlockPromptForPerson:(Person *)person messageText:(NSString *)messageText {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Block %@?", person.displayName] message:messageText delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Block", nil];
    alertView.tag = alertViewTagBlock;
    self.reportObject = person;
    [alertView show];
}

-(void)showTappedProfileFromHeader:(NSNotification *)notification {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    NSString *userToken = (NSString *)[notification object];
    
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

-(void)applyPersonUpdateWithNotification:(NSNotification *)note {
    PersonUpdate *personUpdate = [note object];
    self.profile = [ContactAndProfileManager sharedInstance].profile;
    BOOL changed = [personUpdate applyToMemory:self.mem];
    changed = [personUpdate applyToArray:self.comments] || changed;
    if (changed) {
        if (_tableView) {
            [_tableView reloadData];
        }
        if (_memCell) {
            [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
            [self.memCell updateForCommentDisplay];
        }
    }
}

- (void)showProfile:(id)sender {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    int tag = (int)[sender tag];
    
    Comment *tempComment = (Comment *)self.comments[tag];
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:tempComment.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

-(void)showMemAuthorProfile:(id)sender {
    if (self.mem.realAuthor && self.mem.realAuthor.userToken) {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:self.mem.realAuthor.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    } else if (self.mem.author.recordID == -2) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    }
    else {
        //stop video playback if needed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
        
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:self.mem.author.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
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
    [self.memoryCoordinator deleteMemory:self.mem completionHandler:^(BOOL success) {
        if (success) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryDeleted object:self.mem];
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
    self.reportObject = memory;
    self.reportIndex = -1;
    
    self.reportAlertView = [[SPCReportAlertView alloc] initWithTitle:@"Choose type of report" stringOptions:self.reportMemoryOrCommentsOptions dismissTitles:@[@"CANCEL"] andDelegate:self];
    
    [self.reportAlertView showAnimated:YES];
}

- (void)showReportPromptForComment:(Comment *)comment atIndex:(NSInteger)index {
    self.reportObject = comment;
    self.reportIndex = index;
    
    self.reportAlertView = [[SPCReportAlertView alloc] initWithTitle:@"Choose type of report" stringOptions:self.reportMemoryOrCommentsOptions dismissTitles:@[@"CANCEL"] andDelegate:self];
    
    [self.reportAlertView showAnimated:YES];
}

- (void)selectedSegment:(id)sender {
    
    if (self.hmSegmentedControl.selectedSegmentIndex == 0) {
        selectedSegment = 0;
        [self filterByRecency];
    }
    else if (self.hmSegmentedControl.selectedSegmentIndex == 1) {
        selectedSegment = 1;
        [self filterByStars];
    }
}

- (void)enterVenue:(id)sender {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = self.mem.venue;
    [venueDetailViewController fetchMemories];
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showMemoryActions:(id)sender {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    // NSLog(@"show memory actions");
    // Selected memory
    Memory *memory = self.mem;
    
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
                                                                   [self.navigationController presentViewController:mapVC animated:YES completion:^{}];
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

#pragma mark - Filters

- (void)filterByRecency {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.comments];
    NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:YES];
    [tempArray sortUsingDescriptors:@[dateSorter]];
    NSArray *sortedArray = [NSArray arrayWithArray:tempArray];
    self.comments = [NSMutableArray arrayWithArray:sortedArray];
    
    //reset any comments that have been slid
    for (int i = 0; i < self.comments.count; i++) {
        SWTableViewCell *cell = (SWTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        if (![cell isUtilityButtonsHidden]) {
            [cell hideUtilityButtonsAnimated:YES];
        }
    }
    
    [self reloadData];
}

- (void)filterByStars {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.comments];
    NSSortDescriptor *starSorter = [[NSSortDescriptor alloc] initWithKey:@"starCount" ascending:NO];
    [tempArray sortUsingDescriptors:@[starSorter]];
    NSArray *sortedArray = [NSArray arrayWithArray:tempArray];
    self.comments = [NSMutableArray arrayWithArray:sortedArray];
    
    //reset any comments that have been slid
    for (int i = 0; i < self.comments.count; i++) {
        SWTableViewCell *cell = (SWTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        if (![cell isUtilityButtonsHidden]) {
            [cell hideUtilityButtonsAnimated:YES];
        }
    }
    
    [self reloadData];
}


- (void)buttonHighlight:(id)sender{
    UIButton *btn = (UIButton *)sender;
    btn.alpha = .5;
}

- (void)buttonCancel:(id)sender{
    UIButton *btn = (UIButton *)sender;
    btn.alpha = 1.0f;
}

#pragma mark - Accessors

- (UITableView *)tableView
{
    if (!_tableView) {
        SPCTableView *tableView = [[SPCTableView alloc] initWithFrame:CGRectMake(0, self.tableStart, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-self.tableStart) style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.backgroundColor = [UIColor colorWithRGBHex:0xf3f3f3];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.separatorColor = [UIColor clearColor];
        tableView.showsVerticalScrollIndicator = NO;
        tableView.clipsToBounds = NO;
        tableView.clipsHitsToBounds = NO;
        if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [tableView setSeparatorInset:UIEdgeInsetsZero];
        }
        _tableView = tableView;
    }
    return _tableView;
}

- (UIView *)tableViewContainer {
    if (!_tableViewContainer) {
        SPCView *tableViewContainer = [[SPCView alloc] initWithFrame:CGRectZero];
        tableViewContainer.clipsToBounds = NO;
        tableViewContainer.clipsHitsToBounds = NO;
        _tableViewContainer = tableViewContainer;
    }
    return _tableViewContainer;
}

- (NSArray *)reportMemoryOrCommentsOptions {
    if (nil == _reportMemoryOrCommentsOptions) {
        _reportMemoryOrCommentsOptions = @[@"ABUSE", @"SPAM", @"PERTAINS TO ME"];
    }
    
    return _reportMemoryOrCommentsOptions;
}

#pragma mark - participant details

-(void)doneShowingDetail {
    UIView *view;
    NSArray *subs = [self.view subviews];
    for (view in subs) {
        if (view.tag == -253){
            [view removeFromSuperview];
        }
    }
}

#pragma mark - Private

-(void)fetchMemoryWithId:(NSInteger)memId {
    
    NSLog(@"fetchMemoryWithId %li",memId);
    
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
    self.hmSegmentedControl.hidden = YES;
    
    
    __weak typeof(self)weakSelf = self;
    [MeetManager fetchMemoryWithMemoryId:memId
                          resultCallback:^(NSDictionary *result){
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              
                              if (!strongSelf) {
                                  return;
                              }
                              
                              NSLog(@"result %@",result);
                              if (result[@"dateCreated"] != nil)  {
                                  strongSelf.mem = [Memory memoryWithAttributes:result];
                                  
                                  
                                  strongSelf.memoryType = strongSelf.mem.type;
                                  
                                  memoryId = (int)memId;
                                  
                                  if (strongSelf.memoryType == MemoryTypeVideo) {
                                      VideoMemory *memory = (VideoMemory *)strongSelf.mem;
                                      strongSelf.includedVidURLs = memory.videoURLs;
                                  }
                                  if (strongSelf.memoryType == MemoryTypeAudio) {
                                      AudioMemory *memory = (AudioMemory *)strongSelf.mem;
                                      strongSelf.includedAudioURLs = memory.audioURLs;
                                  }
                                  [strongSelf.spinner stopAnimating];
                                  strongSelf.spinner.alpha = 0;
                                  
                                  [strongSelf setupTableView];
                                  //strongSelf.composeBarView.alpha = 1;
                                  strongSelf.composeBarView.backgroundColor = [UIColor whiteColor];
                                  strongSelf.commentInput.alpha = 1;
                                  strongSelf.sendCommentButton.alpha = 1;
                                  strongSelf.placeholderLabel.alpha = 1;
                                  [strongSelf loadComments];
                                  
                              }
                              else  {
                                  [strongSelf spc_hideNotificationBanner];
                                  [strongSelf spc_showNotificationBannerInParentView:strongSelf.tableView title:NSLocalizedString(@"Memory is unavailable", nil) customText:NSLocalizedString(@"It may have been deleted or made private.",nil)];
                              }
                              
                              
                          }
                           faultCallback:^(NSError *error){
                               __strong typeof(weakSelf)strongSelf = weakSelf;
                               
                               [strongSelf spc_hideNotificationBanner];
                               [strongSelf spc_showNotificationBannerInParentView:strongSelf.tableView title:NSLocalizedString(@"Memory is unavailable", nil) customText:NSLocalizedString(@"It may have been deleted or made private.",nil)];
                           }];
    
}

-(void)videoFailedToLoad {
    if (self.isVisible) {
        [self  spc_hideNotificationBanner];
        [self spc_showNotificationBannerInParentView:self.view title:NSLocalizedString(@"Video failed to load", nil) customText:NSLocalizedString(@"Please check your network and try again.",nil)];
    }
}

-(NSString *)getHashTagsForComment {
    
    NSMutableString *foundHashTags = [[NSMutableString alloc] init];
    
    NSString *workingString = [NSString stringWithFormat:@"%@",self.commentInput.text];
    //NSLog(@"working string %@",workingString);
    
    NSRange range = [workingString rangeOfString:@"#"];
    NSMutableArray *updatedHashArray = [[NSMutableArray alloc] init];
    
    while(range.location != NSNotFound) {
        
        //found a #, get the hashtag
        NSRange currRange = [workingString rangeOfString:@"#"];
        
        if  (currRange.location != NSNotFound) {
            NSString *hashSearchString = [workingString substringFromIndex:currRange.location];
            //NSLog(@"hash search string %@",hashSearchString);
            
            NSRange hashEndRange = [hashSearchString rangeOfString:@" "];
            NSString *hashTag;
            
            //this is the last word in our text
            if (hashEndRange.location == NSNotFound) {
                //NSLog(@"looks like the last word is a hashtag!");
                hashTag = hashSearchString;
            }
            //just get the chunk between the '#' and the ' '
            else {
                hashTag = [hashSearchString substringWithRange:NSMakeRange(0, hashEndRange.location)];
            }
            
            //NSLog(@"found hashTag:%@", hashTag);
            if (hashTag.length > 1){
                [updatedHashArray addObject:hashTag];
            }
            
            NSInteger lastHashEndLocation = currRange.location + hashTag.length;
            
            //continue on our our search
            if (workingString.length > lastHashEndLocation && workingString.length > 0) {
                workingString = [workingString substringFromIndex:lastHashEndLocation];
                //NSLog(@"updated working string %@",workingString);
                if (workingString.length == 0) {
                    break;
                }
            }
            else  {
                //NSLog(@"string all done!");
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
    
    //STRIP OUT THE #s
    while (updatedHashArray.count > 0) {
        
        //get the next hash tag
        NSString *hashedTag = [updatedHashArray objectAtIndex:0];
        
        // sanity check
        if (hashedTag.length > 1) {
            
            //strip out the #s
            NSString *cleanTag = [hashedTag substringFromIndex:1];
            //NSLog(@"cleanTag %@",cleanTag);
            
            //append to our full string with a trailing space
            if (updatedHashArray.count > 1) {
                [foundHashTags appendString:[NSString stringWithFormat:@"%@ ",cleanTag]];
                //NSLog(@"updated full string %@",fullHashTagString);
            }
            //add just the tag to our full string (it's the last one)
            else {
                [foundHashTags appendString:[NSString stringWithFormat:@"%@",cleanTag]];
                //NSLog(@"updated full string %@",fullHashTagString);
            }
        }
        
        //update our data
        if (updatedHashArray.count > 0) {
            [updatedHashArray removeObjectAtIndex:0];
        }
    }
    
    NSString *finalString = @"";
    
    if (foundHashTags.length > 0) {
        finalString = [NSString stringWithFormat:@"%@",foundHashTags];
    }
    
    return finalString;
}

- (void)loadComments
{
    __weak typeof(self)weakSelf = self;
    [MeetManager fetchCommentsWithMemoryID:memoryId
                            resultCallback:^(NSArray *comments) {
                                __strong typeof(weakSelf)strongSelf = weakSelf;
                                [strongSelf.comments removeAllObjects];
                                [strongSelf.comments addObjectsFromArray:comments];
                                strongSelf.commentsFetchComplete = YES;
                                [strongSelf reloadData];
                                
                                if (strongSelf.spinner) {
                                    strongSelf.hmSegmentedControl.hidden = NO;
                                    [strongSelf.spinner stopAnimating];
                                    [strongSelf.spinner removeFromSuperview];
                                }
                            }
                             faultCallback:^(NSError *fault) {
                                 //NSLog(@"fetch comment faultCallback");
                             }
     ];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)updateMemoryViews {
    [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
}

- (void)updateOffset {
    float newOffsetY = 64+self.mem.heightForMemoryText;
    [self.tableView setContentOffset:CGPointMake(0, newOffsetY) animated:YES];
}

- (void)updateForManualNav {
    self.navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), self.tableStart)];
    self.navBar.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95f];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 20.0, 60.0, 44.0)];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton.titleLabel setFont:[UIFont spc_regularSystemFontOfSize:14]];
    backButton.backgroundColor = [UIColor clearColor];
    [backButton setTitleColor:[UIColor colorWithRGBHex:0x6ab1fb] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchUpInside];
    _backButton = backButton;
    
    CGFloat width = 60;
    NSString *text = @"ENTER";
    //4.7" or 5"
    if ([UIScreen mainScreen].bounds.size.width >= 375) {
        width = CGRectGetWidth(self.view.frame) * (200.0 / 750.0);
        text = @"ENTER PLACE";
    }
    UIButton *enterButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-width-10, 27, width, 30)];
    enterButton.backgroundColor = [UIColor colorWithRGBHex:0x4cb0fb];
    [enterButton setTitle:text forState:UIControlStateNormal];
    [enterButton.titleLabel setFont:[UIFont spc_regularSystemFontOfSize:12]];
    [enterButton addTarget:self action:@selector(enterVenue:) forControlEvents:UIControlEventTouchUpInside];
    enterButton.layer.cornerRadius = 1.5;
    
    // Lower and move right the "ENTER..." text and add a location pin
    [enterButton.titleLabel sizeToFit];
    UIImage *imagePin = [UIImage imageNamed:@"pin-white-x-small"];
    [enterButton setTitleEdgeInsets:UIEdgeInsetsMake(2.0f, imagePin.size.width + 3.0f, 0.0f, 0.0f)];
    UIImageView *imageViewPin = [[UIImageView alloc] initWithImage:imagePin];
    imageViewPin.center = CGPointMake(CGRectGetWidth(enterButton.frame)/2.0f - CGRectGetWidth(enterButton.titleLabel.frame)/2.0f - imagePin.size.width/2.0f + 1.0f, CGRectGetHeight(enterButton.frame)/2.0f);
    [enterButton addSubview:imageViewPin];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = NSLocalizedString(@"Comments", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont spc_boldSystemFontOfSize:16];
    titleLabel.frame = CGRectMake(CGRectGetMidX(self.navBar.frame) - 75.0, 42 - titleLabel.font.lineHeight/2, 150.0, titleLabel.font.lineHeight);
    titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
    
    [self.navBar addSubview:self.backButton];
    [self.navBar addSubview:titleLabel];
    [self.navBar addSubview:self.optionsBtn];
    
    if (self.mem.venue.addressKey && !self.viewingFromVenueDetail) {
       // [self.navBar addSubview:enterButton];
    }
    
    [self.view addSubview:self.navBar];
    
    self.composeBarView.frame =  CGRectMake(0.0f, CGRectGetMaxY(self.tableView.frame), self.view.frame.size.width, 45);
    [self reloadData];
    [self.tableView setContentOffset:CGPointMake(0, -1) animated:YES];
}

- (void)updateRecentComments {
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.comments];
    NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
    [tempArray sortUsingDescriptors:@[dateSorter]];
    
    BOOL userHasCommented = NO;
    NSMutableArray *updatedRecentComments = [[NSMutableArray alloc] init];
    for (int i = 0; i< tempArray.count; i++) {
        Comment *tempComment = tempArray[i];
        if (i < 3) {
            [updatedRecentComments addObject:tempComment];
        }
        if ([tempComment.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
            userHasCommented = YES;
        }
    }
    
    NSSortDescriptor *dateSorter2 = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:YES];
    [updatedRecentComments sortUsingDescriptors:@[dateSorter2]];
    
    self.mem.recentComments = updatedRecentComments;
    self.mem.userHasCommented = userHasCommented;
    self.mem.commentsCount = self.comments.count;
    [self.mem updateCommentPreviewHeight];
}


- (void)animateIn {
    if (self.gridCellAsset || self.gridCellImage) {
        // we have an image set...
        [self.memCell layoutSubviews];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 animations:^{
            CGRect frame = self.memCell.mediaContentScreenRect;
            NSLog(@"animating frame to %@ with nav bar max %f, table container %@, table %@, memcell %@", NSStringFromCGRect(frame),
                  CGRectGetMaxY(self.navBar.frame), NSStringFromCGRect(self.tableViewContainer.frame), NSStringFromCGRect(self.tableView.frame), NSStringFromCGRect(self.memCell.frame));
            self.expandingImageView.frame = frame;
            self.expandingImageViewClipped.frame = frame;
        }];
        [UIView animateWithDuration:(VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 - VENUE_GRID_TRANSITION_ALPHA_ANIMATION_DELAY_MCVC) delay:VENUE_GRID_TRANSITION_ALPHA_ANIMATION_DELAY_MCVC options:0 animations:^{
            self.expandingImageView.alpha = 1;
        } completion:nil];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 delay:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 options:0 animations:^{
            self.tableViewContainer.alpha = 1.0f;
            self.navBar.alpha = 1.0f;
            self.composeBarView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            self.tableView.userInteractionEnabled = YES;
            self.navBar.userInteractionEnabled = YES;
            self.composeBarView.userInteractionEnabled = YES;
            self.expandingImageView.image = nil;
            self.expandingImageViewClipped.image = nil;
        }];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    } else {
        // fade in the rest
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC animations:^{
            self.tableViewContainer.alpha = 1.0f;
            self.navBar.alpha = 1.0f;
            self.composeBarView.alpha = 1.0f;
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {
            self.tableView.userInteractionEnabled = YES;
            self.navBar.userInteractionEnabled = YES;
            self.composeBarView.userInteractionEnabled = YES;
        }];
    }
}



- (void)pop {
    [self.memCell clearContent];
    
    [self updateRecentComments];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:self.mem];
    
    BOOL keyboardIsVisible = [self.commentInput isFirstResponder];
    if (keyboardIsVisible) {
        [self.commentInput resignFirstResponder];
        NSLog(@"remove keyboard on delay");
        [self performSelector:@selector(removeKeyControl) withObject:nil afterDelay:.2];
    }
    else {
        [self removeKeyControl];
    }
    
    self.tabBarController.tabBar.alpha = 1.0;
    
    if (!self.viewingFromGrid) {
        [self.navigationController popViewControllerAnimated:YES];
        if (self.revealNavigationBarOnPop) {
            self.navigationController.navigationBarHidden = NO;
        }
    } else if (self.animateTransition) {
        if (keyboardIsVisible) {
            NSLog(@"keyboardIsVisible");
            self.navBar.userInteractionEnabled = NO;
            [self performSelector:@selector(animateOut) withObject:nil afterDelay:0.1f];
        } else {
            NSLog(@"keyboardIs NOT visible");
            [self animateOut];
        }
    } else {
        if (self.revealNavigationBarOnPop) {
            self.navigationController.navigationBarHidden = NO;
            [self performSelector:@selector(dismissOnDelay) withObject:nil afterDelay:.3];
        }
    }
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)dismissOnDelay {
    NSLog(@"pop on delay");
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)removeKeyControl {
    if (self.keyboardControlAdded) {
        self.keyboardControlAdded = NO;
        [self.view removeKeyboardControl];
    }
}

-(void)cleanUp {
    [self removeKeyControl];
    
    SWCommentsCell *cell;
    for (int i = 0; i < self.comments.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        cell = (SWCommentsCell *)[_tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[SWCommentsCell class]]) {
            NSLog(@"clean cell at index %i!",i);
            cell.delegate = nil;
            cell.taggedUserTappedBlock = nil;
            cell.hashTagTappedBlock = nil;
            cell.containingTableView = nil;
            cell.imageButton = nil;
            cell.rightUtilityButtons = nil;
            cell.leftUtilityButtons = nil;
            cell = nil;
        }
    }
    
    _hmSegmentedControl = nil;
    _memoryCoordinator = nil;
    _tableView.delegate = nil;
    _tableView = nil;
    _friendPicker.delegate = nil;
    _commentInput.delegate = nil;
    _commentInput = nil;
    _memCell.hashTagTappedBlock = nil;
    _memCell.locationTappedBlock = nil;
    _memCell.taggedUserTappedBlock = nil;
    _memCell.actionButton = nil;
    [_memCell clearContent];
}

-(void)animateOut {
    if (self.gridCellImage || self.gridCellAsset) {
        self.expandingImageViewClipped.image = self.expandingImageView.image = self.memCell.mediaContentImage;
        // we have an image set...
        self.tableView.userInteractionEnabled = NO;
        self.navBar.userInteractionEnabled = NO;
        self.composeBarView.userInteractionEnabled = NO;
        CGRect frame = self.memCell.mediaContentScreenRect;
        self.expandingImageView.frame = frame;
        self.expandingImageViewClipped.frame = frame;
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 animations:^{
            self.tableViewContainer.alpha = 0;
            self.navBar.alpha = 0;
            self.composeBarView.alpha = 0;
        }];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 delay:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 options:0 animations:^{
            self.expandingImageView.frame = self.gridCellFrame;
            self.expandingImageViewClipped.frame = self.gridCellFrame;
        } completion:^(BOOL finished) {
            [self.navigationController dismissViewControllerAnimated:NO completion:^{}];
            if (self.revealNavigationBarOnPop) {
                self.navigationController.navigationBarHidden = NO;
            }
        }];
        [UIView animateWithDuration:(VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 - VENUE_GRID_TRANSITION_ALPHA_ANIMATION_DELAY_MCVC) delay:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC/2 options:0 animations:^{
            self.expandingImageView.alpha = 0;
        } completion:nil];
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    } else if (!self.snapTransitionDismiss) {
        // fade out the rest
        self.tableView.userInteractionEnabled = NO;
        self.navBar.userInteractionEnabled = NO;
        self.composeBarView.userInteractionEnabled = NO;
        self.expandingImageView.hidden = YES;
        [UIView animateWithDuration:VENUE_GRID_TRANSITION_ANIMATION_LENGTH_MCVC animations:^{
            self.tableViewContainer.alpha = 0;
            self.navBar.alpha = 0;
            self.composeBarView.alpha = 0;
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {
            [self.navigationController dismissViewControllerAnimated:NO completion:^{}];
            if (self.revealNavigationBarOnPop) {
                self.navigationController.navigationBarHidden = NO;
            }
        }];
    } else {
        // IMMEDIATE exit.  The most likely entrance to this is from the MAM
        // animation, where our background view is an obsolete image of the map.
        // Fading to it is a worse experience that just snapping back to whatever screen
        // we end up on.
        [self.navigationController dismissViewControllerAnimated:NO completion:^{}];
        if (self.revealNavigationBarOnPop) {
            self.navigationController.navigationBarHidden = NO;
        }
    }
}


- (void)updateNavBarWithScrollView:(UIScrollView *)scrollView {
    if (!self.friendPicker.hidden) {
        self.navBar.backgroundColor = [self.navBar.backgroundColor colorWithAlphaComponent:1.0];
        return;
    }
    
    CGFloat offsetMinY = self.memCell.frame.origin.y - 20;
    CGFloat offsetMaxY = self.memCell.frame.origin.y + 20;
    
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY < offsetMinY) {
        self.navBar.backgroundColor = [self.navBar.backgroundColor colorWithAlphaComponent:1.0];
    } else if (offsetMinY <= offsetY && offsetY <= offsetMaxY) {
        CGFloat diff = offsetY - offsetMinY;
        CGFloat ratio = diff / (offsetMaxY - offsetMinY);
        
        self.navBar.backgroundColor = [self.navBar.backgroundColor colorWithAlphaComponent:1.0 - 0.06*ratio];
    } else {
        self.navBar.backgroundColor = [self.navBar.backgroundColor colorWithAlphaComponent:0.94];
    }
}

- (void)updateSegmentedControlWithScrollView:(UIScrollView *)scrollView {
    
    CGFloat offsetMinY = self.tableView.tableHeaderView.frame.size.height;
    CGFloat offsetMaxY = self.tableView.tableHeaderView.frame.size.height + 40;
    
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if (offsetY < offsetMinY) {
        self.hmSegmentedControl.backgroundColor = [UIColor colorWithWhite:254.0f/255.0f alpha:1.0];
        self.hmSegmentedControl.selectionIndicatorBoxOpacity = 0.0f;
        
        [self.hmSegmentedControl setNeedsDisplay];
        
    }
    else if (offsetMinY <= offsetY && offsetY <= offsetMaxY) {
        CGFloat diff = offsetY - offsetMinY;
        CGFloat ratio = diff / (offsetMaxY - offsetMinY);
        
        UIColor *srcColor = [UIColor colorWithWhite:254.0f/255.0f alpha:1.0];
        UIColor *desColor = [UIColor colorWithWhite:254.0f/255.0f alpha:0.94];
        
        self.hmSegmentedControl.backgroundColor = [UIColor colorForFadeBetweenFirstColor:srcColor secondColor:desColor atRatio:ratio];
        self.hmSegmentedControl.selectionIndicatorBoxOpacity = 0.0f;
        [self.hmSegmentedControl setNeedsDisplay];
    }
    else {
        self.hmSegmentedControl.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.94];
        self.hmSegmentedControl.selectionIndicatorColor = self.hmSegmentedControl.backgroundColor;
        self.hmSegmentedControl.selectionIndicatorBoxOpacity = 0.0f;
        [self.hmSegmentedControl setNeedsDisplay];
    }
}

- (void)findExactMatch {
    if (!self.friendPicker.hidden) {
        NSRange searchRangeStart = [self.commentInput.text rangeOfString:@"@" options:NSBackwardsSearch];
        long searchStart = searchRangeStart.location + 1;
        long searchEnd = self.commentInput.text.length - searchStart;
        searchEnd = searchEnd - 1;
        
        NSRange matchRange = NSMakeRange(searchStart, searchEnd);
        NSString *searchString = [self.commentInput.text substringWithRange:matchRange];
        [self.friendPicker matchFilterString:searchString];
    }
}

#pragma mark - Stars

-(void)updateComment:(Comment *)comment {
    
    int recordId = (int)comment.recordID;
    
    for (int i = 0; i <self.comments.count; i ++) {
        
        Comment *tempComment = (Comment *)self.comments[i];
        
        if (tempComment.recordID == recordId) {
            self.comments[i] = comment;
            break;
        }
    }
}


-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
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

#pragma mark - SWTableViewCell config

- (NSArray *)rightReportButton
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:226.0f/255.0f green:226.0f/255.0f blue:226.0f/255.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"newFlag"]
                                                title:@"REPORT"
                                           titleColor:[UIColor whiteColor]];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor darkGrayColor]
                                                 icon:[UIImage imageNamed:@"friendship-status-blocked"]
                                                title:@"BLOCK"
                                           titleColor:[UIColor whiteColor]];
    
    
    return rightUtilityButtons;
}

- (NSArray *)rightDeleteButton
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:255.0f/255.0f green:73.0f/255.0f blue:0.0f/255.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"newTrash"]
                                                title:@"DELETE"
                                           titleColor:[UIColor whiteColor]];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor darkGrayColor]
                                                 icon:[UIImage imageNamed:@"friendship-status-blocked"]
                                                title:@"BLOCK"
                                           titleColor:[UIColor whiteColor]];
    
    return rightUtilityButtons;
}

#pragma mark - SWTableViewCell Delegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
{
    switch (state) {
        case 0:
            //NSLog(@"utility buttons closed");
            break;
        case 1:
            //NSLog(@"left utility buttons open");
            break;
        case 2:
            //NSLog(@"right utility buttons open");
            break;
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            //NSLog(@"left button 0 was pressed");
            break;
        case 1:
            //NSLog(@"left button 1 was pressed");
            break;
        case 2:
            //NSLog(@"left button 2 was pressed");
            break;
        case 3:
            //NSLog(@"left btton 3 was pressed");
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            //NSLog(@"Flag/Delete was pressed");
            
            Comment *tempComment = (Comment *)self.comments[cell.tag];
            
            int commentId = (int)tempComment.recordID;
            //NSLog(@"commentId %i",commentId);
            
            BOOL isCurrentUsersComment = NO;
            if ([[AuthenticationManager sharedInstance].currentUser.userToken isEqualToString:tempComment.userToken]) {
                isCurrentUsersComment = YES;
            }
            
            
            if (isCurrentUsersComment) {
                __weak typeof(self)weakSelf = self;
                
                [MeetManager deleteCommentWithCommentId:commentId
                                         resultCallback:^() {
                                             
                                             __strong typeof(weakSelf)strongSelf = weakSelf;
                                             
                                             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                                             [strongSelf.comments removeObjectAtIndex:cell.tag];
                                             
                                             if (strongSelf.comments.count > 0) {
                                                 
                                                 [strongSelf.tableView beginUpdates];
                                                 
                                                 [strongSelf.tableView deleteRowsAtIndexPaths:@[indexPath]
                                                                             withRowAnimation:UITableViewRowAnimationFade];
                                                 [strongSelf.tableView endUpdates];
                                             }
                                             
                                             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                                                 message:@"This comment has been deleted."
                                                                                                delegate:nil
                                                                                       cancelButtonTitle:@"Dismiss"
                                                                                       otherButtonTitles:nil];
                                             [alertView show];
                                             
                                             strongSelf.mem.commentsCount = strongSelf.comments.count;
                                             
                                             [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:self.mem];
                                             [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                             [strongSelf.tableView reloadData];
                                             
                                         }
                                          faultCallback:^(NSError *error) {
                                              
                                          }];
            }
            else {
                [self showReportPromptForComment:tempComment atIndex:cell.tag];
            }
            
            [cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1:
        {
            // Block button was pressed
            Comment *tempComment = (Comment *)self.comments[cell.tag];
            [self showBlockPromptForPerson:tempComment.author];
            
            break;
        }
        default:
            break;
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    // allow just one cell's utility button to be open at once
    return YES;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    switch (state) {
        case 1:
            // set to NO to disable all left utility buttons appearing
            // set to YES to enable all left utility buttons
            return NO;
        case 2:
            // set to NO to disable all right utility buttons
            // set to YES to enable all right utility buttons
            
            return YES;
        default:
            return NO;
    }
    
    return YES;
}

#pragma mark - Tagging

- (void)tagFriends {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    [self.navigationController presentViewController:self.tagFriendsViewController animated:YES completion:nil];
}

- (SPCTagFriendsViewController *)tagFriendsViewController {
    if (!_tagFriendsViewController && self.mem) {
        _tagFriendsViewController = [[SPCTagFriendsViewController alloc] initWithSelectedFriends:self.mem.taggedUsers];
        _tagFriendsViewController.delegate = self;
    }
    return _tagFriendsViewController;
}

#pragma mark - SPCTagFriendsViewControllerDelegate

- (void)pickedFriends:(NSArray *)selectedFriends {
    self.mem.taggedUsers = selectedFriends;
    [MeetManager updateMemoryParticipantsWithMemoryID:self.mem.recordID
                                 taggedUserIdsUserIds:self.mem.taggedUsersIDs
                                       resultCallback:^(NSDictionary *results) {
                                           [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:self.mem];
                                           [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
                                       }
                                        faultCallback:^(NSError *fault) {}];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        self.tagFriendsViewController = nil;
    }];
}

- (void)cancelTaggingFriends {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        self.tagFriendsViewController = nil;
    }];
}

#pragma mark SPCMapViewController

- (void)cancelMap {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didAdjustLocationForMemory:(Memory *)memory {
    [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
    [self.memCell updateForCommentDisplay];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark = SPCAdjustMemoryViewControllerDelegate

-(void)didAdjustLocationForMemory:(Memory *)memory withViewController:(UIViewController *)viewController {
    [self.memCell configureWithMemory:self.mem tag:0 dateFormatter:nil placeholder:self.gridCellImage];
    [self.memCell updateForCommentDisplay];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

-(void)dismissAdjustMemoryLocationViewController:(UIViewController *)viewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
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
        alertView.tag = serviceType; // MUST correspond to alertViewTagFacebook/alertViewTagTwitter
        [alertView show];
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"alert view with tag %d button index %d cancel button index %d", alertView.tag, buttonIndex, alertView.cancelButtonIndex);
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView.tag == alertViewTagTwitter) {
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeTwitter viewController:appDelegate.mainViewController.customTabBarController completionHandler:^{
                [self shareMemory:self.mem serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        }
        else if (alertView.tag == alertViewTagFacebook) {
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeFacebook viewController:nil completionHandler:^{
                [self shareMemory:self.mem serviceName:@"FACEBOOK" serviceType:SocialServiceTypeFacebook];
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        } else if (alertView.tag == alertViewTagReport) {
            // These buttons were configured so that buttonIndex 1 = 'Send', buttonIndex 0 = 'Add Detail'
            if (1 == buttonIndex) {
                if ([self.reportObject isKindOfClass:[Memory class]]) {
                    Memory *memory = (Memory *)self.reportObject;
                    
                    [Flurry logEvent:@"MEM_REPORTED"];
                    [self.memoryCoordinator reportMemory:memory withType:self.reportType text:nil completionHandler:^(BOOL success) {
                        if (success) {
                            [self showMemoryReportWithSuccess:YES];
                        } else {
                            [self showMemoryReportWithSuccess:NO];
                        }
                    }];
                } else if ([self.reportObject isKindOfClass:[Comment class]]) {
                    Comment *comment = (Comment *)self.reportObject;
                    BOOL deleteOnReport = [AuthenticationManager sharedInstance].currentUser.isAdmin
                            || [[AuthenticationManager sharedInstance].currentUser.userToken isEqualToString:self.mem.author.userToken];
                            
                    
                    __weak typeof(self) weakSelf = self;
                    [MeetManager reportCommentWithCommentId:comment.recordID reportType:self.reportType text:nil resultCallback:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        
                        [strongSelf showBlockReportedPromptForComment:comment];
                        
                        if (deleteOnReport) {
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.reportIndex inSection:0];
                            [strongSelf.comments removeObjectAtIndex:self.reportIndex];
                            
                            if (strongSelf.comments.count > 0) {
                                [strongSelf.tableView beginUpdates];
                                [strongSelf.tableView deleteRowsAtIndexPaths:@[indexPath]
                                                            withRowAnimation:UITableViewRowAnimationFade];
                                [strongSelf.tableView endUpdates];
                            }
                            
                            strongSelf.mem.commentsCount = strongSelf.comments.count;
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:self.mem];
                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                            [strongSelf.tableView reloadData];
                        }
                        
                    } faultCallback:^(NSError *fault) {
                        [self showCommentReportWithSuccess:NO];
                    }];
                }
            } else if (0 == buttonIndex) {
                //stop video playback if needed
                [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
                
                SPCReportViewController *rvc = [[SPCReportViewController alloc] initWithReportObject:self.reportObject reportType:self.reportType andDelegate:self];
                [self.navigationController pushViewController:rvc animated:YES];
            }
        } else if (alertView.tag == alertViewTagBlock) {
            Person *person = (Person *)self.reportObject;
            NSLog(@"Blocking %@: %d",person.displayName, person.recordID);
            [MeetManager blockUserWithId:person.recordID
                          resultCallback:^(NSDictionary *result)  {
                              
                              [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:[NSString stringWithFormat:NSLocalizedString(@"You have successfully blocked %@", nil), person.displayName] delegate:nil
                                                                        cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                              
                          }
                           faultCallback:^(NSError *error){
                               
                               NSLog(@"block failed, please try again");
                               
                           }
             ];
        }
    }
}

#pragma mark - SPCReportViewControllerDelegate

- (void)invalidReportObjectOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    // This can be memory or comment report, because they show the same message.
    [self showMemoryReportWithSuccess:NO];
}

- (void)canceledReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
}

- (void)sendFailedOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    // This can be memory or comment report, because they show the same message.
    [self showMemoryReportWithSuccess:NO];
}

- (void)sentReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    if ([reportViewController.reportObject isKindOfClass:[Memory class]]) {
        [self showMemoryReportWithSuccess:YES];
    } else if ([reportViewController.reportObject isKindOfClass:[Comment class]]) {
        [self showCommentReportWithSuccess:YES];
    }
}

#pragma mark - Report/Flagging Results

- (void)showCommentReportWithSuccess:(BOOL)succeeded {
    if (succeeded) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"This comment has been flagged. Thank you.", nil)
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
            
        case SPCAdminSockPuppetActionComment:
            NSLog(@"Commenting as %@", puppet.firstname);
            [self postCommentWithButton:self.sendCommentButton sockPuppet:puppet];
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