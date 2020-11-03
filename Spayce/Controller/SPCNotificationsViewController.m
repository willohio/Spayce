//
//  SpayceNotificationsViewController.m
//  Spayce
//
//  Created by Joseph Jupin on 10/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SPCNotificationsViewController.h"

// Framework
#import "Flurry.h"

// Model
#import "Asset.h"
#import "ProfileDetail.h"
#import "SPCHereDataSource.h"
#import "User.h"
#import "UserProfile.h"

// View
#import "Buttons.h"
#import "PXAlertView.h"
#import "SPCNotificationCell.h"

// Controller
#import "SPCMainViewController.h"
#import "SPCProfileViewController.h"
#import "SPCHereViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCFollowRequestsViewController.h"

// Category
#import "NSDate+SPCAdditions.h"
#import "UIViewController+SPCAdditions.h"
#import "UIAlertView+SPCAdditions.h"
#import "UITableView+SPXRevealAdditions.h"

// General
#import "AppDelegate.h"
#import "Constants.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "MeetManager.h"
#import "PNSManager.h"
#import "SPCPullToRefreshManager.h"

// Utilities
#import "APIUtils.h"

@interface SPCNotificationsViewController ()<SPCPullToRefreshManagerDelegate> {
    bool pushed;
    
    BOOL registeredForNotifications;
    
    NSInteger rowCount;
    
}
@property (nonatomic,strong) PXAlertView *alertView;
@property (nonatomic,strong) SPCPullToRefreshManager *pullToRefreshManager;
@property (nonatomic, strong) UIView *customNav;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIView *loadingSpinner;
@property (nonatomic, assign) BOOL tableViewHasAppeared;

@end

@implementation SPCNotificationsViewController

static NSString * ThreadCellId = @"NotificationCell";

#pragma mark - Managing the View

- (void)dealloc {
    [self spc_dealloc];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    registeredForNotifications = NO;
}


-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;

    if (!registeredForNotifications) {
        registeredForNotifications = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(displayProfileForUserToken:)
                                                     name:@"displayProfileForUserToken"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidSortNotifications:)
                                                     name:PNSManagerDidSortNotifications
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidFinishRefreshingNotifications:)
                                                     name:PNSManagerNotificationsLoaded
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateNotificationsAfterFriendRequestResponse)
                                                     name:kFriendRequestResponseCompleteRefreshNotificationDisplay
                                                   object:nil];
    }
    
    // Set the background color - this will be visible prior to the tableView loading
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // Add the spinner, for the period before the tableView loads
    [self.view addSubview:self.loadingSpinner];
}

-(void)viewWillAppear:(BOOL)animate {
    [super viewWillAppear:animate];
    
    if (!self.tableViewHasAppeared) {
        // iOS 8 only call - we don't have to ask users of earlier versions for permission
        // should trigger a permissions request for new devices
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert) categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        } else  {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
        }
    }
    self.navigationController.navigationBarHidden = YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self initializeTableView];
    [self.loadingSpinner removeFromSuperview];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_pullToRefreshManager) {
        _pullToRefreshManager.fadingHeaderView = nil;
    }
    
}

-(void)viewWillLayoutSubviews {
    self.tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 44);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)initializeTableView {
    
    if (self.tableViewHasAppeared) {
        [self.tableView reloadData];
    }
    else {
        self.tableViewHasAppeared = YES;
        //NSLog(@"viewDidLoad: creating table with height %f", self.view.bounds.size.height);
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 114) style:UITableViewStylePlain];
        self.tableView.backgroundView = nil;
        self.tableView.backgroundColor = [UIColor whiteColor];
        self.tableView.separatorColor = [UIColor colorWithRGBHex:0xCEC8C2];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.view.clipsToBounds = NO;
        self.tableView.clipsToBounds = YES;
        [self.view addSubview:self.tableView];
        [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
        
        self.pullToRefreshManager = [[SPCPullToRefreshManager alloc] initWithScrollView:self.tableView];
        self.pullToRefreshManager.delegate = self;
        
        // unfortunately, have to check for iOS7's separator separately...
        if ([self.tableView respondsToSelector:@selector(setSeparatorStyle:)]) {
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        }
        
        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsZero];
        }
        
        [self.tableView registerClass:[SPCNotificationCell class]forCellReuseIdentifier:ThreadCellId];
        
        CGFloat bottom = CGRectGetHeight(self.tabBarController.tabBar.frame);
        self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, bottom, 0.0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
        self.tabBarController.tabBar.alpha = 1.0;
        
        if (_pullToRefreshManager) {
            _pullToRefreshManager.fadingHeaderView = _pullToRefreshFadingHeader;
        }
    }
}

