//
//  SPCMessagesViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 3/18/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMessagesViewController.h"

// Model
#import "SPCMessage.h"
#import "Person.h"
#import "Asset.h"
#import "ProfileDetail.h"
#import "SPCAlertAction.h"
#import "SPCBaseDataSource.h"
#import "User.h"
#import "UserProfile.h"
#import "SPCMessageTableViewCell.h"
#import "SPCMessageThread.h"

//Manager
#import "ContactAndProfileManager.h"
#import "AuthenticationManager.h"
#import "SPCMessageManager.h"
#import "MeetManager.h"

// View
#import "DAKeyboardControl.h"

// Utils
#import "APIUtils.h"
#import "PXAlertView.h"
#import "Flurry.h"

//Category
#import "UITableView+SPXRevealAdditions.h"

//Controller
#import "SPCProfileViewController.h"
#import "SPCAlertViewController.h"


static NSString *msgCellIdentifier = @"msgCellIdentifier";

@interface SPCMessagesViewController ()

//Nav
@property (nonatomic, strong) UILabel *titleLbl;
@property (nonatomic, strong) UILabel *handleLbl;
@property (nonatomic, strong) NSString *chatName;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *optionsBtn;
@property (nonatomic, assign) BOOL viewingFromProfile;
@property (nonatomic, assign) CGFloat tabAdj;


//keyboard
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL hasAppeared;
@property (nonatomic, assign) BOOL keyboardControlAdded;

//msg input
@property (nonatomic, strong) UIView *composeBarView;
@property (nonatomic, strong) UITextView *messageInput;
@property (nonatomic, strong) UIButton *sendMsgButton;
@property (nonatomic, strong) UILabel *placeholderLabel;

//msg display
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat tableStart;

//Data
@property (nonatomic, strong) SPCMessageThread *messageThread;
@property (nonatomic, strong) NSString *threadKey;
@property (nonatomic, strong) NSString *recipientKeyStr;
@property (nonatomic, strong) NSArray *eventsArray;
@property (nonatomic, strong) NSArray *messagesArray;
@property (nonatomic, strong) UserProfile *profile;
@property (nonatomic, strong) NSArray *participants;

@property (nonatomic, strong) NSTimer *msgsTimer;
@property (nonatomic, assign) NSTimeInterval dateThreadLastUpdated;
@property (nonatomic, strong) NSString *threadPageKeyStr;
@property (nonatomic, assign) BOOL fetchInProgress;
@property (nonatomic, assign) BOOL readyToFetchPreviousMsgs;

@end

@implementation SPCMessagesViewController

-(void)dealloc {
    //NSLog(@"SPCMessagesViewController dealloc?");
    if (_keyboardControlAdded) {
        _keyboardControlAdded = NO;
        [self.view removeKeyboardControl];
    }
    
    [_msgsTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController.navigationBar setHidden:YES];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.readyToFetchPreviousMsgs = NO;
    
    self.profile = [ContactAndProfileManager sharedInstance].profile;
    
    //top nav - back, title, lbl,
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.titleLbl];
    [self.view addSubview:self.handleLbl];
    [self.view addSubview:self.optionsBtn];
    
    UIView *borderLine = [[UIView alloc] initWithFrame:CGRectMake(0, 69, self.view.frame.size.width, 1)];
    borderLine.backgroundColor = [UIColor lightGrayColor];
    borderLine.alpha = 0.25;
    [self.view addSubview:borderLine];
    
    self.tableStart = 70;
    self.tabAdj = 44;
    [self.view addSubview:self.tableView];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    
    [self.tableView registerClass:[SPCMessageTableViewCell class] forCellReuseIdentifier:@"msgCellIdentifier"];
    
    //compose bar
    [self setupComposeBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pollForThreadUpdates) name:@"pollForThreadUpdates" object:nil];
    
    if (!_msgsTimer) {
        _msgsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(pollForThreadUpdates) userInfo:nil repeats:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (!self.hasAppeared && !self.keyboardControlAdded) {
        
        self.hasAppeared = YES;
        self.keyboardControlAdded = YES;
        self.tableView.frame = CGRectMake(0, self.tableStart, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-self.composeBarView.frame.size.height-self.tableStart-self.tabAdj);
        self.composeBarView.frame =  CGRectMake(0.0f, CGRectGetMaxY(self.tableView.frame), self.view.frame.size.width, 46);
        float toolBarMaxYOrigin = CGRectGetMaxY(self.tableView.frame);
        
        self.view.keyboardTriggerOffset = 46.0f;
        
        UIView *tempCompose = self.composeBarView;
        UITableView *tempTable = self.tableView;
        
        float tableStart = self.tableStart;
        
        [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
            
            CGRect toolBarFrame = tempCompose.frame;
            toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
            
            if (toolBarFrame.origin.y > toolBarMaxYOrigin) {
                toolBarFrame.origin.y = toolBarMaxYOrigin;
            }
            
            tempCompose.frame = toolBarFrame;
            
            CGRect tableViewFrame = tempTable.frame;
            tableViewFrame.size.height = toolBarFrame.origin.y - tableStart;
            tempTable.frame = tableViewFrame;
        }];
        
    }
}

