//
//  SPCActivityViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCActivityViewController.h"

//manager

#import "PNSManager.h"
#import "SPCMessageManager.h"

//controllers
#import "SPCNotificationsViewController.h"
#import "SPCMessagesThreadsViewController.h"

//view
#import "HMSegmentedControl.h"

#import "Flurry.h"

@interface SPCActivityViewController ()


@property (nonatomic, strong) UIViewController *currentViewController;

@property (nonatomic, strong) UIView *segControlContainer;
@property (nonatomic, strong) HMSegmentedControl *hmSegmentedControl;
@property (nonatomic, strong) UILabel *unreadNotifCountLbl;
@property (nonatomic, strong) UILabel *unreadMsgThreadCountLbl;

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) SPCMessagesThreadsViewController *messagesViewController;
@property (nonatomic, strong) SPCNotificationsViewController *notificationsViewController;

@end

@implementation SPCActivityViewController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    @try {
        [[PNSManager sharedInstance] removeObserver:self forKeyPath:@"totalCount"];
        [[SPCMessageManager sharedInstance] removeObserver:self forKeyPath:@"unreadThreadCount"];
    }
    @catch (NSException *exception) {}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setHidden:YES];
    
    [self.view addSubview:self.segControlContainer];
    [self.view addSubview:self.containerView];
    
    [self.containerView addSubview:self.notificationsViewController.view];
    self.notificationsViewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width,self.containerView.frame.size.height);
    self.currentViewController = self.notificationsViewController;
    
    self.messagesViewController.view.frame = CGRectMake(self.view.bounds.size.width, 0, self.view.bounds.size.width,self.containerView.frame.size.height);
    [self.containerView addSubview:self.messagesViewController.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateActivityBadges) name:@"checkForNotifBadgeUpdate" object:nil];
    
    // Start observing the value of the total unread notifications & message threads counts
    [[PNSManager sharedInstance] addObserver:self forKeyPath:@"totalCount" options:NSKeyValueObservingOptionInitial context:nil];
    [[SPCMessageManager sharedInstance] addObserver:self forKeyPath:@"unreadThreadCount" options:NSKeyValueObservingOptionInitial context:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([PNSManager sharedInstance].unreadNews > 0) {
        NSLog(@"%li unread news!",[PNSManager sharedInstance].unreadNews);
        self.unreadNotifCountLbl.text = [NSString stringWithFormat:@"%li",[PNSManager sharedInstance].unreadNews];
    }
    else {
        NSLog(@"no unread news!");
        self.unreadNotifCountLbl.text = @"";
    }
    
    
    if ([SPCMessageManager sharedInstance].unreadThreadCount > 0) {
        NSLog(@"%li unread threads!",[SPCMessageManager sharedInstance].unreadThreadCount);
        self.unreadMsgThreadCountLbl.text = [NSString stringWithFormat:@"%li",[SPCMessageManager sharedInstance].unreadThreadCount];
    }
    else {
        NSLog(@"no unread threads!");
        self.unreadMsgThreadCountLbl.text = @"";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors

- (UIView *)segControlContainer {
    if (!_segControlContainer) {
        _segControlContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 50)];
        _segControlContainer.backgroundColor = [UIColor whiteColor];
        
        [_segControlContainer addSubview:self.hmSegmentedControl];
        
        CGFloat fSepWidth = 1.0f / [UIScreen mainScreen].scale;
        CGFloat fSepHeight = 17.0f;
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - fSepWidth / 2.0f, 20, fSepWidth, fSepHeight)];
        sepLine.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [_segControlContainer addSubview:sepLine];
        
        _segControlContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        _segControlContainer.layer.shadowOffset = CGSizeMake(0, 1.0f/[UIScreen mainScreen].scale);
        _segControlContainer.layer.shadowOpacity = 0.12f;
        _segControlContainer.layer.shadowRadius = 1.0f/[UIScreen mainScreen].scale;
        
        UIView *borderLine = [[UIView alloc] initWithFrame:CGRectMake(0, _segControlContainer.frame.size.height-1, _segControlContainer.frame.size.width, 1)];
        borderLine.backgroundColor = [UIColor lightGrayColor];
        borderLine.alpha = 0.25;
        [_segControlContainer addSubview:borderLine];
        
        [_segControlContainer addSubview:self.unreadNotifCountLbl];
        [_segControlContainer addSubview:self.unreadMsgThreadCountLbl];
    }
    
    return _segControlContainer;
}

- (HMSegmentedControl *)hmSegmentedControl {
    if (!_hmSegmentedControl) {
        _hmSegmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"NOTIFICATIONS", @"MESSAGES"]];
        _hmSegmentedControl.frame = CGRectMake(0,15, _segControlContainer.frame.size.width, 35);
        [_hmSegmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        _hmSegmentedControl.backgroundColor = [UIColor whiteColor];
        _hmSegmentedControl.textColor = [UIColor colorWithRed:139.0f/255.0f  green:153.0f/255.0f  blue:175.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectedTextColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f + (self.view.bounds.size.width >= 375 ? 1.0f : 0.0f)];
        _hmSegmentedControl.selectionIndicatorColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStripe;
        _hmSegmentedControl.selectionIndicatorHeight = 3.0f;
        _hmSegmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        _hmSegmentedControl.shouldAnimateUserSelection = YES;
        _hmSegmentedControl.selectedSegmentIndex = 0;
        
    }
    
    return _hmSegmentedControl;
}

- (UIView *)containerView {
    if (!_containerView ) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.segControlContainer.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.segControlContainer.frame))];
        _containerView.backgroundColor = [UIColor clearColor];
    }
    return _containerView;
}

