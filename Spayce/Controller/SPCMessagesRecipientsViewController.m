//
//  SPCMessagesRecipientsViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMessagesRecipientsViewController.h"

//Framework
#import <CoreText/CoreText.h>

//Manager
#import "MeetManager.h"

//Model
#import "Person.h"
#import "Asset.h"

//View
#import "SPCNoSearchResultsCell.h"
#import "SPCMessageRecipientCell.h"

//Category
#import "UITableView+SPXRevealAdditions.h"

static NSString *recipientCellIdentifier = @"recipientCellIdentifier";
static NSString *noResultsCellIdentifier = @"noResultsCellIdentifier";

@interface SPCMessagesRecipientsViewController ()

//Nav
@property (nonatomic, strong) UILabel *titleLbl;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *nextBtn;

//Data
@property (nonatomic, strong) NSArray *selectedRecipients;
@property (nonatomic, strong) NSArray *possibleRecipients;
@property (nonatomic, strong) NSString *recipientsPageKey;
@property (nonatomic, strong) NSString *recipientsPartialPageKey;
@property (nonatomic, assign) BOOL haveCheckedForMoreRecipients;
@property (nonatomic, assign) BOOL recipFetchInProgress;

//Text Entry
@property (nonatomic, strong) UIView *textEntryBg;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSString * searchFilter;
@property (nonatomic, assign) CGFloat heightForRecipientText;
@property (nonatomic, strong) UILabel *placeholderTextLabel;
@property (nonatomic, assign) BOOL isEditing;

@property (nonatomic, strong) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, strong) UITableView *tableView;


@end

@implementation SPCMessagesRecipientsViewController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.titleLbl];
    [self.view addSubview:self.nextBtn];
    [self.view addSubview:self.textEntryBg];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.loadingSpinner];
    
    [self.tableView registerClass:[SPCMessageRecipientCell class] forCellReuseIdentifier:recipientCellIdentifier];
    [self.tableView registerClass:[SPCNoSearchResultsCell class] forCellReuseIdentifier:noResultsCellIdentifier];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    [self fetchRecipients];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
        _titleLbl.text = @"New Message";
        _titleLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:16];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.center = CGPointMake(self.view.bounds.size.width/2, _titleLbl.center.y);
    }
    return _titleLbl;
}

-(UIButton *)nextBtn {
    if (!_nextBtn) {
        _nextBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 70, 20, 80, 50)];
        [_nextBtn setTitle:@"NEXT" forState:UIControlStateNormal];
        _nextBtn.titleLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:12];
        [_nextBtn addTarget:self action:@selector(createNewThread) forControlEvents:UIControlEventTouchDown];
        [_nextBtn setTitleColor:[UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _nextBtn.enabled = NO;
        _nextBtn.alpha = 0.5f;
    }
    return _nextBtn;
}

-(UIView *)textEntryBg {
    if (!_textEntryBg) {
        _textEntryBg = [[UIView alloc] initWithFrame:CGRectMake(0, 70, self.view.bounds.size.width, 52)];
        _textEntryBg.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:241.0f/255.0f blue:248.0f/255.0f alpha:1.0f];
        _textEntryBg.userInteractionEnabled = YES;
        [_textEntryBg addSubview:self.textView];
        [_textEntryBg addSubview:self.placeholderTextLabel];
    }
    return _textEntryBg;
}

-(UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, self.view.bounds.size.width - 20, self.textEntryBg.frame.size.height - 20)];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor clearColor];
        //_textView.placeholder = @"Enter a name";
        _textView.font = [UIFont fontWithName:@"OpenSans" size:13];
        _textView.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    return _textView;
}

-(UILabel *)placeholderTextLabel {
    if (!_placeholderTextLabel) {
        _placeholderTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeholderTextLabel.text = @"Search followers...";
        _placeholderTextLabel.font = [UIFont fontWithName:@"OpenSans" size:13];
        _placeholderTextLabel.frame = CGRectMake(self.textView.frame.origin.x + 10, (self.textEntryBg.frame.size.height-_placeholderTextLabel.font.lineHeight)/2,  280, _placeholderTextLabel.font.lineHeight);
        _placeholderTextLabel.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _placeholderTextLabel.userInteractionEnabled = NO;
    }
    return _placeholderTextLabel;
}

