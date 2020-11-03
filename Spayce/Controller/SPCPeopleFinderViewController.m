//
//  SPCPeopleFinderViewController.m
//  Spayce
//
//  Created by Jordan Perry on 3/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCPeopleFinderViewController.h"

#import "SPCPeopleFinderCollectionViewCell.h"
#import "SPCPeopleFinderCollectionReusableView.h"
#import "SPCPeopleFinderController.h"
#import "SPCProfileViewController.h"
#import "SPCSearchTextField.h"
#import "SPCSuggestedFriendsBannerView.h"
#import "SocialProfile.h"

// Model
#import "Person.h"

// Utils
#import "UIAlertView+SPCAdditions.h"
#import "Flurry.h"


typedef NS_ENUM(NSUInteger, SPCPeopleFinderViewControllerSelectionState) {
    SPCPeopleFinderViewControllerSelectionStatePeople,
    SPCPeopleFinderViewControllerSelectionStateContacts
};

typedef NS_ENUM(NSUInteger, SPCPeopleFinderViewControllerNotSearchingSectionIndex) {
    SPCPeopleFinderViewControllerNotSearchingSectionIndexSuggestedFriends,
    SPCPeopleFinderViewControllerNotSearchingSectionIndexCoolPeopleNearby
};

@interface SPCPeopleFinderViewController ()
<
SPCPeopleFinderCollectionReusableViewDelegate,
SPCPeopleFinderCollectionViewCellDelegate,
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
UITextFieldDelegate
>

@property (nonatomic, strong) SPCPeopleFinderController *peopleFinderController;
@property (nonatomic, assign) SPCPeopleFinderViewControllerSelectionState selectionState;

@property (nonatomic, strong) UIView *headerContainerView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) SPCSearchTextField *searchTextField;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *peopleButton;
@property (nonatomic, strong) UIImageView *peopleContactSeparator;
@property (nonatomic, strong) UIButton *contactsButton;
@property (nonatomic, strong) UIView *peopleContactButtonUnderline;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) UICollectionViewFlowLayout *gridLayout;
@property (nonatomic, strong) UICollectionViewFlowLayout *tableLayout;

@property (nonatomic, strong) UIView *promptView;

@property (nonatomic, assign) CGFloat searchTextFieldOriginalOriginX;
@property (nonatomic, assign) CGFloat searchTextFieldActiveOriginX;
@property (nonatomic, assign) CGFloat searchTextFieldOriginalSizeWidth;
@property (nonatomic, assign) CGFloat searchTextFieldActiveSizeWidth;

@property (nonatomic, assign, getter=isSearching) BOOL searching;

@property (nonatomic, copy) NSString *currentSearchTerm;

@property (nonatomic, assign) BOOL isResigningDueToPush;

@end

static NSString * FinderCellIdentifier = @"SPCPeopleFinderCell";

@implementation SPCPeopleFinderViewController

#pragma mark - Creation / Destroy

