//
//  SPCHereVenueSelectionViewController.m
//  Spayce
//
//  Created by Jake Rosin on 6/18/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHereVenueSelectionViewController.h"

#define STATUS_BAR_HEIGHT 20
#define TITLE_HEIGHT 50
#define VENUE_HEIGHT 50
#define DIVIDER_HEIGHT 1
#define FOOTER_HEIGHT 41

#define HORIZ_MARGIN 10

@interface SPCHereVenueSelectionViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *statusBarBackground;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, assign) NSInteger venuesPerPage;
@property (nonatomic, strong) UIColor * contentBackgroundColor;

@end

@implementation SPCHereVenueSelectionViewController

- (instancetype) init {
    self = [super init];
    if (self) {
        self.venuesPerPage = 3;
        self.contentBackgroundColor = [UIColor colorWithRGBHex:0x2d3747];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithRGBHex:0x27303e];
    
    // title, scroll, footer
    [self.view addSubview:self.statusBarBackground];
    [self.view addSubview:self.titleView];
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.footerView];
    
    // resize everything as appropriate
    [self sizeToFitPerPage:self.venuesPerPage];
}


#pragma mark - Property Accessors

- (UIView *)statusBarBackground {
    if (!_statusBarBackground) {
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 0)];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
            view.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), STATUS_BAR_HEIGHT);
        }
        _statusBarBackground = view;
    }
    return _statusBarBackground;
}

- (UIView *)titleView {
    if (!_titleView) {
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.statusBarBackground.frame), CGRectGetWidth(self.view.frame), TITLE_HEIGHT)];
        view.backgroundColor = self.contentBackgroundColor;
        
        // contains title label and close button
        // TODO: real button close icon
        UIImage *closeImage = [UIImage imageNamed:@"camera-cancel"];
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 45, 45)];
        [closeButton setImage:closeImage forState:UIControlStateNormal];
        closeButton.center = CGPointMake(CGRectGetWidth(view.frame) - 29, CGRectGetHeight(view.frame)/2.0);
        [closeButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(HORIZ_MARGIN, 0, CGRectGetWidth(view.frame) - HORIZ_MARGIN - 58, TITLE_HEIGHT)];
        label.text = @"Multiple Venues on this Pin";
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor colorWithRed:68.0/255.0 green:197.0/255.0 blue:249.0/255.0 alpha:1.0];
        label.font = [UIFont spc_mediumSystemFontOfSize:16];
        label.numberOfLines = 1;
        
        [view addSubview:closeButton];
        [view addSubview:label];
        
        _titleView = view;
    }
    return _titleView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.titleView.frame), CGRectGetWidth(self.view.frame), VENUE_HEIGHT * self.venuesPerPage)];
        scrollView.backgroundColor = [UIColor clearColor];
        scrollView.pagingEnabled = YES;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.delegate = self;
        _scrollView = scrollView;
    }
    return _scrollView;
}


- (UIView *)footerView {
    if (!_footerView) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.scrollView.frame) + DIVIDER_HEIGHT, CGRectGetWidth(self.view.frame), FOOTER_HEIGHT)];
        _footerView.backgroundColor = self.contentBackgroundColor;
        [_footerView addSubview:self.pageControl];
    }
    return _footerView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), FOOTER_HEIGHT - DIVIDER_HEIGHT)];
        _pageControl.pageIndicatorTintColor = [UIColor colorWithRGBHex:0x27303e];
        _pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        [_pageControl addTarget:self action:@selector(pageSelectedWithPageControl:) forControlEvents:UIControlEventValueChanged];
    }
    return _pageControl;
}


#pragma mark - Property mutators / Mutator methods

- (void)setVenues:(NSArray *)venues {
    _venues = venues;
    if (_scrollView) {
        // clear out the scroll view...
        for (UIView * view in self.scrollView.subviews) {
            [view removeFromSuperview];
        }
        
        // add items (if they exist)
        NSInteger pages = 0;
        if (venues && venues.count > 0) {
            pages = ((venues.count-1) / self.venuesPerPage)+1;
            int page = 0;
            int venuesOnPage = 0;
            for (int i = 0; i < venues.count; i++) {
                Venue *venue = (Venue *)venues[i];
                UIView * view = [self makeVenueCellWithVenue:venue frameOrigin:CGPointMake(page * CGRectGetWidth(self.view.frame), VENUE_HEIGHT * venuesOnPage)];
                view.tag = i;
                [self.scrollView addSubview:view];
                venuesOnPage++;
                if (venuesOnPage >= self.venuesPerPage) {
                    page++;
                    venuesOnPage = 0;
                }
            }
        }
        self.scrollView.contentSize = CGSizeMake(pages*CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame));
        self.scrollView.contentOffset = CGPointMake(0, 0);
        [self.scrollView setNeedsDisplay];
        [self.scrollView setNeedsLayout];
        self.pageControl.currentPage = 0;
        self.pageControl.numberOfPages = pages;
        self.footerView.hidden = pages <= 1;
        
        [self.view setNeedsDisplay];
        [self.view setNeedsLayout];
    }
}

