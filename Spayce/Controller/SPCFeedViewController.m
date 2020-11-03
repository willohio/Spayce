//
//  FeedViewController.m
//  Spayce
//
//  Created by Jake Rosin on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFeedViewController.h"
#import "Flurry.h"

// View
#import "DZNSegmentedControl.h"

// Controller
#import "SPCMemoriesViewController.h"
#import "SPCNotificationsViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCPeopleFinderViewController.h"

// Category
#import "UITabBarController+SPCAdditions.h"
#import "UIViewController+SPCAdditions.h"

// Manager
#import "PNSManager.h"

// Utils
#import "TranslationUtils.h"
#import "Constants.h"

#import "AuthenticationManager.h"
#import "User.h"
#import "UserProfile.h"
#import "ProfileDetail.h"

NSString * const kFindButtonAnimationKeyPath = @"transform.scale";
NSString * const kFindButtonAnimationName = @"animateScale";

@interface SPCFeedViewController () <SPCMemoriesViewControllerDelegate>

@property (nonatomic, assign) NSInteger controllerType;
@property (nonatomic, strong) DZNSegmentedControl *segmentControl;
@property (nonatomic, strong) UIView *headerContainerView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIViewController *currentViewController;
@property (nonatomic, strong) SPCMemoriesViewController *memoriesViewController;
@property (nonatomic, strong) SPCNotificationsViewController *spayceNotificationsViewController;
@property (nonatomic, strong) UILabel *notificationLabel;
@property (nonatomic, strong) UILabel *feedNotificationLabel;
@property (nonatomic, strong) UIButton *findPeopleButton;

@property (nonatomic, assign) float headerOriginalCenterY;
@property (nonatomic, assign) float maxAdjustment;
@property (nonatomic, assign) float baseOffset;
@property (nonatomic, assign) float previousOffset;
@property (nonatomic, assign) float changedDirectionAtOffSetY;
@property (nonatomic, assign) BOOL userHasBeenScrollingUp;
@property (nonatomic, assign) float triggerUpDelta;
@property (nonatomic, assign) float triggerDownDelta;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, assign) BOOL isVisible;

@end

@implementation SPCFeedViewController

#pragma mark - Object lifecyle

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Remove all observers
    @try {
        [_memoriesViewController removeObserver:self forKeyPath:@"draggingScrollView"];
        [_memoriesViewController.tableView removeObserver:self forKeyPath:@"contentOffset"];
    } @catch (NSException *exception) {}
}

- (id)initWithType:(NSInteger)type
{
    self = [super init];
    if (self) {
        _controllerType = type;
        self.title = @"Follows";
        
        self.memoriesViewController = [[SPCMemoriesViewController alloc] init];
        self.memoriesViewController.delegate = self;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    [self.headerContainerView addSubview:self.headerView];
    [self.view addSubview:self.headerContainerView];

    UIButton *scrollToTopBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
    [scrollToTopBtn addTarget:self action:@selector(scrollToTop) forControlEvents:UIControlEventTouchDown];
    scrollToTopBtn.backgroundColor = [UIColor clearColor];
    [self.view addSubview:scrollToTopBtn];

    self.findPeopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.findPeopleButton.frame = CGRectMake(0.0, 20.0, 29.0, 50.0);
    [self.findPeopleButton setImage:[UIImage imageNamed:@"friendship-people-search"] forState:UIControlStateNormal];
    CGRect findPeopleButtonFrame = self.findPeopleButton.frame;
    findPeopleButtonFrame.origin.x = CGRectGetWidth(self.headerView.frame) - CGRectGetWidth(findPeopleButtonFrame) - 10.0;
    self.findPeopleButton.frame = findPeopleButtonFrame;
    [self.findPeopleButton addTarget:self action:@selector(findPeopleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.findPeopleButton];
    
    self.triggerUpDelta = 25;
    self.triggerDownDelta = 20;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUnreadFeedCount) name:@"newMemsAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFailedToLoad) name:@"videoLoadFailed" object:nil];
    
    
    self.memoriesViewController.pullToRefreshFadingHeader = self.headerView;
    
    [self.memoriesViewController addObserver:self forKeyPath:@"draggingScrollView" options:NSKeyValueObservingOptionNew context:nil];
    [self.memoriesViewController.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar.layer removeAllAnimations];
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    self.isVisible = YES;
    [self showMemories];
    
    //ensure nav bar is correctly aligned
    if (self.memoriesViewController.tableView.contentOffset.y == self.baseOffset) {
        self.titleLabel.alpha = 1;
        self.headerContainerView.center = CGPointMake(self.headerContainerView.center.x, self.headerOriginalCenterY);
    }
    [self updateBadge];
    
    // Pulse the find people button if:
    // FTU or less than 10 people followed and haven't pressed it twice.
    BOOL shouldPulse = NO;
    
    UserProfile *signedInUserProfile = [AuthenticationManager sharedInstance].currentUserProfile;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:kSPCFeedHasAppearedBefore]) {
        shouldPulse = YES;
        
        [userDefaults setBool:YES forKey:kSPCFeedHasAppearedBefore];
    } else if ([userDefaults integerForKey:kSPCFeedFindPressCountUpToTwo] < 2 && signedInUserProfile.profileDetail.followingCount < 10) {
        shouldPulse = YES;
    }
    
    if (shouldPulse) {
        CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:kFindButtonAnimationKeyPath];
        pulseAnimation.duration = 0.3;
        pulseAnimation.repeatCount = HUGE_VALF;
        pulseAnimation.autoreverses = YES;
        pulseAnimation.fromValue = @(1.0);
        pulseAnimation.toValue = @(1.1);
        pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.findPeopleButton.layer addAnimation:pulseAnimation forKey:kFindButtonAnimationName];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isVisible = NO;
    [self hideBadge];
    
    [self.findPeopleButton.layer removeAnimationForKey:kFindButtonAnimationName];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}