- (instancetype)init {
    if ((self = [super init])) {
        _peopleFinderController = [[SPCPeopleFinderController alloc] init];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handleKeyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(handleKeyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Lifecycle

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.headerContainerView];
    [self.headerContainerView addSubview:self.headerView];
    [self.view addSubview:self.collectionView];
    [self.view sendSubviewToBack:self.collectionView];
    [self.view addSubview:self.promptView];
    [self.view addSubview:self.activityIndicatorView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self peopleButtonPressed:self.peopleButton];
}


#pragma mark - Accessors

-(UIView *)promptView {
    if (!_promptView) {
        _promptView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.headerContainerView.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.headerContainerView.frame) - 44 - 20)];
        _promptView.hidden = YES;
        
        NSString *promptText =  NSLocalizedString(@"Sync your contacts to grow\nyour network and earn 50 stars.", nil);
        NSRange styleRange = [promptText rangeOfString:@"50 stars."];
        NSRange baseRange = NSMakeRange(0, styleRange.location);
        
        NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:promptText];
        [styledText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:170.0f/255.0f alpha:1.0f] range:baseRange];
        [styledText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans" size:16] range:baseRange];
        
        [styledText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:1 green:210.0f/255.0f blue:0 alpha:1.0f] range:styleRange];
        [styledText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Bold" size:16] range:styleRange];
        
        UILabel *promptLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 20, 60)];
        promptLbl.center = CGPointMake(_promptView.frame.size.width/2, -30 + _promptView.frame.size.height/2);
        promptLbl.numberOfLines = 2;
        promptLbl.textAlignment = NSTextAlignmentCenter;
        promptLbl.lineBreakMode = NSLineBreakByWordWrapping;
        promptLbl.attributedText = styledText;
        [_promptView addSubview:promptLbl];
        
        UIButton *syncContacts = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 200)/2, CGRectGetMaxY(promptLbl.frame) + 10, 200, 45)];
        syncContacts.backgroundColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        [syncContacts setTitle:[NSLocalizedString(@"Sync Contancts", nil) uppercaseString] forState:UIControlStateNormal];
        [syncContacts setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        syncContacts.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        [syncContacts setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
        syncContacts.layer.cornerRadius = 8;
        [syncContacts setImage:[UIImage imageNamed:@"sync-refresh"] forState:UIControlStateNormal];
        [syncContacts setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        [syncContacts addTarget:self action:@selector(tryToSyncContacts) forControlEvents:UIControlEventTouchDown];
        [_promptView addSubview:syncContacts];
        
        UIImageView *contactsImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sync-contacts-icon"]];
        contactsImgView.center = CGPointMake(_promptView.frame.size.width/2, promptLbl.center.y - 70);
        [_promptView addSubview:contactsImgView];
        
    }
    
    return _promptView;
}

#pragma mark - UICollectionViewDelegate / DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (!self.isSearching) {
        if (self.selectionState == SPCPeopleFinderViewControllerSelectionStatePeople) {
            if ([self.peopleFinderController countOfCoolPeopleNearby] < 6) {
                return !![self.peopleFinderController countOfSuggestedPeople];
            }
            
            return !![self.peopleFinderController countOfSuggestedPeople] + !![self.peopleFinderController countOfCoolPeopleNearby];
        } else {
            return !![self.peopleFinderController countOfSocialProfilesInAddressBook];
        }
    } else {
        return 1;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!self.isSearching) {
        if (self.selectionState == SPCPeopleFinderViewControllerSelectionStatePeople) {
            if (section == SPCPeopleFinderViewControllerNotSearchingSectionIndexSuggestedFriends) {
                if ([self.peopleFinderController countOfCoolPeopleNearby] < 6) {
                    return MIN([self.peopleFinderController countOfSuggestedPeople], 40);
                } else {
                    return MIN([self.peopleFinderController countOfSuggestedPeople], 6);
                }
            } else {
                return 0;
            }
        } else {
            return [self.peopleFinderController countOfSocialProfilesInAddressBook];
        }
    } else {
        return [self.peopleFinderController countOfPeople] ?: [self.peopleFinderController countOfPeopleInSearchHistory];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCPeopleFinderCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:FinderCellIdentifier
                                                                                        forIndexPath:indexPath];
    cell.delegate = self;
    
    id dataObject = [self objectAtIndexPath:indexPath];
    
    if ([dataObject isKindOfClass:[Person class]]) {
        cell.person = dataObject;
    } else if ([dataObject isKindOfClass:[SocialProfile class]]) {
        cell.socialProfile = dataObject;
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        SPCPeopleFinderCollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                           withReuseIdentifier:NSStringFromClass([SPCPeopleFinderCollectionReusableView class])
                                                                                                  forIndexPath:indexPath];
        header.delegate = self;
        
        if (!self.isSearching) {
            if (self.selectionState == SPCPeopleFinderViewControllerSelectionStatePeople) {
                if (indexPath.section == 0) {
                    header.text = @"SUGGESTED PEOPLE TO FOLLOW";
                } else {
                    header.text = @"COOL PEOPLE NEARBY";
                }
            }
        } else {
            header.text = @"RECENT SEARCHES";
            header.showXButton = !![self.peopleFinderController countOfPeopleInSearchHistory];
        }
        
        return header;
    }
    
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.isSearching && [self.peopleFinderController countOfPeople]) {
        return CGSizeZero;
    }
    
    if (self.selectionState == SPCPeopleFinderViewControllerSelectionStateContacts) {
        return CGSizeZero;
    }
    
    return CGSizeMake(CGRectGetWidth(self.view.frame), 30.0);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *currentText = textField.text;
    NSString *incomingText = [currentText stringByReplacingCharactersInRange:range withString:string];
    
    CGFloat delayInSeconds = 0.0;
    if ([currentText length] && [incomingText length]) {
        delayInSeconds = 0.2;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchForPeopleWithText:) object:currentText];
    
    if (delayInSeconds >= 0) {
        [self performSelector:@selector(searchForPeopleWithText:) withObject:incomingText afterDelay:delayInSeconds];
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchForPeopleWithText:) object:textField.text];
    [self searchForPeopleWithText:@""];
    
    return YES;
}