- (UIView *)makeVenueCellWithVenue:(Venue *)venue frameOrigin:(CGPoint)origin {
    // TODO: recycle these views, rather than create them for each new venue list?
    
    // convention: allow a margin at the top, showing the background.
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(origin.x, origin.y + DIVIDER_HEIGHT, CGRectGetWidth(self.scrollView.frame), VENUE_HEIGHT - DIVIDER_HEIGHT)];
    containerView.backgroundColor = self.contentBackgroundColor;
    [containerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(venueTapped:)]];
    
    // label?
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(HORIZ_MARGIN, 0, CGRectGetWidth(containerView.frame) - HORIZ_MARGIN*2, CGRectGetHeight(containerView.frame))];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont spc_regularSystemFontOfSize:16];
    label.numberOfLines = 1;
    
    NSRange range = [venue.displayName rangeOfString:@"," options:NSBackwardsSearch];
    if (range.location == NSNotFound) {
        label.text = venue.displayName;
    } else {
        label.text = [venue.displayName substringToIndex:range.location];
    }
    
    [containerView addSubview:label];
    
    return containerView;
}


- (void)sizeToFitPerPage:(NSInteger)numberOfVenues {
    self.venuesPerPage = numberOfVenues;
    if (_scrollView) {
        // resize scrollview
        self.scrollView.frame = CGRectMake(0.0, CGRectGetMaxY(self.titleView.frame), CGRectGetWidth(self.view.frame), VENUE_HEIGHT * self.venuesPerPage);
        // reposition footer
        self.footerView.frame = CGRectMake(0.0, CGRectGetMaxY(self.scrollView.frame) + DIVIDER_HEIGHT, CGRectGetWidth(self.view.frame), FOOTER_HEIGHT);
        
        // resize view
        self.view.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMaxY(self.footerView.frame));
    }
    
    if (_venues && _venues.count > 0) {
        // reposition venues
        self.venues = _venues;
    }
}

#pragma mark - Button / Tap targets

- (void)dismiss:(id)sender {
    // dismiss this view
    NSLog(@"dismiss");
    if ([self.delegate respondsToSelector:@selector(dismissVenueSelectionViewController:animated:)]) {
        NSLog(@"delegate responds");
        [self.delegate dismissVenueSelectionViewController:self animated:YES];
    } else {
        NSLog(@"delegate does NOT respond");
        [self.navigationController popToViewController:self animated:YES];
    }
}

- (void)venueTapped:(UIGestureRecognizer *)sender {
    NSInteger index = sender.view.tag;
    
    if (self.selectingFromFullScreenMap) {
        if ([self.delegate respondsToSelector:@selector(venueSelectionViewController:didSelectVenueFromFullScreen:dismiss:)]) {
            [self.delegate venueSelectionViewController:self didSelectVenueFromFullScreen:self.venues[index] dismiss:YES];
        }
    }
    else {
        if ([self.delegate respondsToSelector:@selector(venueSelectionViewController:didSelectVenue:dismiss:)]) {
            [self.delegate venueSelectionViewController:self didSelectVenue:self.venues[index] dismiss:YES];
        }
    }
}

- (void)pageSelectedWithPageControl:(UIPageControl *)control {
    NSInteger page = control.currentPage;
    self.scrollView.contentOffset = CGPointMake(page * CGRectGetWidth(self.scrollView.frame), 0);
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // offset: add a half page, so we snap upon > 1/2 the screen being scrolled.
    NSInteger offset = scrollView.contentOffset.x + CGRectGetWidth(scrollView.frame) / 2.0;
    NSInteger pageWidth = CGRectGetWidth(scrollView.frame);
    NSInteger page = offset / pageWidth;
    
    if (_pageControl) {
        _pageControl.currentPage = page;
    }
}

@end
