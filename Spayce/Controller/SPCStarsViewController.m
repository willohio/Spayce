//
//  SPCStarsViewController.m
//  Spayce
//
//  Created by William Santiago on 5/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCStarsViewController.h"

// Model
#import "Asset.h"
#import "Memory.h"
#import "Star.h"
#import "User.h"

// View
#import "Buttons.h"
#import "SPCRankedUserTableViewCell.h"

// Controller
#import "SPCProfileViewController.h"

// Category
#import "UIAlertView+SPCAdditions.h"
#import "UIColor+SPCAdditions.h"
#import "UIScrollView+GifPullToRefresh.h"
#import "UITabBarController+SPCAdditions.h"
#import "UITableView+SPXRevealAdditions.h"

// Manager
#import "MeetManager.h"
#import "SPCPullToRefreshManager.h"
#import "AuthenticationManager.h"

// Utilities
#import "APIUtils.h"

static NSString * CellIdentifier = @"StarCellIdentifier";

@interface SPCStarsViewController () <UITableViewDataSource, UITableViewDelegate, SPCPullToRefreshManagerDelegate>

@property (nonatomic, strong) NSArray *stars;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) SPCPullToRefreshManager *pullToRefreshManager;
@property (nonatomic) BOOL draggingScrollView;

@end

@implementation SPCStarsViewController {
    BOOL refreshAdded;
}

#pragma mark - Object lifecycle

- (void)dealloc {
    // Remove all observers
    @try {
        [self removeObserver:self forKeyPath:@"draggingScrollView"];
        [_tableView removeObserver:self forKeyPath:@"contentOffset"];
        [_pullToRefreshManager.fadingHeaderView removeObserver:self forKeyPath:@"alpha"];
    } @catch (NSException *exception) {}
    
    self.pullToRefreshManager = nil;
}

- (id)init {
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

#pragma mark - View's lifecycle

- (void)loadView {
    [super loadView];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureTableView];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    [self addObserver:self forKeyPath:@"draggingScrollView" options:NSKeyValueObservingOptionNew context:nil];
    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];

    [self fetchStars];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self configurePullDownRefreshControl];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

#pragma mark - Accessors

- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 70)];
        _navBar.backgroundColor = [UIColor whiteColor];
        _navBar.hidden = NO;
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectZero];
        backButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        backButton.layer.cornerRadius = 2;
        backButton.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : backButton.titleLabel.font,
                                                  NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Back" attributes:backStringAttributes];
        [backButton setAttributedTitle:backString forState:UIControlStateNormal];
        backButton.frame = CGRectMake(0, CGRectGetHeight(_navBar.frame) - 44.0f, 60, 44);
        [backButton addTarget:self action:@selector(pop:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        NSDictionary *titleLabelAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x292929],
                                                NSKernAttributeName : @(1.1) };
        NSString *titleText = NSLocalizedString(@"Stars", nil);
        titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleText attributes:titleLabelAttributes];
        CGSize sizeOfTitle = [titleLabel.text sizeWithAttributes:titleLabelAttributes];
        titleLabel.frame = CGRectMake(0, 0, sizeOfTitle.width, sizeOfTitle.height);
        titleLabel.center = CGPointMake(CGRectGetMidX(_navBar.frame), CGRectGetMidY(backButton.frame) - 1);
        
        CGFloat sepBottomHeight = 1.0f / [UIScreen mainScreen].scale;
        UIView *sepBottom = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_navBar.frame) - sepBottomHeight, CGRectGetWidth(_navBar.frame), sepBottomHeight)];
        [sepBottom setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f]];
        
        [_navBar addSubview:backButton];
        [_navBar addSubview:titleLabel];
        [_navBar addSubview:sepBottom];
    }
    return _navBar;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.navigationController.view.frame) - CGRectGetMaxY(self.navBar.frame)) style:UITableViewStylePlain];
        _tableView.tableFooterView = [[UIView alloc] init];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView setSeparatorInset:UIEdgeInsetsZero];
        
        if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            _tableView.layoutMargins = UIEdgeInsetsZero;
        }
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stars.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCRankedUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Star *star = self.stars[indexPath.row];
    
    [cell configureWithStar:star];
    [cell.imageButton setTag:indexPath.row];
    [cell.imageButton addTarget:self action:@selector(handleProfileImageTap:) forControlEvents:UIControlEventTouchUpInside];
  
    // Check if this cell's user is equal to the current user
    NSString *userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
    if ([star.userToken isEqualToString:userToken]) {
        cell.youBadge.hidden = NO; // If so, show the 'you' badge
    }
    
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]){
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Selected star data
    Star *star = self.stars[indexPath.row];
    
    if (star.recordID == -2) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    }
    else {
        // Push profile detail
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:star.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75.0;
}

