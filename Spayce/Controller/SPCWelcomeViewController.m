//
//  SPCWelcomeViewController.m
//  Spayce
//
//  Created by William Santiago on 4/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCWelcomeViewController.h"

// Controller
#import "LogInViewController.h"
#import "SignUpViewController.h"

// Manager
#import "SocialService.h"

// Framework
#import "Flurry.h"

static NSString *CellIdentifier = @"SPCWelcomeCellIdentifier";

@interface SPCWelcomeViewController () <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *ivBackgroundImage;
@property (nonatomic, weak) IBOutlet UIButton *exploreButton;
@property (nonatomic, weak) IBOutlet UILabel *detailTextLabel;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat offsetYIncrement;
@property (nonatomic, assign) BOOL spc_viewDidAppear;
@property (nonatomic, strong) UIImage *launchImg;
@property (weak, nonatomic) IBOutlet UIButton *connectWithFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;

@end

@implementation SPCWelcomeViewController

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopAnimation];
}

- (id)init {
    self = [super init];
    if (self) {
        [self _initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _initialize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _initialize];
        
        
    }
    return self;
}

#pragma mark - Accessors

- (NSArray *)images {
    if (!_images) {
        _images = @[
                    /* These images have been removed from the catalog
                    [UIImage imageNamed:@"animation-welcome-tile-5"],
                    [UIImage imageNamed:@"animation-welcome-tile-6"],
                    [UIImage imageNamed:@"animation-welcome-tile-7"],
                    [UIImage imageNamed:@"animation-welcome-tile-1"],
                    [UIImage imageNamed:@"animation-welcome-tile-2"],
                    [UIImage imageNamed:@"animation-welcome-tile-3"],
                    [UIImage imageNamed:@"animation-welcome-tile-4"],
                    [UIImage imageNamed:@"animation-welcome-tile-5"],
                    [UIImage imageNamed:@"animation-welcome-tile-6"],
                    [UIImage imageNamed:@"animation-welcome-tile-7"],
                    [UIImage imageNamed:@"animation-welcome-tile-1"]*/
                    ];
    }
    return _images;
}

#pragma mark - UIViewController - Managing the View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:self.detailTextLabel.text];
    [attrStr addAttribute:NSKernAttributeName value:@(1.1) range:NSMakeRange(0, attrStr.length)];
    [attrStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans" size:17.0f] range:NSMakeRange(0, attrStr.length)];
    self.detailTextLabel.attributedText = attrStr;
    
    [self.exploreButton addTarget:self action:@selector(beginPreviewMode) forControlEvents:UIControlEventTouchDown];
    
    // Configure button appearances - THIS FUNCTION OVERRIDES THE XIB BUTTON APPEARANCES/TEXT
    [self configureButtonAppearances];
    
    // Use the specially-cropped-for-4/4s image if we're on a 960pt screen
    // Apparently, xibs don't enjoy auto-scaling to various screen sizes, so this ViewController's view will always be rendered at one resolution (go ahead and NSLog the height of self.view to see if it changes across devices)
    if (480 >= CGRectGetHeight([UIScreen mainScreen].bounds)) {
        self.ivBackgroundImage.image = [UIImage imageNamed:@"welcome-background-960"];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeInitialLoadingView) name:@"removeInitialLoadingScreen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLoadingView) name:@"addLoadingView" object:nil];
    
    self.navigationController.delegate = self;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Hide navigation bar
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    // Status Bar Appearance
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    if (!self.spc_viewDidAppear) {
        self.spc_viewDidAppear = YES;
        
        // Commenting, in case we decide to add it back in
//        [self startReceivingGyroUpdates];
        [self startAnimation];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.spc_viewDidAppear) {
        self.spc_viewDidAppear = NO;
        
//        [self stopReceivingGyroUpdates];
        [self stopAnimation];
    }
}

#pragma mark - Button Fonts

