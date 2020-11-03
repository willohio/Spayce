//
//  SPCTagFriendsViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 5/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTagFriendsViewController.h"

// Model
#import "Friend.h"
#import "Memory.h"

// View
#import "AddFriendsCollectionViewCell.h"
#import "DAKeyboardControl.h"
#import "LargeBlockingProgressView.h"
#import "SPCSearchBar.h"

// Category
#import "SPCSearchTextField.h"

// Manager
#import "MeetManager.h"
#import "SPCColorManager.h"

static NSString *CollectionViewCellIdentifier = @"FriendCell";
static NSString *LoadingViewCellIdentifier = @"LoadingCell";

@interface SPCTagFriendsViewController ()

@property (nonatomic, strong) NSArray *loadedFriendsArray;
@property (nonatomic, strong) NSString *nextPageKey;
@property (nonatomic, strong) NSString *currentSearchTerm;
@property (nonatomic, assign) BOOL isFetching;
@property (nonatomic, assign) NSInteger fetchNumber;

@property (nonatomic, strong) NSString *searchFilter;

@property (nonatomic, strong) NSArray *initialSelectedFriendsArray;
@property (nonatomic, strong) NSArray *selectedFriendsArray;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (strong, nonatomic) LargeBlockingProgressView *progressView;
@property (nonatomic, strong) UIView *textFieldBackgroundView;
@property (nonatomic, strong) SPCSearchTextField *textField;
@property (nonatomic, strong) NSOperationQueue *searchOperationQueue;
@property (nonatomic, strong) UIActivityIndicatorView *loader;

@end

@implementation SPCTagFriendsViewController


#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    // Cancel any previous requests that were set to execute on a delay!!
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self.view removeKeyboardControl];
}

- (id)initWithSelectedFriends:(NSArray *)selectedFriends {
    self = [super init];
    if (self) {
        self.selectedFriendsArray = selectedFriends;
        self.initialSelectedFriendsArray = selectedFriends;
    }
    return self;
}

- (instancetype)initWithMemory:(Memory *)memory {
    self = [super init];
    if (self) {
        _memory = memory;
        _selectedFriendsArray = memory.taggedUsers;
        _initialSelectedFriendsArray = memory.taggedUsers;
    }
    return self;
}

#pragma mark - Accessors

-(UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 60)];
        _navBar.backgroundColor = [UIColor whiteColor];
        _navBar.hidden = NO;
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        closeButton.titleLabel.font = [UIFont spc_mediumSystemFontOfSize: 14];
        closeButton.layer.cornerRadius = 2;
        closeButton.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : closeButton.titleLabel.font,
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Back" attributes:backStringAttributes];
        [closeButton setAttributedTitle:backString forState:UIControlStateNormal];
        closeButton.frame = CGRectMake(0, CGRectGetHeight(_navBar.frame) - 44.0f, 60, 44);
        closeButton.center = CGPointMake(closeButton.center.x, 30);
        [closeButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        titleLabel.text = NSLocalizedString(@"Tag Followers", nil);
        CGSize sizeOfTitle = [titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : titleLabel.font }];
        titleLabel.frame = CGRectMake(0, 0, sizeOfTitle.width, sizeOfTitle.height);
        titleLabel.center = CGPointMake(CGRectGetMidX(_navBar.frame), 30);
        titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
        
        self.doneBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        self.doneBtn.backgroundColor = [UIColor colorWithRed:106.0/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        self.doneBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        self.doneBtn.layer.cornerRadius = 2;
        self.doneBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [self.doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.doneBtn setTitle:@"Save" forState:UIControlStateNormal];
        CGSize sizeOfSaveButtonText = [self.doneBtn.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.doneBtn.titleLabel.font }];
        self.doneBtn.frame = CGRectMake(0, 0, sizeOfSaveButtonText.width + 30, sizeOfSaveButtonText.height + 16); // 11f padding on all four sides
        self.doneBtn.center = CGPointMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.doneBtn.frame) / 2 - 10, 30);
        [self.doneBtn addTarget:self action:@selector(doneSelectingFriends) forControlEvents:UIControlEventTouchUpInside];
        self.doneBtn.enabled = YES;
        self.doneBtn.alpha = 1.0f;
        
        [_navBar addSubview:closeButton];
        [_navBar addSubview:titleLabel];
        [_navBar addSubview:self.doneBtn];
    }
    return _navBar;
}