-(void)setupComposeBar {
    CGRect frame = CGRectMake(0.0f, CGRectGetHeight(self.view.frame)-100, self.view.frame.size.width, 46);
    self.composeBarView = [[UIView alloc] initWithFrame:frame];
    self.composeBarView.userInteractionEnabled = YES;
    self.composeBarView.backgroundColor =  [UIColor whiteColor];
    [self.view addSubview:self.composeBarView];
    
    UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.composeBarView.frame.size.width, (1.0f / [UIScreen mainScreen].scale))];
    sepLine.backgroundColor = [UIColor colorWithWhite:.85 alpha:1.0f];
    [self.composeBarView addSubview:sepLine];
    
    self.sendMsgButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-53, 8, 51, 30)];
    self.sendMsgButton.backgroundColor = [UIColor clearColor];
    self.sendMsgButton.layer.cornerRadius = 5;
    self.sendMsgButton.alpha = .5;
    self.sendMsgButton.enabled = NO;
    [self.sendMsgButton setTitle:@"Send" forState:UIControlStateNormal];
    self.sendMsgButton.titleLabel.font = [UIFont spc_boldSystemFontOfSize:14];
    self.sendMsgButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.sendMsgButton setTitleColor:[UIColor colorWithRed:106/255.0f green:177/255.0f blue:251/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.sendMsgButton addTarget:self action:@selector(postMessage:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendMsgButton addTarget:self action:@selector(buttonCancel:) forControlEvents:UIControlEventTouchUpOutside];
    [self.sendMsgButton addTarget:self action:@selector(buttonHighlight:) forControlEvents:UIControlEventTouchDown];
    [self.composeBarView addSubview:self.sendMsgButton];
    
    self.messageInput = [[UITextView alloc] initWithFrame:CGRectMake(13, 8, CGRectGetWidth(self.view.frame)-68, 30)];
    self.messageInput.keyboardType = UIKeyboardTypeTwitter;
    self.messageInput.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    self.messageInput.delegate = self;
    self.messageInput.font = [UIFont spc_regularSystemFontOfSize:14];
    self.messageInput.textContainerInset = UIEdgeInsetsMake(6.0, 6.0, 6.0, 6.0);
    self.messageInput.layer.cornerRadius = 5;
    self.messageInput.textColor = [UIColor colorWithRGBHex:0x14294b];
    self.messageInput.layer.borderColor = [UIColor colorWithRed:172/255.0f green:182/255.0f blue:198/255.0f alpha:1.0f].CGColor;
    self.messageInput.layer.borderWidth = 1;
    self.messageInput.spellCheckingType  = UITextSpellCheckingTypeYes;
    self.messageInput.autocorrectionType = UITextAutocorrectionTypeYes;
    self.messageInput.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [self.composeBarView addSubview:self.messageInput];
    
    self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 8, CGRectGetWidth(self.view.frame)-73, 30)];
    self.placeholderLabel.userInteractionEnabled = NO;
    self.placeholderLabel.text = @"Send a message";
    self.placeholderLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
    self.placeholderLabel.backgroundColor = [UIColor clearColor];
    self.placeholderLabel.textColor = [UIColor grayColor];
    [self.composeBarView addSubview:self.placeholderLabel];
}

-(void)updateComposeBarForProfile {

    //Remove Keyboard Control that was sized for tab bar
    [self.view removeKeyboardControl];

    //Update Frames
    self.tableView.frame = CGRectMake(0, self.tableStart, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-self.composeBarView.frame.size.height-self.tableStart);
    self.composeBarView.frame =  CGRectMake(0.0f, CGRectGetMaxY(self.tableView.frame), self.view.frame.size.width, 46);
    
    float toolBarMaxYOrigin = CGRectGetMaxY(self.tableView.frame);
    
    self.view.keyboardTriggerOffset = 46.0f;
    
    UIView *tempCompose = self.composeBarView;
    UITableView *tempTable = self.tableView;
    
    float tableStart = self.tableStart;
    
    //ADd updated Panning ActionHandler
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        
        CGRect toolBarFrame = tempCompose.frame;
        toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
        
        if (toolBarFrame.origin.y > toolBarMaxYOrigin) {
            toolBarFrame.origin.y = toolBarMaxYOrigin;
        }
        
        tempCompose.frame = toolBarFrame;
        
        CGRect tableViewFrame = tempTable.frame;
        tableViewFrame.size.height = toolBarFrame.origin.y - tableStart;
        tempTable.frame = tableViewFrame;
    }];
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

-(UIButton *)optionsBtn {
    if (!_optionsBtn) {
        _optionsBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 45, 20, 45, 50)];
        [_optionsBtn addTarget:self action:@selector(showOptions:) forControlEvents:UIControlEventTouchDown];
        [_optionsBtn setBackgroundImage:[UIImage imageNamed:@"chatOptions"] forState:UIControlStateNormal];
        [_optionsBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return _optionsBtn;
}


-(UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl  = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width - 140, 50)];
        _titleLbl.text = self.chatName;
        _titleLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:16];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.textColor = [UIColor blackColor];
        //_titleLbl.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:.2];
        _titleLbl.center = CGPointMake(self.view.bounds.size.width/2, _titleLbl.center.y);
    }
    return _titleLbl;
}


-(UILabel *)handleLbl {
    if (!_handleLbl) {
        _handleLbl  = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, self.view.bounds.size.width - 140, 15)];
        _handleLbl.text = self.chatName;
        _handleLbl.font = [UIFont fontWithName:@"OpenSans" size:13];
        _handleLbl.textAlignment = NSTextAlignmentCenter;
        _handleLbl.textColor = [UIColor colorWithRed:187.0f/255.0f green:189.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
        //_handleLbl.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:.2];
        _handleLbl.center = CGPointMake(self.view.bounds.size.width/2, _handleLbl.center.y);
    }
    return _handleLbl;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.tableStart, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-self.tableStart) style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.separatorColor = [UIColor clearColor];
        tableView.showsVerticalScrollIndicator = NO;
        tableView.autoresizesSubviews = YES;
        tableView.clipsToBounds = YES;
        if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [tableView setSeparatorInset:UIEdgeInsetsZero];
        }
        _tableView = tableView;
    }
    return _tableView;
}