- (void)setCurrentViewController:(UIViewController *)currentViewController {
    if (_currentViewController != currentViewController) {
        [_currentViewController willMoveToParentViewController:nil];
        [_currentViewController.view removeFromSuperview];
        [_currentViewController removeFromParentViewController];
        
        [self addChildViewController:currentViewController];
        
        // FIXME: This is a hack at the moment
        CGFloat offsetY = currentViewController == self.memoriesViewController ? 0.0 : 70;
        
        currentViewController.view.frame = CGRectMake(0.0, offsetY, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - offsetY);
        [currentViewController viewWillAppear:YES];
        [self.view insertSubview:currentViewController.view atIndex:0];
        [currentViewController viewDidAppear:YES];
        [currentViewController didMoveToParentViewController:self];
        
        _currentViewController = currentViewController;
    }
}

- (void)showMemories {
    self.currentViewController = self.memoriesViewController;
    self.headerContainerView.alpha = 1.0;
    [self.tabBarController setTabBarHidden:NO animated:YES];
}


#pragma mark - Accessors

- (UIView *)headerContainerView {
    if (!_headerContainerView) {
        _headerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 70)];
        _headerContainerView.backgroundColor = [UIColor clearColor];
        
        self.headerOriginalCenterY = _headerContainerView.center.y;
        self.maxAdjustment = _headerContainerView.frame.size.height - 20;
    }
    return _headerContainerView;
}

- (UIView *) headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
        _headerView.backgroundColor = [UIColor whiteColor];
        [_headerView addSubview:self.titleLabel];
        
        UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(0, _headerView.frame.size.height - 1, self.view.bounds.size.width, 1)];
        sepView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
        [_headerView addSubview:sepView];
    }
    
    return _headerView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 50)];
        _titleLabel.text = self.title;
        _titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
        
    }
    return _titleLabel;
}

-(UILabel *)notificationLabel {
    if (!_notificationLabel) {
        _notificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(290, 33, 20, 20)];
        _notificationLabel.layer.cornerRadius = _notificationLabel.frame.size.height/2;
        _notificationLabel.backgroundColor = [UIColor colorWithRed:254.0/255.0f green:150.0/255.0f blue:30.0/255.0f alpha:1.0f];
        _notificationLabel.textColor = [UIColor whiteColor];
        _notificationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:10];
        _notificationLabel.textAlignment = NSTextAlignmentCenter;
        _notificationLabel.clipsToBounds = YES;
        [_headerView addSubview:_notificationLabel];
    }
    return _notificationLabel;
}