- (UITableView *)tableView {
    if (!_tableView) {
        // allocate and set up
        float yOrigin = CGRectGetMaxY(self.textEntryBg.frame);
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, yOrigin, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-yOrigin - 44)];
        tableView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.hidden = NO;
        tableView.allowsMultipleSelection = YES;
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _tableView = tableView;
    }
    return _tableView;
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


#pragma mark - UITextViewDelegate


-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
   
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSLog(@"newText %@",newText);
    self.placeholderTextLabel.hidden = newText.length > 0;

    if([text isEqualToString:@""]) {
        NSLog(@"delete?");
        //Detected backspace character as the new character is @"" meaning something will be deleted
        [self performSelector:@selector(checkForRecipientToDelete) withObject:nil afterDelay:.5];
        return YES;
    }
    
    if (newText.length == 0) {

        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        [self performSelector:@selector(filterContentForSearchText) withObject:nil afterDelay:.5];
    } else {
        
        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        // Schedule delayed filter request in order to allow textField to update it's internal state
        [self performSelector:@selector(filterContentForSearchText) withObject:nil afterDelay:.5];
    }
    
    return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    self.isEditing = YES;
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         //update text entry frame size
                         _tableView.frame = CGRectMake(0, CGRectGetMaxY(self.textEntryBg.frame), self.tableView.frame.size.width,self.view.bounds.size.height - CGRectGetMaxY(self.textEntryBg.frame) - 44 - 170);
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             
                         }
                     }];
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         //update text entry frame size
                         _tableView.frame = CGRectMake(0, CGRectGetMaxY(self.textEntryBg.frame), self.tableView.frame.size.width,self.view.bounds.size.height - CGRectGetMaxY(self.textEntryBg.frame) - 44);
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             self.isEditing = NO;
                         }
                     }];
}

-(void)textViewDidChange:(UITextView *)textView  {
 
}