- (NSString *)recipientKeyStr {
    NSMutableArray *keyArray = [[NSMutableArray alloc] init];
    NSString *keyString = @"";
    
    for (int i = 0; i < self.participants.count; i++) {
        
        Person *tempPerson = (Person *)self.participants[i];
        NSString *personKey = tempPerson.userToken;
        [keyArray addObject:personKey];
    }
    
    keyString = [keyArray componentsJoinedByString:@","];
    return keyString;
}

#pragma mark - TableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.threadPageKeyStr.length > 0) {
        return self.eventsArray.count + 1;
    }
    else {
        return self.eventsArray.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
 
    NSInteger adjIndex = indexPath.row;
    
    if (self.threadPageKeyStr.length > 0) {
        adjIndex = indexPath.row - 1;
        if (adjIndex < 0) {
            return 50;
        }
    }
    
    NSObject *object = self.eventsArray[adjIndex];
    CGFloat cellHeight = 30;
    
    if ([object isKindOfClass:[SPCMessage class]]) {
        SPCMessage *message = self.eventsArray[adjIndex];
        cellHeight = message.messageHeight + 20;
    }
    
    return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView messageCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //Adjust our index to account for the possible existing of a loading cell
    NSInteger adjIndex = indexPath.row;
    
    if (self.threadPageKeyStr.length > 0) {
        adjIndex = indexPath.row - 1;
    }
    
    SPCMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:msgCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[SPCMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:msgCellIdentifier];
    }
    
    //Get the message
    SPCMessage *message = (SPCMessage *)self.eventsArray[adjIndex];
    
    //Populate the cell with the message contentce
    [cell configureWitMessage:message];
    
    //Enable profile pic tappability
    cell.authorBtn.tag = adjIndex;
    cell.tag = adjIndex;
    [cell.authorBtn addTarget:self action:@selector(showAuthor:) forControlEvents:UIControlEventTouchUpInside];
    cell.autoresizesSubviews = NO;
    
    // Configure revealable time stamp view //
    cell.revealableView = [[UINib nibWithNibName:@"TimestampView" bundle:nil] instantiateWithOwner:nil options:nil].firstObject;
    cell.revealableView.backgroundColor = [UIColor clearColor];
    [cell.revealableView viewWithTag:-2].backgroundColor = [UIColor clearColor];
    
    UILabel *detailLabel = (UILabel *)[[cell.revealableView viewWithTag:-2] viewWithTag:-1];
    detailLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
    detailLabel.textColor = [UIColor colorWithRed:.5 green:.5 blue:.5 alpha:1.0f];
    detailLabel.backgroundColor = [UIColor clearColor];
    
    detailLabel.text = message.displayTime;
    if ([message.author.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
        cell.revealStyle = SPXRevealableViewStyleSlide;
    }
    else {
        cell.revealStyle = SPXRevealableViewStyleOverlay;

    }
    // -- End revealable time stamp view confiugration -- //
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView placeHolderCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PlaceHolder";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = @"";
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12.0f];
    cell.textLabel.textColor = [UIColor grayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView timestampCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TimeStamp";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:11.0f];
    cell.textLabel.textColor = [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1.0f];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSInteger adjIndex = indexPath.row;
    
    if (self.threadPageKeyStr.length > 0){
        adjIndex = indexPath.row - 1;
    }
    
    NSObject *object = self.eventsArray[adjIndex];

    if ([object isKindOfClass:[NSString class]]) {
        NSString *dateString = (NSString *)object;
        NSRange endStyleRange = [dateString rangeOfString:@"," options:NSBackwardsSearch];
        NSRange styleRange = NSMakeRange(0, endStyleRange.location);
        
        NSMutableAttributedString *dateStyledStr = [[NSMutableAttributedString alloc] initWithString:dateString];
        
        //style participant names
        [dateStyledStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1.0f] range:styleRange];
        
        [dateStyledStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Bold" size:11] range:styleRange];
        
        cell.textLabel.attributedText = dateStyledStr;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LoadingMore";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.eventsArray.count == 0){
        return [self tableView:tableView placeHolderCellForRowAtIndexPath:indexPath];
    } else {
        
        NSInteger adjIndex = indexPath.row;
        
        if (self.threadPageKeyStr.length > 0) {
            adjIndex = indexPath.row - 1;
            
            if (indexPath.row == 0) {
               return [self tableView:tableView loadingCellForRowAtIndexPath:indexPath];
            }
            
        }
       
        NSObject *object = self.eventsArray[adjIndex];
        
        if ([object isKindOfClass:[SPCMessage class]]) {
            return [self tableView:tableView messageCellForRowAtIndexPath:indexPath];
        }
        else {
            return [self tableView:tableView timestampCellForRowAtIndexPath:indexPath];
        }

    }
}