-(SPCNotificationsViewController *)notificationsViewController {
    if (!_notificationsViewController) {
        _notificationsViewController = [[SPCNotificationsViewController alloc] init];
        [_notificationsViewController initializeTableView];
        
    }
    return _notificationsViewController;
}

-(SPCMessagesThreadsViewController *)messagesViewController {
    if (!_messagesViewController) {
        _messagesViewController = [[SPCMessagesThreadsViewController alloc] init];
    }
    return _messagesViewController;
}


-(UILabel *)unreadNotifCountLbl {
    if (!_unreadNotifCountLbl) {
        
        float xOrigin = 125;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            xOrigin = 148;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            xOrigin = 161;
        }
        
        
        _unreadNotifCountLbl = [[UILabel alloc] initWithFrame:CGRectMake(xOrigin, 20, 30, 20)];
        _unreadNotifCountLbl.backgroundColor = [UIColor clearColor];
        _unreadNotifCountLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:10];
        _unreadNotifCountLbl.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _unreadNotifCountLbl.textAlignment = NSTextAlignmentLeft;

    }
    
    return _unreadNotifCountLbl;
}

-(UILabel *)unreadMsgThreadCountLbl {
    if (!_unreadMsgThreadCountLbl) {
        
        float xOrigin = 273;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            xOrigin = 310;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            xOrigin = 335;
        }
        
        _unreadMsgThreadCountLbl = [[UILabel alloc] initWithFrame:CGRectMake(xOrigin, 20, 30, 20)];
        _unreadMsgThreadCountLbl.backgroundColor = [UIColor clearColor];
        _unreadMsgThreadCountLbl.textAlignment = NSTextAlignmentLeft;
        _unreadMsgThreadCountLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:10];
        _unreadMsgThreadCountLbl.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        
    }
    return _unreadMsgThreadCountLbl;
}


#pragma mark - Actions

- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
    if (segmentedControl.selectedSegmentIndex == 0) {
        [Flurry logEvent:@"NOTIFS_VIEWED"];
        self.unreadMsgThreadCountLbl.text = @"";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"markAllThreadsAsRead" object:nil];
        self.currentViewController = self.notificationsViewController;
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             //make sure our seg control and nav bar are fully in place
                             self.notificationsViewController.view.center = CGPointMake(self.containerView.center.x, self.notificationsViewController.view.center.y);
                             self.messagesViewController.view.center = CGPointMake(self.containerView.bounds.size.width/2 + self.containerView.bounds.size.width, self.messagesViewController.view.center.y);
                             
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
        
    }
    if (segmentedControl.selectedSegmentIndex == 1) {
        [Flurry logEvent:@"CHAT_THREADS_VIEWED"];
        self.unreadNotifCountLbl.text = @"";
        [[PNSManager sharedInstance] markasReadNewsLogOnDelay];
    
        self.currentViewController = self.messagesViewController;
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             //make sure our seg control and nav bar are fully in place
                             self.notificationsViewController.view.center = CGPointMake(self.containerView.center.x - self.containerView.bounds.size.width, self.notificationsViewController.view.center.y);
                             self.messagesViewController.view.center = CGPointMake(self.containerView.bounds.size.width/2, self.messagesViewController.view.center.y);
                             
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
        
    }
    
}

- (void)setCurrentViewController:(UIViewController *)currentViewController {
    if (_currentViewController != currentViewController) {
        
        if (currentViewController == self.notificationsViewController) {
            [self.notificationsViewController refreshFollowRequests];
        }
        
        [_currentViewController willMoveToParentViewController:nil];
        [_currentViewController removeFromParentViewController];
        
        [self addChildViewController:currentViewController];
        [currentViewController viewDidAppear:YES];
        [currentViewController didMoveToParentViewController:self];
        
        _currentViewController = currentViewController;
    }
}


#pragma mark - Private 

- (void)updateActivityBadges {
    
    // This method gets called when the user taps away to a different tab from the tab bar!
    
    if (self.hmSegmentedControl.selectedSegmentIndex == 0) {
        //Mark all as read on slight delay to avoid impacting visual transition to new controller;
        [[PNSManager sharedInstance] markasReadNewsLogOnDelay];
        
        //update badge text here
        self.unreadNotifCountLbl.text = @"";
    }
    
    if (self.hmSegmentedControl.selectedSegmentIndex == 1) {
        //Mark all threads as read
        [[NSNotificationCenter defaultCenter] postNotificationName:@"markAllThreadsAsRead" object:nil];
        
        //update badge text here
        self.unreadMsgThreadCountLbl.text = @"";
    }
    
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [PNSManager sharedInstance]) {
        
        if ([keyPath isEqualToString:@"totalCount"])  {
            if ([PNSManager sharedInstance].unreadNews <= 0) {
                  self.unreadNotifCountLbl.text = @"";
            } else {
                self.unreadNotifCountLbl.text = [NSString stringWithFormat:@"%i",(int)[PNSManager sharedInstance].unreadNews];
            }
        }
    }
    
    if (object == [SPCMessageManager sharedInstance]) {
        if ([keyPath isEqualToString:@"unreadThreadCount"])  {
            if ([SPCMessageManager sharedInstance].unreadThreadCount <= 0) {
                self.unreadMsgThreadCountLbl.text = @"";
            } else {
                self.unreadMsgThreadCountLbl.text = [NSString stringWithFormat:@"%i",(int)[SPCMessageManager sharedInstance].unreadThreadCount];
            }
        }
    }

}



@end
