//
//  SPCHereVenueViewController.m
//  Spayce
//
//  Created by Jake Rosin on 8/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHereVenueViewController.h"

// Model
#import "SPCMapDataSource.h"

// View
#import "SPCView.h"
#import "TTFadeThumbSwitch.h"
#import "SPCSuggestionItemView.h"
#import "CoachMarks.h"

// Controller
#import "SPCCreateVenueViewController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"

// Manager
#import "VenueManager.h"
#import "AuthenticationManager.h"

// General
#import "SPCLiterals.h"

//Category
#import "UIApplication+SPCAdditions.h"

const CGFloat BUTTON_WIDTH = 45;
const CGFloat BUTTON_SLIDE_DURATION = 0.5f;
const CGFloat BUTTON_FADE_DURATION = 0.25f;

const CGFloat SEARCH_DELAY_MAP = 3.0f;
const CGFloat SEARCH_DELAY_LIST = 0.5f;


#define VENUE_COACH_MARK_TRIGGER_COUNT 3

@interface SPCHereVenueViewController () <UISearchBarDelegate, UITextFieldDelegate>

@property (nonatomic, strong) SPCHereVenueListViewController * listViewController;


@property (nonatomic, strong) UIView * navBar;
@property (nonatomic, strong) UIView * controlsBar;

@property (nonatomic, strong) UIButton * closeButton;
@property (nonatomic, strong) UILabel * titleLabel;
@property (nonatomic, strong) UIView *exploreSwitchContainer;
@property (nonatomic, strong) TTFadeThumbSwitch *exploreSwitch;

@property (nonatomic, strong) UIButton * buttonSearch;
@property (nonatomic, strong) UIButton * buttonRefreshLocation;
@property (nonatomic, strong) UIButton * buttonAddVenue;
@property (nonatomic, strong) UIButton * buttonMap;
@property (nonatomic, strong) UIButton * buttonList;
@property (nonatomic, strong) UILabel *suggestionsStatus;
@property (nonatomic, assign) CGSize keyboardSize;
@property (nonatomic, strong) NSArray * suggestedVenues;
@property (nonatomic, assign) BOOL initialSuggestionsSet;

@property (nonatomic, strong) NSArray * controlButtonsMapExploreOn;
@property (nonatomic, strong) NSArray * controlButtonsMapExploreOff;
@property (nonatomic, readonly) NSArray * controlButtonsMap;
@property (nonatomic, strong) NSArray * controlButtonList;

@property (nonatomic, strong) UIView * containerView;
@property (nonatomic, strong) UIView * mapContainerView;
@property (nonatomic, strong) UIView * listContainerView;

@property (nonatomic, readonly) BOOL isMapViewDisplayed;
@property (nonatomic, assign) BOOL isSearchActive;

@property (nonatomic, strong) UIColor * closeButtonColor;
@property (nonatomic, strong) UIColor * closeButtonColorPressed;
@property (nonatomic, strong) UIColor * controlsBackgroundColor;
@property (nonatomic, strong) UIColor * controlsSearchBackgroundColor;

@property (nonatomic, readonly) CGFloat headerBarHeight;

@property (nonatomic, strong) NSArray * venuesProvided;
@property (nonatomic, strong) NSArray * allVenues;
@property (nonatomic, strong) Venue * currentVenue;
@property (nonatomic, strong) Venue * deviceVenue;
@property (nonatomic, assign) SpayceState spayceState;
@property (nonatomic, strong) UIImageView *animationImageView;

@end

@implementation SPCHereVenueViewController

-(void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)loadView {
    [super loadView];
    
    [self.view addSubview:self.containerView];
    [self.containerView addSubview:self.mapContainerView];
    
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.controlsBar];
    [self.view addSubview:self.suggestionsView];
    
    [self switchToMap];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    // TODO configure?
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryPosted:) name:@"addMemoryLocally" object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navBar.hidden = NO;
    self.navigationController.navigationBarHidden = YES;
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.searchBar resignFirstResponder];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - properties 

-(SPCHereVenueMapViewController *)mapViewController {
    if (!_mapViewController) {
        _mapViewController = [[SPCHereVenueMapViewController alloc] init];
        _mapViewController.delegate = self;
        _mapViewController.isExplorePaused = YES;
        _mapViewController.isExploreOn = YES;
    }
    return _mapViewController;
}

-(SPCHereVenueListViewController *)listViewController {
    if (!_listViewController) {
        _listViewController = [[SPCHereVenueListViewController alloc] init];
        _listViewController.delegate = self;
    }
    return _listViewController;
}

- (UIView *)navBar {
    if (!_navBar) {
        UIView *navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 64)];
        navBar.backgroundColor = [UIColor whiteColor];
        navBar.hidden = YES;
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(-1.0, 28.0, 65.0, 30.0)];
        closeButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        closeButton.layer.cornerRadius = 2;
        closeButton.backgroundColor = [UIColor clearColor];
        [closeButton setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [closeButton setTitleColor:[UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:.7f] forState:UIControlStateHighlighted];
        [closeButton setTitle:@"Back" forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeButtonActivated:) forControlEvents:UIControlEventTouchUpInside];
        [closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchDown];
        [closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchDragEnter];
        [closeButton addTarget:self action:@selector(closeButtonReleased:) forControlEvents:UIControlEventTouchUpOutside];
        [closeButton addTarget:self action:@selector(closeButtonReleased:) forControlEvents:UIControlEventTouchDragExit];
        _closeButton = closeButton;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        titleLabel.frame = CGRectMake(CGRectGetMidX(navBar.frame) - 75.0, CGRectGetMidY(navBar.frame), 150.0, titleLabel.font.lineHeight);
        titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
        titleLabel.text = NSLocalizedString(@"Map", nil);
        _titleLabel = titleLabel;
        
        _buttonAddVenue = [self makeControlButtonWithImage:@"spayce-create-normal" highlightedImage:@"spayce-create-normal" action:@selector(createButtonPressed:)];
        _buttonAddVenue.center = CGPointMake(navBar.frame.size.width - _buttonAddVenue.frame.size.width/2, 10 + navBar.frame.size.height/2);
        [navBar addSubview:_buttonAddVenue];
        
        [navBar addSubview:closeButton];
        [navBar addSubview:titleLabel];
        
        _navBar = navBar;
    }
    return _navBar;
}