-(UICollectionView *)collectionView {
    if (!_collectionView){
        
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 5;
        CGRect collectionFrame = CGRectMake(0, 60, self.view.bounds.size.width, self.view.bounds.size.height - 106.0);
        
        _collectionView=[[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:layout];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        _collectionView.allowsMultipleSelection = YES;
        
        [_collectionView setBackgroundColor:[UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0]];
    }
    return _collectionView;
}

- (LargeBlockingProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[LargeBlockingProgressView alloc] initWithFrame:self.navigationController.view.frame];
        _progressView.label.text = @"One moment";
    }
    return _progressView;
}

- (UIView *)textFieldBackgroundView {
    if (!_textFieldBackgroundView) {
        _textFieldBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-46, CGRectGetWidth(self.view.frame), 46)];
        _textFieldBackgroundView.backgroundColor = [UIColor whiteColor];
        
        UIView *outlineView = [[UIView alloc] initWithFrame:CGRectMake(13, 8, self.view.bounds.size.width - 26, 29)];
        outlineView.backgroundColor = [UIColor colorWithWhite:250.0f/255.0f alpha:1.0f];
        outlineView.layer.borderColor = [UIColor colorWithRed:199.0f/255.0f green:199.0f/255.0f  blue:204.0f/255.0f  alpha:1.0f].CGColor;
        outlineView.layer.borderWidth = 1;
        outlineView.layer.cornerRadius = 4;
        [_textFieldBackgroundView addSubview:outlineView];
        
        UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 1)];
        sepView.backgroundColor = [UIColor colorWithRed:203.0f/255.0f green:206.0f/255.0f blue:208.0f/255.0f alpha:1.0f];
        [_textFieldBackgroundView addSubview:sepView];
        
    }
    return _textFieldBackgroundView;
}

- (SPCSearchTextField *)textField {
    if (!_textField) {
        _textField = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height-37, CGRectGetWidth(self.view.frame)-40, 29)];
        _textField.delegate = self;
        _textField.backgroundColor = [UIColor clearColor];
        _textField.textColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000f];
        _textField.tintColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000f];
        _textField.font = [UIFont spc_regularSystemFontOfSize:17];
        _textField.placeholder = @"Search followers";
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.returnKeyType = UIReturnKeySearch;
        _textField.leftView = nil;
        _textField.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:205.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:17] };
    }
    return _textField;
}

- (NSOperationQueue *)searchOperationQueue {
    if (!_searchOperationQueue) {
        _searchOperationQueue = [[NSOperationQueue alloc] init];
        _searchOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _searchOperationQueue;
}

- (UIActivityIndicatorView *)loader {
    
    if (!_loader) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
        indicatorView.tag = 111;
        indicatorView.color = [UIColor grayColor];
        [indicatorView startAnimating];
        _loader = indicatorView;
    }
    
    return _loader;
}

#pragma mark - UIViewController - Managing the View

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.loader];
    [self.loader startAnimating];
    [self fetchFollowers];
    
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.doneBtn];
    [self.view addSubview:self.textFieldBackgroundView];
    [self.view addSubview:self.textField];

    
    self.view.keyboardTriggerOffset = 45.0f;
    
    UITextField *textField = self.textField;
    UIView *textFieldBGView = self.textFieldBackgroundView;
    UICollectionView *tempCollection = self.collectionView;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        
        CGRect toolBarFrame = textFieldBGView.frame;
        toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
        textFieldBGView.frame = toolBarFrame;
        textField.center = CGPointMake(textField.center.x,textFieldBGView.center.y);
        
        CGRect collectionFrame = tempCollection.frame;
        collectionFrame.size.height = toolBarFrame.origin.y-64;
        tempCollection.frame = collectionFrame;
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[AddFriendsCollectionViewCell class] forCellWithReuseIdentifier:CollectionViewCellIdentifier];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:LoadingViewCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