#pragma mark - UITextView delegate

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.readyToFetchPreviousMsgs = NO;
    [self performSelector:@selector(scrollToLastMessage) withObject:nil afterDelay:.1];
    return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    NSString *resultString = [self.messageInput.text stringByReplacingCharactersInRange:range withString:text];
    
    if (resultString.length > 0) {
        self.placeholderLabel.alpha = 0;
        self.sendMsgButton.alpha = 1.0f;
        self.sendMsgButton.enabled = YES;
    } else {
        self.placeholderLabel.alpha = 1;
        self.sendMsgButton.alpha = 0.5f;
        self.sendMsgButton.enabled = NO;
    }
    
    CGSize maximumLabelSize = CGSizeMake(CGRectGetWidth(self.messageInput.frame) - self.messageInput.textContainerInset.left - self.messageInput.textContainerInset.right - 10, FLT_MAX);
    CGSize newMsgLabelSize = [resultString boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: self.messageInput.font } context:NULL].size;
    NSInteger totalLines = round(newMsgLabelSize.height/([UIFont spc_regularSystemFontOfSize:14].lineHeight));
    if (totalLines<1) {
        totalLines = 1;
    }
    
    float inputHeight =  12+18*totalLines;
    if (inputHeight > 200) {
        inputHeight = 200;
    }
    
    
    self.messageInput.frame = CGRectMake(13, 8, CGRectGetWidth(self.view.frame)-68, inputHeight);
    self.composeBarView.frame = CGRectMake(0, CGRectGetMaxY(self.composeBarView.frame) - (CGRectGetHeight(self.messageInput.frame)+16), self.view.frame.size.width,CGRectGetHeight(self.messageInput.frame)+16);
    self.sendMsgButton.frame = CGRectMake(self.sendMsgButton.frame.origin.x,CGRectGetHeight(self.composeBarView.frame) - 38, self.sendMsgButton.frame.size.width, self.sendMsgButton.frame.size.height);
    
    
    
    return resultString.length < 1000;
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    self.tableView.frame = CGRectMake(0, self.tableStart, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 46 - self.tableStart - self.tabAdj);
    self.composeBarView.frame =  CGRectMake(0.0f, CGRectGetMaxY(self.tableView.frame), self.view.frame.size.width, 46);
    
    self.messageInput.frame = CGRectMake(13, 8, CGRectGetWidth(self.view.frame)-68, 30);
    self.sendMsgButton.frame = CGRectMake(CGRectGetWidth(self.view.frame)-53, 8, 51, 30);
}

-(void)textViewDidChange:(UITextView *)textView  {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float triggerPoint = 70;
    if (scrollView == self.tableView) {
        if (scrollView.contentOffset.y < triggerPoint) {
            if (self.readyToFetchPreviousMsgs) {
                [self getPreviousMessages];
            }
        }
        else {
            if (scrollView.contentOffset.y > triggerPoint) {
                if (!self.readyToFetchPreviousMsgs) {
                    self.readyToFetchPreviousMsgs = YES;
                }
            
            }
        }
    }
}


#pragma mark - Configuration

-(void)configureWithRecipients:(NSArray *)recipients {
    
    self.participants = [NSArray arrayWithArray:recipients];
    
    if (recipients.count == 1) {
        Person *tempPerson = recipients[0];
        self.titleLbl.text = [NSString stringWithFormat:@"%@", tempPerson.displayName];
        self.chatName = [NSString stringWithFormat:@"%@", tempPerson.displayName];
        self.handleLbl.text = [NSString stringWithFormat:@"@%@",tempPerson.handle];
        self.titleLbl.frame  = CGRectMake(0, 20, self.view.bounds.size.width - 140, 25);
        self.titleLbl.center = CGPointMake(self.view.bounds.size.width/2, _titleLbl.center.y);
    }
    else {
        self.titleLbl.text = @"Group";
        self.chatName = @"Group";
    }
}


-(void)configureWithPerson:(Person *)person {
    
    self.viewingFromProfile = YES;
    [self updateComposeBarForProfile];
    self.tabAdj = 0;
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    [tempArray addObject:person];
    NSArray *recipients = [NSArray arrayWithArray:tempArray];
    self.participants = [NSArray arrayWithArray:recipients];
 
    self.titleLbl.text = [NSString stringWithFormat:@"%@", person.displayName];
    self.chatName = [NSString stringWithFormat:@"%@", person.displayName];
    self.handleLbl.text = [NSString stringWithFormat:@"@%@",person.handle];
    self.titleLbl.frame  = CGRectMake(0, 20, self.view.bounds.size.width - 140, 25);
    self.titleLbl.center = CGPointMake(self.view.bounds.size.width/2, _titleLbl.center.y);

    
    //FETCH & DISPLAY RECENT MSG HISTORY (IF ANY) WITH THIS PERSON
  
    __weak typeof(self)weakSelf = self;
    
    
    [[SPCMessageManager sharedInstance] getThreadForUser:person.userToken
                  withCompletionHandler:^(NSString *keyString) {
                      
                      __strong typeof(weakSelf)strongSelf = weakSelf;
                      if (!strongSelf) {
                          return ;
                      }

                      NSLog(@"thread key str %@",keyString);
                      if (keyString.length > 0) {
                          
                          //now that we know we have a key string, create and populate the thread with fetched data
                          
                          strongSelf.fetchInProgress = YES;
                          strongSelf.messageThread = [[SPCMessageThread alloc] init];
                          strongSelf.messageThread.keyStr = keyString;
                          strongSelf.messageThread.participants = self.participants;
                          [strongSelf.messageThread updateLastReadDate];
                          
                          NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
                          
                          [[SPCMessageManager sharedInstance] getMessagesBefore:nowIntervalMS
                                                     threadKey:self.messageThread.keyStr
                                         withCompletionHandler:^(NSArray *messages, NSString *pagingKeyStr){
                                             
                                             if (pagingKeyStr.length > 0) {
                                                 strongSelf.threadPageKeyStr = pagingKeyStr;
                                             }
                                             
                                             strongSelf.dateThreadLastUpdated = nowIntervalMS;
                                             NSMutableArray *tempMessages = [NSMutableArray arrayWithArray:messages];
                                             
                                             //match messsage token strings with full author info that was provided with thread
                                             for (int i = 0; i< tempMessages.count; i++) {
                                                 
                                                 SPCMessage *msg = tempMessages[i];
                                                 if (msg.author.firstname.length == 0) {
                                                     
                                                     for (int k = 0; k < strongSelf.participants.count; k++) {
                                                         Person *tempPartcip = strongSelf.participants[k];
                                                         if ([tempPartcip.userToken isEqualToString:msg.author.userToken]) {
                                                             msg.author = tempPartcip;
                                                             break;
                                                         }
                                                     }
                                                 }
                                             }
                                             
                                             
                                             strongSelf.messageThread.messages = [NSArray arrayWithArray:tempMessages];
                                             strongSelf.messagesArray = [NSArray arrayWithArray:tempMessages];
                                             
                                             [strongSelf reloadData];
                                             [strongSelf scrollToLastMessage];
                                             
                                             [strongSelf performSelector:@selector(readyToFetch) withObject:nil afterDelay:1];
                                             
                                         } errorHandler:^(NSError *error) {
                                             //NSLog(@"error %@",error);
                                             __strong typeof(weakSelf)strongSelf = weakSelf;
                                             strongSelf.fetchInProgress = NO;
                                         }];
                          
                      }
                      
                  }
                           errorHandler:^(NSError *error) {
                           }];
    
    
}
-(void)configureWithMessageThread:(SPCMessageThread *)messageThread {
    
    self.messageThread = messageThread;
    self.messagesArray = [NSArray arrayWithArray:self.messageThread.messages];
    self.participants = [NSArray arrayWithArray:self.messageThread.participants];
    
    if (messageThread.participants.count == 1) {
        Person *tempPerson = messageThread.participants[0];
        self.titleLbl.text = [NSString stringWithFormat:@"%@", tempPerson.displayName];
        self.chatName = [NSString stringWithFormat:@"%@", tempPerson.displayName];
        self.handleLbl.text = [NSString stringWithFormat:@"@%@",tempPerson.handle];
        self.titleLbl.frame  = CGRectMake(0, 20, self.view.bounds.size.width - 140, 25);
        self.titleLbl.center = CGPointMake(self.view.bounds.size.width/2, _titleLbl.center.y);
    }
    else {
        self.titleLbl.text = @"Group";
        self.chatName = @"Group";
    }
    
    [self getMessagesBeforeNow];
}


