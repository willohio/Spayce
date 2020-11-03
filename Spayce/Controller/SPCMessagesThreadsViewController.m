//
//  SPCMessagesThreadsViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

//Messages Controllers
#import "SPCMessagesThreadsViewController.h"
#import "SPCMessagesRecipientsViewController.h"
#import "SPCMessagesViewController.h"

//Manager
#import "MeetManager.h"
#import "SPCMessageManager.h"

//Model
#import "SPCMessageThread.h"
#import "Person.h"
#import "SPCMessage.h"

//Cell
#import "SPCMessageThreadTableViewCell.h"
#import "SWTableViewCell.h"

//Category
#import "UITableView+SPXRevealAdditions.h"

#import "Flurry.h"


static NSString *threadCellIdentifier = @"threadCellIdentifier";

@interface SPCMessagesThreadsViewController () <SWTableViewCellDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIActivityIndicatorView *loadingSpinner;

@property (nonatomic, strong) NSArray *messageThreads;
@property (nonatomic, assign) NSInteger followersCount;

@property (nonatomic, strong) UIView *noMsgsView;
@property (nonatomic, strong) UILabel *promptLbl;

@property (nonatomic, strong) UIButton *chatBtn;

@property (nonatomic, assign) BOOL retrievedMsgThreads;
@property (nonatomic, assign) BOOL retrievedFollowerCount;
@property (nonatomic, strong) NSTimer *msgsTimer;
@property (nonatomic, assign) NSTimeInterval dateLastRefreshed;

@end

@implementation SPCMessagesThreadsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_msgsTimer invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];

    [self.view addSubview:self.tableView];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    [self.view addSubview:self.noMsgsView];
    [self.view addSubview:self.chatBtn];

    [self.view addSubview:self.loadingSpinner];

    [self fetchFollowersForUser];
    [self fetchMessageThreadsForUser];
    
    [self.tableView registerClass:[SPCMessageThreadTableViewCell class] forCellReuseIdentifier:threadCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageThread:) name:@"updateMessageThread" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteMessageThread:) name:@"deleteMsgThread" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markAllThreadsAsRead) name:@"markAllThreadsAsRead" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pollForThreadUpdates) name:@"pollForThreadUpdates" object:nil];


    if (!_msgsTimer) {
        _msgsTimer = [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(pollForThreadUpdates) userInfo:nil repeats:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateDisplay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors

- (UITableView *)tableView {
    if (!_tableView) {
        // allocate and set up
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 44)];
        tableView.backgroundColor = [UIColor colorWithWhite:255.0f/255.0f alpha:1.0f];
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

-(UIButton *)chatBtn {
    if (!_chatBtn) {
        _chatBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 90, self.view.bounds.size.height - 210, 80, 80)];
        [_chatBtn setBackgroundImage:[UIImage imageNamed:@"chatBtn"] forState:UIControlStateNormal];
        [_chatBtn addTarget:self action:@selector(showRecipientsSelection) forControlEvents:UIControlEventTouchDown];
        _chatBtn.hidden = YES;
    }
    return _chatBtn;
}

- (UIView *)loadingSpinner {
    if (!_loadingSpinner) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.center = CGPointMake(self.view.center.x, self.tableView.frame.size.height/2);
        indicatorView.color = [UIColor grayColor];
        [indicatorView startAnimating];
        
        _loadingSpinner = indicatorView;
    }
    return _loadingSpinner;
}

- (UIView *)noMsgsView {
    if (!_noMsgsView) {
        _noMsgsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 44 - 70)];
        _noMsgsView.backgroundColor = [UIColor clearColor];
        
        UIImageView *iconImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"no-msgs"]];
        [_noMsgsView addSubview:iconImgView];
        iconImgView.center = CGPointMake(_noMsgsView.frame.size.width/2, -100 + (_noMsgsView.frame.size.height/2));
        
        self.promptLbl.frame = CGRectMake(0, CGRectGetMaxY(iconImgView.frame) + 10, 300, 140);
        self.promptLbl.center = CGPointMake(_noMsgsView.frame.size.width/2, self.promptLbl.center.y);
        [_noMsgsView addSubview:self.promptLbl];
        
        _noMsgsView.hidden = YES;
        
    }
    return _noMsgsView;
}