#pragma mark - Scroll view delegation

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.draggingScrollView = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.pullToRefreshManager scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.pullToRefreshManager scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    
    if (!decelerate) {
        self.draggingScrollView = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.draggingScrollView = NO;
}


#pragma mark - Private

- (void)configureTableView {
    [self.tableView registerClass:[SPCRankedUserTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    self.tableView.rowHeight = [self tableView:nil heightForRowAtIndexPath:nil];
}

- (void)configurePullDownRefreshControl {
    if (!refreshAdded) {
        refreshAdded = YES;
        
        self.pullToRefreshManager = [[SPCPullToRefreshManager alloc] initWithScrollView:self.tableView];
        self.pullToRefreshManager.fadingHeaderView = self.navBar;
        self.pullToRefreshManager.delegate = self;
        
        [self.pullToRefreshManager.fadingHeaderView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
    }
}

#pragma mark - Actions

- (void)handleProfileImageTap:(id)sender {
    // Sender is a UIButton
    UIButton *btnSender = (UIButton *)sender;
    NSIndexPath *rowSelected = [NSIndexPath indexPathForRow:btnSender.tag inSection:0];
    
    // Simulate a tap on the row
    [self tableView:self.tableView didSelectRowAtIndexPath:rowSelected];
}

- (void)fetchStars {
    __weak typeof(self)weakSelf = self;

    [MeetManager fetchStarsWithMemoryId:self.memory.recordID
                      completionHandler:^(NSArray *stars) {
                          __strong typeof(weakSelf)strongSelf = weakSelf;
                          
                          // End loading
                          [strongSelf.pullToRefreshManager refreshFinished];
                          
                          // Array - Sorted by most recent to oldest
                          strongSelf.stars = [stars sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                              Star *starObj1 = (Star *)obj1;
                              Star *starObj2 = (Star *)obj2;
                              return [starObj2.dateStarred compare:starObj1.dateStarred];
                          }];
                          
                          // Reload view
                          [strongSelf.tableView reloadData];
                      } errorHandler:^(NSError *error) {
                          __strong typeof(weakSelf)strongSelf = weakSelf;
                          
                          // End loading
                          [strongSelf.tableView didFinishPullToRefresh];
                          
                          // Show alert
                          [UIAlertView showError:error];
                      }];
}

- (void)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - SPCPullToRefreshManagerDelegate

-(void)pullToRefreshTriggered:(SPCPullToRefreshManager *)manager {
    [self fetchStars];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self) {
        if ([keyPath isEqualToString:@"draggingScrollView"]) {
            //BOOL isScrolling = [[object valueForKeyPath:keyPath] boolValue];
            
            // Fade in/out navigation bar
            [UIView animateWithDuration:0.35 animations:^{
                //self.statusBar.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:isScrolling ? 0.9 : 1.0];
                //self.navigationController.navigationBar.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:isScrolling ? 0.9 : 1.0];
            }];
        }
    }
    else if (object == self.tableView) {
        if ([keyPath isEqualToString:@"contentOffset"]) {
            //CGPoint contentOffset = [[object valueForKeyPath:keyPath] CGPointValue];
            
            BOOL draggingScrollView = self.draggingScrollView;
            if (draggingScrollView) {
                //self.statusBar.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:contentOffset.y > -self.tableView.contentInset.top ? 0.9 : 1.0];
                //self.navigationController.navigationBar.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:contentOffset.y > -self.tableView.contentInset.top ? 0.9 : 1.0];
            }
        }
    }
    else if (object == self.navigationController.navigationBar) {
        if ([keyPath isEqualToString:@"alpha"]) {
            //CGFloat alpha = [[object valueForKeyPath:keyPath] floatValue];
            //self.statusBar.alpha = alpha;
        }
    }
}

@end