#pragma mark - Actions

- (void)postMessage:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    btn.alpha = 0.5f;
    btn.enabled = NO;
    
    if (self.messageInput.text.length > 0) {

        __weak typeof(self)weakSelf = self;
        
        NSString *msgText = self.messageInput.text;
        
        [[SPCMessageManager sharedInstance] sendMessage:msgText
                          toRecipients:self.recipientKeyStr
                 withCompletionHandler:^(NSString *msgKeyStr, NSString *threadKeystr){
                     
                     __strong typeof(weakSelf)strongSelf = weakSelf;
                     
                     if (!strongSelf) {
                         return ;
                     }

                     [Flurry logEvent:@"CHAT_MSG_SENT"];
                     for (int i = (int)(strongSelf.messagesArray.count - 1); i >= 0; i--) {
                         SPCMessage *sentMessage = (SPCMessage *)[strongSelf.messagesArray objectAtIndex:i];
                         
                         if ([sentMessage.messageText isEqualToString:msgText]) {
                             //NSLog(@"set key str for msg after posting!");
                             sentMessage.keyStr = msgKeyStr;
                            
                             //NSLog(@"set key str for thread after posting!");
                             [strongSelf updateThreadWithKeyStr:threadKeystr];
                             break;
                         }
                     }
                     
                     NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
                     strongSelf.dateThreadLastUpdated = nowIntervalMS;
                 }
                          errorHandler:^(NSError *error){
                          }
         ];
         

        [self updateLocally];
        self.messageInput.text = nil;
        
        self.composeBarView.frame =  CGRectMake(0.0f, CGRectGetMaxY(self.tableView.frame), self.view.frame.size.width, 46);
        self.messageInput.frame = CGRectMake(13, 8, CGRectGetWidth(self.view.frame)-68, 30);
        self.sendMsgButton.frame = CGRectMake(CGRectGetWidth(self.view.frame)-53, 8, 51, 30);
        
        //reset view
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:.5];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDelegate:self];
        self.placeholderLabel.alpha = 1;
        [UIView commitAnimations];
    }
}

- (void)buttonHighlight:(id)sender{
    UIButton *btn = (UIButton *)sender;
    btn.alpha = .5;
}

- (void)buttonCancel:(id)sender{
    UIButton *btn = (UIButton *)sender;
    btn.alpha = 1.0f;
}