-(UILabel *)promptLbl {
    if (!_promptLbl) {
        _promptLbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _promptLbl.textAlignment = NSTextAlignmentCenter;
        _promptLbl.font = [UIFont fontWithName:@"OpenSans" size:16];
        _promptLbl.lineBreakMode = NSLineBreakByWordWrapping;
        _promptLbl.numberOfLines = 0;
        _promptLbl.textColor = [UIColor colorWithWhite:162.0f/255.0f alpha:1.0f];
    }
    return _promptLbl;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   return self.messageThreads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView threadCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SPCMessageThreadTableViewCell *cell = (SPCMessageThreadTableViewCell *)[tableView dequeueReusableCellWithIdentifier:threadCellIdentifier
                                                                                           forIndexPath:indexPath];

    if (!cell) {
        cell = [[SPCMessageThreadTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:threadCellIdentifier];
    }
    
    SPCMessageThread *thread = self.messageThreads[indexPath.row];
    [cell configureWitMessageThread:thread];
    
    cell.containingTableView = tableView;
    if (thread.isMuted) {
        cell.rightUtilityButtons = [self rightunMuteButtons];
    }
    else {
        cell.rightUtilityButtons = [self rightButtons];
    }
    cell.delegate = self;
    [cell setCellH:cell.frame.size.height];
    cell.tag    = indexPath.row;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self tableView:tableView threadCellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [Flurry logEvent:@"CHAT_THREAD_TAPPED"];
    SPCMessageThread *thread = self.messageThreads[indexPath.row];
    [thread updateLastReadDate];
    [self updateUnreadThreads];
    [self updateDisplay];
    [self loadExistingThread:thread];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}


#pragma mark - SWTableViewCell config

- (NSArray *)rightButtons {

    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
   
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:226.0f/255.0f green:226.0f/255.0f blue:226.0f/255.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"newFlag"]
                                                title:@"REPORT"
                                           titleColor:[UIColor whiteColor]];
     
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:203.0f/255.0f green:203.0f/255.0f blue:203.0f/255.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"newMute"]
                                                title:@"MUTE"
                                           titleColor:[UIColor whiteColor]];
    
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:255.0f/255.0f green:73.0f/255.0f blue:0.0f/255.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"newTrash"]
                                                title:@"DELETE"
                                           titleColor:[UIColor whiteColor]];
    
    
    return rightUtilityButtons;
}

- (NSArray *)rightunMuteButtons {
 
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:226.0f/255.0f green:226.0f/255.0f blue:226.0f/255.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"newFlag"]
                                                title:@"REPORT"
                                           titleColor:[UIColor whiteColor]];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:203.0f/255.0f green:203.0f/255.0f blue:203.0f/255.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"newUnMute"]
                                                title:@"UNMUTE"
                                           titleColor:[UIColor whiteColor]];
    
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:255.0f/255.0f green:73.0f/255.0f blue:0.0f/255.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"newTrash"]
                                                title:@"DELETE"
                                           titleColor:[UIColor whiteColor]];
    
    return rightUtilityButtons;
}


