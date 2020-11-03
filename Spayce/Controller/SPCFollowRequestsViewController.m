//
//  SPCFollowRequestsViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 4/7/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCFollowRequestsViewController.h"
#import "SPCProfileViewController.h"

#import "MeetManager.h"
#import "SPCFollowRequestCollectionViewCell.h"

static NSString *FollowerRequestCellId = @"FollowerRequestCellId";
static NSString *LoadingCellId = @"LoadingCellId";


@interface SPCFollowRequestsViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UILabel *titleLbl;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign) BOOL isFetching;
@property (nonatomic, strong) NSString *nextPageKey;

@property (nonatomic, strong) NSArray *loadedRequests;

@end

@implementation SPCFollowRequestsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController.navigationBar setHidden:YES];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //top nav - back, title, lbl,
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.titleLbl];
    
    [self.view addSubview:self.collectionView];
    [self fetchRequests];
    
    [self.collectionView registerClass:[SPCFollowRequestCollectionViewCell class] forCellWithReuseIdentifier:FollowerRequestCellId];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:LoadingCellId];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.alpha = 0.0;
}

#pragma mark Accessor

-(UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 15, 60, 60)];
        [_backBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchDown];
        [_backBtn setBackgroundImage:[UIImage imageNamed:@"mamBackToCapture"] forState:UIControlStateNormal];
        [_backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return _backBtn;
}

-(UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl  = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width - 140, 50)];
        _titleLbl.text = @"Follow Requests";
        _titleLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:16];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.textColor = [UIColor blackColor];
        _titleLbl.center = CGPointMake(self.view.bounds.size.width/2, _titleLbl.center.y);
    }
    return _titleLbl;
}