-(void)cancel {
    [_msgsTimer invalidate];
    
    if (self.viewingFromProfile) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)showAuthor:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    NSInteger adjIndex = btn.tag;
    SPCMessage *message = (SPCMessage *)self.eventsArray[adjIndex];
    
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:message.author.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)showOptions:(id)sender {
    NSLog(@"do stuff for show options!");
    
    // Alert view controller
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    
    
    // Alert view controller - alerts
    alertViewController.alertTitle = self.titleLbl.text;
    
    
    // - Notifications
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Turn off notifications", nil)
                                                             style:SPCAlertActionStyleNormal
                                                           handler:^(SPCAlertAction *action) {
                                                               
                                                               //TODO -- WHEN API CALL IS AVAILABLE
                                                               
                                                           }]];
        
    // - Delete
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil)
                                                             style:SPCAlertActionStyleDestructive
                                                           handler:^(SPCAlertAction *action) {
                                                               
                                                               [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteMsgThread" object:self.messageThread.keyStr];
                                                               [self cancel];
                                                               
                                                           }]];
    
    
    // We only support Block w/in 1:1 chats
    if (self.participants.count == 1) {
        
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Block", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
        
            Person *tempPerson = (Person *)self.participants[0];
            
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Block %@?", nil), tempPerson.displayName];
            
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Block", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                
                [MeetManager blockUserWithId:tempPerson.recordID resultCallback:^(NSDictionary *result) {

                    
                    //Show confirmation?
                    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 165)];
                    contentView.backgroundColor = [UIColor whiteColor];
                    
                    UILabel *contentTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 270, 30)];
                    contentTitleLabel.font = [UIFont boldSystemFontOfSize:20];
                    contentTitleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
                    contentTitleLabel.backgroundColor = [UIColor clearColor];
                    contentTitleLabel.text = NSLocalizedString(@"Blocked!",nil);
                    contentTitleLabel.textAlignment = NSTextAlignmentCenter;
                    [contentView addSubview:contentTitleLabel];
                    
                    UILabel *contentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 250, 60)];
                    contentMessageLabel.font = [UIFont systemFontOfSize:16];
                    contentMessageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
                    contentMessageLabel.backgroundColor = [UIColor clearColor];
                    contentMessageLabel.center=CGPointMake(contentView.center.x, contentMessageLabel.center.y);
                    contentMessageLabel.text = [NSString stringWithFormat:@"You have blocked %@.",tempPerson.displayName];
                    contentMessageLabel.numberOfLines=0;
                    contentMessageLabel.lineBreakMode=NSLineBreakByWordWrapping;
                    contentMessageLabel.textAlignment = NSTextAlignmentCenter;
                    [contentView addSubview:contentMessageLabel];
                    
                    UIColor *contentCancelBgColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
                    UIColor *contentCancelTextColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
                    CGRect contentCancelBtnFrame = CGRectMake(70,100,130,40);
                    
                    [PXAlertView showAlertWithView:contentView cancelTitle:@"OK" cancelBgColor:contentCancelBgColor
                                   cancelTextColor:contentCancelTextColor
                                       cancelFrame:contentCancelBtnFrame
                                        completion:^(BOOL cancelled) {
                                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                            [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteMsgThread" object:self.messageThread.keyStr];
                                            
                                            
                                            [self cancel];
                                        }];
                
                } faultCallback:^(NSError *fault) {
    
                }];
                
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
    }
    
  
    // - Cancel
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:SPCAlertActionStyleCancel
                                                           handler:nil]];
    
    // Alert view controller - show
    [self presentViewController:alertViewController animated:YES completion:nil];
}


#pragma mark Private

-(void)reloadData {
    
    [self insertEventsAsNeeded];
    [self.tableView reloadData];
}

-(void)updateLocally {
    NSString *msgStr = self.messageInput.text;
    
    NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate])*1000;
    NSNumber *nowNum = @(nowIntervalMS);

    NSString *userNameStr;
    NSString *userTokenStr;

    userNameStr = self.profile.profileDetail.firstname;
    userTokenStr = [AuthenticationManager sharedInstance].currentUser.userToken;
    
    NSMutableDictionary *mutableAuthorDictionary = [NSMutableDictionary dictionary];
    if (userNameStr) {
        mutableAuthorDictionary[@"firstname"] = userNameStr;
    }
    if (userTokenStr) {
        mutableAuthorDictionary[@"userToken"] = userTokenStr;
    }
    
    NSMutableDictionary *mutablePostedMsgDictionary = [NSMutableDictionary dictionary];
    if (nowNum) {
        mutablePostedMsgDictionary[@"createdDate"] = nowNum;
    }
    if (msgStr) {
        mutablePostedMsgDictionary[@"text"] = msgStr;
    }
    if (mutableAuthorDictionary) {
        mutablePostedMsgDictionary[@"author"] = [NSDictionary dictionaryWithDictionary:mutableAuthorDictionary];
    }
    
    SPCMessage *newMessage = [[SPCMessage alloc] initWithAttributes:mutablePostedMsgDictionary];
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.messagesArray];
    [tempArray addObject:newMessage];
    self.messagesArray = [NSArray arrayWithArray:tempArray];
    [self.messageThread updateLastReadDate];
    
    [self reloadData];
    [self scrollToLastMessage];
}