-(UILabel *)feedNotificationLabel {
    if (!_feedNotificationLabel) {
        _feedNotificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 33, 20, 20)];
        _feedNotificationLabel.layer.cornerRadius = _feedNotificationLabel.frame.size.height/2;
        _feedNotificationLabel.backgroundColor = [UIColor colorWithRed:254.0/255.0f green:150.0/255.0f blue:30.0/255.0f alpha:1.0f];
        _feedNotificationLabel.textColor = [UIColor whiteColor];
        _feedNotificationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:10];
        _feedNotificationLabel.textAlignment = NSTextAlignmentCenter;
        _feedNotificationLabel.clipsToBounds = YES;
        [_headerView addSubview:_feedNotificationLabel];
    }
    return _feedNotificationLabel;
}


#pragma mark - Actions

-(void)scrollToTop {
    if (!self.memoriesViewController.pullToRefreshStarted) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.memoriesViewController.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [self.tabBarController slideTabBarHidden:NO animated:YES];
    }
}

- (void)findPeopleButtonPressed:(UIButton *)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger numberOfPresses = [userDefaults integerForKey:kSPCFeedFindPressCountUpToTwo];
    if (numberOfPresses < 2) {
        [userDefaults setInteger:numberOfPresses + 1 forKey:kSPCFeedFindPressCountUpToTwo];
        [userDefaults synchronize];
    }
    
    [Flurry logEvent:@"FIND_PEOPLE_TAPPED"];
    SPCPeopleFinderViewController *peopleFinderViewController = [[SPCPeopleFinderViewController alloc] init];
    [self.navigationController pushViewController:peopleFinderViewController animated:YES];
}

#pragma mark - Private 

- (void)updateBadge {
    NSInteger unreadFeedCount = [PNSManager sharedInstance].unreadFeedCount;
    

    self.feedNotificationLabel.text = [NSString stringWithFormat:@"%@", @(unreadFeedCount)];
    self.feedNotificationLabel.hidden = (unreadFeedCount == 0);
}

- (void)hideBadge {

    [self updateBadge];
}

-(void)updateUnreadFeedCount {
    if (self.currentViewController != self.memoriesViewController) {
        NSInteger unreadFeedCount = [PNSManager sharedInstance].unreadFeedCount;
        self.feedNotificationLabel.text = (unreadFeedCount > 0 ? [NSString stringWithFormat:@"%i", (int)unreadFeedCount] : nil);
        self.feedNotificationLabel.hidden = (unreadFeedCount == 0);
    }
}


- (void)userDidScrollAndYOffset:(float)offset {
    

    /*
     // - Goal animate elements in containing view controllers based upon scroll movement
     
     Requirements:
     1. Hide elements when user has scrolled more than 25% of a cell upwards since last change in direction
     2. Show elements when user has scrolled more than 20% of a cell downwards since last change in direction
     */
    
    //User is scrolling up
    if (self.previousOffset < offset) {
        
        self.userHasBeenScrollingUp = YES;
        
        //are we sure we haven't overscrolled (i.e. pull to refresh)
        if (offset < self.baseOffset) {
            self.changedDirectionAtOffSetY = offset;
            return;
        }
        
        //is this a change in direction?  If so, we need to note it
        if (!self.userHasBeenScrollingUp) {
            self.changedDirectionAtOffSetY = offset;
        }
        
        //how far have we scrolled up since we changed directions?
        float deltaAdj = fabsf(self.changedDirectionAtOffSetY - offset);
        
        //is this far enough to matter?
        if (deltaAdj > self.triggerUpDelta) {
            
            //are we sure we haven't overscrolled (i.e. pull to refresh)
            if (offset >= self.baseOffset) {
                
                //is user actually dragging? (or is it the delayed PTR reset? if PTR, ignore..)
                if (self.memoriesViewController.draggingScrollView) {
                    
                    //adjust the view
                    float deltaToMoveViews = fabsf(offset - self.previousOffset);
                    [self scrollingUpAdjustViewsWithDelta:deltaToMoveViews];
                }
            }
        }
    }
    //User is scrolling down
    else {
        
        
        //is this a change in direction?  If so, we need to note it
        if (self.userHasBeenScrollingUp) {
            self.changedDirectionAtOffSetY = offset;
        }
        
        self.userHasBeenScrollingUp = NO;
        
        //how far have we scrolled down since we changed directions?
        float deltaAdj = fabsf(self.changedDirectionAtOffSetY - offset);
        
        //is this far enough to matter?
        if (deltaAdj > self.triggerDownDelta) {
            
            //tell the delegate to adjust the view
            float deltaToMoveViews = fabsf(offset - self.previousOffset);
            [self scrollingDownAdjustViewsWithDelta:deltaToMoveViews];
        
        }
        
    }
    
    self.previousOffset = offset;
}



