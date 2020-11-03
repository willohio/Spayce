//
//  SPCAdminSockPuppetChooserViewController.m
//  Spayce
//
//  Created by Jake Rosin on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCAdminSockPuppetChooserViewController.h"

// Controller
#import "SPCProfileViewController.h"
#import "SPCAlertViewController.h"

// Manager
#import "AdminManager.h"
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"

// View
#import "SPCFriendsListCell.h"
#import "SPCAlertAction.h"

// Model
#import "User.h"
#import "UserProfile.h"
#import "ProfileDetail.h"
#import "Person.h"
#import "Asset.h"

// Utils
#import "UIAlertView+SPCAdditions.h"
#import "UITableView+SPXRevealAdditions.h"

@interface SPCAdminSockPuppetChooserViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) SPCAdminSockPuppetAction adminSockPuppetAction;
@property (nonatomic, strong) NSObject *adminSockPuppetActionObject;

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *puppets;
@property (nonatomic, strong) NSString *nextPageKey;
@property (nonatomic, assign) BOOL morePuppets;
@property (nonatomic, assign) BOOL isFetching;

@end


@implementation SPCAdminSockPuppetChooserViewController


- (instancetype)initWithSockPuppetAction:(SPCAdminSockPuppetAction)action object:(NSObject *)object {
    self = [super init];
    if (self) {
        self.adminSockPuppetAction = action;
        self.adminSockPuppetActionObject = object;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add subviews
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.tableView];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    
    // Fetch the first set of puppets...
    [self fetchMorePuppets];
    
    // display...
    [self.tableView reloadData];
}


#pragma mark accessors

- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 64)];
        _navBar.backgroundColor = [UIColor whiteColor];
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 20.0, 60.0, 44.0)];
        [backButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [backButton.titleLabel setFont:[UIFont spc_regularSystemFontOfSize:14]];
        backButton.backgroundColor = [UIColor clearColor];
        [backButton setTitleColor:[UIColor colorWithRGBHex:0x6ab1fb] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = [SPCAdminSockPuppetChooserViewController titleCapitalizedForAction:self.adminSockPuppetAction];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont spc_boldSystemFontOfSize:16];
        titleLabel.frame = CGRectMake(CGRectGetMaxX(backButton.frame), 42 - titleLabel.font.lineHeight/2, CGRectGetWidth(self.view.frame) - CGRectGetMaxX(backButton.frame)*2, titleLabel.font.lineHeight);
        titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
        
        [_navBar addSubview:backButton];
        [_navBar addSubview:titleLabel];
    }
    return _navBar;
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.navBar.frame))];
        
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor colorWithRGBHex:0xe6e7e7];
        
        if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            _tableView.layoutMargins = UIEdgeInsetsZero;
        }
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}



#pragma mark helpers

+ (NSString *)titleForAction:(SPCAdminSockPuppetAction)action {
    NSString *title;
    switch (action) {
        case SPCAdminSockPuppetActionStar:
            title = NSLocalizedString(@"Star as..", nil);
            break;
        case SPCAdminSockPuppetActionUnstar:
            title = NSLocalizedString(@"Unstar as...", nil);
            break;
        case SPCAdminSockPuppetActionStarComment:
            title = NSLocalizedString(@"Star comment as...", nil);
            break;
        case SPCAdminSockPuppetActionUnstarComment:
            title = NSLocalizedString(@"Unstar comment as...", nil);
            break;
        case SPCAdminSockPuppetActionComment:
            title = NSLocalizedString(@"Comment as...", nil);
            break;
    }
    return title;
}

+ (NSString *)titleCapitalizedForAction:(SPCAdminSockPuppetAction)action {
    NSString *title;
    switch (action) {
        case SPCAdminSockPuppetActionStar:
            title = NSLocalizedString(@"STAR AS...", nil);
            break;
        case SPCAdminSockPuppetActionUnstar:
            title = NSLocalizedString(@"UNSTAR AS...", nil);
            break;
        case SPCAdminSockPuppetActionStarComment:
            title = NSLocalizedString(@"STAR COMMENT AS...", nil);
            break;
        case SPCAdminSockPuppetActionUnstarComment:
            title = NSLocalizedString(@"UNSTAR COMMENT AS...", nil);
            break;
        case SPCAdminSockPuppetActionComment:
            title = NSLocalizedString(@"COMMENT AS...", nil);
            break;
    }
    return title;
}



#pragma mark actions