#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.haveCheckedForMoreRecipients) {
        
        if ((self.searchFilter.length > 0) && (self.possibleRecipients.count == 0)) {
            return 1;
        }
        else {
            return self.possibleRecipients.count;
        }
    }
    else {
        return self.possibleRecipients.count +1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.possibleRecipients.count > 0) {
        if (indexPath.row < self.possibleRecipients.count) {
            return [self tableView:tableView recipientCellForRowAtIndexPath:indexPath];
        }
        else {
            return [self tableView:tableView loadingCellForRowAtIndexPath:indexPath];
        }
    }
    else {
        if (self.searchFilter.length > 0) {
            return [self tableView:tableView noSearchResultsCellAtIndexPath:indexPath];
        }
        else {
            return [self tableView:tableView placeHolderCellForRowAtIndexPath:indexPath];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float triggerPoint = 70 * (self.possibleRecipients.count - 10);
    if (scrollView.contentOffset.y > triggerPoint) {
        [self fetchMoreRecipients];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView recipientCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Person *recipient = self.possibleRecipients[indexPath.row];
    SPCMessageRecipientCell *cell = [tableView dequeueReusableCellWithIdentifier:recipientCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[SPCMessageRecipientCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recipientCellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellEditingStyleNone;
    
    
    BOOL recipientIsSelected = [self isRecipientSelected:recipient];
    
    if (recipientIsSelected ) {
        [cell displayCustomCheck:YES];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
    else {
        [cell displayCustomCheck:NO];
        [self tableView:self.tableView didDeselectRowAtIndexPath:indexPath];
    }
    [cell configureWithPerson:recipient url:[NSURL URLWithString:recipient.imageAsset.imageUrlThumbnail]];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView noSearchResultsCellAtIndexPath:(NSIndexPath *)indexPath {
    SPCNoSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:noResultsCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[SPCNoSearchResultsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:noResultsCellIdentifier];
        cell.userInteractionEnabled = NO;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView placeHolderCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PlaceHolder";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LoadingMore";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.tag = 111;
        indicatorView.color = [UIColor grayColor];
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:indicatorView];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        
        [indicatorView startAnimating];
    } else {
        UIActivityIndicatorView *animation = (UIActivityIndicatorView *)[cell viewWithTag:111];
        [animation startAnimating];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   
    if (self.selectedRecipients.count <= 20) {
    
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        SPCMessageRecipientCell *cell = (SPCMessageRecipientCell *)[tableView cellForRowAtIndexPath:indexPath];
        [cell displayCustomCheck:YES];
        
        Person *recipient = self.possibleRecipients[indexPath.row];
        [self addRecipient:recipient];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Hang on!"
                                                            message:@"You cannot include any more people in this message."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    SPCMessageRecipientCell *cell = (SPCMessageRecipientCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell displayCustomCheck:NO];
    
    
    Person *recipient = self.possibleRecipients[indexPath.row];
    [self removeRecipient:recipient];

}


#pragma mark Actions

-(void)cancel {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)addRecipient:(Person *)selectedRecipient {
    
    //Do we have this recipient already?
    
    BOOL newRecipient = YES;
    
    if (self.selectedRecipients.count > 0) {
    
        for (int i = 0; i < self.selectedRecipients.count; i++) {
            
            Person *prevRecip = self.selectedRecipients[i];
            
            if ([prevRecip.userToken isEqualToString:selectedRecipient.userToken]) {
                newRecipient = NO;
                break;
            }
        }
    }
    else {
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        self.selectedRecipients = [NSArray arrayWithArray:tempArray];
    }
    
    if (newRecipient) {
        //update our array
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedRecipients];
        [tempArray addObject:selectedRecipient];
        self.selectedRecipients = [NSArray arrayWithArray:tempArray];
        
        
        //Only refresh our results if user had been typing a search query
 
        if (self.recipientsPartialPageKey.length > 0 || self.haveCheckedForMoreRecipients) {
            self.recipientsPartialPageKey = nil;
            self.recipientsPageKey = nil;
            [self fetchRecipients];
        }
        
        //update text
        [self updateRecipientList];
        
    }
}

-(void)removeRecipient:(Person *)recipientToRemove {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.selectedRecipients];
    BOOL removedUser = NO;
    
    for (int i = 0; i < self.selectedRecipients.count; i++) {
        
        Person *prevRecip = self.selectedRecipients[i];
        
        if ([prevRecip.userToken isEqualToString:recipientToRemove.userToken]) {
            [tempArray removeObjectAtIndex:i];
            removedUser = YES;
            break;
        }
    }
    
    if (removedUser){
       
        self.selectedRecipients = [NSArray arrayWithArray:tempArray];
    
        //update text
        [self updateRecipientList];
    }
}

-(BOOL)isRecipientSelected:(Person *)recipient {
    
    
    BOOL isSelected = NO;
    
    for (int i = 0; i < self.selectedRecipients.count; i++) {
        
        Person *tempRecip = self.selectedRecipients[i];
        
        if ([tempRecip.userToken isEqualToString:recipient.userToken]) {
            isSelected = YES;
            break;
        }
    }
    
    return isSelected;
}

-(void)createNewThread {
    if (self.delegate && [self.delegate respondsToSelector:@selector(createNewThreadWithRecipients:)]) {
        [self.delegate createNewThreadWithRecipients:self.selectedRecipients];
    }
}

#pragma mark Private

- (void)checkForRecipientToDelete {
    
    NSMutableArray *updatedRecipients = [NSMutableArray arrayWithArray:self.selectedRecipients];
    
    for (int i = 0; i < self.selectedRecipients.count; i++) {
        Person *currRecipient = self.selectedRecipients[i];
        
        NSRange recipRange = [self.textView.attributedText.string rangeOfString:currRecipient.displayName];
        if (recipRange.location == NSNotFound) {
            [updatedRecipients removeObjectAtIndex:i];
        }
    }

    if (updatedRecipients.count != self.selectedRecipients.count) {
        self.selectedRecipients = [NSArray arrayWithArray:updatedRecipients];
        [self updateRecipientList];
        [self reloadData];
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self filterContentForSearchText];
        
    }
    
}

- (void)updateRecipientList {
    
    //Display comma separated list of display names for selected recipients
    NSMutableArray *namesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < self.selectedRecipients.count; i++) {
        Person *tempRecipient = self.selectedRecipients[i];
        [namesArray addObject:tempRecipient.displayName];
    }
    
    
    NSString *fullList = [namesArray componentsJoinedByString:@", "];
    if (namesArray.count > 0) {
        fullList = [NSString stringWithFormat:@"%@, ",fullList];
    }
    else {
        fullList = @"";
    }
    NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:fullList];
    NSRange recipientsRange = NSMakeRange(0,fullList.length);
    
    //style participant names
    [styledText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f] range:recipientsRange];
    [styledText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans" size:12] range:recipientsRange];
    
    self.textView.attributedText = styledText;
    
    self.heightForRecipientText = [self heightForRecipientText:styledText.string];

    //respect min height for bg
    if (self.heightForRecipientText < 32) {
        self.heightForRecipientText = 32;
    }
    
    float keyDelta = 0;
    
    if (self.isEditing) {
        keyDelta = 170;
    }
    
    
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         //update text entry frame size
                         self.textEntryBg.frame = CGRectMake(0, self.textEntryBg.frame.origin.y, self.view.bounds.size.width, self.heightForRecipientText + 20);
                         self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width,self.heightForRecipientText);
                         self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.textEntryBg.frame), self.tableView.frame.size.width,self.view.bounds.size.height - CGRectGetMaxY(self.textEntryBg.frame) - 44 - keyDelta);
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             
                         }
                     }];
    
    self.nextBtn.enabled = NO;
    self.nextBtn.alpha = 0.5f;
    
    if (self.selectedRecipients.count > 0) {
        self.placeholderTextLabel.hidden = YES;
        self.nextBtn.enabled = YES;
        self.nextBtn.alpha = YES;
    }
    else {
        self.placeholderTextLabel.hidden = NO;
     }
}