-(UICollectionView *)collectionView {
    
    if (!_collectionView) {
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 70, self.view.bounds.size.width, self.view.bounds.size.height - 70) collectionViewLayout:flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        [_collectionView setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0]];
    }
    
    return _collectionView;
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.loadedRequests count] + (self.nextPageKey ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView customCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCFollowRequestCollectionViewCell *cell = (SPCFollowRequestCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:FollowerRequestCellId forIndexPath:indexPath];
    
    if (indexPath.item < self.loadedRequests.count) {
        [cell configureWithPerson:self.loadedRequests[indexPath.item]];
        cell.acceptBtn.tag = indexPath.item;
        cell.declineBtn.tag = indexPath.item;
        cell.authorBtn.tag = indexPath.item;
        cell.tag = indexPath.item;
    
        [cell.authorBtn addTarget:self action:@selector(showProfileTap:) forControlEvents:UIControlEventTouchUpInside];
        [cell.acceptBtn addTarget:self action:@selector(handleAcceptButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [cell.declineBtn addTarget:self action:@selector(handleDeclineButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView loadingCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:LoadingCellId forIndexPath:indexPath];
    UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView *)[cell viewWithTag:111];
    if (indicatorView) {
        [indicatorView startAnimating];
    } else {
        cell.backgroundColor = [UIColor clearColor];
        
        indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.tag = 111;
        indicatorView.color = [UIColor grayColor];
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:indicatorView];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        
        [indicatorView startAnimating];
    }
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loadedRequests.count > 6 && indexPath.item + 6 >= self.loadedRequests.count && self.nextPageKey) {
        [self fetchMoreRequests];
    }
    return [self collectionView:collectionView customCellForItemAtIndexPath:indexPath];
    
    if (indexPath.item < self.loadedRequests.count) {
        return [self collectionView:collectionView customCellForItemAtIndexPath:indexPath];
    } else {
        return [self collectionView:collectionView loadingCellForItemAtIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    float itemWidth = self.view.bounds.size.width / 3;
    float itemHeight = 160;
    
    return CGSizeMake(itemWidth, itemHeight);
}


#pragma mark Private

-(void)reloadData {
    [self.collectionView reloadData];
}


-(void)fetchRequests {
    
    if (self.isFetching) {
        return;
    }

    self.isFetching = YES;
    
    __weak typeof(self)weakSelf = self;

    
    [MeetManager fetchFollowerRequestsWithPageKey:nil
                                completionHandler:^(NSArray *followerRequests, NSString *nextPageKey) {
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    if (!strongSelf) {
                                        return ;
                                    }
                                    
                                    strongSelf.loadedRequests = followerRequests;
                                    strongSelf.nextPageKey = nextPageKey;
                                    strongSelf.isFetching = NO;
                                    [strongSelf reloadData];
        
                                }
                                     errorHandler:^(NSError *error) {
                                         
                                         __strong typeof(weakSelf) strongSelf = weakSelf;
                                         if (!strongSelf) {
                                             return ;
                                         }
                                         
                                         strongSelf.isFetching = NO;
                                     }];
}

-(void)fetchMoreRequests {
    if (self.isFetching || !self.nextPageKey) {
        return;
    }
    
    self.isFetching = YES;
    
    __weak typeof(self)weakSelf = self;
    
    NSLog(@"fetch more requests!");
    
    [MeetManager fetchFollowerRequestsWithPageKey:self.nextPageKey
                                completionHandler:^(NSArray *followerRequests, NSString *nextPageKey) {
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    if (!strongSelf) {
                                        return ;
                                    }
                                    
                                    strongSelf.loadedRequests = [strongSelf.loadedRequests arrayByAddingObjectsFromArray:followerRequests];
                                    
                                    strongSelf.nextPageKey = nextPageKey;
                                    
                                    strongSelf.isFetching = NO;
                                    [strongSelf reloadData];
                                    
                                    NSLog(@"follower requests %@",followerRequests);
                                }
                                     errorHandler:^(NSError *error) {
                                         
                                         __strong typeof(weakSelf) strongSelf = weakSelf;
                                         if (!strongSelf) {
                                             return ;
                                         }
                                         
                                         strongSelf.isFetching = NO;
                                     }];
    
}


#pragma mark Actions

-(void)cancel {
    self.tabBarController.tabBar.alpha = 1.0;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showProfileTap:(id)sender {
    
    int tag = (int)[sender tag];
    
    if (tag < self.loadedRequests.count) {
        
        Person *requestingPerson = self.loadedRequests[tag];
        
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:requestingPerson.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}

- (void)handleAcceptButtonTap:(id)sender {
    int tag = (int)[sender tag];
    
    if (tag < self.loadedRequests.count) {
        
        Person *requestingPerson = self.loadedRequests[tag];
    
        //update locally
        requestingPerson.followerStatus = FollowingStatusFollowing;
        
        //update data source
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.loadedRequests];
        [tempArray replaceObjectAtIndex:tag withObject:requestingPerson];
        self.loadedRequests = [NSArray arrayWithArray:tempArray];
        
        //find & update cell
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:tag inSection:0];
        SPCFollowRequestCollectionViewCell *cell = (SPCFollowRequestCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell configureWithPerson:requestingPerson];
        
        __weak typeof(self)weakSelf = self;
        
        [MeetManager acceptFollowRequestWithUserToken:requestingPerson.userToken completionHandler:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return ;
            }
    
            //TODO correct local display in case of fault?
            
            
        } errorHandler:^(NSError *error) {
            //[UIAlertView showError:error];
        }];
    }
}

- (void)handleDeclineButtonTap:(id)sender {
    int tag = (int)[sender tag];
    
    if (tag < self.self.loadedRequests.count) {
        
        //Get the request
        Person *requestingPerson = self.loadedRequests[tag];
    
        //Disable interaction during update
        self.collectionView.userInteractionEnabled = NO;

        //Handle local update
        [self.collectionView performBatchUpdates:^{
            
            // Delete the request from the data source.
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.loadedRequests];
            [tempArray removeObjectAtIndex:tag];
            self.loadedRequests = [NSArray arrayWithArray:tempArray];
            
            // Now delete the item from the collection view.
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:tag inSection:0];
            NSMutableArray *indexArray = [[NSMutableArray alloc] init];
            [indexArray addObject:indexPath];
            [self.collectionView deleteItemsAtIndexPaths:indexArray];
            
            // Update remaining button tags to account for delete
            for (int i = 0; i < self.loadedRequests.count; i++) {
                NSIndexPath *tempPath = [NSIndexPath indexPathForItem:i inSection:0];
                SPCFollowRequestCollectionViewCell *cell = (SPCFollowRequestCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:tempPath];
                
                if (cell.tag > tag ) {
                    cell.acceptBtn.tag = cell.acceptBtn.tag - 1;
                    cell.declineBtn.tag = cell.declineBtn.tag - 1;
                    cell.authorBtn.tag = cell.authorBtn.tag - 1;
                    cell.tag = cell.tag - 1;
                }
            }
          
            
        } completion:^(BOOL completeion){
            //re-enable interaction
            self.collectionView.userInteractionEnabled = YES;
        }];
        
        __weak typeof(self)weakSelf = self;
        [MeetManager rejectFollowRequestWithUserToken:requestingPerson.userToken completionHandler:^{

            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return ;
            }
          
        } errorHandler:^(NSError *error) {
           // [UIAlertView showError:error];
        }];
    }
}


@end