-(void)updateThreadWithKeyStr:(NSString *)keyStr {
    
    if (!self.messageThread) {
 
        SPCMessageThread *newThread = [[SPCMessageThread alloc] init];
        [newThread configureWithParticipants:self.participants andMessages:self.messagesArray threadID:keyStr];
        self.messageThread = newThread;
    }
    else {
        self.messageThread.messages = [NSArray arrayWithArray:self.messagesArray];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMessageThread" object:self.messageThread];
}

-(void)insertEventsAsNeeded {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    NSDate *dateOfPreviousMsg;
    
    for (int i = 0; i < self.messagesArray.count; i++) {
        
        SPCMessage *tempMsg = self.messagesArray[i];
        
        if (i == 0) {
            [tempArray addObject:tempMsg.displayDate];
        }
        else {
            //add another date/time stamp if it's been 'awhile'
            NSTimeInterval seconds = [tempMsg.createdDate timeIntervalSinceReferenceDate];
            NSTimeInterval prevSecond = [dateOfPreviousMsg timeIntervalSinceReferenceDate];
            if ((seconds - prevSecond) > (60 * 120)) {
                [tempArray addObject:tempMsg.displayDate];
            }
        }
        
        dateOfPreviousMsg = tempMsg.createdDate;
        [tempArray addObject:tempMsg];
        
    }

    self.eventsArray = [NSArray arrayWithArray:tempArray];
}

-(NSArray *)insertEventsAsNeededForArray:(NSArray *)messages {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    NSDate *dateOfPreviousMsg;
    
    for (int i = 0; i < messages.count; i++) {
        
        SPCMessage *tempMsg = messages[i];
        
        if (i == 0) {
            [tempArray addObject:tempMsg.displayDate];
        }
        else {
            //add another date/time stamp if it's been 'awhile'
            NSTimeInterval seconds = [tempMsg.createdDate timeIntervalSinceReferenceDate];
            NSTimeInterval prevSecond = [dateOfPreviousMsg timeIntervalSinceReferenceDate];
            if ((seconds - prevSecond) > (60 * 120)) {
                [tempArray addObject:tempMsg.displayDate];
            }
        }
        
        dateOfPreviousMsg = tempMsg.createdDate;
        [tempArray addObject:tempMsg];
        
    }
    
    NSArray *tempEvents = [NSArray arrayWithArray:tempArray];
    
    return tempEvents;
}

-(void)pollForThreadUpdates {
    
    __weak typeof(self)weakSelf = self;
    //NSLog(@"poll for updates to thread with %@",self.titleLbl.text);
    if (self.messageThread.keyStr && !self.fetchInProgress) {
        
        [[SPCMessageManager sharedInstance] getMessagesSince:self.dateThreadLastUpdated
                                  threadKey:self.messageThread.keyStr
                      withCompletionHandler:^(NSArray *messages){
                          __strong typeof(weakSelf)strongSelf = weakSelf;
                          if (!strongSelf) {
                              return ;
                          }
                      
                          strongSelf.fetchInProgress = NO;
                          BOOL anyNewMsgs = NO;
                          
                          if (messages.count > 0) {
                              //NSLog(@"got new messages?");
                              NSMutableArray *tempArray = [NSMutableArray arrayWithArray:strongSelf.messageThread.messages];
                             
                              //do we have these messages already? (i.e. local copies..)
                              for (int i = 0; i < messages.count; i++) {
                                  SPCMessage *msg = messages[i];
                                  NSString *msgKeyStr = msg.keyStr;
                                  //NSLog(@"new message test?  ---- msgKeyStr %@", msgKeyStr);
                                  BOOL newMessage = YES;
                                  
                                  for (int j = 0; j < strongSelf.messageThread.messages.count; j++) {
                                      SPCMessage *oldMsg = strongSelf.messageThread.messages[j];
                                      if ([msgKeyStr isEqualToString:oldMsg.keyStr]) {
                                          newMessage = NO;
                                          //NSLog(@"already had this message?");
                                          break;
                                      }
                                  }
                                  
                                  if (newMessage) {
                                      //NSLog(@"should be a new message???");
                                      //NSLog(@"new message test?  ---- msgKeyStr %@", msg.keyStr);
                                      anyNewMsgs = YES;
                                      
                                      if (msg.author.firstname.length == 0) {
                                          
                                          for (int k = 0; k < strongSelf.participants.count; k++) {
                                              
                                              Person *tempPartcip = strongSelf.participants[k];
                                              if ([tempPartcip.userToken isEqualToString:msg.author.userToken]) {
                                                  msg.author = tempPartcip;
                                                  break;
                                              }
                                          }
                                          
                                      }
                                      
                                      [tempArray addObject:msg];
                                  }
                              }
                              
                              
                              
                              if (anyNewMsgs) {
                                  
                                  strongSelf.messageThread.messages = [NSArray arrayWithArray:tempArray];
                                  [strongSelf.messageThread configureDates];
                                  strongSelf.dateThreadLastUpdated = [strongSelf.messageThread.dateOfMostRecentThreadActivity timeIntervalSince1970] * 1000;
                                  [strongSelf.messageThread updateLastReadDate];
                                  
                                  
                                  strongSelf.messagesArray = [NSArray arrayWithArray:tempArray];
                                  [strongSelf reloadData];
                              
                                  [strongSelf scrollToLastMessage];
                              }
                          }
                      }
                               errorHandler:^(NSError *error) {
                                   NSLog(@"error %@",error);
                                   __strong typeof(weakSelf)strongSelf = weakSelf;
                                   strongSelf.fetchInProgress = NO;
                               }
         ];
    }
}

-(void)getMessagesBeforeNow {

   //is this an existing thread?  do we need to get any pre-existing messages?
    
    NSTimeInterval nowIntervalMS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]) * 1000;
    
    if (self.messageThread.keyStr) {

        __weak typeof(self)weakSelf = self;
        self.fetchInProgress = YES;
        
        
        [[SPCMessageManager sharedInstance] getMessagesBefore:nowIntervalMS
                                   threadKey:self.messageThread.keyStr
                       withCompletionHandler:^(NSArray *messages, NSString *pagingKeyStr){
                           __strong typeof(weakSelf)strongSelf = weakSelf;
                           if (!strongSelf) {
                               return ;
                           }
                           
                           if (pagingKeyStr.length > 0) {
                               self.threadPageKeyStr = pagingKeyStr;
                           }
                           
                           strongSelf.dateThreadLastUpdated = nowIntervalMS;
                           
                           NSMutableArray *tempMessages = [NSMutableArray arrayWithArray:messages];
                           
                           //match messsage token strings with full author info that was provided with thread
                           for (int i = 0; i< tempMessages.count; i++) {
                               
                               SPCMessage *msg = tempMessages[i];
                               if (msg.author.firstname.length == 0) {

                                   for (int k = 0; k < strongSelf.participants.count; k++) {
                                       Person *tempPartcip = strongSelf.participants[k];
                                       if ([tempPartcip.userToken isEqualToString:msg.author.userToken]) {
                                           msg.author = tempPartcip;
                                           break;
                                       }
                                   }
                               }
                           }
                           
                           
                           strongSelf.messageThread.messages = [NSArray arrayWithArray:tempMessages];
                           strongSelf.messagesArray = [NSArray arrayWithArray:tempMessages];
                           
                           [strongSelf reloadData];
                           [strongSelf scrollToLastMessage];
                           
                           [strongSelf performSelector:@selector(readyToFetch) withObject:nil afterDelay:1];
                           
                       } errorHandler:^(NSError *error) {
                           //NSLog(@"error %@",error);
                           __strong typeof(weakSelf)strongSelf = weakSelf;
                           strongSelf.fetchInProgress = NO;
                       }];
    }
}