#pragma mark - SPCPeopleFinderCollectionViewCellDelegate

- (void)peopleFinderCollectionViewCell:(SPCPeopleFinderCollectionViewCell *)cell profileImageSelectedForPerson:(Person *)person {
    self.isResigningDueToPush = YES;
    
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:person.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
    
    if (self.searching) {
        [self.peopleFinderController addPersonToSearchHistory:person];
    }
}

- (void)peopleFinderCollectionViewCell:(SPCPeopleFinderCollectionViewCell *)cell followButtonSelectedForPerson:(Person *)person {
    __weak SPCPeopleFinderCollectionViewCell *weakCell = cell;
    
    [self.peopleFinderController followOrUnfollowPerson:person
                                         withCompletion:^(NSError *error) {
                                             if (error) {
                                                 [UIAlertView showError:error];
                                             }
                                             
                                             [weakCell setNeedsLayout];
                                         }];
}

- (void)peopleFinderCollectionViewCell:(SPCPeopleFinderCollectionViewCell *)cell inviteButtonSelectedForSocialProfile:(SocialProfile *)socialProfile {
    __weak SPCPeopleFinderCollectionViewCell *weakCell = cell;
    
    [self.peopleFinderController inviteSocialProfile:socialProfile
                                      withCompletion:^(NSError *error) {
                                          if (error) {
                                              [UIAlertView showError:error];
                                          }
                                          
                                          [weakCell setNeedsLayout];
                                      }];
}

#pragma mark - SPCPeopleFinderCollectionReusableViewDelegate

- (void)didSelectXButtonForPeopleFinderReusableView:(SPCPeopleFinderCollectionReusableView *)reusableView {
    [self.peopleFinderController clearSearchHistory];
    [self.collectionView reloadData];
}

#pragma mark - Actions

- (void)backButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelButtonPressed:(UIButton *)sender {
    [self.searchTextField resignFirstResponder];
    self.searchTextField.text = @"";
    [self.peopleFinderController fetchPeopleWithText:@"" completion:nil];
}

- (void)peopleButtonPressed:(UIButton *)sender {
    
    self.promptView.hidden = YES;
    
    if ([self setSelectedPeopleOrContactsButton:sender]) {
        
        [Flurry logEvent:@"SUGGESTED_PEOPLE_TAPPED"];
        
        self.selectionState = SPCPeopleFinderViewControllerSelectionStatePeople;
        
        [self.gridLayout invalidateLayout];
        
        self.gridLayout.sectionInset = UIEdgeInsetsMake(5.0, 22.0, 5.0, 22.0);
        self.gridLayout.minimumInteritemSpacing = 28.0;
        self.gridLayout.minimumLineSpacing = 5.0;
        
        CGFloat dimension = 90.0;
        self.gridLayout.itemSize = CGSizeMake(dimension, dimension * 2.0);
        
        [self.collectionView reloadData];
        
        if (![self.peopleFinderController countOfSuggestedPeople]) {
            [self dataStartedLoading];
            
            __weak typeof(self) weakSelf = self;
            
            [self.peopleFinderController fetchSuggestedPeopleWithCompletion:^(NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                [strongSelf dataFinishedLoading];
                
                if (!error) {
                    [strongSelf.collectionView reloadData];
                }
            }];
        }
    }
}