- (UIView *)controlsBar {
    if (!_controlsBar) {
        _controlsBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 64.0, CGRectGetWidth(self.view.frame), BUTTON_WIDTH)];
        _controlsBar.backgroundColor = self.controlsSearchBackgroundColor;
        _controlsBar.hidden = YES;
        
        // lots of elements share this bar: 5 buttons and a search bar.
        //
        // -search
        // -current pos.
        // -add venue
        // -switch to list
        // -switch to map
        // -search bar text entry
        //
        // Not all will be displayed at once, and their relative positions and sizes change
        // depending on how many are displayed.
        
        _buttonSearch = [self makeControlButtonWithImage:@"spayce-search-new-normal" highlightedImage:@"spayce-search-new-selected" action:@selector(searchButtonPressed:)];
        [_controlsBar addSubview:_buttonSearch];
        
        
        
        // Add the search bar...
        [_controlsBar addSubview:self.searchBar];
        
        _controlButtonsMapExploreOn = @[_buttonSearch, ];
        _controlButtonsMapExploreOff = @[_buttonSearch, ];
        _controlButtonList = @[_buttonSearch];
    }
    return _controlsBar;
}

- (NSArray *)controlButtonsMap {
    if (self.exploreSwitch.isOn) {
        return _controlButtonsMapExploreOn;
    } else {
        return _controlButtonsMapExploreOff;
    }
}

- (UIButton *)makeControlButtonWithImage:(NSString *)imageName highlightedImage:(NSString *)highlightedImageName action:(SEL)selector {
    UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, BUTTON_WIDTH, BUTTON_WIDTH)];
    button.backgroundColor = [UIColor clearColor];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:highlightedImageName] forState:UIControlStateHighlighted];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.hidden = NO;
    button.alpha = 1.0;
    button.userInteractionEnabled = YES;
    return button;
}

- (SPCSearchTextField *)searchBar {
    if (!_searchBar) {
        _searchBar = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(38, 0, CGRectGetWidth(_controlsBar.frame)-48, BUTTON_WIDTH)];
        _searchBar.delegate = self;
        _searchBar.leftView = nil; // no magnifying class
        _searchBar.backgroundColor = [UIColor clearColor];
        _searchBar.textColor = [UIColor whiteColor];
        _searchBar.tintColor = [UIColor colorWithRed:0.984 green:0.514 blue:0.094 alpha:1.000];
        _searchBar.font = [UIFont spc_regularSystemFontOfSize:14];
        _searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
        _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        _searchBar.leftView.tintColor = [UIColor whiteColor];
        _searchBar.placeholder = NSLocalizedString(@"Search nearby venues...", nil);
        _searchBar.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor  colorWithRed:118.0f/255.0f green:158.0f/255.0f blue:222.0f/255.0f alpha:1.0f], NSFontAttributeName: _searchBar.font };
        _searchBar.hidden = NO;
        _searchBar.alpha = 1.0f;
        _searchBar.userInteractionEnabled = YES;
        self.isSearchActive = YES;
    }
    return _searchBar;
}


- (UIView *)containerView {
    if (!_containerView) {
        SPCView * view = [[SPCView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        view.clipsToBounds = NO;
        [view setPointInsideBlock:^BOOL(CGPoint point, UIEvent *event) {
            return YES;
        }];
        
        _containerView = view;
    }
    return _containerView;
}

- (UIView *)mapContainerView {
    if (!_mapContainerView) {
        SPCView * view = [[SPCView alloc] initWithFrame:self.containerView.bounds];
        view.clipsToBounds = NO;
        [view setPointInsideBlock:^BOOL(CGPoint point, UIEvent *event) {
            return YES;
        }];
        
        _mapContainerView = view;
        
        [self addChildViewController:self.mapViewController];
        [self.mapViewController didMoveToParentViewController:self];
        [self.mapViewController viewWillAppear:YES];
        [_mapContainerView addSubview:self.mapViewController.view];
        [self.mapViewController viewDidAppear:YES];
        
        // allow the map to extend above this container (i.e. under where the header
        // bar is usually displayed).
        self.mapViewController.view.frame = _mapContainerView.bounds;
    }
    return _mapContainerView;
}

- (UIView *)listContainerView {
    if (!_listContainerView) {
        _listContainerView = [[UIView alloc] initWithFrame:self.containerView.bounds];
        _listContainerView.backgroundColor = [UIColor whiteColor];
        
        [self addChildViewController:self.listViewController];
        [self.listViewController didMoveToParentViewController:self];
        [self.listViewController viewWillAppear:YES];
        [_listContainerView addSubview:self.listViewController.view];
        [self.listViewController viewDidAppear:YES];
        
        self.listViewController.view.frame = CGRectMake(0.0, self.headerBarHeight, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.containerView.frame) - CGRectGetMaxY(self.controlsBar.frame) - 47);
    }
    return _listContainerView;
}

- (UIImageView *)animationImageView {
    if (!_animationImageView) {
        _animationImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        _animationImageView.backgroundColor = [UIColor whiteColor];
        _animationImageView.clipsToBounds = YES;
    }
    return _animationImageView;
}

- (UIView *)suggestionsView {
    
    if (!_suggestionsView) {
        _suggestionsView = [[UIView alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(self.controlsBar.frame),self.view.frame.size.width, 300)];
        _suggestionsView.backgroundColor = [UIColor whiteColor];
        _suggestionsView.hidden = YES;
        
        [_suggestionsView addSubview:self.suggestionsStatus];
        
        float initialY = 60;
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            initialY = 90;
        }
        
        UILabel *recLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, initialY, _suggestionsView.frame.size.width, 20)];
        recLabel.text = NSLocalizedString(@"Suggested Destinations", nil);
        recLabel.font = [UIFont spc_boldSystemFontOfSize:14];
        recLabel.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        recLabel.textAlignment = NSTextAlignmentCenter;
        [_suggestionsView addSubview:recLabel];
    }
    
    return _suggestionsView;
}