#pragma mark - SWTableViewCell Delegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
{
    switch (state) {
        case 0:
            //NSLog(@"utility buttons closed");
            break;
        case 1:
            //NSLog(@"left utility buttons open");
            break;
        case 2:
            //NSLog(@"right utility buttons open");
            break;
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            //NSLog(@"left button 0 was pressed");
            break;
        case 1:
            //NSLog(@"left button 1 was pressed");
            break;
        case 2:
            //NSLog(@"left button 2 was pressed");
            break;
        case 3:
            //NSLog(@"left btton 3 was pressed");
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            //NSLog(@"report was pressed");
            //TODO!
            [cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1:
        {
            // Mute button was pressed
            // NSLog(@"mute was pressed");
            [cell hideUtilityButtonsAnimated:YES];
            [self toggleMuteForThreadAtIndex:cell.tag];
            break;
        }
        case 2:
        {
            //Delete button was pressed
            //NSLog(@"Delete was pressed");
            [cell hideUtilityButtonsAnimated:YES];
            [self deleteThreadAtIndex:cell.tag];
            break;
        }
        default:
            break;
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    // allow just one cell's utility button to be open at once
    return YES;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    switch (state) {
        case 1:
            // set to NO to disable all left utility buttons appearing
            // set to YES to enable all left utility buttons
            return NO;
        case 2:
            // set to NO to disable all right utility buttons
            // set to YES to enable all right utility buttons
            
            return YES;
        default:
            return NO;
    }
    
    return YES;
}


#pragma mark - Actions

-(void)showRecipientsSelection {
    SPCMessagesRecipientsViewController *recipientsVC = [[SPCMessagesRecipientsViewController alloc] init];
    recipientsVC.delegate = self;
    [self.navigationController pushViewController:recipientsVC animated:YES];
}

- (void)createNewThreadWithRecipients:(NSArray *)recipients {
    SPCMessagesViewController *messagesVC = [[SPCMessagesViewController alloc] init];
    [messagesVC performSelector:@selector(configureWithRecipients:) withObject:recipients afterDelay:.2];
    [self.navigationController pushViewController:messagesVC animated:YES];
}


- (void)loadExistingThread:(SPCMessageThread *)thread {
    SPCMessagesViewController *messagesVC = [[SPCMessagesViewController alloc] init];
    [messagesVC performSelector:@selector(configureWithMessageThread:) withObject:thread afterDelay:.2];
    [self.navigationController pushViewController:messagesVC animated:YES];
}

#pragma mark - Private

-(void)fetchMessageThreadsForUser {
    
    //We need fetch the user's active recent threads from server
    __weak typeof(self)weakSelf = self;
    
    
    [[SPCMessageManager sharedInstance] getMessageThreadsWithCompletionHandler:^(NSArray *threadsArray){
        //NSLog(@"threadsArray %@",threadsArray);
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return ;
        }
        
        strongSelf.messageThreads = [NSArray arrayWithArray:threadsArray];
        strongSelf.retrievedMsgThreads = YES;
        strongSelf.dateLastRefreshed = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
        [strongSelf updateDisplay];

    }
                                                 errorHandler:^(NSError *fault){
                                                     NSLog(@"fault %@",fault);
                                                 }];
    
    
    self.retrievedMsgThreads = YES;
    [self updateDisplay];
}

-(void)fetchFollowersForUser {
    
    //We need to determine if user has at least one follower
    NSLog(@"fetch following for user!");

    __weak typeof(self)weakSelf = self;
    
    [MeetManager fetchFollowersOrderedByLastMessageWithPageKey:nil
                                             completionHandler:^(NSArray *followers, NSString *pageKey) {
                                                 __strong typeof(weakSelf)strongSelf = weakSelf;
                                                 if (!strongSelf) {
                                                     return ;
                                                 }
                                                 strongSelf.followersCount = followers.count;
                                                 strongSelf.retrievedFollowerCount = YES;
                                                 [strongSelf updateDisplay];
                                             }
                                                  errorHandler:^(NSError *error) {
                                                      NSLog(@"error %@",error);
                                                  }];
}

-(void)reloadData {
    [self.tableView reloadData];
}

-(void)updateDisplay {
    
    //NSLog(@"update display!");
    
    //Confirm we have the info we need regarding both threads and follower counts
    if (self.retrievedMsgThreads && self.retrievedFollowerCount) {
        
        //hide spinner
        //NSLog(@"hide spinner!");
        self.loadingSpinner.hidden = YES;
        [self.loadingSpinner stopAnimating];
        self.noMsgsView.hidden = YES;
        
        //Do we have message threads?
        if (self.messageThreads.count > 0) {
            //display message threads
            
            //sorted by recency
            NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"dateOfMostRecentThreadActivity" ascending:NO];
            NSArray *descriptors = @[descriptor];
            NSArray *sortedThreads = [self.messageThreads sortedArrayUsingDescriptors:descriptors];
            self.messageThreads = [NSArray arrayWithArray:sortedThreads];
            
            [self reloadData];
        }
        
        
        //Do we have followers
        if (self.followersCount > 0) {
            //display chat btn
            self.chatBtn.hidden = NO;
        
        
        }
        
        if (self.messageThreads.count == 0) {
            //Display no messages messaging
            self.noMsgsView.hidden = NO;
            self.promptLbl.frame = CGRectMake(0, self.promptLbl.frame.origin.y, 300, 70);
            self.promptLbl.center = CGPointMake(_noMsgsView.frame.size.width/2, self.promptLbl.center.y);
            self.promptLbl.text = @"You don't have any messages yet.\nTo get started, tap the blue chat button below..";
        
        
        }
        
        if (self.followersCount == 0 && self.messageThreads.count == 0) {
            //Display no followers messaging
            self.noMsgsView.hidden = NO;
            self.promptLbl.frame = CGRectMake(0, self.promptLbl.frame.origin.y, 300, 140);
            self.promptLbl.center = CGPointMake(_noMsgsView.frame.size.width/2, self.promptLbl.center.y);
            self.promptLbl.text = @"You can chat with anyone that follows you, and you attract followers by sharing great moments. Wanna chat? Get noticed. Share a moment now!";
            
        }
    }
    
}

