//
//  BlockedUsersViewController.m
//  Spayce
//
//  Created by Pavel Dušátko on 11/23/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SPCBlockedUsersViewController.h"

// Model

#import "Asset.h"
#import "Person.h"
#import "User.h"

// View

#import "Buttons.h"
#import "SPCBlockedUserCell.h"

// Controller

#import "SPCProfileViewController.h"

// Manager

#import "AuthenticationManager.h"
#import "MeetManager.h"
#import "ProfileManager.h"

// Utilities

#import "APIUtils.h"
#import "UITableView+SPXRevealAdditions.h"
static NSString *BlockedUserCellIdentifier = @"BlockedUserCell";
static NSString *PlaceholderCellIdentifier = @"PlaceholderCell";

@interface SPCBlockedUsersViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *blockedUsers;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation SPCBlockedUsersViewController {
    UIRefreshControl *refreshControl;
}

#pragma mark - View lifecycle

-(void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_tableView];
}

- (void)loadView {
    [super loadView];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(fetchBlockedUsersList) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureNavigationBar];
    
    [self.tableView registerClass:[SPCBlockedUserCell class] forCellReuseIdentifier:BlockedUserCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:PlaceholderCellIdentifier];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self fetchBlockedUsersList];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.tableView.frame = self.view.bounds;
}

#pragma mark - Configuration

- (void)configureNavigationBar {
    // Background and tint color
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    
    // Left '<--' button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"button-back-light-small"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
    
    // Title
    self.navigationItem.title = NSLocalizedString(@"BLOCKED USERS", nil);
    self.navigationController.navigationBar.titleTextAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                                     NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x3f5578],
                                                                     NSKernAttributeName : @(1.1) };
    
    // Removing the shadow image. To do this, we must also set the background image
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,[[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:img forBarMetrics:UIBarMetricsDefault];
    
    // Adding the bottom separator
    CGFloat separatorSize = 1.0f / [UIScreen mainScreen].scale;
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.navigationController.navigationBar.frame) - separatorSize, CGRectGetWidth(self.navigationController.navigationBar.frame), separatorSize)];
    [separator setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f]];
    [self.navigationController.navigationBar addSubview:separator];
}

#pragma mark - Private

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.blockedUsers.count > 0){
        return self.blockedUsers.count;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.blockedUsers.count > 0) {
        SPCBlockedUserCell *cell = [tableView dequeueReusableCellWithIdentifier:BlockedUserCellIdentifier forIndexPath:indexPath];
        
        Person *blockedUser = self.blockedUsers[indexPath.row];
        
        [cell.actionButton setTag:indexPath.row];
        [cell.actionButton addTarget:self action:@selector(unblockUser:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.imageButton setTag:indexPath.row];
        [cell.imageButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        
        NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:blockedUser.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailMedium]];
        
        [cell configureWithText:blockedUser.firstname detailText:[NSString stringWithFormat:@"Blocked since %@", [self.dateFormatter stringFromDate:blockedUser.dateBlocked]] url:url];
        
        return cell;
    } else {
        UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:PlaceholderCellIdentifier forIndexPath:indexPath];
        cell.contentView.backgroundColor = [UIColor whiteColor];
        cell.textLabel.text = @"You have not blocked anyone yet.";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.font = [UIFont spc_lightFont];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.blockedUsers.count > 0){
        return 50;
    } else {
        return self.tableView.frame.size.height;
    }
}

#pragma mark - Private

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"MMMM dd, yyyy";
    }
    return _dateFormatter;
}

#pragma mark - Actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)fetchBlockedUsersList {
    [MeetManager fetchBlockedUsersResultCallback:^(NSArray *blockedUsers) {
        self.blockedUsers = blockedUsers;
        
        [self.tableView reloadData];
        
        [refreshControl endRefreshing];
    } faultCallback:^(NSError *fault) {
        [refreshControl endRefreshing];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                            message:@"There was an error retrieving your friends. Please check your connection and try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
}

- (void)unblockUser:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unblock user", nil)
                                                        message:NSLocalizedString(@"Are you sure that you want to unblock this user?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Unblock", nil), nil];
    alertView.tag = [sender tag];
    [alertView show];
}

- (void)showProfile:(id)sender {
    NSInteger tag = [sender tag];
    Person * user = self.blockedUsers[tag];
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:user.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)removeBlockedUserAtIndex:(NSInteger)index {
    if (index < self.blockedUsers.count) {
        // Remove blocked user object
        NSMutableArray *mutableUsers = [NSMutableArray arrayWithArray:self.blockedUsers];
        [mutableUsers removeObjectAtIndex:index];
        self.blockedUsers = [NSArray arrayWithArray:mutableUsers];
        // Reload table
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.35];
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        NSInteger index = alertView.tag;
        
        Person *selectedUser = self.blockedUsers[index];
        
        [MeetManager unblockUserWithId:selectedUser.recordID
                        resultCallback:^{
                            [self removeBlockedUserAtIndex:index];

                            [ProfileManager fetchProfileWithUserToken:[AuthenticationManager sharedInstance].currentUser.userToken
                                                       resultCallback:^(UserProfile *profile) {}
                                                        faultCallback:^(NSError *fault) {}];
                        } faultCallback:^(NSError *fault) {
                            [[[UIAlertView alloc] initWithTitle:@"Uh oh"
                                                        message:fault.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] show];
                        }];
    }
}

@end