- (UILabel *)suggestionsStatus {
    if (!_suggestionsStatus) {
        _suggestionsStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, self.view.bounds.size.width, 20)];
        _suggestionsStatus.textAlignment = NSTextAlignmentCenter;
        _suggestionsStatus.font = [UIFont spc_regularSystemFontOfSize:12];
        _suggestionsStatus.textColor = [UIColor colorWithRed:131.0f/255.0f green:174.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    }
    return _suggestionsStatus;
}

- (CGFloat)headerBarHeight {
    CGFloat height = 0;
    if (self.navBar) {
        height = MAX(height, CGRectGetMaxY(self.navBar.frame));
    }
    if (self.controlsBar) {
        height = MAX(height, CGRectGetMaxY(self.controlsBar.frame));
    }
    return height;
}

- (UIColor *)closeButtonColor {
    if (!_closeButtonColor) {
        _closeButtonColor = [UIColor clearColor];
    }
    return _closeButtonColor;
}

- (UIColor *)closeButtonColorPressed {
    if (!_closeButtonColorPressed) {
        _closeButtonColorPressed = [UIColor clearColor];
    }
    return _closeButtonColorPressed;
}

- (UIColor *)controlsBackgroundColor {
    if (!_controlsBackgroundColor) {
        _controlsBackgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:0.9f];
    }
    return _controlsBackgroundColor;
}

- (UIColor *)controlsSearchBackgroundColor {
    if (!_controlsSearchBackgroundColor) {
        _controlsSearchBackgroundColor = [UIColor whiteColor];
    }
    return _controlsSearchBackgroundColor;
}

- (BOOL)isMapViewDisplayed {
    return _mapContainerView && !_listContainerView.superview;
}

- (void)setVerticalOffset:(CGFloat)verticalOffset {
    if (_verticalOffset != verticalOffset) {
        _verticalOffset = verticalOffset;
        // update container view....
        CGRect frame = self.containerView.frame;
        frame.origin.y = verticalOffset;
        self.containerView.frame = frame;
    }
}

- (void)setVerticalOffset:(CGFloat)verticalOffset withDuration:(CGFloat)duration {
    if (_verticalOffset != verticalOffset) {
        _verticalOffset = verticalOffset;
        [UIView animateWithDuration:duration animations:^{
            CGRect frame = self.containerView.frame;
            frame.origin.y = verticalOffset;
            self.containerView.frame = frame;
        }];
    }
}

#pragma mark - actions


- (void)showMapUserInterfaceAnimated:(BOOL)animated {
    self.mapViewController.isExplorePaused = NO;
    
    self.navBar.hidden = NO;
    self.controlsBar.hidden = NO;
    self.buttonAddVenue.hidden = YES;
    
    // show our UI
    [self showUserInterface:animated];
    [self switchToMap];
}

- (void)showListUserInterfaceAnimated:(BOOL)animated {
    self.mapViewController.isExplorePaused = YES;
    
    // show our UI
    [self showUserInterface:animated];
    [self switchToList];
    
    //configure title bar
    self.navBar.hidden = NO;
    self.controlsBar.hidden = NO;
    self.buttonAddVenue.hidden = NO;

}

- (void)showUserInterface:(BOOL)animated {
    // Animate in the nav bar
    [UIView animateWithDuration:(animated ? 0.3 : 0.0) animations:^{
        self.navBar.hidden = NO;
        self.navBar.alpha = 1.0;
        self.controlsBar.hidden = NO;
        self.controlsBar.alpha = 1.0;
    }];
    
    // TODO: include view offset?
    self.mapViewController.visibleRectInsets = UIEdgeInsetsMake(self.headerBarHeight, 0.0, 0.0, 0.0);
    
    [self.mapViewController showUserInterfaceAnimated:YES];
    self.mapViewController.jumpToVenueDetails = YES;
}


- (void)hideUserInterfaceAnimated:(BOOL)animated {
    // Inform the map: disable explore mode, let the map know that
    // it isn't in the foreground, etc.
    self.mapViewController.isExplorePaused = YES;
    [self.mapViewController hideUserInterfaceAnimated:YES];
 
    self.suggestionsView.hidden = YES;
 
    
    [UIView animateWithDuration:(animated ? 0.3 : 0.0) animations:^{
        self.navBar.alpha = 0.0;
        self.controlsBar.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            self.navBar.hidden = YES;
            self.controlsBar.hidden = YES;
        }
    }];
    
    self.mapViewController.visibleRectInsets = UIEdgeInsetsMake(self.view.frame.size.height* 0.3, 0.0, self.view.frame.size.height* 0.3, 0.0);
    
    self.mapViewController.jumpToVenueDetails = NO;
}