#pragma mark - Accessors

-(UIView *)customNav {
    if (!_customNav) {
        NSLog(@"add custom nav??");
        _customNav = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, 64)];
        _customNav.backgroundColor = [UIColor whiteColor];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 44)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        NSDictionary *titleLabelAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x3f5578],
                                                NSKernAttributeName : @(1.1) };
        NSString *titleText = NSLocalizedString(@"NEWS LOG", nil);
        titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleText attributes:titleLabelAttributes];
        
        [_customNav addSubview:self.backBtn];
        [_customNav addSubview:titleLabel];
        
        // Add the bottom separator
        CGFloat separatorSize = 1.0f / [UIScreen mainScreen].scale;
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_customNav.frame) - separatorSize, CGRectGetWidth(_customNav.frame), separatorSize)];
        [separator setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f]];
        [_customNav addSubview:separator];
    }
    return _customNav;
}

-(UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 27, 60, 30)];
        _backBtn.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : [UIFont spc_regularSystemFontOfSize: 14],
                                   NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x6ab1fb] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Back" attributes:backStringAttributes];
        [_backBtn setAttributedTitle:backString forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(handleBackButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (void) handleBackButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"markNewsLogReadOnDelay" object:nil];
}

- (void)refresh:(id)sender {
    [self spc_hideNotificationBanner];
    
    PNSManager *manager = PNSManager.sharedInstance;
    
    __weak typeof(self) weakSelf = self;
    
    [manager requestNotificationsListWithFaultCallback:^(NSError *fault) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf.pullToRefreshManager refreshFinished];
        
        if (fault) {
            [strongSelf.pullToRefreshManager refreshFinished];
            [strongSelf spc_showNotificationBannerInParentView:strongSelf.tableView title:NSLocalizedString(@"Couldn't Refresh Notifications", nil) error:fault];
        }
    }];
}

- (UIView *)loadingSpinner {
    if (!_loadingSpinner) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.center = CGPointMake(self.view.center.x, self.view.frame.size.height/2);
        indicatorView.color = [UIColor grayColor];
        [indicatorView startAnimating];
        
        _loadingSpinner = indicatorView;
    }
    return _loadingSpinner;
}