-(void)updateMessageThread:(NSNotification *)notification {
    
    SPCMessageThread *thread = (SPCMessageThread *)[notification object];
    
    //Do we have a matching thread?
    BOOL haveMatchingThread = NO;
    
    
    //Check our currently loaded threads?
    for (int i = 0; i < self.messageThreads.count; i ++) {
        
        SPCMessageThread *matchThread = self.messageThreads[i];
        
        if ([thread.keyStr isEqualToString:matchThread.keyStr]) {
            
            //We have a match!  Replace the old copy of this thread with the updated one!
            haveMatchingThread = YES;
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.messageThreads];
            [tempArray removeObjectAtIndex:i];
            [tempArray insertObject:thread atIndex:0];
            self.messageThreads = [NSArray arrayWithArray:tempArray];
            break;
        }
        
    }
    
    //Create a new thread
    if (!haveMatchingThread){
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.messageThreads];
        [tempArray insertObject:thread atIndex:0];
        self.messageThreads = [NSArray arrayWithArray:tempArray];
    }
        
    self.retrievedMsgThreads = YES;
    [self updateDisplay];
    
}

-(void)deleteThreadAtIndex:(NSInteger)deleteAtIndex {

    if (self.messageThreads.count > deleteAtIndex) {
        SPCMessageThread *thread = self.messageThreads[deleteAtIndex];
        
        NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
        
        __weak typeof(self)weakSelf = self;
        
        [[SPCMessageManager sharedInstance] deleteThread:thread.keyStr
                             beforeDate:nowIntervalMS
                  withCompletionHandler:^(BOOL succcess) {
                      __strong typeof(weakSelf)strongSelf = weakSelf;
                      if (!strongSelf) {
                          return ;
                      }
                      if (succcess) {
                          NSLog(@"success deleting thread?");
                      }
                  }
                           errorHandler:^(NSError *error){
                               NSLog(@"error deleting thread?");
                           }];
        
        
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.messageThreads];
        [tempArray removeObjectAtIndex:deleteAtIndex];
        self.messageThreads = [NSArray arrayWithArray:tempArray];
        
        //Refresh display
        [self updateDisplay];
        
    }
}

-(void)toggleMuteForThreadAtIndex:(NSInteger)toggleMuteAtIndex {
    
    if (self.messageThreads.count > toggleMuteAtIndex) {
        SPCMessageThread *thread = self.messageThreads[toggleMuteAtIndex];
     
        if (thread.isMuted) {
            __weak typeof(self)weakSelf = self;
            NSLog(@"unmute");
            [[SPCMessageManager sharedInstance] unmuteThread:thread.keyStr
                                     withCompletionHandler:^(BOOL succcess) {
                                         __strong typeof(weakSelf)strongSelf = weakSelf;
                                         if (!strongSelf) {
                                             return ;
                                         }
                                         if (succcess) {
                                             NSLog(@"success unmuting thread?");
                                         }
                                     }
                                              errorHandler:^(NSError *error){
                                                  NSLog(@"error unmuting thread?");
                                              }];
        }
        else {
            
                NSLog(@"mute");
            __weak typeof(self)weakSelf = self;
            
            [[SPCMessageManager sharedInstance] muteThread:thread.keyStr
                                       withCompletionHandler:^(BOOL succcess) {
                                           __strong typeof(weakSelf)strongSelf = weakSelf;
                                           if (!strongSelf) {
                                               return ;
                                           }
                                           if (succcess) {
                                               NSLog(@"success muting thread?");
                                           }
                                       }
                                                errorHandler:^(NSError *error){
                                                    NSLog(@"error muting thread?");
                                                }];
        }
        
        
        //Update locally
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.messageThreads];
        thread.isMuted = !thread.isMuted;
        [tempArray replaceObjectAtIndex:toggleMuteAtIndex withObject:thread];
        self.messageThreads = [NSArray arrayWithArray:tempArray];
        
        //Refresh display
        [self updateDisplay];
        
    }
}


