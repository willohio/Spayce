//
//  SPCFollowingViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 7/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFollowingViewController.h"

// Model
#import "Asset.h"
#import "Friend.h"

// View
#import "Buttons.h"
#import "SPCFriendUserCell.h"

// Controller
#import "SPCProfileViewController.h"

// Manager
#import "MeetManager.h"

// Utilities
#import "APIUtils.h"

static NSString *FriendCellIdentifier = @"FriendUserCell";
static NSString *PlaceholderCellIdentifier = @"PlaceholderCell";

@interface SPCFollowingViewController ()<UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *followingUsers;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic) BOOL isOtherPersonsProfile;

@end

@implementation SPCFollowingViewController {
    UIRefreshControl *refreshControl;
}

#pragma mark - Object lifecycle

- (id)initWithUserToken:(NSString *)userToken userName:(NSString *)userName isUsersProfile:(BOOL)isUsersProfile {
    self = [super init];
    if (self != nil) {
        self.userToken = userToken;
        self.userName = userName;
        self.isOtherPersonsProfile = !isUsersProfile;
    }
    
    return self;
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(fetchFollowing) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Following", nil);
    self.navigationItem.leftBarButtonItems = [Buttons backNavBarButtonsWithTarget:self action:@selector(pop)];
    
    [self.tableView registerClass:[SPCFriendUserCell class] forCellReuseIdentifier:FriendCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:PlaceholderCellIdentifier];
    
    [self fetchFollowing];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.tableView.frame = self.view.bounds;
}

#pragma mark - Appearance

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark - Accessors

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"MMMM dd, yyyy";
    }
    return _dateFormatter;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.followingUsers.count > 0) {
        return self.followingUsers.count;
    }
    else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.followingUsers.count > 0) {
        SPCFriendUserCell *cell = [tableView dequeueReusableCellWithIdentifier:FriendCellIdentifier forIndexPath:indexPath];
        
        Friend *friend = self.followingUsers[indexPath.row];
        
        [cell.imageButton setTag:indexPath.row];
        [cell.imageButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.actionButton setHidden:self.isOtherPersonsProfile];
        [cell.actionButton setTag:indexPath.row];
        [cell.actionButton setTitle:NSLocalizedString(@"Unfollow", nil) forState:UIControlStateNormal];
        [cell.actionButton addTarget:self action:@selector(unfollowUser:) forControlEvents:UIControlEventTouchUpInside];
        
        NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:friend.imageAsset.imageUrlThumbnail size:ImageCacheSizeSquareMedium]];
        
        [cell configureWithFriendId:friend.recordID
                               text:friend.firstname
                         detailText:[NSString stringWithFormat:NSLocalizedString(@"Following since %@", nil), [self.dateFormatter stringFromDate:friend.dateAcquainted]]
                                url:url];
        
        return cell;
    }
    else {
        UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:PlaceholderCellIdentifier forIndexPath:indexPath];
        
        NSString *text = NSLocalizedString(@"You aren't following \nanyone yet. \n\n\n\n\n\n", nil);
        if (self.isOtherPersonsProfile) {
            text = [NSString stringWithFormat:NSLocalizedString(@"%@ isn't following \nanyone yet. \n\n\n\n\n\n", nil), self.userName];
        }
        
        cell.contentView.backgroundColor = [UIColor whiteColor];
        cell.textLabel.text = text;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.font = [UIFont spc_lightFont];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.followingUsers.count > 0) {
        return 50;
    }
    else {
        if (fetchedFollowing){
            return self.tableView.frame.size.height;
        } else {
            return 0;
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        NSInteger index = alertView.tag;
        
        Friend *selectedFriend = self.followingUsers[index];
        
         [MeetManager unfollowUserWithUserToken:selectedFriend.userToken
                                 resultCallback:^{
                                     [self removeFriendAtIndex:index];
         }
                                  faultCallback:^(NSError *fault) {
                                     [[[UIAlertView alloc] initWithTitle:@"Uh oh"
                                                                 message:fault.localizedDescription
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] show];
         }];
        
    }
}

#pragma mark - Actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)fetchFollowing {
    if (self.userToken.length == 0) {
        [MeetManager fetchFollowingWithCompletionHandler:^(NSArray *following) {
            NSMutableArray *mutableFollowing = [NSMutableArray arrayWithArray:following];
            
            //sort friends
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"firstname" ascending:YES selector:@selector(caseInsensitiveCompare:)];
            NSArray *sortedDesc = @[sort];
            [mutableFollowing sortUsingDescriptors:sortedDesc];
            
            self.followingUsers= [NSArray arrayWithArray:mutableFollowing];
            fetchedFollowing = YES;
            [self.tableView reloadData];
            
            [refreshControl endRefreshing];
        } errorHandler:^(NSError *fault) {
            [refreshControl endRefreshing];
        }];
    }
    else {
        [MeetManager fetchFollowingWithUserToken:self.userToken
                               completionHandler:^(NSArray *following) {
                                   NSMutableArray *mutableFollowing = [NSMutableArray arrayWithArray:following];
                                   
                                   //sort friends
                                   NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"firstname" ascending:YES selector:@selector(caseInsensitiveCompare:)];
                                   NSArray *sortedDesc = @[sort];
                                   [mutableFollowing sortUsingDescriptors:sortedDesc];
                                   
                                   self.followingUsers= [NSArray arrayWithArray:mutableFollowing];
                                   fetchedFollowing = YES;
                                   [self.tableView reloadData];
                                   
                                   [refreshControl endRefreshing];
                               } errorHandler:^(NSError *fault) {
                                   [refreshControl endRefreshing];
                               }];
    }
}

- (void)unfollowUser:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unfollow user", nil)
                                                        message:NSLocalizedString(@"Are you sure that you want to unfollow this user?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Unfollow", nil), nil];
    alertView.tag = [sender tag];
    [alertView show];
}

- (void)showProfile:(id)sender {
    int tag = (int)[sender tag];
    Friend * user = self.followingUsers[tag];
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:user.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)removeFriendAtIndex:(NSInteger)index {
    if (index < self.followingUsers.count) {
        NSMutableArray *mutableFollowing = [NSMutableArray arrayWithArray:self.followingUsers];
        [mutableFollowing removeObjectAtIndex:index];
        
        self.followingUsers = [NSArray arrayWithArray:mutableFollowing];
        
        // Remove friend cell
        NSArray *deleteIndexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        // Reload table
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.35];
    }
}

@end