#pragma mark UITableViewDataSource and UITableViewDelegate

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    int numSections = [[PNSManager sharedInstance] getSectionsCount];
    if (numSections > 5){
       // numSections = 5;
    }
    return (numSections == 0) ? 1 : numSections;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sortedByDate = [[PNSManager sharedInstance] getNotificationsForSection:(int)section];
    if (section == 0) {
        rowCount = sortedByDate.count;
    }
    return MAX(sortedByDate.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sortedByDate = [[PNSManager sharedInstance] getNotificationsForSection:(int)indexPath.section];
    
    if (indexPath.section == 0) {
        if (sortedByDate == nil || sortedByDate.count == 0) {
            UITableViewCell * emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            emptyCell.textLabel.font = [UIFont spc_placeholderFont];
            emptyCell.textLabel.textAlignment = NSTextAlignmentCenter;
            emptyCell.textLabel.text = NSLocalizedString(@"You have no notifications", nil);
            emptyCell.selectionStyle = UITableViewCellSelectionStyleNone;
            emptyCell.backgroundView = nil;
            
            return emptyCell;
        }
    }

    SPCNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:ThreadCellId];
    if (cell == nil) {
        cell = [[SPCNotificationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ThreadCellId];
        cell.backgroundColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
   
    if (indexPath.row < sortedByDate.count) {
    
        SpayceNotification *notification = sortedByDate[indexPath.row];
        
        // Connect actions
        [cell.imageButton addTarget:self action:@selector(handleProfileImageTap:) forControlEvents:UIControlEventTouchUpInside];
        [cell.notificationAuthorBtn addTarget:self action:@selector(handleProfileImageTap:) forControlEvents:UIControlEventTouchUpInside];
        [cell.acceptBtn addTarget:self action:@selector(handleAcceptButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [cell.declineBtn addTarget:self action:@selector(handleDeclineButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        
        
        cell.backgroundColor = (notification.hasBeenRead) ? [UIColor whiteColor] : [UIColor colorWithWhite:246.0f/255.0f alpha:1.0f];
        
        Asset *asset = notification.user.imageAsset;
        // we might want to override this -- new users may not have their profile asset
        // in place at the time this notification was cached.  Also, changes in profile asset
        // over time may not be reflected in our cached notifications.
        if ([notification.user.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
            if ([ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset != nil) {
                asset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
            }
        }
        
        // Buttons
        [cell.imageButton setTag:notification.notificationId];
        [cell.acceptBtn setTag:notification.notificationId];
        [cell.declineBtn setTag:notification.notificationId];
        [cell.notificationAuthorBtn setTag:notification.notificationId];
        cell.clipsToBounds = YES;
        
        NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:asset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
        
        [cell configureWithText:notification.user.firstName url:url];
        
        // Author
        NSString *authorName = [NSString stringWithFormat:@"%@", notification.user.firstName];
        CGSize authorNameSize = [authorName sizeWithAttributes: @{ [UIFont spc_regularFont]: NSFontAttributeName }];
        cell.authorNameWidth = authorNameSize.width+5;
        
        NSRange testRange = NSMakeRange(0, 3);
        NSString *isItYouStr = [notification.notificationText substringWithRange:testRange];
        if ([isItYouStr isEqualToString:@"You"]) {
             cell.authorNameWidth = 25;
        }
        
        [cell styleNotification:notification];
        cell.notificationDateAndTimeLabel.text = [NSDate formattedDateStringWithString:notification.createdTime];
    //    [cell layoutSubviews];
   
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // set background view
    [cell setBackgroundView:nil];
    
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *sortedByDate = [[PNSManager sharedInstance] getNotificationsForSection:(int)indexPath.section];
    
    if (sortedByDate == nil || sortedByDate.count == 0) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        return CGRectGetHeight(self.tableView.frame) - CGRectGetHeight(appDelegate.mainViewController.customTabBarController.tabBar.frame) - 65.0;
    }
    
    SpayceNotification *sn = sortedByDate[indexPath.row];
    return [SPCNotificationCell heightForCellWithNotification:sn];
    
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sortedByDate = [[PNSManager sharedInstance] getNotificationsForSection:(int)indexPath.section];
    SpayceNotification *sn = sortedByDate[indexPath.row];
    bool doComingSoon;
    UIViewController *segueToVC = nil;
    int type = [SpayceNotification retrieveNotificationType:sn];
    
    /*
    NSLog(@"sn notification id %i",(int)sn.notificationId);
    NSLog(@"sn user id %i",(int)sn.user.userId);
    NSLog(@"sn type %i",type);
    NSLog(@"sn.objectId %i",(int)sn.objectId);
    NSLog(@"sn.param 1 %@",sn.param1);
    NSLog(@"sn.param 2 %@",sn.param2);
    */
    
    switch (type) {
        case NOTIFICATION_TYPE_FOLLOWING: {
            doComingSoon = NO;
            // occurs when the user starts following a (private) user.
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:sn.user.userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
            break;
        }
            
        case NOTIFICATION_TYPE_FOLLOWED_BY: {
            doComingSoon = NO;
            // occurs when a different user begins to follow you
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:sn.user.userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
            break;
        }
            
        case NOTIFICATION_TYPE_FOLLOW_REQUEST: {
            doComingSoon = NO;
            break;
        }
            
        case NOTIFICATION_TYPE_MEMORY: {
            doComingSoon = NO;
            int memoryID = (int)sn.objectId;
            NSLog(@"memory notification tapped!");
            if (!tapped) {                
                tapped = YES;
                MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemoryId:memoryID];
                [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
                tapped = NO;
            }
            break;
        }
        case NOTIFICATION_TYPE_COMMENT: {
            doComingSoon = NO;
            int memoryID = (int)sn.objectId;
            NSLog(@"comment notification tapped!");
            if (!tapped) {
                tapped = YES;
                MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemoryId:memoryID];
                [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
                tapped = NO;
            }
            break;
        }
        case NOTIFICATION_TYPE_STAR: {
            doComingSoon = NO;
            int memoryID = (int)sn.objectId;
            NSLog(@"star notif tapped! notificationId:%i objectId:%i type:%@, look for memID:%i",(int)sn.notificationId,(int)sn.objectId,sn.notificationType,memoryID);
            
            if (!tapped) {
                tapped = YES;
                MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemoryId:memoryID];
                [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
                tapped = NO;
            }
            break;
        }
        case NOTIFICATION_TYPE_PLACEINVITE: {
            doComingSoon = NO;
            break;
        }
            
        case NOTIFICATION_TYPE_LOCATION_FRIEND: {
            doComingSoon = NO;

            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            UITabBarController *uiTabBarController = [appDelegate.mainViewController customTabBarController];
            [uiTabBarController setSelectedIndex:TAB_BAR_HOME_ITEM_INDEX];


            UINavigationController *spayceNavController = uiTabBarController.viewControllers[0];
            SPCHereViewController *spayceViewController = spayceNavController.viewControllers[0];
            SPCBaseDataSource *spcHereDataSource = [spayceViewController dataSource];
            [spcHereDataSource setSelectedSegmentIndex:2];

            break;
        }
            
        case NOTIFICATION_TYPE_LOCATION_PUBLIC: {
            doComingSoon = NO;

            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            UITabBarController *uiTabBarController = [appDelegate.mainViewController customTabBarController];
            [uiTabBarController setSelectedIndex:TAB_BAR_HOME_ITEM_INDEX];


            UINavigationController *spayceNavController = uiTabBarController.viewControllers[0];
            SPCHereViewController *spayceViewController = spayceNavController.viewControllers[0];
            SPCBaseDataSource *spcHereDataSource = [spayceViewController dataSource];
            [spcHereDataSource setSelectedSegmentIndex:0];

            break;
        }
            
        case NOTIFICATION_TYPE_LOCATION_OLD: {
            doComingSoon = NO;

            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            UITabBarController *uiTabBarController = [appDelegate.mainViewController customTabBarController];
            [uiTabBarController setSelectedIndex:TAB_BAR_HOME_ITEM_INDEX];

            UINavigationController *spayceNavController = uiTabBarController.viewControllers[0];
            SPCHereViewController *spayceViewController = spayceNavController.viewControllers[0];
            SPCBaseDataSource *spcHereDataSource = [spayceViewController dataSource];
            [spcHereDataSource setSelectedSegmentIndex:2];

            break;
        }
            
        case NOTIFICATION_TYPE_LOCATION_NONE: {
            doComingSoon = NO;

            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            UITabBarController *uiTabBarController = [appDelegate.mainViewController customTabBarController];

            
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
                
                // It's not allowed to present view controllers that are already placed in the tab bar controller modally
                // Therefore we are going to re-create the same exact container hierarchy and present that to the user instead
                UINavigationController *navController = uiTabBarController.viewControllers[2];
                UIViewController *originalViewController = navController.topViewController;
                UIViewController *newViewController = [[originalViewController.class alloc] init];

                // Place inside of the navigation controller
                navController = [[UINavigationController alloc] initWithRootViewController:newViewController];

                // Present modally
                [self presentViewController:navController animated:NO completion:nil];
            }
            else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location Services Off"
                                                                    message:@"Please enable location services to create a memory"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
            
            break;
        }

        case NOTIFICATION_TYPE_DAILY:
            doComingSoon = NO;
            [self onLookBackNotificationClick:sn];
            break;

        case NOTIFICATION_TYPE_DAILY_REWARD:
            doComingSoon = NO;
            [self onMemoryNotificationClick:sn];
            break;

        case NOTIFICATION_TYPE_COMMENT_NEW:
            doComingSoon = NO;
            [self onMemoryNotificationClick:sn];
            break;

        case NOTIFICATION_TYPE_COMMENT_STAR: {
            doComingSoon = NO;
            int memoryID = [sn.param1 intValue];
            NSLog(@"comment star notif tapped! notificationId:%i objectId:%i type:%@, look for memID:%i",(int)sn.notificationId,(int)sn.objectId,sn.notificationType,memoryID);
            
            if (!tapped) {
                tapped = YES;
                MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemoryId:memoryID];
                [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
                tapped = NO;
            }
            break;
        }
        case NOTIFICATION_TYPE_TAGGED_COMMENT: {
            doComingSoon = NO;
            int memoryID = [sn.param1 intValue];
            NSLog(@"tagged comment notif tapped! notificationId:%i objectId:%i type:%@, look for memID:%i",(int)sn.notificationId,(int)sn.objectId,sn.notificationType,memoryID);
            
            if (!tapped) {
                tapped = YES;
                MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemoryId:memoryID];
                [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
                tapped = NO;
            }
            break;
        }
        case NOTIFICATION_TYPE_UNKNOWN: {
            doComingSoon = NO;
            break;
        }
        default: {
            doComingSoon = NO;
        }

    }

    if (!sn.hasBeenRead) {
        sn.hasBeenRead = YES;
        [[PNSManager sharedInstance] performSelector:@selector(markAsReadSingleNotification:) withObject:sn afterDelay:.1];
    }
        
    if (doComingSoon) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Coming Soon!", nil)
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    } else {
        if (nil != segueToVC) {
            [self.navigationController pushViewController:segueToVC animated:YES];
        }
    }
}

- (void)onMemoryNotificationClick:(SpayceNotification *)sn
{
    int memoryID = (int)sn.objectId;
    if (!tapped) {
        tapped = YES;
        MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemoryId:memoryID];
        [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
        tapped = NO;
    }
}


- (void)onLookBackNotificationClick:(SpayceNotification *)sn
{
    if (!tapped) {
        tapped = YES;
       
        SPCLookBackViewController *spcLookBackViewController = [[SPCLookBackViewController alloc] init];
        spcLookBackViewController.delegate = self;
        [spcLookBackViewController fetchLookBackWithID:(int)sn.notificationId];
        
        SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:spcLookBackViewController];
        navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
        navController.navigationBarHidden = YES;
        [self presentViewController:navController animated:YES completion:nil];
    }
}

-(void)dismissLookBack {
    [self dismissViewControllerAnimated:YES completion:^{
        tapped = NO;
    }];
}

#pragma mark misc functions

-(void) handleDidSortNotifications:(id)sender {
    [self.pullToRefreshManager refreshFinished];
    
    NSArray *sortedByDate = [[PNSManager sharedInstance] getNotificationsForSection:0];
    
    if (sortedByDate.count > 0) {
        if (rowCount != sortedByDate.count) {
            rowCount = sortedByDate.count;
            [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
        }
        [self.tableView reloadData];
    }
    
    [self refreshFollowRequests];
}

-(void) handleDidFinishRefreshingNotifications:(id)sender {
    [self.pullToRefreshManager refreshFinished];
}

- (void)updateNotificationsAfterFriendRequestResponse {
    [self spc_hideNotificationBanner];
    
    PNSManager *manager = PNSManager.sharedInstance;
    
    __weak typeof(self) weakSelf = self;
    
    [manager requestNotificationsListWithFaultCallback:^(NSError *fault) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (fault) {
            [strongSelf spc_showNotificationBannerInParentView:strongSelf.tableView title:NSLocalizedString(@"Couldn't Refresh Notifications", nil) error:fault];
        }
    }];
}

- (void)setPullToRefreshFadingHeader:(UIView *)pullToRefreshFadingHeader {
    _pullToRefreshFadingHeader = pullToRefreshFadingHeader;
    if (_pullToRefreshManager) {
        _pullToRefreshManager.fadingHeaderView = _pullToRefreshFadingHeader;
    }
}

- (void)pullToRefreshTriggered:(SPCPullToRefreshManager *)manager {
    // This call performs a lot of work in the calling thread: delay it a bit,
    // so the manager can display it's "refreshing" content.
    [Flurry logEvent:@"PTR_NEWSLOG"];
    [self performSelector:@selector(refresh:) withObject:manager afterDelay:0.1f];
    //[self refresh:manager];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.pullToRefreshManager scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.pullToRefreshManager scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

-(void)refreshFollowRequests {
    
    __weak typeof(self)weakSelf = self;
    
    [MeetManager fetchUnhandleFollowRequestsCountWithResultCallback:^(NSInteger unhandledCount) {
        NSLog(@"unhandledCount %li",unhandledCount);
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
       
        if (!strongSelf) {
            return ;
        }
    
        NSLog(@"unhandledCount %li",unhandledCount);
        
        if (unhandledCount > 0) {
            
            UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 85)];
            headerView.backgroundColor = [UIColor whiteColor];
            
            UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 84.5, self.view.bounds.size.width,0.5)];
            sepLine.backgroundColor = [UIColor colorWithWhite:235.0f/255.0f alpha:1.0f];
            [headerView addSubview:sepLine];
            
            UIButton *followRequestsBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
            followRequestsBtn.backgroundColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
            followRequestsBtn.layer.cornerRadius = 20;
            [followRequestsBtn setTitle:[NSString stringWithFormat:@"New follow requests (%li)",unhandledCount] forState:UIControlStateNormal];
            [followRequestsBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            followRequestsBtn.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
            [followRequestsBtn addTarget:self action:@selector(showFollowRequests) forControlEvents:UIControlEventTouchDown];
            
            [headerView addSubview:followRequestsBtn];
            followRequestsBtn.center = CGPointMake(headerView.frame.size.width/2, headerView.frame.size.height/2);
            
            //TODO - set when buttons are wired up and paging is tested!
            strongSelf.tableView.tableHeaderView = headerView;
            
        }
        else {
            strongSelf.tableView.tableHeaderView = nil;
        }
    
    } faultCallback:^(NSError *error) {
    
    }];
    
    
   
}

-(void)showFollowRequests {
    SPCFollowRequestsViewController *followVC = [[SPCFollowRequestsViewController alloc] init];
    [self.navigationController pushViewController:followVC animated:YES];
}


#pragma mark - deleted mem alert 

- (void)showDeletedMemoryAlert:(NSString *)authorName {
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 220)];
    demoView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 10, 270, 40);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [demoView addSubview:imageView];
    
    NSString *title = @"Hang on!";
    
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
    messageLabel.text = [NSString stringWithFormat:@"%@ deleted this memory!",authorName];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:messageLabel];
    
    
    CGRect cancelFrame = CGRectMake(70, 155, 130, 40);
    
    self.alertView = [PXAlertView showAlertWithView:demoView cancelTitle:@"OK" cancelBgColor:[UIColor darkGrayColor] cancelTextColor:[UIColor whiteColor] cancelFrame:cancelFrame completion:^(BOOL cancelled) {
        self.alertView = nil;
    }];
}


- (void)handleProfileImageTap:(id)sender {
    NSLog(@"handleProfileImageTap");
    int tag = (int)[sender tag];
    SpayceNotification * notification = [[PNSManager sharedInstance] getNotificationForId:tag];
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:notification.user.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)displayProfileForUserToken:(NSNotification *)notification {
    
    NSLog(@"displayProfileForUserToken!");
    NSString *userToken = (NSString *)[notification object];
    
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)handleAcceptButtonTap:(id)sender {
    int tag = (int)[sender tag];
    SpayceNotification *notification = [[PNSManager sharedInstance] getNotificationForId:tag];
    [MeetManager acceptFollowRequestWithUserToken:notification.user.userToken completionHandler:^{
        [self.tableView reloadData];
    } errorHandler:^(NSError *error) {
        [UIAlertView showError:error];
    }];
}

- (void)handleDeclineButtonTap:(id)sender {
    int tag = (int)[sender tag];
    SpayceNotification *notification = [[PNSManager sharedInstance] getNotificationForId:tag];
    [MeetManager rejectFollowRequestWithUserToken:notification.user.userToken completionHandler:^{
        [self.tableView reloadData];
    } errorHandler:^(NSError *error) {
        [UIAlertView showError:error];
    }];
}

@end
