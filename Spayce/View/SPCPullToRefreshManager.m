//
//  SPCPullToRefreshManager.m
//  Spayce
//
//  Created by Jake Rosin on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCPullToRefreshManager.h"
#import "MNMPullToRefreshManager.h"
#import "SPCPullToRefreshView.h"

@interface SPCPullToRefreshManager()<MNMPullToRefreshManagerClient, MNMPullToRefreshManagerListener>

@property (strong, nonatomic) MNMPullToRefreshManager *pullToRefreshManager;
@property (assign, nonatomic) CGFloat fadingViewAlpha;
@property (strong, nonatomic) SPCPullToRefreshView *pullingView;

@end

@implementation SPCPullToRefreshManager

- (instancetype)initWithScrollView:(UIScrollView *)scrollView {
    self = [super init];
    if (self) {
        SPCPullToRefreshView * pullToRefreshView = [[SPCPullToRefreshView alloc] init];
        SPCPullToRefreshView * pullToRefreshLoadingView = [[SPCPullToRefreshView alloc] init];
        self.pullToRefreshManager = [[MNMPullToRefreshManager alloc] initWithPullToRefreshView:pullToRefreshView
                                                                      pullToRefreshLoadingView:pullToRefreshLoadingView
                                                                                    scrollView:scrollView
                                                                                    withClient:self];
        self.pullToRefreshManager.listener = self;
        self.pullingView = pullToRefreshView;
        self.loadingView = pullToRefreshLoadingView;
        self.fadingViewAlpha = 1.0f;
    }
    return self;
}

- (void)setFadingHeaderView:(UIView *)fadingHeaderView {
    _fadingHeaderView = fadingHeaderView;
    self.fadingHeaderView.alpha = self.fadingViewAlpha;
    self.fadingHeaderView.hidden = self.fadingViewAlpha <= 0;
}

#pragma mark - properties

-(BOOL)isLoading {
    return self.pullToRefreshManager.isLoading;
}

#pragma mark - UIScrollView delegate methods 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.pullToRefreshManager tableViewScrolled];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.pullToRefreshManager tableViewReleased];
}


#pragma mark - MNMPullToRefreshManagerClient

- (void)pullToRefreshTriggered:(MNMPullToRefreshManager *)manager {
    [self.delegate pullToRefreshTriggered:self];
}

- (void)pullToRefreshManager:(MNMPullToRefreshManager *)manager didChangeOffsetWithContentProportionDisplayed:(CGFloat)contentProportion refreshProportionDisplayed:(CGFloat)refreshProportion contentRefreshMarginDisplayed:(CGFloat)contentRefreshMarginDisplayed {
    self.fadingViewAlpha = 1.0 - contentRefreshMarginDisplayed;
    if (self.fadingHeaderView) {
        self.fadingHeaderView.alpha = self.fadingViewAlpha;
        self.fadingHeaderView.hidden = self.fadingViewAlpha <= 0;
    }
}


#pragma mark - Refreshed content

- (void)refreshFinished {
    [self.pullToRefreshManager tableViewReloadFinishedAnimated:YES];
}

- (void)refreshFinishedAnimated:(BOOL)animated {
    [self.pullToRefreshManager tableViewReloadFinishedAnimated:animated];
}

- (void)setPullToRefreshViewVisible:(BOOL)visible {
    [self.pullToRefreshManager setPullToRefreshViewVisible:visible];
}

- (void)hideContentUntilStateChange {
    [self.pullingView hideContentUntilStateChange];
    [self.loadingView hideContentUntilStateChange];
}

@end
