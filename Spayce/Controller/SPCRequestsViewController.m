//
//  SPCRequestsViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 10/20/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

//view
#import "SPCRequestsViewController.h"
#import "SPCFriendRequestCell.h"
#import "SPCNoSearchResultsCell.h"

//model
#import "SpayceNotification.h"
#import "User.h"
#import "Friend.h"

//manager
#import "PNSManager.h"

//controller
#import "SPCProfileViewController.h"

// Category
#import "UITabBarController+SPCAdditions.h"

@interface SPCRequestsViewController ()

@property (nonatomic, strong) NSArray *requests;
@property (nonatomic, strong) NSArray *initialRequests;
@property (nonatomic, strong) NSArray *acceptedRequests;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation SPCRequestsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];

    [self.tableView registerClass:[SPCFriendRequestCell class] forCellReuseIdentifier:@"request"];
    [self.tableView registerClass:[SPCNoSearchResultsCell class] forCellReuseIdentifier:@"placeholder"];
    
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.requests = [NSArray arrayWithArray:[PNSManager sharedInstance].friendRequests];
    self.initialRequests = [NSArray arrayWithArray:[PNSManager sharedInstance].allFriendRequests];
    
    
    //NSLog(@"self.requests %@",self.requests);
    [self reloadData];
    
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.alpha = 0.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PNSManager sharedInstance] markAsReadFriendRequests];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.tabBarController.tabBar.alpha = 1.0;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (UITableView *)tableView {
    if (!_tableView) {
        // It's necessary to add an artificial separator, since there is a separator at the top of the FindFriendsContainerViewController.h, which neighbors this SPCRequestsViewController
        CGFloat topSpacing = 1.0f / [UIScreen mainScreen].scale; // artificial separator
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topSpacing, self.view.bounds.size.width, self.view.bounds.size.height)];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
    }
    return _tableView;
}

#pragma mark UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.requests.count > 0) {
        return self.requests.count;
    }
    else {
        return 1;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView friendRequestCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCFriendRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"request" forIndexPath:indexPath];
    if (!cell) {
        cell = [[SPCFriendRequestCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"request"];
    }
    Friend *friendRequestFromPerson = (Friend *)[self.requests objectAtIndex:indexPath.row];
    cell.tag = indexPath.row;
    cell.imageButton.tag = friendRequestFromPerson.recordID;
    cell.viewProfileBtn.tag = friendRequestFromPerson.recordID;
    
    [cell.imageButton addTarget:self action:@selector(handleProfileImageTap:) forControlEvents:UIControlEventTouchUpInside];
    [cell.viewProfileBtn addTarget:self action:@selector(handleProfileImageTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell configureWithRequest:friendRequestFromPerson];
    cell.delegate = self;
    cell.backgroundColor = [UIColor clearColor];
    
    NSInteger requestID = friendRequestFromPerson.recordID;
    NSNumber *reqID = @(requestID);
    
    for (int i = 0; i < self.acceptedRequests.count; i++) {
        NSNumber *testId = self.acceptedRequests[i];
        if (testId == reqID) {
            [cell updateCellForNewFriendship];
            break;
        }
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView placeholderCellForRowAtIndexPath:(NSIndexPath *)indexPath {

    SPCNoSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"placeholder" forIndexPath:indexPath];
    if (!cell) {
        cell = [[SPCNoSearchResultsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"placeholder"];
    }
    
    cell.noFriendsResult = YES;
    cell.msgLbl.text = @"No friend requests.";
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.requests.count > 0) {
        return [self tableView:tableView friendRequestCellForRowAtIndexPath:indexPath];
    }
    else {
        return [self tableView:tableView placeholderCellForRowAtIndexPath:indexPath];
    }
    
}


#pragma mark UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    
    if (self.requests.count > 0) {
        return 95;
    }
    else {
        return self.tableView.frame.size.height;
    }
}

#pragma mark Actions

-(void)reloadData {
    [self.tableView reloadData];
}

-(void)hideRowAtIndex:(NSInteger)index {
    if (index > [self.requests count]) {
        return;
    }
    
    if (self.requests.count > 1) {
        
        [self.tableView beginUpdates];
       
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.requests];
        [tempArray removeObjectAtIndex:index];
        self.requests = [NSArray arrayWithArray:tempArray];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView endUpdates];
        
        for (int i = 0; i < self.requests.count; i ++) {
            SPCFriendRequestCell *cell = (SPCFriendRequestCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.tag = i;
        }
    }
    else {
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.requests];
        [tempArray removeObjectAtIndex:index];
        self.requests = [NSArray arrayWithArray:tempArray];
        [self reloadData];
    }
    
}

-(void)acceptedRequestWithId:(NSInteger)acceptedRequestId {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.acceptedRequests];
    NSNumber *acceptedID = @(acceptedRequestId);
    [tempArray addObject:acceptedID];
    self.acceptedRequests = [NSArray arrayWithArray:tempArray];
}

- (void)handleProfileImageTap:(id)sender {
    int tag = (int)[sender tag];

    Friend *person = [self getRequestForRecordId:tag];
    
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:person.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
    
}

#pragma mark Private

- (Friend *)getRequestForRecordId:(int)recordId {
    for (int i = 0; i < self.initialRequests.count; i++) {
        if (((Friend *)self.initialRequests[i]).recordID == recordId) {
            return self.initialRequests[i];
        }
    }
    return nil;
}

@end