- (void)fetchMoreRecipients {
    
    if (!self.recipFetchInProgress && !self.haveCheckedForMoreRecipients) {
    
        //get mroe recipients for this partial search
        if (self.searchFilter.length > 0 && self.recipientsPartialPageKey.length > 0) {
            [self fetchRecipientsWithPartial:self.searchFilter];
        }
        //get more recipients for our base search
        else {
            if (self.recipientsPageKey.length > 0) {
                NSLog(@"get more recips for the base search!");
                [self fetchRecipients];
            }
        }
    }
}


- (void)fetchRecipients {
    
    if (!self.recipFetchInProgress) {
    
        self.recipFetchInProgress = YES;
        __weak typeof(self)weakSelf = self;
        
        [MeetManager fetchFollowersOrderedByLastMessageWithPageKey:self.recipientsPageKey
                                 completionHandler:^(NSArray *followers, NSString *pageKey) {
                                     __strong typeof(weakSelf)strongSelf = weakSelf;
                                     if (!strongSelf) {
                                        return ;
                                     }
                                    
                                     //did we have a page key?
                                     BOOL startFresh = self.recipientsPageKey.length == 0;
                                     
                                     
                                     // update our page key or note that we don't have another
                                     if (pageKey) {
                                         self.haveCheckedForMoreRecipients = NO;
                                         strongSelf.recipientsPageKey = pageKey;
                                     }
                                     else {
                                         self.haveCheckedForMoreRecipients = YES;
                                     }
                                     
                                     //create fresh
                                     if (startFresh) {
                                         strongSelf.possibleRecipients = [NSArray arrayWithArray:followers];
                                      
                                         //update display
                                         [strongSelf reloadData];
                                          strongSelf.tableView.contentOffset = CGPointMake(0, 0);
                                     }
                                     
                                     
                                     //append
                                     else {
                                         
                                         //grab existing & add new
                                         if (followers.count > 0) {
                                             NSMutableArray *tempArray = [NSMutableArray arrayWithArray:strongSelf.possibleRecipients];
                                             [tempArray addObjectsFromArray:followers];
                                             strongSelf.possibleRecipients = [NSArray arrayWithArray:tempArray];
                                         }
                                      
                                         //update display
                                         CGPoint previousOffset = strongSelf.tableView.contentOffset;
                                         [strongSelf reloadData];
                                         strongSelf.tableView.contentOffset = previousOffset;
                                        
                                     }
                                     
                                     //clean up
                                     strongSelf.recipFetchInProgress = NO;
                                     

                                 }
                                      errorHandler:^(NSError *error) {
                                          NSLog(@"error %@",error);
                                          __strong typeof(weakSelf)strongSelf = weakSelf;
                                          strongSelf.recipFetchInProgress = NO;
                                          
                                          strongSelf.haveCheckedForMoreRecipients = YES;
                                          
                                          //update display
                                          CGPoint previousOffset = strongSelf.tableView.contentOffset;
                                          [strongSelf reloadData];
                                          strongSelf.tableView.contentOffset = previousOffset;
                                      }];
    }
    
}