- (void)scrollingUpAdjustViewsWithDelta:(float)deltaAdj {
    
    //disable movement during pull to refresh
    if (!self.memoriesViewController.pullToRefreshStarted) {
        
        //adjust the views from their current position, based on movement of collection view
        if (self.headerContainerView.center.y - deltaAdj > self.headerOriginalCenterY - self.maxAdjustment) {
            self.headerContainerView.center = CGPointMake(self.headerContainerView.center.x, self.headerContainerView.center.y  - deltaAdj);
            self.titleLabel.alpha = 1;
            self.findPeopleButton.alpha = 1;
        }
        //cap the maximum movement
        else {
            self.findPeopleButton.alpha = 0;
            self.titleLabel.alpha = 0;
            self.headerContainerView.center = CGPointMake(self.headerContainerView.center.x, self.headerOriginalCenterY - self.maxAdjustment);
            [self.tabBarController slideTabBarHidden:YES animated:YES]; //only hide tab bar when our top nav is fully off screen
        }
        
    }
}

- (void)scrollingDownAdjustViewsWithDelta:(float)deltaAdj {
    
    //disable movement during pull to refresh
    if (!self.memoriesViewController.pullToRefreshStarted) {
        
        //adjust views from their current position, based on movement of collection view
        if (self.headerContainerView.center.y + deltaAdj <= self.headerOriginalCenterY) {
            self.titleLabel.alpha = 1;
            self.findPeopleButton.alpha = 1;
            self.headerContainerView.center = CGPointMake(self.headerContainerView.center.x, self.headerContainerView.center.y + deltaAdj);
            [self.tabBarController slideTabBarHidden:NO animated:YES]; //show tab bar immediately if user is looking for it
            
        }
        //everything should be reset to its original position
        else {
            self.titleLabel.alpha = 1;
            self.findPeopleButton.alpha = 1;
            self.headerContainerView.center = CGPointMake(self.headerContainerView.center.x, self.headerOriginalCenterY);
        }
    }
}

-(void)videoFailedToLoad {
    if (self.isVisible) {
        [self  spc_hideNotificationBanner];
        [self spc_showNotificationBannerInParentView:self.view title:NSLocalizedString(@"Video failed to load", nil) customText:NSLocalizedString(@"Please check your network and try again.",nil)];
   }
}

#pragma mark - Look Back methods - used when app is opened from PNS

- (void)onLookBackNotificationClick:(NSDictionary *)remoteNotification {
    
    int lookBackId =  (int)[TranslationUtils integerValueFromDictionary:remoteNotification withKey:@"Id"];
    
    SPCLookBackViewController *spcLookBackViewController = [[SPCLookBackViewController alloc] init];
    spcLookBackViewController.delegate = self;
    [spcLookBackViewController fetchLookBackWithID:lookBackId];

    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:spcLookBackViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    navController.navigationBarHidden = YES;
    [self presentViewController:navController animated:YES completion:nil];
}

-(void)dismissLookBack {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.memoriesViewController) {
        if ([keyPath isEqualToString:@"draggingScrollView"]) {
            BOOL isScrolling = [[object valueForKeyPath:keyPath] boolValue];
            
            if (self.memoriesViewController.tableView.contentOffset.y >= -self.memoriesViewController.tableView.contentInset.top) {
                // Fade in/out navigation bar
                [UIView animateWithDuration:0.35 animations:^{
                    self.headerContainerView.alpha = isScrolling ? 0.9 : 1.0;
                }];
            }
        }
    }
    else if (object == self.memoriesViewController.tableView) {
        if ([keyPath isEqualToString:@"contentOffset"]) {
            CGPoint contentOffset = [[object valueForKeyPath:keyPath] CGPointValue];
            [self userDidScrollAndYOffset:contentOffset.y];
            self.baseOffset = -self.memoriesViewController.tableView.contentInset.top;
            
            
            BOOL draggingScrollView = self.memoriesViewController.draggingScrollView;
            if (draggingScrollView) {
                if ([object window]) {
                    self.headerContainerView.alpha = contentOffset.y > -self.memoriesViewController.tableView.contentInset.top ? 0.9 : 1.0;
                }
            }
        }
    }
}


#pragma mark - SPCMemoriesViewControllerDelegate

-(void)spcMemoriesViewControllerDidLoadFeed:(UIViewController *)viewController {

}



@end