-(void)deleteMessageThread:(NSNotification *)notification {
    
    NSLog(@"delete message thread!");
    
    NSString *delKeyString = (NSString *)[notification object];
    
    //Do we have a matching thread?
    BOOL haveMatchingThread = NO;
    
    
    //Check our currently loaded threads?
    for (int i = 0; i < self.messageThreads.count; i ++) {
        
        SPCMessageThread *matchThread = self.messageThreads[i];
        
        if ([delKeyString isEqualToString:matchThread.keyStr]) {
            
            //We have a match!  Delete the local copy of this thread!
            haveMatchingThread = YES;
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.messageThreads];
            [tempArray removeObjectAtIndex:i];
            self.messageThreads = [NSArray arrayWithArray:tempArray];
            break;
        }
        
    }
    
    NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
    
    __weak typeof(self)weakSelf = self;
    
    [[SPCMessageManager sharedInstance] deleteThread:delKeyString
                         beforeDate:nowIntervalMS
              withCompletionHandler:^(BOOL succcess) {
                  __strong typeof(weakSelf)strongSelf = weakSelf;
                  if (!strongSelf) {
                      return ;
                  }
                  if (succcess) {
                      NSLog(@"success deleting thread?");
                  }
              }
                       errorHandler:^(NSError *error){
                           NSLog(@"error deleting thread?");
                       }];
    
    
    //Refresh display
    [self updateDisplay];
}

-(void)pollForThreadUpdates {
    
    __weak typeof(self)weakSelf = self;
    //NSLog(@"-- poll for updates to all threads -- ");
    
    [[SPCMessageManager sharedInstance] getMessageThreadsWithCompletionHandler:^(NSArray *threadsArray){
        //NSLog(@"threadsArray %@",threadsArray);
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return ;
        }
        
        strongSelf.messageThreads = [NSArray arrayWithArray:threadsArray];
        strongSelf.retrievedMsgThreads = YES;
        [strongSelf updateDisplay];
        
        NSInteger newUnreadCount = 0;
        
        for (int i = 0; i < strongSelf.messageThreads.count; i++) {
            SPCMessageThread *thread = strongSelf.messageThreads[i];
            if (thread.hasUnreadMessages) {
                newUnreadCount++;
            }
        }
        
        
        strongSelf.dateLastRefreshed = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
        
        NSString *unreadStr = [NSString stringWithFormat:@"%li",newUnreadCount];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUnreadThreadCount" object:unreadStr];

    }
                                                 errorHandler:^(NSError *fault){
                                                     NSLog(@"fault %@",fault);
                                                 }];
    
}

-(void)updateUnreadThreads {
    
    NSInteger newUnreadCount = 0;
    
    for (int i = 0; i < self.messageThreads.count; i++) {
        SPCMessageThread *thread = self.messageThreads[i];
        if (thread.hasUnreadMessages) {
            newUnreadCount++;
        }
    }
    
    NSString *unreadStr = [NSString stringWithFormat:@"%li",newUnreadCount];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUnreadThreadCount" object:unreadStr];
}

-(void)markAllThreadsAsRead {
    
    //update locally!
    for (int i = 0; i < self.messageThreads.count; i++) {
        SPCMessageThread *thread = self.messageThreads[i];
        thread.userLastReadDate =  [NSDate dateWithTimeIntervalSince1970:self.dateLastRefreshed];
    
    }
    [self reloadData];
    
    [[SPCMessageManager sharedInstance] markAllThreadsRead:self.dateLastRefreshed];
}

@end