- (void)fetchRecipientsWithPartial:(NSString *)searchString {
    
    if (!self.recipFetchInProgress && searchString.length > 0) {
    
        self.recipFetchInProgress = YES;
        self.recipientsPageKey = nil;
        
        __weak typeof(self)weakSelf = self;
        
        [MeetManager fetchFollowersWithPartialSearch:searchString pageKey:self.recipientsPartialPageKey
                                   completionHandler:^(NSArray *followers, NSString *pageKey) {
                                       __strong typeof(weakSelf)strongSelf = weakSelf;
                                       if (!strongSelf) {
                                           return ;
                                       }

                                       //did we have a page key?
                                       BOOL startFresh = self.recipientsPartialPageKey.length == 0;
                                       
                                       //update our page key
                                       if (pageKey) {
                                           self.haveCheckedForMoreRecipients = NO;
                                           strongSelf.recipientsPartialPageKey = pageKey;
                                       }
                                       else {
                                           //we had a page key, but there are no more recipients - update our flag to hide the spinner
                                           self.haveCheckedForMoreRecipients = YES;
                                       }
                                       
                                       //create fresh
                                       if (startFresh) {
                                           strongSelf.possibleRecipients = [NSArray arrayWithArray:followers];
                                           [strongSelf reloadData];
                                           strongSelf.tableView.contentOffset = CGPointMake(0, 0);
                                       }
                                       
                                       //append to existing
                                       else {
                                           
                                           //grab existing & add new recipients, if they exist..
                                           if (followers.count > 0) {
                                               NSMutableArray *tempArray = [NSMutableArray arrayWithArray:strongSelf.possibleRecipients];
                                               [tempArray addObjectsFromArray:followers];
                                               strongSelf.possibleRecipients = [NSArray arrayWithArray:tempArray];
                                           }
                                        
                                           //update display
                                           CGPoint previousOffset = strongSelf.tableView.contentOffset;
                                           [strongSelf reloadData];
                                           strongSelf.tableView.contentOffset = previousOffset;
                                           
                                       }
                                       
                                       //cleanup
                                       strongSelf.recipFetchInProgress = NO;
                                       
                                   }
                                   errorHandler:^(NSError *error) {
                                       __strong typeof(weakSelf)strongSelf = weakSelf;

                                       strongSelf.recipFetchInProgress = NO;
                                       strongSelf.haveCheckedForMoreRecipients = YES;
                                       
                                       //update display
                                       CGPoint previousOffset = strongSelf.tableView.contentOffset;
                                       [strongSelf reloadData];
                                       strongSelf.tableView.contentOffset = previousOffset;
                                   }];
    }
    
    else {
        
        if (searchString.length == 0) {
            [self fetchRecipients];
        }
    }
}