- (void)contactsButtonPressed:(UIButton *)sender {
    
     if ([self setSelectedPeopleOrContactsButton:sender]) {
         
        [Flurry logEvent:@"CONTACTS_TAPPED"];
        self.selectionState = SPCPeopleFinderViewControllerSelectionStateContacts;
        
        [self.gridLayout invalidateLayout];
        
        self.gridLayout.sectionInset = UIEdgeInsetsZero;
        self.gridLayout.minimumInteritemSpacing = 0.0;
        self.gridLayout.minimumLineSpacing = 0.0;
        self.gridLayout.itemSize = CGSizeMake(CGRectGetWidth(self.view.frame), 70.0);
        
        [self.collectionView reloadData];
        
        //do we already have contacts?
        if (![self.peopleFinderController countOfSocialProfilesInAddressBook]) {
            
            //do we have permission?
           if ([self.peopleFinderController addressBookAccessGranted]) {
                [self syncContacts];
            }
            //show prompt if not
            else {
                self.promptView.hidden = NO;
            }
            
        }
        else {
            [self showContacts];
        }
    }
}


-(void)tryToSyncContacts {
 
    if ([self.peopleFinderController canAskForAddressBookAccess] || [self.peopleFinderController addressBookAccessGranted]) {
        [self syncContacts];
    }
    else {
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Spayce Would Like to Access Your Address Book", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy > Contacts and enable Spayce", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
    
}

-(void)syncContacts {
    
    [self dataStartedLoading];
    self.promptView.hidden = YES;
    __weak typeof(self) weakSelf = self;
    
    [self.gridLayout invalidateLayout];
    self.gridLayout.minimumInteritemSpacing = 0.0;
    self.gridLayout.minimumLineSpacing = 0.0;
    self.gridLayout.itemSize = CGSizeMake(CGRectGetWidth(self.view.frame), 70.0);
    self.gridLayout.sectionInset = UIEdgeInsetsZero;
    [self.collectionView reloadData];
    
    [self.peopleFinderController fetchAddressBookProfilesWithCompletion:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf dataFinishedLoading];
        
        if (!error) {
            [strongSelf.collectionView reloadData];
        }
        else
            if (self.selectionState == SPCPeopleFinderViewControllerSelectionStateContacts) {
            self.promptView.hidden = NO;
        }
        
    }];
}

-(void)showContacts {    
    [self.gridLayout invalidateLayout];
    self.gridLayout.minimumInteritemSpacing = 0.0;
    self.gridLayout.minimumLineSpacing = 0.0;
    self.gridLayout.itemSize = CGSizeMake(CGRectGetWidth(self.view.frame), 70.0);
    self.gridLayout.sectionInset = UIEdgeInsetsZero;
    [self.collectionView reloadData];
}

- (BOOL)setSelectedPeopleOrContactsButton:(UIButton *)peopleOrContactsButton {
    if (peopleOrContactsButton.selected) {
        return NO;
    }
    
    peopleOrContactsButton.selected = YES;
    
    UIButton *otherButton = [peopleOrContactsButton isEqual:self.peopleButton] ? self.contactsButton : self.peopleButton;
    otherButton.selected = NO;
    
    if (!self.peopleContactButtonUnderline.superview) {
        [self.headerView addSubview:self.peopleContactButtonUnderline];
    }
    
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:25.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         CGRect peopleContactButtonUnderlineFrame = self.peopleContactButtonUnderline.frame;
                         peopleContactButtonUnderlineFrame.size.width = CGRectGetWidth(peopleOrContactsButton.titleLabel.frame);
                         self.peopleContactButtonUnderline.frame = peopleContactButtonUnderlineFrame;
                         self.peopleContactButtonUnderline.center = CGPointMake(CGRectGetMidX(peopleOrContactsButton.frame), self.peopleContactButtonUnderline.center.y);
                     } completion:^(BOOL finished) {
                         
                     }];
    
    return YES;
}

- (void)searchForPeopleWithText:(NSString *)text {
    self.currentSearchTerm = text;
    
    __weak typeof(self) weakSelf = self;
    
    [self.peopleFinderController fetchPeopleWithText:text
                                          completion:^(NSError *error) {
                                              __strong typeof(weakSelf) strongSelf = weakSelf;
                                              
                                              if (!error && [strongSelf.currentSearchTerm isEqualToString:text]) {
                                                  [strongSelf.collectionView reloadData];
                                              }
    }];
}