-(void)readyToFetch {
    self.fetchInProgress = NO;
}

-(void)getPreviousMessages {
    
    if (self.readyToFetchPreviousMsgs && !self.fetchInProgress && self.threadPageKeyStr.length > 0) {
       
        self.fetchInProgress = YES;
        self.readyToFetchPreviousMsgs = NO;
        
        __weak typeof(self)weakSelf = self;
        
        [[SPCMessageManager sharedInstance] getMessagesWithPageKey:self.threadPageKeyStr
                                        threadKey:self.messageThread.keyStr
                            withCompletionHandler:^(NSArray *messages, NSString *pagingKeyStr){
                                
                                __strong typeof(weakSelf)strongSelf = weakSelf;
                                if (!strongSelf) {
                                    return ;
                                }
                                
                                if (pagingKeyStr.length > 0) {
                                    self.threadPageKeyStr = pagingKeyStr;
                                }
                                else {
                                    self.threadPageKeyStr = @"";
                                }
                                
                                BOOL gotFreshPreviousMessages = NO;
                                
                                
                                NSMutableArray *tempMessages = [NSMutableArray arrayWithArray:messages];
                                NSMutableArray *tempFreshMsgs = [[NSMutableArray alloc] init];
                                
                                //do we have these messages already? (i.e. local copies..)
                                for (int i = 0; i < tempMessages.count; i++) {
                                    SPCMessage *msg = tempMessages[i];
                                    NSString *msgKeyStr = msg.keyStr;
                                    //NSLog(@"new message test?  ---- msgKeyStr %@", msgKeyStr);
                                    BOOL newMessage = YES;
                                    
                                    for (int j = 0; j < strongSelf.messageThread.messages.count; j++) {
                                        SPCMessage *oldMsg = strongSelf.messageThread.messages[j];
                                        if ([msgKeyStr isEqualToString:oldMsg.keyStr]) {
                                            newMessage = NO;
                                            //NSLog(@"already had this message?");
                                            break;
                                        }
                                    }
                                    
                                    //add de-duplicated (fresh!) messages to our array
                                    
                                    if (newMessage) {
                                        
                                        gotFreshPreviousMessages = YES;
                                        //match messsage token strings with full author info that was provided with thread
                                        if (msg.author.firstname.length == 0) {
                                            
                                            for (int k = 0; k < strongSelf.participants.count; k++) {
                                                Person *tempPartcip = strongSelf.participants[k];
                                                if ([tempPartcip.userToken isEqualToString:msg.author.userToken]) {
                                                    msg.author = tempPartcip;
                                                    break;
                                                }
                                            }
                                        }
                                        [tempFreshMsgs addObject:msg];
                                    }
                                }
                                
                                
                                if (gotFreshPreviousMessages) {
                                    NSLog(@"got fresh previous!!");
                                    
                                    //calculate height of new events in order to update our offest
                                    NSArray *newEvents = [self insertEventsAsNeededForArray:tempFreshMsgs];
                                    NSInteger newOffset = 0;
                                
                                    for (int i = 0; i  < newEvents.count; i++) {
                                    
                                        NSObject *object = newEvents[i];
                                        
                                        if ([object isKindOfClass:[SPCMessage class]]) {
                                            SPCMessage *message = (SPCMessage *)newEvents[i];
                                            newOffset = newOffset + message.messageHeight + 20;
                                        }
                                        else {
                                            newOffset = newOffset + 30;
                                        }
                                    }
                                
                                    //add existing messages to array after the fresh ones we just fetched!
                                    [tempFreshMsgs addObjectsFromArray:strongSelf.messagesArray];
                                    strongSelf.messageThread.messages = [NSArray arrayWithArray:tempFreshMsgs];
                                    strongSelf.messagesArray = [NSArray arrayWithArray:tempFreshMsgs];
                                    strongSelf.fetchInProgress = NO;
                                    [strongSelf reloadData];
                                   
                                    //update offset to account for new events
                                    [strongSelf.tableView setContentOffset:CGPointMake(0, newOffset)];
                                    
                                    //Prep to load the next batch
                                    strongSelf.fetchInProgress = NO;
                                }
                                     
                                
                            }
                                     errorHandler:^(NSError *error) {
                                         NSLog(@"error %@",error);
                                         __strong typeof(weakSelf)strongSelf = weakSelf;
                                         strongSelf.fetchInProgress = NO;
                                     }];
    }
}

-(void)scrollToLastMessage {
    
    float lastRow = self.eventsArray.count - 1;
    
    if (self.threadPageKeyStr.length > 0) {
        lastRow = self.eventsArray.count;
    }

    if (lastRow > 0) {
        NSLog(@"readyToFetchPreviousMsgs = NO - scrolling to last message!");
        self.readyToFetchPreviousMsgs = NO;
    
        NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
        [self.tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}


@end