-(void)updateForCall {
    
    self.textField.frame = CGRectMake(20, self.view.bounds.size.height-57, CGRectGetWidth(self.view.frame)-40, 29);
    self.textFieldBackgroundView.frame = CGRectMake(0, self.view.bounds.size.height-66, CGRectGetWidth(self.view.frame), 46);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.loadedFriendsArray count] + (self.nextPageKey ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView customCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AddFriendsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellIdentifier forIndexPath:indexPath];
    
    Friend *tempFriend = self.loadedFriendsArray[indexPath.item];
    
    [cell configureWithFriend:tempFriend];
    
    for (int i = 0; i < [self.selectedFriendsArray count]; i++){
        if ([tempFriend.userToken isEqual:[self.selectedFriendsArray[i] userToken]]) {
            [cell includeFriend:YES];
            break;
        }
    }
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView loadingCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:LoadingViewCellIdentifier forIndexPath:indexPath];
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
    if (indexPath.item + 6 >= self.loadedFriendsArray.count && self.nextPageKey) {
        [self fetchMoreFollowers];
    }
    
    if (indexPath.item < self.loadedFriendsArray.count) {
        return [self collectionView:collectionView customCellForItemAtIndexPath:indexPath];
    } else {
        return [self collectionView:collectionView loadingCellForItemAtIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    // 3.5" & 4" screens
    float itemWidth = 100;
    float itemHeight = 120;
    
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        itemWidth = 118;
        itemHeight = 140;
    }
    
    //5"
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        itemWidth = 131;
        itemHeight = 157;
    }
    
    if (indexPath.item < self.loadedFriendsArray.count) {
        return CGSizeMake(itemWidth, itemHeight);
    } else {
        int cellSpan = 3 - (indexPath.item % 3);
        return CGSizeMake(cellSpan * itemWidth, itemHeight);
    }
    
    // loading spinner...
    return CGSizeMake(CGRectGetWidth(self.view.frame), 80);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item < self.loadedFriendsArray.count) {
        AddFriendsCollectionViewCell *selectedCell = (AddFriendsCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        BOOL currentlyIncluded = [selectedCell friendIsIncluded];
        
        if (!currentlyIncluded) {
            
            if (self.selectedFriendsArray.count < 10) {
                [selectedCell includeFriend:YES];
                
                Friend *tempFriend = self.loadedFriendsArray[indexPath.item];
                
                NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedFriendsArray];
                [tempArray addObject:tempFriend];
                self.selectedFriendsArray = [NSArray arrayWithArray:tempArray];
            }
            else {
                [self displayMaxTaggedFriendsAlert];
            }
        }
        else {
            [selectedCell includeFriend:NO];
            selectedCell.layer.borderWidth = 0;
            
            Friend *tempFriend = self.loadedFriendsArray[indexPath.item];
            
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedFriendsArray];
            [tempArray removeObject:tempFriend];
            self.selectedFriendsArray = [NSArray arrayWithArray:tempArray];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    AddFriendsCollectionViewCell *selectedCell = (AddFriendsCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    BOOL currentlyIncluded = [selectedCell friendIsIncluded];
    
    if (!currentlyIncluded) {
        
        if (self.selectedFriendsArray.count < 10) {
            [selectedCell includeFriend:YES];
            
            Friend *tempFriend = self.loadedFriendsArray[indexPath.item];
            
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedFriendsArray];
            [tempArray addObject:tempFriend];
            self.selectedFriendsArray = [NSArray arrayWithArray:tempArray];
        }
        else {
            [self displayMaxTaggedFriendsAlert];
        }
    }
    else {
        [selectedCell includeFriend:NO];
        selectedCell.layer.borderWidth = 0;
        Friend *tempFriend = self.loadedFriendsArray[indexPath.item];
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedFriendsArray];
        [tempArray removeObject:tempFriend];
        self.selectedFriendsArray = [NSArray arrayWithArray:tempArray];
    }
}

#pragma mark - UITextFieldDelegate - Editing the Text Field’s Text

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self filterContentForSearchText];
        [self.textField resignFirstResponder];
        return NO;
    }
   
    //NSLog(@"newText %@",newText);
    
    // Cancel previous filter request
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // Schedule delayed filter request in order to allow textField to update it's internal state
    [self performSelector:@selector(filterContentForSearchText) withObject:nil afterDelay:.5];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyDefault) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

#pragma mark - Private

-(void)fetchFollowers {

    if (self.isFetching) {
        return;
    }
    
    if (self.loadedFriendsArray.count == 0) {
        [self startLoadingProgressView:@"Loading ..."];
        self.loader.hidden = NO;
    }
    
    self.fetchNumber++;
    self.isFetching = YES;

    __weak typeof(self)weakSelf = self;
    NSString *partialSearch = self.textField.text;
    NSInteger fetchNumber = self.fetchNumber;
    [MeetManager fetchFollowersWithPartialSearch:partialSearch pageKey:nil completionHandler:^(NSArray *followers, NSString *nextPageKey) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.fetchNumber != fetchNumber) {
            return ;
        }
        
        strongSelf.loadedFriendsArray = followers;
        strongSelf.nextPageKey = nextPageKey;
        strongSelf.currentSearchTerm = partialSearch;
        strongSelf.isFetching = NO;
        [strongSelf stopLoadingProgressView];
        strongSelf.loader.hidden = YES;
        [strongSelf reloadData];
        
    } errorHandler:^(NSError *error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf || strongSelf.fetchNumber != fetchNumber) {
            return ;
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                            message:@"There was an error retrieving friends to tag. Please check your connection and try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        strongSelf.loader.hidden = YES;
        strongSelf.isFetching = NO;
        [strongSelf stopLoadingProgressView];
    }];
}