#pragma mark - Notification Handling

- (void)handleKeyboardWillShowNotification:(NSNotification *)notification {
    if (self.isSearching) {
        return;
    }
    
    self.searching = YES;
    [self.collectionView reloadData];
    
    self.headerView.backgroundColor = [UIColor colorWithRed:76.0/255.0 green:176.0/255.0 blue:251.0/255.0 alpha:1.0];
    self.searchTextField.backgroundColor = [UIColor whiteColor];
    
    CGRect searchTextFieldFrame = self.searchTextField.frame;
    CGRect backButtonFrame = self.backButton.frame;
    CGRect cancelButtonFrame = self.cancelButton.frame;
    
    if (searchTextFieldFrame.origin.x != self.searchTextFieldActiveOriginX) {
        CGFloat deltaX = self.searchTextFieldOriginalOriginX - self.searchTextFieldActiveOriginX;
        CGFloat deltaWidth = (CGRectGetMaxX(self.cancelButton.frame) - (CGRectGetWidth(self.headerView.frame) - 10.0)) - deltaX;
        
        searchTextFieldFrame.origin.x -= deltaX;
        backButtonFrame.origin.x -= deltaX;
        cancelButtonFrame.origin.x -= (deltaX + deltaWidth);
        
        searchTextFieldFrame.size.width -= deltaWidth;
        
        CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [UIView animateWithDuration:animationDuration
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:25.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.searchTextField.frame = searchTextFieldFrame;
                             self.backButton.frame = backButtonFrame;
                             self.cancelButton.frame = cancelButtonFrame;
                             
                             CGFloat newHeaderHeight = [self heightForHeader] - 40.0;
                             self.headerContainerView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.headerContainerView.frame), newHeaderHeight);
                             self.collectionView.contentInset = UIEdgeInsetsMake(newHeaderHeight, 0.0, CGRectGetHeight(keyboardFrame), 0.0);
                             self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
                         } completion:^(BOOL finished) {
                             
                         }];
    }
}

- (void)handleKeyboardWillHideNotification:(NSNotification *)notification {
    if (!self.isSearching) {
        return;
    }
    
    if (self.isResigningDueToPush) {
        self.isResigningDueToPush = NO;
        return;
    }
    
    self.searching = NO;
    [self.collectionView reloadData];
    
    self.headerView.backgroundColor = [UIColor whiteColor];
    self.searchTextField.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:241.0/255.0 blue:248.0/255.0 alpha:1.0];
    
    CGRect searchTextFieldFrame = self.searchTextField.frame;
    CGRect backButtonFrame = self.backButton.frame;
    CGRect cancelButtonFrame = self.cancelButton.frame;
    
    CGFloat deltaX = self.searchTextFieldOriginalOriginX - CGRectGetMinX(searchTextFieldFrame);
    CGFloat deltaWidth = self.searchTextFieldOriginalSizeWidth - CGRectGetWidth(searchTextFieldFrame);
    
    searchTextFieldFrame.origin.x += deltaX;
    backButtonFrame.origin.x += deltaX;
    cancelButtonFrame.origin.x += (deltaX + deltaWidth);
    
    searchTextFieldFrame.size.width += deltaWidth;
    
    CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:25.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.searchTextField.frame = searchTextFieldFrame;
                         self.backButton.frame = backButtonFrame;
                         self.cancelButton.frame = cancelButtonFrame;
                         
                         CGFloat newHeaderHeight = [self heightForHeader];
                         self.headerContainerView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.headerContainerView.frame), newHeaderHeight);
                         self.collectionView.contentInset = UIEdgeInsetsMake(newHeaderHeight, 0.0, 10.0, 0.0);
                         self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
                     } completion:^(BOOL finished) {
                         
                     }];
}

#pragma mark - Custom View Getters

- (UIView *)headerContainerView {
    if (!_headerContainerView) {
        _headerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), [self heightForHeader])];
        _headerContainerView.backgroundColor = [UIColor clearColor];
        _headerContainerView.clipsToBounds = YES;
    }
    
    return _headerContainerView;
}