- (void)configureButtonAppearances {
    // First, configure the explore button's appearance
    self.exploreButton.layer.borderColor = [UIColor colorWithRGBHex:0x000000].CGColor;
    NSDictionary *exploreAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:13.0f], NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x000000] };
    [self.exploreButton setAttributedTitle:[[NSAttributedString alloc] initWithString:self.exploreButton.titleLabel.text attributes:exploreAttributes] forState:UIControlStateNormal];
    self.exploreButton.layer.cornerRadius = 3.0f;
    self.exploreButton.layer.borderWidth = 1.0f;
    self.exploreButton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.exploreButton setImage:[UIImage imageNamed:@"disclosure-indicator-black"] forState:UIControlStateNormal];
    self.exploreButton.imageEdgeInsets = UIEdgeInsetsMake(1, CGRectGetWidth(self.exploreButton.frame) - 19, 0, 1);
    self.exploreButton.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 7);
    
    // Now, configure the three lower buttons, i.e. 'connect with fb', 'log in', 'sign up'
    NSDictionary *boldFontAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f], NSForegroundColorAttributeName : [UIColor whiteColor] };
    
    NSAttributedString *logInString = [[NSAttributedString alloc] initWithString:@"Log In" attributes:boldFontAttributes];
    [self.logInButton setAttributedTitle:logInString forState:UIControlStateNormal];
    [self.logInButton setAttributedTitle:logInString forState:UIControlStateHighlighted];
    self.logInButton.layer.cornerRadius = 2.0f;
    
    NSAttributedString *signUpString = [[NSAttributedString alloc] initWithString:@"Sign Up" attributes:boldFontAttributes];
    [self.signUpButton setAttributedTitle:signUpString forState:UIControlStateNormal];
    [self.signUpButton setAttributedTitle:signUpString forState:UIControlStateHighlighted];
    self.signUpButton.layer.cornerRadius = 2.0f;
    self.signUpButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.signUpButton.layer.borderWidth = 1.0f;
    
    NSMutableAttributedString *connectWithFacebookString = [[NSMutableAttributedString alloc] initWithString:@"Connect with Facebook" attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    [connectWithFacebookString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Semibold" size:14.0f] range:NSMakeRange(0, [@"Connect with" length])];
    [connectWithFacebookString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans" size:14.0f] range:NSMakeRange([@"Connect with " length], [@"Facebook" length])];
    [self.connectWithFacebookButton setAttributedTitle:connectWithFacebookString forState:UIControlStateNormal];
    [self.connectWithFacebookButton setAttributedTitle:connectWithFacebookString forState:UIControlStateHighlighted];
    self.connectWithFacebookButton.layer.cornerRadius = 2.0f;
}

#pragma mark - UIViewController - Configuring the View’s Layout Behavior

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private

- (void)_initialize {
//    self.motionManager = [[CMMotionManager alloc] init];
}

- (void)addLoadingView {
    // Show logo
    UIImageView *bigLogoImgView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    bigLogoImgView.image = self.launchImg;
    bigLogoImgView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [self.view addSubview:bigLogoImgView];
}

#pragma mark - Actions

- (void)startAnimation {
//    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateOffset:)];
//    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopAnimation {
//    [self.displayLink invalidate];
}

- (IBAction)connectWithFacebook:(id)sender {
    [[SocialService sharedInstance] loginToFacebook];
    
    [Flurry logEvent:@"LOGIN_FACEBOOK"];    
    // Show loading message immediately
    UIView *initialLoadingView = [[UIView alloc] initWithFrame:self.view.frame];
    initialLoadingView.backgroundColor = [UIColor colorWithRed:28.0f/255.0f green:26.0f/255.0f blue:33.0f/255.0f alpha:1.0f];
    [self.view addSubview:initialLoadingView];
    
    UIImage *initialLogoImg = [UIImage imageNamed:@"connectingtofb"];
    UIImageView *bigLogoImgView = [[UIImageView alloc] initWithImage:initialLogoImg];
    bigLogoImgView.center = CGPointMake(initialLoadingView.frame.size.width/2, initialLoadingView.frame.size.height/2);
    
    UILabel *loadingLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(bigLogoImgView.frame)+10, 280, 40)];
    loadingLbl.text = NSLocalizedString(@"Connecting to Facebook...", nil);
    loadingLbl.backgroundColor = [UIColor clearColor];
    loadingLbl.textColor = [UIColor whiteColor];
    loadingLbl.numberOfLines = 0;
    loadingLbl.lineBreakMode = NSLineBreakByWordWrapping;
    loadingLbl.font = [UIFont fontWithName:@"OpenSans" size:15];
  
    float yAdj = 70;
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        loadingLbl.font = [UIFont fontWithName:@"OpenSans" size:17];
        yAdj = 85;
    }
  
    loadingLbl.center = CGPointMake(initialLoadingView.frame.size.width/2, yAdj + initialLoadingView.frame.size.height/2);
    loadingLbl.textAlignment = NSTextAlignmentCenter;
    [initialLoadingView addSubview:bigLogoImgView];
    [initialLoadingView addSubview:loadingLbl];
    initialLoadingView.tag = -1;

}

- (IBAction)presentSignInViewController:(id)sender {
    LogInViewController *signInViewController = [[LogInViewController alloc] init];
    [self.navigationController pushViewController:signInViewController animated:YES];
}

- (IBAction)presentSignUpViewController:(id)sender {
    SignUpViewController *signUpViewController = [[SignUpViewController alloc] init];
    [self.navigationController pushViewController:signUpViewController animated:YES];
}

-(void)beginPreviewMode {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beginPreviewMode" object:nil];
}

-(void)removeInitialLoadingView {
    UIView *view;
    NSArray *subs = [self.view subviews];
    
    for (view in subs) {
        if (view.tag == -1){
            [view removeFromSuperview];
        }
    }
}

-(UIImage *)launchImg {
    NSArray *allPngImageNames = [[NSBundle mainBundle] pathsForResourcesOfType:@"png"
                                                                   inDirectory:nil];
    
    for (NSString *imgName in allPngImageNames) {
        
        if ([imgName respondsToSelector:@selector(containsString:)]) {
            
            if ([imgName rangeOfString:@"LaunchImage"].location != NSNotFound) {
                UIImage *img = [UIImage imageNamed:imgName];
                // Has image same scale and dimensions as our current device's screen?
                if (img.scale == [UIScreen mainScreen].scale && CGSizeEqualToSize(img.size, [UIScreen mainScreen].bounds.size)) {
                    return img;
                    break;
                }
            }
        }
        else {
            if ([imgName rangeOfString:@"LaunchImage"].location != NSNotFound) {
                NSMutableString *mutImgName = [NSMutableString stringWithString:imgName];
                NSInteger loc = [imgName rangeOfString:@"LaunchImage"].location;
                NSInteger length = imgName.length - loc;
                NSString *trimmedStr = [mutImgName substringWithRange:NSMakeRange(loc,length)];
                UIImage *img = [UIImage imageNamed:trimmedStr];
                
                if (img.scale * img.size.width == [UIScreen mainScreen].scale * [UIScreen mainScreen].bounds.size.width) {
                    return img;
                    break;
                }
            }
        }
    }
    
    return nil;
}

@end