- (void)showVenue:(Venue *)venue {
    [self.mapViewController showVenue:venue];
}

- (void)prepareToAnimateMemory {
    [self.view addSubview:self.animationImageView];
    
    //retrieve screenshot image saved when posting a mem
    NSString *documentsDirectoryPrev = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *currPreviewPath = [NSString stringWithFormat:@"mamAnimationImg.png"];
    NSString *previewPngPath = [documentsDirectoryPrev stringByAppendingPathComponent:currPreviewPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL previewSuccess = [fileManager fileExistsAtPath:previewPngPath];
    
    if (previewSuccess) {
        UIImage* screenImage = [[UIImage alloc] initWithContentsOfFile:previewPngPath];
        self.animationImageView.image = screenImage;
        self.animationImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.animationImageView.frame = CGRectMake(0,
                                              0,
                                              self.view.frame.size.width,
                                              self.view.frame.size.height);
    } else {
        self.animationImageView.image = nil;
        self.animationImageView.frame = CGRectMake(0,
                                              0,
                                              self.view.frame.size.width,
                                              self.view.frame.size.height);
    }
    
    self.mapViewController.animatingMemory = YES;
}

- (void)animateMemory {
    if (!_animationImageView) {
        [self prepareToAnimateMemory];
    }
    
    CGPoint center = CGPointMake(self.animationImageView.frame.size.width/2, self.animationImageView.frame.size.height/2);
    self.animationImageView.layer.position = center;
    
    // time scalar.  Change this to alter the overall duration of
    // the animation without affecting relative timing.
    CGFloat ts = 4.6;
    
    // Animation has 3 stages (although they bleed into each other a little).
    // First: shrink down significantly to a point around the SW of the pin
    // Second: make a full rotation around the center (oval or circle), shrinking for
    //      the first 40-45% of the orbit.
    // Third: drop down into the center (the map pin) and fade out completely.
    
    // First section: shrink to starting position
    
    // set up scaling.  We quickly scale to 0.2, then finish the scaling
    // slowly from there.
    CABasicAnimation *resizeAnimation = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
    CGFloat scale = 0.1;
    [resizeAnimation setToValue:[NSValue valueWithCGSize:CGSizeMake(self.animationImageView.frame.size.width * scale, self.animationImageView.frame.size.height * scale)]];
    resizeAnimation.fillMode = kCAFillModeForwards;
    resizeAnimation.removedOnCompletion = NO;
    resizeAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.1 :.65 :.4 :.8];
    resizeAnimation.duration = 0.23 * ts;
    
    CABasicAnimation *resizeAnimation2 = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
    scale = 0.08;
    [resizeAnimation2 setToValue:[NSValue valueWithCGSize:CGSizeMake(self.animationImageView.frame.size.width * scale, self.animationImageView.frame.size.height * scale)]];
    resizeAnimation2.fillMode = kCAFillModeForwards;
    resizeAnimation2.removedOnCompletion = NO;
    resizeAnimation2.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.0 :.15 :.6 :1];
    resizeAnimation2.beginTime = resizeAnimation.duration;
    resizeAnimation2.duration = 0.10 * ts;
    
    // set up movement.  We move up during the initial, sharp scale-down, then swing around
    // a circle with EaseIn, EaseOut, before turning and descending into the center.
    
    // move left
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.calculationMode = kCAAnimationPaced;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.1 :.5 :.2 :.6];
    pathAnimation.duration = 0.03 * ts;
    
    CGPoint endPoint = CGPointMake(self.view.bounds.size.width/2 - CGRectGetHeight(self.view.bounds)*0.2*0.8*0.9, self.view.bounds.size.height/2 + 30);
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath, NULL, center.x, center.y);
    CGPathAddCurveToPoint(curvedPath, NULL,
                          [self intrp:center.x to:endPoint.x with:0.5], center.y,
                          [self intrp:center.x to:endPoint.x with:0.9], [self intrp:center.y to:endPoint.y with:0.2],
                          endPoint.x, endPoint.y);
    pathAnimation.path = curvedPath;
    CGPathRelease(curvedPath);
    
    // ~circle
    CAKeyframeAnimation *pathAnimation2 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation2.calculationMode = kCAAnimationPaced;
    pathAnimation2.fillMode = kCAFillModeForwards;
    pathAnimation2.removedOnCompletion = NO;
    pathAnimation2.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.5 :.25 :.5 :.65];
    pathAnimation2.duration = .16 * ts;
    pathAnimation2.beginTime = pathAnimation.duration;
    
    // See http://spencermortensen.com/articles/bezier-circle/ for a description
    // of this circle approximation.  For an oval approximation, alter the two values of
    // xC / yC to be nonequal.
    CGFloat yR = CGRectGetHeight(self.view.bounds)*0.2;
    CGFloat xR = yR * 0.8;
    CGFloat yBend = 0;// 0.05 * yR;
    CGFloat xC = 0.551915024494 * xR;
    CGFloat yC = 0.551915024494 * yR;
    CGMutablePathRef curvedPath2 = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath2, NULL, endPoint.x, endPoint.y);
    
    // counter-clockwise from top to left...
    //CGPathAddCurveToPoint(curvedPath2, NULL,
    //                      endPoint.x-xC, center.y-yR - yBend,
    //                      center.x-xR, center.y-yC,
    //                      center.x-xR, center.y);
     
    
    endPoint = CGPointMake(self.view.bounds.size.width/2 - 30, self.view.bounds.size.height*0.3);
    
    // left to bottom...
    CGPathAddCurveToPoint(curvedPath2, NULL,
                          center.x-xR, center.y+yC,
                          center.x-xC, center.y+yR,
                          center.x,    center.y+yR);
    // bottom to right...
    CGPathAddCurveToPoint(curvedPath2, NULL,
                          center.x+xC, center.y+yR,
                          center.x+xR, center.y+yC,
                          center.x+xR, center.y);
    
    // right to top...
    CGPathAddCurveToPoint(curvedPath2, NULL,
                          center.x+xR, center.y-yC,
                          center.x*2 - endPoint.x+xC, center.y-yR,
                          center.x*2 - endPoint.x,    center.y-yR - yBend);
    pathAnimation2.path = curvedPath2;
    CGPathRelease(curvedPath2);
    
    // move down
    CAKeyframeAnimation *pathAnimation3 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation3.calculationMode = kCAAnimationPaced;
    pathAnimation3.fillMode = kCAFillModeForwards;
    pathAnimation3.removedOnCompletion = NO;
    pathAnimation3.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.8 :.5 :.9 :.6];
    pathAnimation3.duration = 0.05*ts;
    pathAnimation3.beginTime = pathAnimation2.beginTime + pathAnimation2.duration;
    
    endPoint = CGPointMake(self.view.bounds.size.width/2 + 30, self.view.bounds.size.height*0.3);
    CGMutablePathRef curvedPath3 = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath3, NULL, endPoint.x, endPoint.y);
    CGPathAddCurveToPoint(curvedPath3, NULL,
                          [self intrp:center.x to:endPoint.x with:0.2], [self intrp:center.y to:endPoint.y with:1.03],
                          center.x, [self intrp:center.y to:endPoint.y with:0.5],
                          center.x, center.y);
    pathAnimation3.path = curvedPath3;
    CGPathRelease(curvedPath3);
    
    
    // Set up fade out effect (alpha and size)
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fadeOutAnimation setToValue:@0.0];
    fadeOutAnimation.fillMode = kCAFillModeForwards;
    fadeOutAnimation.removedOnCompletion = NO;
    fadeOutAnimation.beginTime = pathAnimation3.beginTime;
    fadeOutAnimation.duration = pathAnimation3.duration;
    fadeOutAnimation.timingFunction = pathAnimation3.timingFunction;
    
    CABasicAnimation *resizeAnimation3 = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
    scale = 0.03;
    [resizeAnimation3 setToValue:[NSValue valueWithCGSize:CGSizeMake(self.animationImageView.frame.size.width * scale, self.animationImageView.frame.size.height * scale)]];
    resizeAnimation3.fillMode = kCAFillModeForwards;
    resizeAnimation3.removedOnCompletion = NO;
    resizeAnimation3.timingFunction = pathAnimation3.timingFunction;
    resizeAnimation3.duration = pathAnimation3.duration;
    resizeAnimation3.beginTime = pathAnimation3.beginTime;
    
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.fillMode = kCAFillModeForwards;
    group.removedOnCompletion = NO;
    [group setAnimations:@[pathAnimation, pathAnimation2, pathAnimation3, resizeAnimation, resizeAnimation2, resizeAnimation3, fadeOutAnimation]];
    group.duration = MAX(resizeAnimation2.duration + resizeAnimation2.beginTime, pathAnimation3.duration + pathAnimation3.beginTime);
    group.delegate = self;
    [group setValue:self.animationImageView forKey:@"imageViewBeingAnimated"];
    
    
    
    // Add the animation
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self cleanUpAnimation];
    }];
    [self.animationImageView.layer addAnimation:group forKey:@"savingAnimation"];
    [CATransaction commit];
}