- (UIView *) headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), [self heightForHeader])];
        _headerView.backgroundColor = [UIColor whiteColor];
        [_headerView addSubview:self.backButton];
        [_headerView addSubview:self.searchTextField];
        [_headerView addSubview:self.cancelButton];
        [_headerView addSubview:self.peopleButton];
        [_headerView addSubview:self.peopleContactSeparator];
        [_headerView addSubview:self.contactsButton];
        
        UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_headerView.frame) - 1, CGRectGetWidth(self.view.frame), 1)];
        sepView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
        [_headerView addSubview:sepView];
    }
    
    return _headerView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[UIImage imageNamed:@"button-back-dark-small"] forState:UIControlStateNormal];
        [_backButton sizeToFit];
        _backButton.frame = CGRectMake(10, 0.0, CGRectGetWidth(_backButton.frame), CGRectGetHeight(_backButton.frame));
        _backButton.center = CGPointMake(_backButton.center.x, [self adjustedCenterYForNavigationElements]);
        
        [_backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _backButton;
}

- (SPCSearchTextField *)searchTextField {
    if (!_searchTextField) {
        _searchTextField = [[SPCSearchTextField alloc] init];
        _searchTextField.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:241.0/255.0 blue:248.0/255.0 alpha:1.0];
        _searchTextField.delegate = self;
        
        _searchTextField.placeholder = @"Find people";
        _searchTextField.placeholderAttributes = @{
                                                   NSForegroundColorAttributeName: [UIColor colorWithRed:116.0/255.0 green:191.0/255.0 blue:248.0/255.0 alpha:1.0],
                                                   NSFontAttributeName: [UIFont fontWithName:@"OpenSans" size:14.0]
                                                   };
        _searchTextField.textColor = [UIColor colorWithRGBHex:0x4cb0fb];
        
        CGFloat originX = CGRectGetMaxX(_backButton.frame) + 10.0;
        CGFloat sizeWidth = CGRectGetWidth(self.view.frame) - originX - 10.0;
        CGFloat sizeHeight = 30.0;
        _searchTextField.frame = CGRectMake(originX, 0.0, sizeWidth, sizeHeight);
        _searchTextField.center = CGPointMake(_searchTextField.center.x, [self adjustedCenterYForNavigationElements]);
        _searchTextField.layer.cornerRadius = 3.0;
        
        self.searchTextFieldOriginalOriginX = CGRectGetMinX(_searchTextField.frame);
        self.searchTextFieldActiveOriginX = 10.0;
        self.searchTextFieldOriginalSizeWidth = CGRectGetWidth(_searchTextField.frame);
        
        UIImageView *newSearchIcon = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"search-people-finder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        newSearchIcon.contentMode = UIViewContentModeCenter;
        _searchTextField.leftView = newSearchIcon;
        
        _searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    
    return _searchTextField;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0];
        [_cancelButton sizeToFit];
        
        CGFloat originX = CGRectGetMaxX(_searchTextField.frame) + 10.0;
        CGRect cancelButtonFrame = _cancelButton.frame;
        cancelButtonFrame.origin.x = originX;
        _cancelButton.frame = cancelButtonFrame;
        _cancelButton.center = CGPointMake(_cancelButton.center.x, [self adjustedCenterYForNavigationElements]);
        
        [_cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cancelButton;
}