- (void)fetchMorePuppets {
    if (self.isFetching) {
        return;
    }
    
    self.morePuppets = YES;
    self.isFetching = YES;
    
    __weak typeof(self) weakSelf = self;
    [[AdminManager sharedInstance] fetchSockPuppetListPageWithPageKey:self.nextPageKey completionHandler:^(NSArray *puppets, NSString *nextPageKey) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf.puppets) {
            strongSelf.puppets = puppets;
        } else {
            strongSelf.puppets = [self.puppets arrayByAddingObjectsFromArray:puppets];
        }
        strongSelf.nextPageKey = nextPageKey;
        
        strongSelf.isFetching = NO;
        strongSelf.morePuppets = nextPageKey != nil;
        
        [strongSelf.tableView reloadData];
        
    } errorHandler:^(NSError *error) {
        [UIAlertView showError:error];
    }];
}


- (void)imageButtonTapped:(id)button {
    UIView *buttonView = (UIView *)button;
    Person *person = self.puppets[buttonView.tag];
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:person.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}


- (void)cancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adminSockPuppetChooserViewControllerDidCancel:)]) {
        [self.delegate adminSockPuppetChooserViewControllerDidCancel:self];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.morePuppets ? self.puppets.count + 1 : self.puppets.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75;
}

- (UITableViewCell *)tableView:(UITableView *)tableView puppetCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PuppetListCell";
    
    SPCFriendsListCell *cell = (SPCFriendsListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[SPCFriendsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.tag = -1;
    }
    
    Person *person = self.puppets[indexPath.row];
    [cell configureWithPerson:person url:[NSURL URLWithString:person.imageAsset.imageUrlThumbnail]];
    
    // set button actions
    [cell.imageButton addTarget:self action:@selector(imageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    cell.imageButton.tag = indexPath.row;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView placeHolderCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PlaceHolder";
    static NSInteger ActivityIndicatorTag = 11100;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.color = [UIColor grayColor];
        activityIndicator.center = CGPointMake(CGRectGetMidX(cell.frame), CGRectGetMidY(cell.frame));
        activityIndicator.tag = ActivityIndicatorTag;
        [cell.contentView addSubview:activityIndicator];
    }
    cell.textLabel.text = @"";
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12.0f];
    cell.textLabel.textColor = [UIColor grayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:ActivityIndicatorTag];
    [activityIndicator startAnimating];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.puppets.count) {
        return [self tableView:self.tableView puppetCellForRowAtIndexPath:indexPath];
    } else {
        return [self tableView:tableView placeHolderCellForRowAtIndexPath:indexPath];
        [self fetchMorePuppets];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.puppets.count) {
        Person *person = self.puppets[indexPath.row];
        if (self.delegate && [self.delegate respondsToSelector:@selector(adminSockPuppetChooserViewController:didChoosePuppet:forAction:object:)]) {
            [self.delegate adminSockPuppetChooserViewController:self didChoosePuppet:person forAction:self.adminSockPuppetAction object:self.adminSockPuppetActionObject];
        }
    }
}


#pragma mark Optional selection

+ (void)allowSockPuppetSelectionIfAdminForAction:(SPCAdminSockPuppetAction)adminSockPuppetAction object:(NSObject *)object withNavigationController:(UINavigationController *)navigationController transitioningDelegate:(id<UIViewControllerTransitioningDelegate>)transitioningDelegate delegate:(id<SPCAdminSockPuppetChooserViewControllerDelegate>)delegate defaultBlock:(void (^)())defaultBlock {
    
    User *user = [AuthenticationManager sharedInstance].currentUser;
    UserProfile *userProfile = [ContactAndProfileManager sharedInstance].profile;
    
    if (user.isAdmin) {
        // allow the user the option...
        SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
        alertViewController.modalPresentationStyle = UIModalPresentationCustom;
        alertViewController.alertTitle = [SPCAdminSockPuppetChooserViewController titleForAction:adminSockPuppetAction];
        alertViewController.transitioningDelegate = transitioningDelegate;
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ %@", userProfile.profileDetail.firstname, userProfile.profileDetail.lastname] style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            
            if (defaultBlock) {
                defaultBlock();
            }
            
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Sock Puppet", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:adminSockPuppetAction object:object];
            vc.delegate = delegate;
            [navigationController pushViewController:vc animated:YES];
            
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
        
        [navigationController presentViewController:alertViewController animated:YES completion:nil];
    } else {
        if (defaultBlock) {
            defaultBlock();
        }
    }
    
}


@end