-(CGFloat)intrp:(CGFloat)a to:(CGFloat)b with:(CGFloat)prop {
    return b * prop + a * (1 - prop);
}

-(void)cleanUpAnimation {
    UIView *view;
    NSArray *subs = [self.animationImageView subviews];
    
    for (view in subs) {
        [view removeFromSuperview];
    }
    [self.animationImageView removeFromSuperview];
    self.animationImageView = nil;
    self.view.userInteractionEnabled = YES;
    
    self.mapViewController.animatingMemory = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"restoreFeedAfterMAMAnimation" object:nil];
}

-(void)locationResetManually {
    [_mapViewController locationResetManually];
    [_listViewController locationResetManually];
}

// Update the currently selected venue, the device location venue (which may or may
// not be the same), and the list of all venues nearby.
-(void)updateVenues:(NSArray *)venues withCurrentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue spayceState:(SpayceState)spayceState {
    _currentVenue = currentVenue;
    _deviceVenue = deviceVenue;
    _venuesProvided = venues;
    _spayceState = spayceState;
    
    BOOL hasCurrent = NO;
    BOOL hasDevice = NO;
    for (Venue * v in venues) {
        if ([SPCMapDataSource venue:v is:currentVenue]) {
            hasCurrent = YES;
        }
        if ([SPCMapDataSource venue:v is:deviceVenue]) {
            hasDevice = YES;
        }
    }
    
    if (_spayceState == SpayceStateDisplayingLocationData) {
        [self refreshSuggestionsIfNeeded];
    }
    
    self.allVenues = [NSArray arrayWithArray:venues];
    if (!hasCurrent && currentVenue) {
        self.allVenues = [self.allVenues arrayByAddingObject:currentVenue];
    }
    if (!hasDevice && deviceVenue && ![SPCMapDataSource venue:deviceVenue is:currentVenue]) {
        self.allVenues = [self.allVenues arrayByAddingObject:deviceVenue];
    }
    
    // tell child VCs.
    [self.mapViewController updateVenues:self.allVenues withCurrentVenue:self.currentVenue deviceVenue:self.deviceVenue spayceState:self.spayceState];
    [self.listViewController updateVenues:self.allVenues withCurrentVenue:self.currentVenue deviceVenue:self.deviceVenue atDeviceVenue:self.mapViewController.isAtDeviceLocation spayceState:self.spayceState];
    
    // if updating in the background, jump the map to the current venue so
    // we can load the map view there while we wait.
    if (self.currentVenue && self.spayceState == SpayceStateRetrievingLocationData) {
        if (self.currentVenue.latitude && self.currentVenue.longitude && self.currentVenue.latitude.doubleValue && self.currentVenue.longitude.doubleValue) {
            [self.mapViewController showVenue:self.currentVenue];
        }
    }
}