- (UIButton *)peopleButton {
    if (!_peopleButton) {
        _peopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _peopleButton.titleLabel.font = [self fontForPeopleAndContactsButtons];
        [_peopleButton setTitle:@"People" forState:UIControlStateNormal];
        
        [_peopleButton setTitleColor:[UIColor colorWithRed:137.0/255.0 green:137.0/255.0 blue:137.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_peopleButton setTitleColor:[UIColor colorWithRed:76.0/255.0 green:176.0/255.0 blue:251.0/255.0 alpha:1.0] forState:UIControlStateSelected];
        
        _peopleButton.frame = CGRectMake(0.0, CGRectGetHeight(self.headerView.frame) - 40.0, CGRectGetWidth(self.headerView.frame) / 2.0, 40.0);
        
        [_peopleButton addTarget:self action:@selector(peopleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _peopleButton;
}

- (UIImageView *)peopleContactSeparator {
    if (!_peopleContactSeparator) {
        _peopleContactSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"people-finder-segmented-separator"]];
        _peopleContactSeparator.center = CGPointMake(CGRectGetMidX(self.headerView.frame), CGRectGetMidY(_peopleButton.frame));
    }
    
    return _peopleContactSeparator;
}

- (UIButton *)contactsButton {
    if (!_contactsButton) {
        _contactsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _contactsButton.titleLabel.font = [self fontForPeopleAndContactsButtons];
        [_contactsButton setTitle:@"Contacts" forState:UIControlStateNormal];
        
        [_contactsButton setTitleColor:[UIColor colorWithRed:137.0/255.0 green:137.0/255.0 blue:137.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_contactsButton setTitleColor:[UIColor colorWithRed:76.0/255.0 green:176.0/255.0 blue:251.0/255.0 alpha:1.0] forState:UIControlStateSelected];
        
        _contactsButton.frame = CGRectMake(CGRectGetMaxX(_peopleButton.frame), CGRectGetMinY(_peopleButton.frame), CGRectGetWidth(self.headerView.frame) / 2.0, CGRectGetHeight(_peopleButton.frame));
        
        [_contactsButton addTarget:self action:@selector(contactsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _contactsButton;
}

- (UIView *)peopleContactButtonUnderline {
    if (!_peopleContactButtonUnderline) {
        _peopleContactButtonUnderline = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(_peopleButton.frame) - 4.0, 0.0, 4.0)];
        _peopleContactButtonUnderline.backgroundColor = [UIColor colorWithRed:76.0/255.0 green:176.0/255.0 blue:251.0/255.0 alpha:1.0];
    }
    
    return _peopleContactButtonUnderline;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.gridLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(self.headerContainerView.frame) - [self heightOfStatusBar], 0.0, 45.0, 0.0);
        _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(CGRectGetHeight(self.headerContainerView.frame) - [self heightOfStatusBar], 0.0, 5.0, 0.0);
        
        [_collectionView registerClass:[SPCPeopleFinderCollectionViewCell class] forCellWithReuseIdentifier:FinderCellIdentifier];
        
        Class headerClass = [SPCPeopleFinderCollectionReusableView class];
        [_collectionView registerClass:headerClass forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass(headerClass)];
    }
    
    return _collectionView;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicatorView.center = self.view.center;
        _activityIndicatorView.color = [UIColor grayColor];
        _activityIndicatorView.hidesWhenStopped = YES;
    }
    
    return _activityIndicatorView;
}

- (UICollectionViewFlowLayout *)gridLayout {
    if (!_gridLayout) {
        _gridLayout = [[UICollectionViewFlowLayout alloc] init];
    }
    
    return _gridLayout;
}

#pragma mark - Helpers

- (CGFloat)heightOfStatusBar {
    return CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
}

- (CGFloat)heightForHeader {
    return [self heightOfStatusBar] + 90.0;
}

- (CGFloat)adjustedCenterYForNavigationElements {
    return ([self heightForHeader] / 2) + ([self heightOfStatusBar] / 2) - (40.0 / 2.0);
}

- (UIFont *)fontForPeopleAndContactsButtons {
    return [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.isSearching) {
        if (self.selectionState == SPCPeopleFinderViewControllerSelectionStatePeople) {
            return [self.peopleFinderController suggestedPersonInSuggestedPeopleAtIndex:indexPath.row];
        } else {
            return [self.peopleFinderController socialProfileInAddressBookAtIndex:indexPath.row];
        }
    } else {
        if ([self.peopleFinderController countOfPeople]) {
            return [self.peopleFinderController personInPeopleAtIndex:indexPath.row];
        } else {
            return [self.peopleFinderController personInSearchHistoryAtIndex:indexPath.row];
        }
    }
    
    return nil;
}

- (void)dataStartedLoading {
    [self.activityIndicatorView startAnimating];
    
    self.peopleButton.enabled = NO;
    self.contactsButton.enabled = NO;
    self.searchTextField.enabled = NO;
}

- (void)dataFinishedLoading {
    [self.activityIndicatorView stopAnimating];
    
    self.peopleButton.enabled = YES;
    self.contactsButton.enabled = YES;
    self.searchTextField.enabled = YES;
}

@end