-(void)fetchMoreFollowers {
    if (self.isFetching || !self.nextPageKey) {
        return;
    }
    
    self.isFetching = YES;
    
    __weak typeof(self)weakSelf = self;
    NSString *partialSearch = self.currentSearchTerm;
    NSInteger fetchNumber = self.fetchNumber;
    [MeetManager fetchFollowersWithPartialSearch:partialSearch pageKey:self.nextPageKey completionHandler:^(NSArray *followers, NSString *nextPageKey) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.fetchNumber != fetchNumber) {
            return ;
        }
        
        strongSelf.loadedFriendsArray = [self.loadedFriendsArray arrayByAddingObjectsFromArray:followers];
        strongSelf.nextPageKey = nextPageKey;
        strongSelf.isFetching = NO;
        [strongSelf reloadData];
        
    } errorHandler:^(NSError *error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf || strongSelf.fetchNumber != fetchNumber) {
            return ;
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                            message:@"There was an error retrieving friends to tag. Please check your connection and try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        strongSelf.isFetching = NO;
    }];
}

-(void)reloadData {
    
    if (self.loadedFriendsArray.count > 0 || self.currentSearchTerm.length > 0) {
        [self.collectionView reloadData];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh oh!"
                                                            message:@"You don't have any followers yet"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
        [self performSelector:@selector(cancel) withObject:nil afterDelay:.5];
    }
}

- (void)startLoadingProgressView:(NSString *)msg
{
    _progressView.label.text = msg;
    [self.navigationController.view addSubview:self.progressView];
    [self.progressView.activityIndicator startAnimating];
}
- (void)stopLoadingProgressView
{
    [self.progressView removeFromSuperview];
}

-(BOOL)friendsHaveChanged {
    
    if (self.selectedFriendsArray.count != self.initialSelectedFriendsArray.count) {
        return YES;
    }
    
    BOOL arraysMatch = YES;
    
    //check to see if all inital friends are currently selected
    for (int i = 0; i < self.initialSelectedFriendsArray.count; i++) {
        Friend *friend = (Friend *)self.initialSelectedFriendsArray[i];
        
        BOOL matchFound = NO;

        for (int j = 0; j < self.selectedFriendsArray.count; j++) {
            Friend *f = (Friend *)self.selectedFriendsArray[j];
            
            if (friend.recordID == f.recordID){
                matchFound = YES;
            }
        }
        if (!matchFound) {
            arraysMatch = NO;
            break;
        }
        
    }
    return !arraysMatch;
}

-(void)displayMaxTaggedFriendsAlert {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Hang on!"
                                                        message:@"You can tag a maximum of 10 friends in a memory"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
      [alertView show];
}

#pragma mark - Navigation actions

-(void)cancel {
    [self.searchOperationQueue cancelAllOperations];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelTaggingFriends)]){
        [self.delegate cancelTaggingFriends];
    }
    else if (self.delegate && [self.delegate respondsToSelector:@selector(tagFriendsViewControllerDidCancel:)]) {
        [self.delegate tagFriendsViewControllerDidCancel:self];
    }
}

-(void)doneSelectingFriends {
    [self.searchOperationQueue cancelAllOperations];
    
    if (self.memory) {
        self.memory.taggedUsers = self.selectedFriendsArray;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(tagFriendsViewController:finishedPickingFriends:)]){
            [self.delegate tagFriendsViewController:self finishedPickingFriends:self.selectedFriendsArray];
        }
        else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(pickedFriends:)]){
                [self.delegate pickedFriends:self.selectedFriendsArray];
            }
        }
    }
    else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(pickedFriends:)]){
            [self.delegate pickedFriends:self.selectedFriendsArray];
        }
    }
}

#pragma mark - Content filtering

- (void)filterContentForSearchText {
    self.searchFilter = self.textField.text;
    
    if (!self.searchFilter || self.searchFilter.length == 0) {
        // no search...
        // TODO restore the original first page?
        if (self.currentSearchTerm && self.currentSearchTerm.length > 0) {
            self.nextPageKey = nil;
            self.isFetching = NO;
            [self fetchFollowers];
        }
    } else {
        // Perform this search
        if (!self.currentSearchTerm || self.currentSearchTerm.length == 0 || ![self.currentSearchTerm isEqualToString:self.searchFilter]) {
            self.nextPageKey = nil;
            self.isFetching = NO;
            [self fetchFollowers];
        }
    }
}


#pragma  mark - Orientation Methods

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
@end