#pragma mark - back button actions

-(void)closeButtonActivated:(id)sender {
    if (!self.isSearchActive) {
        // first: the user has released the button; change its color
        [self closeButtonReleased:sender];
        // second: flip back to the map (if necessary)
        [self switchToMap];

        // third: tell the delegate
        if ([self.delegate respondsToSelector:@selector(dismissVenueViewController:animated:)]) {
            [self.delegate dismissVenueViewController:self animated:YES];
        }
    } else {
        // cancel search
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.searchBar.text = @"";
        self.buttonSearch.highlighted = NO;
        if ([self.searchBar isFirstResponder]) {
            [self.searchBar resignFirstResponder];
        }
        
        if (self.isMapViewDisplayed) {
            self.suggestionsView.hidden = YES;
           
            BOOL mapResetNeeded = [self.mapViewController isMapResetNeeded];
            
            if (mapResetNeeded) {
                 [self.mapViewController resetMapAfterTeleport];
                 [self performSelector:@selector(dismissMapOnDelay) withObject:nil afterDelay:.5];
            }
            else {
                // tell the delegate
                if ([self.delegate respondsToSelector:@selector(dismissVenueViewController:animated:)]) {
                    [self.delegate dismissVenueViewController:self animated:YES];
                }
            }
        }
        else {
            self.listViewController.searchFilter = nil;
            [self switchToMap];
            
            // tell the delegate
            if ([self.delegate respondsToSelector:@selector(dismissVenueViewController:animated:)]) {
                [self.delegate dismissVenueViewController:self animated:YES];
            }
        }
    }
    
    self.navBar.hidden = YES;
    self.controlsBar.hidden = YES;
}

-(void)dismissMapOnDelay {
    if ([self.delegate respondsToSelector:@selector(dismissVenueViewController:animated:)]) {
        [self.delegate dismissVenueViewController:self animated:YES];
    }
}

-(void)closeButtonPressed:(id)sender {
    [((UIButton *)sender) setBackgroundColor:self.closeButtonColorPressed];
}

-(void)closeButtonReleased:(id)sender {
    [((UIButton *)sender) setBackgroundColor:self.closeButtonColor];
}

-(void)searchButtonPressed:(id)sender {

}

-(void)locationButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(hereVenueViewControllerDidRefreshLocation:)]) {
        [self.delegate hereVenueViewControllerDidRefreshLocation:self];
    }
}

-(void)refreshLocation {
    if ([self.delegate respondsToSelector:@selector(hereVenueViewControllerDidRefreshLocation:)]) {
        [self.delegate hereVenueViewControllerDidRefreshLocation:self];
    }
}

-(void)createButtonPressed:(id)sender {
    SPCCreateVenueViewController *createVenueVC = [[SPCCreateVenueViewController alloc] initWithNearbyVenues:self.allVenues];
    [self.navigationController pushViewController:createVenueVC animated:YES];
}

-(void)mapButtonPressed:(id)sender {
    [self switchToMap];
}

-(void)listButtonPressed:(id)sender {
    [self switchToList];
}

-(void)switchToMap {
    // cancel search editing
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    // set title
    NSString *title = NSLocalizedString(@"FLY", nil);
    self.searchBar.placeholder = NSLocalizedString(@"Explore the World...", nil);
    self.suggestionsStatus.text = @"";
    self.controlsBar.backgroundColor = self.controlsSearchBackgroundColor;
    
    if (![title isEqualToString:self.titleLabel.text]) {
        [UIView animateWithDuration:BUTTON_FADE_DURATION animations:^{
            self.titleLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.titleLabel.text = title;
            [UIView animateWithDuration:BUTTON_FADE_DURATION animations:^{
                self.titleLabel.alpha = 1.0f;
            }];
        }];
    }
    
    // unpause explore
    self.mapViewController.isExplorePaused = NO;
    
    if (!self.isMapViewDisplayed) {
        NSTimeInterval duration = 0.5;
        self.listContainerView.alpha = 1.0f;
        [self.mapViewController viewWillAppear:YES];
        [UIView animateWithDuration:duration animations:^{
            self.listContainerView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.listContainerView removeFromSuperview];
        }];
    }
}

-(void)switchToList {
    // cancel search editing
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    self.searchBar.placeholder = NSLocalizedString(@"Search nearby venues...", nil);
    self.controlsBar.backgroundColor = self.controlsSearchBackgroundColor;
    
    
    // set title
    NSString * title = NSLocalizedString(@"Nearby", nil);
    self.titleLabel.text = title;
    
    // pause explore
    self.mapViewController.isExplorePaused = YES;
    
    if (self.isMapViewDisplayed) {
        NSTimeInterval duration = 0.5;
        [self.containerView addSubview:self.listContainerView];
        [self.listViewController viewWillAppear:YES];
        self.listViewController.searchFilter = nil;
        [UIView animateWithDuration:duration animations:^{
            self.listContainerView.alpha = 1.0f;
        }];
    }
}


#pragma mark - Search support methods