- (CGFloat)heightForRecipientText:(NSString *)recipientList {
    
    float maxWidth = self.textView.frame.size.width - 10;
    CGSize constraint = CGSizeMake(maxWidth, 20000);
    
    _heightForRecipientText = 0;
    
    NSMutableAttributedString * cellText;
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor blackColor],
                                  NSFontAttributeName: [UIFont fontWithName:@"OpenSans" size:12] };
    
    // Account for recipients
    if (recipientList.length > 0) {
        cellText = [[NSMutableAttributedString alloc] initWithString:recipientList attributes:attributes];
    }
    else {
        cellText = [[NSMutableAttributedString alloc] initWithString:@"" attributes:attributes];
    }
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithAttributedString:cellText];
    
    //using core text to correctly handle sizing for emoji
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
    CGSize targetSize = CGSizeMake(constraint.width, CGFLOAT_MAX);
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [attrString length]), NULL, targetSize, NULL);
    CFRelease(framesetter);
    _heightForRecipientText = ceilf(fitSize.height) + 15;
    
    if (_heightForRecipientText < 23) {
        _heightForRecipientText = 23;
    }
    if (_heightForRecipientText > 110) {
        _heightForRecipientText = 110;
    }

    return _heightForRecipientText;
}

- (void)filterContentForSearchText {
    // perform the search...
    NSLog(@"searchFilter %@",[self getSearchString]);
    self.searchFilter = [self getSearchString];
}

- (NSString *)getSearchString {
    NSString *fullString = self.textView.attributedText.string;
    NSLog(@"full string %@",fullString);
    NSMutableArray *namesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < self.selectedRecipients.count; i++) {
        Person *tempRecipient = self.selectedRecipients[i];
        NSString *displayName = tempRecipient.displayName;
        [namesArray addObject:displayName];
    }
    
    NSString *fullList = [namesArray componentsJoinedByString:@", "];
    if (namesArray.count > 0) {
        fullList = [NSString stringWithFormat:@"%@, ",fullList];
    }
    else {
        fullList = @"";
    }
    
    NSString *clippedString = @"";

    if (fullString.length > fullList.length) {
        clippedString = [fullString substringFromIndex:fullList.length];
    }
    return clippedString;
}

- (void)setSearchFilter:(NSString *)searchFilter {
    if (![_searchFilter isEqualToString:searchFilter]) {
        _searchFilter = searchFilter;
        self.haveCheckedForMoreRecipients = NO;
        self.recipientsPartialPageKey = nil;
        [self fetchRecipientsWithPartial:_searchFilter];
    }
}

- (NSArray *)filterRecipients:(NSArray *)recipients withSearchTerm:(NSString *)searchTerm {
    if (searchTerm) {
        NSArray *wordsAndEmptyStrings = [searchTerm componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *words = [wordsAndEmptyStrings filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        for (NSString * word in words) {
            NSMutableArray * includedRecipients = [NSMutableArray arrayWithCapacity:recipients.count];
            for (Person * recipient in recipients) {
                // match name!  A venue name is a match if venue name or
                // address name matches the string, i.e. it contains the string
                // in a case-insensitive format.
                NSString * recipientName = recipient.displayName;
                NSString * recipientHandle = recipient.handle;
                
                BOOL include = recipientName && [recipientName rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound;
                include = include || (recipientHandle && [recipientHandle rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound);
                
                if (include) {
                    [includedRecipients addObject:recipient];
                }
            }
            
            // that's our new list
            recipients = [NSArray arrayWithArray:includedRecipients];
        }
    }
    return recipients;
}


-(void)reloadData {
    [self.loadingSpinner stopAnimating];
    self.loadingSpinner = nil;
    [self.tableView reloadData];
}

@end