-(void)filterContentForSearchText:(NSString *)searchText {
    if (self.isSearchActive && (searchText == self.searchBar.text || [self.searchBar.text isEqualToString:searchText])) {
        // perform the search...
        if (self.isMapViewDisplayed) {
            //NSLog(@"Performing search for potential map teleport to %@", searchText);
            if (searchText.length > 0) {
                self.suggestionsStatus.text = [NSString stringWithFormat:@"Looking for memories in \"%@\"",searchText];
            }
            self.mapViewController.searchFilter = searchText;
        } else {
            // NSLog(@"Performing list search for %@", searchText);
            self.listViewController.searchFilter = searchText;
        }
    }
}

-(void)refreshSuggestionsIfNeeded {
    if  (self.suggestedVenues.count < 5) {
        [self suggestionRefreshNeeded];
    }
}

- (void)suggestionRefreshNeeded {
    //FETCH BATCH OF SUGGESTED VENUES FROM SERVER
    [[VenueManager sharedInstance] fetchSuggestedVenuesResultCallback:^(NSArray *venues) {
        self.suggestedVenues = [NSArray arrayWithArray:venues];
        if (!self.initialSuggestionsSet){
            [self updateSuggestions];
        }
    } faultCallback:^(NSError *error) {
    }];
}

-(void)updateSuggestions {
    //NSLog(@"update suggestions");
    
    NSMutableArray *updatedArray = [[NSMutableArray alloc] init];
    if (self.suggestedVenues.count > 0) {
        self.initialSuggestionsSet = YES;
        updatedArray = [NSMutableArray arrayWithArray:self.suggestedVenues];
        
        //clean up the old view
        UIView *view;
        NSArray *subs = [self.suggestionsView subviews];
        
        for (view in subs) {
            if (view.tag < 0) {
                [view removeFromSuperview];
            }
        }
    }
    
 
    //ADD THE CURRENT FLIGHT OF SUGGESTIONS TO THE VIEW
    float itemWidth = 100;
    float adjY = 20;
    
    if (self.view.bounds.size.width > 320) {
       itemWidth = 105;
        adjY = 50;
    }
    float initialX = (self.suggestionsView.frame.size.width - (itemWidth * 3))/2;
    
    
    NSString *firstSuggestedCity;
    NSString *secondSuggestedCity;
    NSInteger suggestionsAdded = 0;
    
    for (int i = 0; i < self.suggestedVenues.count; i++) {
   
        //get a suggested venue, avoiding including 2 venues from the same city...
        Venue *tempV = (Venue *)self.suggestedVenues[i];
        //NSLog(@"tempV.city %@",tempV.city);
    
        BOOL cityAlreadyIncluded = NO;
        
        if ([tempV.city isEqualToString:firstSuggestedCity] || [tempV.city isEqualToString:secondSuggestedCity]) {
            cityAlreadyIncluded = YES;
            //NSLog(@"already included!");
        }
        
        else {
            //NSLog(@"new city..");
            if (firstSuggestedCity) {
                if (!secondSuggestedCity) {
                    secondSuggestedCity = tempV.city;
                    //NSLog(@"remeber as second city");
                }
            }
            else {
                firstSuggestedCity = tempV.city;
                //NSLog(@"remember as first city");
            }
        }
        
        if (!cityAlreadyIncluded) {
            
            if (updatedArray.count > i ) {
                [updatedArray removeObjectAtIndex:i];
            }
            float originX = initialX + itemWidth * suggestionsAdded;
            suggestionsAdded++;

            SPCSuggestionItemView *tempVenView = [[SPCSuggestionItemView alloc] initWithVenue:tempV andFrame:CGRectMake(originX, 80+adjY, itemWidth, itemWidth)];
            tempVenView.tag = -777;
            [tempVenView addTarget:self action:@selector(goToRecommendedVenue:) forControlEvents:UIControlEventTouchDown];
            [self.suggestionsView addSubview:tempVenView];
        }
        
        if (suggestionsAdded >= 3) {
            break;
        }
    }
    if (updatedArray.count > 4) {
        if (suggestionsAdded >= 3) {
            self.suggestedVenues = [NSArray arrayWithArray:updatedArray];
        }
        else {
            [self suggestionRefreshNeeded];
        }
    } else {
        self.suggestedVenues = nil;
        [self refreshSuggestionsIfNeeded];
    }
}

-(void)searchIsCompleteWithResults:(BOOL)hasResults {
    
    if (hasResults) {
        if ([self.searchBar isFirstResponder]) {
            [self.searchBar resignFirstResponder];
        }
        self.suggestionsView.hidden = YES;
        self.suggestionsStatus.text = @"";
    }
    else {
        _mapViewController.isExplorePaused = YES;
        if (self.isMapViewDisplayed) {
            [self updateSuggestions];
            self.suggestionsView.hidden = NO;
            self.suggestionsStatus.text = @"No real-time memories here right now";
        }
    }
}

-(void)goToRecommendedVenue:(id)sender {
    
    _mapViewController.isExplorePaused = NO;
    SPCSuggestionItemView *sugVenueBtn = (SPCSuggestionItemView *)sender;
    Venue *destinationVenue = (Venue *)sugVenueBtn.venue;
    self.searchBar.text = destinationVenue.city;
    [self.mapViewController showVenue:destinationVenue withZoom:12];
    
    [self.mapViewController displayAnyExploreMemoryFromSuggestedVenue:destinationVenue];
    
    //give the map some time to update
    [self performSelector:@selector(revealVenue) withObject:nil afterDelay:.7];
    [self performSelector:@selector(updateSuggestions) withObject:nil afterDelay:.8];
}

-(void)revealVenue {
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    self.suggestionsView.hidden = YES;
    self.suggestionsStatus.text = @"";
}

- (void)spc_localMemoryPosted:(NSNotification *)notification {
    Venue *venue = ((Memory *)notification.object).venue;
    if (venue) {
        self.mapViewController.animatingMemory = YES;
        [self.mapViewController showVenue:venue withZoom:19 animated:NO];
    }
}

#pragma mark - UITextFieldDelegate

- (void)keyboardWillShow:(NSNotification *)notification
{
    self.keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    float sugHeight = self.view.frame.size.height - CGRectGetMaxY(self.controlsBar.frame) - self.keyboardSize.height;
    self.suggestionsView.frame = CGRectMake(0,CGRectGetMaxY(self.controlsBar.frame),self.view.frame.size.width, sugHeight);
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // no change
        if (self.isMapViewDisplayed) {
            _mapViewController.isExplorePaused = YES;
            self.suggestionsView.hidden = NO;
        }

}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // no change
    self.suggestionsView.hidden = YES;
    if (self.isMapViewDisplayed) {
        _mapViewController.isExplorePaused = NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyDefault) {
        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        // Schedule delayed filter request in order to allow textField to update it's internal state
        [self performSelector:@selector(filterContentForSearchText:) withObject:textField.text afterDelay:0.05];
        
        if (self.isMapViewDisplayed) {
        }
        else {
            // resign
            [textField resignFirstResponder];
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (text.length == 0) {
        textField.text = nil;
        self.suggestionsStatus.text = @"";
        self.buttonSearch.highlighted = NO;
        
        if (self.isMapViewDisplayed) {
            // Nothing, user must exit map to leave map search once begun
        } else {
            self.suggestionsView.hidden = YES;
            self.listViewController.searchFilter = nil;
        }
    } else {
        self.buttonSearch.highlighted = YES;
        
        if (self.isMapViewDisplayed) {
            self.suggestionsView.hidden = NO;
            self.suggestionsStatus.text = @"";
            [self.view bringSubviewToFront:self.suggestionsView];
        } else {
            self.suggestionsView.hidden = YES;
        }
        
        
        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        // Schedule delayed filter request in order to allow textField to update it's internal state
        [self performSelector:@selector(filterContentForSearchText:) withObject:text afterDelay:(self.isMapViewDisplayed ? SEARCH_DELAY_MAP : SEARCH_DELAY_LIST)];
    }
    
    return YES;
}


#pragma mark - HereMapVenueVC delegate methods

-(void)hereVenueMapViewController:(UIViewController *)viewController revealAnimated:(BOOL)animated {
    if ([self.delegate respondsToSelector:@selector(revealVenueViewController:animated:)]) {
        [self.delegate revealVenueViewController:self animated:YES];
    }
}

-(void)hereVenueMapViewController:(UIViewController *)viewController didSelectVenue:(Venue *)venue {
    // first: update current venue
    [self updateVenues:self.venuesProvided withCurrentVenue:venue deviceVenue:self.deviceVenue spayceState:self.spayceState];
    
    // second: inform delegate
    if ([self.delegate respondsToSelector:@selector(hereVenueViewController:didSelectVenue:dismiss:)]) {
        [self.delegate hereVenueViewController:self didSelectVenue:venue dismiss:YES];
    }
}

-(void)hereVenueMapViewController:(UIViewController *)viewController didSelectVenues:(NSArray *)venues {
    // pass to the delegate; make no change yet.
    if ([self.delegate respondsToSelector:@selector(hereVenueViewController:didSelectVenues:dismiss:)]) {
        [self.delegate hereVenueViewController:self didSelectVenues:venues dismiss:YES];
    }
}

-(void)hereVenueMapViewController:(UIViewController *)viewController didSelectVenuesFromFullScreen:(NSArray *)venues {
    // pass to the delegate; make no change yet.
    if ([self.delegate respondsToSelector:@selector(hereVenueViewController:didSelectVenuesFromFullScreen:dismiss:)]) {
        [self.delegate hereVenueViewController:self didSelectVenuesFromFullScreen:venues dismiss:NO];
    }
}

#pragma mark - HereListVenueVC delegate methods

-(void)hereVenueListViewController:(UIViewController *)viewController didSelectVenue:(Venue *)venue {
    
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = venue;
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    
    [self.tabBarController presentViewController:navController animated:YES completion:nil];
}

-(void)hereVenueListViewControllerDismissKeyboard:(UIViewController *)viewController {
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}


#pragma mark - Coach mark

- (void)showCoachMarkSpayce {
    NSString *key = [SPCLiterals literal:kCoachMarkSpayceKey forUser:[AuthenticationManager sharedInstance].currentUser];
    BOOL shouldDislayCoachMark = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    
    if (!shouldDislayCoachMark) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        //self.navigationItem.rightBarButtonItem
        CGRect f1 = self.navigationItem.rightBarButtonItem.customView.frame;
        f1.origin.y += [UIApplication sharedApplication].statusBarFrame.size.height;
        
        
        CoachMarks *coachMark = [[CoachMarks alloc] initWithFrame:self.view.bounds type:CoachMarkTypeSpayce boundFrame:self.view.bounds];
        coachMark.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0);
        coachMark.alpha = 0.0;
        [[UIApplication sharedApplication] addSubviewToWindow:coachMark];
        
        [UIView animateWithDuration:0.8
                              delay:0.0
                            options:0
                         animations:^{
                             coachMark.alpha = 1.0;
                             coachMark.center = self.view.center;
                         }
                         completion:^(BOOL finished) {
                             [coachMark performSelector:@selector(setDismissOnTouch:) withObject:@(YES) afterDelay:1.0];
                         }];
    }
}

@end
