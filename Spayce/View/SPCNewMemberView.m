//
//  SPCNewMemberView.m
//  Spayce
//
//  Created by Christopher Taylor on 5/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCNewMemberView.h"
#import "CustomPageTracker.h"
#import "UIScreen+Size.h"

@interface SPCNewMemberView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) CustomPageTracker *pageTracker;
@property (nonatomic, assign) BOOL swipeEnabled;
@property (nonatomic, assign) BOOL fbInProgress;
@property (nonatomic, assign) NSInteger introCount;
@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, strong) UIButton *continueBtn;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *pctProgressLabel;
@property (nonatomic, strong) UIView *progressBar;
@property (nonatomic, strong) UIView *progressBarOverlay;
@property (nonatomic, strong) UIView *mainProgressBar;
@property (nonatomic, strong) UIView *mainProgressBarOverlay;
@property (nonatomic, assign) BOOL loadingComplete;

@end

@implementation SPCNewMemberView

-(void)dealloc  {
    self.loadingComplete = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


#pragma mark - Accessors

-(UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [[UIButton alloc] initWithFrame:CGRectMake(230, 20, 75, 30)];
        [_doneBtn addTarget:self action:@selector(finished) forControlEvents:UIControlEventTouchUpInside];
        [_doneBtn setBackgroundColor:[UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f]];
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_doneBtn setTitle:@"Skip" forState:UIControlStateNormal];
        [_doneBtn setTitle:@"Skip" forState:UIControlStateSelected];
        [_doneBtn setTitle:@"Skip" forState:UIControlStateHighlighted];
        _doneBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        _doneBtn.hidden = YES;
    }
    return _doneBtn;
}

-(UIButton *)continueBtn {
    if (!_continueBtn) {
        _continueBtn = [[UIButton alloc] initWithFrame:CGRectMake(-75+self.frame.size.width/2, -25+self.frame.size.height/2, 150, 50)];
        [_continueBtn addTarget:self action:@selector(finished) forControlEvents:UIControlEventTouchUpInside];
        [_continueBtn setBackgroundColor:[UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f]];
        [_continueBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_continueBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_continueBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_continueBtn setTitle:@"Enter" forState:UIControlStateNormal];
        [_continueBtn setTitle:@"Enter" forState:UIControlStateSelected];
        [_continueBtn setTitle:@"Enter" forState:UIControlStateHighlighted];
        _continueBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        _continueBtn.hidden = YES;
    }
    return _continueBtn;
}

-(UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(-105+self.frame.size.width/2, CGRectGetMinY(self.continueBtn.frame)-60, 210, 40)];
        _statusLabel.text = @"We are almost finished \ncreating your Spayce account";
        _statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        _statusLabel.textColor = [UIColor colorWithRed:154.0f/255.0f green:166.0f/255.0f blue:171.0f/255.0f alpha:1.0f];
        _statusLabel.numberOfLines = 0;
        _statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.backgroundColor = [UIColor clearColor];
    }
    return _statusLabel;
}

-(UILabel *)pctProgressLabel {
    if (!_pctProgressLabel) {
        _pctProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(-30+self.frame.size.width/2, CGRectGetMaxY(self.continueBtn.frame)+20, 60, 20)];
        _pctProgressLabel.text = @"1%";
        _pctProgressLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
        _pctProgressLabel.textColor = [UIColor colorWithRed:154.0f/255.0f green:166.0f/255.0f blue:171.0f/255.0f alpha:1.0f];
        _pctProgressLabel.textAlignment = NSTextAlignmentCenter;
        _pctProgressLabel.backgroundColor = [UIColor clearColor];
        
        if (!self.fbInProgress) {
            _pctProgressLabel.text = @"90%";
        }
    }
    return _pctProgressLabel;
}

-(UIView *)progressBar {
    if (!_progressBar) {
        _progressBar = [[UIView alloc] initWithFrame:CGRectMake(-125+self.frame.size.width/2, -2+self.frame.size.height/2, 250, 4)];
        _progressBar.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:41.0f/255.0f blue:53.0f/255.0f alpha:1.0f];
    }
    
    return _progressBar;
}

-(UIView *)progressBarOverlay {
    if (!_progressBarOverlay) {
        _progressBarOverlay = [[UIView alloc] initWithFrame:CGRectMake(-125+self.frame.size.width/2, -2+self.frame.size.height/2, 1, 4)];
        _progressBarOverlay.backgroundColor = [UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f];
        if (!self.fbInProgress) {
            _progressBarOverlay.frame = CGRectMake(-125+self.frame.size.width/2, -2+self.frame.size.height/2, 225, 4);
        }
    }
    
    return _progressBarOverlay;
}

-(UIView *)mainProgressBar {
    if (!_mainProgressBar) {
        _mainProgressBar = [[UIView alloc] initWithFrame:CGRectMake(0, 374, self.frame.size.width, 5)];
        _mainProgressBar.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:41.0f/255.0f blue:53.0f/255.0f alpha:1.0f];
    }
    
    return _mainProgressBar;
}

-(UIView *)mainProgressBarOverlay {
    if (!_mainProgressBarOverlay) {
        _mainProgressBarOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 374,self.frame.size.width * .2, 5)];
        _mainProgressBarOverlay.backgroundColor = [UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f];
    }
    
    return _mainProgressBarOverlay;
}

#pragma mark - Setup the view

- (void)prepIntroScroller {
    
    self.fbInProgress = [[NSUserDefaults standardUserDefaults] boolForKey:@"facebookBatchInProgress"];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.bounces = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.userInteractionEnabled = YES;
    [self addSubview:self.scrollView];
    
    float startX = self.bounds.size.width/2;
    float deltaX = self.bounds.size.width;
    float tempX = 0;
    
    NSArray *titlesArray = @[@"Memories", @"Anchor", @"Stars", @"Reputation"];
    
    NSArray *subheadArray = @[
            @"Spayce lets you make memories with friends to capture the best moments in life",
            @"Memories are anchored to the place they are made in. They will be there when you return.",
            @"Star your favorite memories. When people star your memories your starpower goes up.",
            @"The more stars you earn, the higher your local repuation will be in the areas you live in."
    ];
    
    for (int i =0; i <=3; i++) {
        
        tempX = startX + deltaX * i;
        
        NSString *walkThruImgStr = [NSString stringWithFormat:@"intro-%i",i];
        UIImage *heroImg = [UIImage imageNamed:walkThruImgStr];
        UIImageView *heroImgView = [[UIImageView alloc] initWithImage:heroImg];
        heroImgView.center = CGPointMake(tempX, 189);
        [self.scrollView addSubview:heroImgView];
        
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(heroImgView.frame), self.frame.size.width, self.frame.size.height - CGRectGetMaxY(heroImgView.frame))];
        bgView.center = CGPointMake(tempX, bgView.center.y);
        bgView.backgroundColor = [UIColor whiteColor];
        [self.scrollView addSubview:bgView];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20+CGRectGetMaxY(heroImgView.frame), self.frame.size.width, 20)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.center = CGPointMake(tempX, titleLabel.center.y);
        titleLabel.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
        titleLabel.text = titlesArray[i];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.scrollView addSubview:titleLabel];
        
        UILabel *subheadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(titleLabel.frame), 275, 80)];
        subheadLabel.backgroundColor = [UIColor clearColor];
        subheadLabel.center = CGPointMake(tempX, subheadLabel.center.y);
        subheadLabel.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        subheadLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        subheadLabel.text = subheadArray[i];
        subheadLabel.numberOfLines = 0;
        subheadLabel.lineBreakMode = NSLineBreakByWordWrapping;
        subheadLabel.textAlignment = NSTextAlignmentCenter;
        [self.scrollView addSubview:subheadLabel];
        
        if ([UIScreen isLegacyScreen]) {
            bgView.center = CGPointMake(bgView.center.x, bgView.center.y-80);
            titleLabel.center = CGPointMake(titleLabel.center.x, titleLabel.center.y-80);
            subheadLabel.center = CGPointMake(subheadLabel.center.x, subheadLabel.center.y-80);
        }
        
    }
    
    //add final view
    
    tempX = tempX + deltaX;
    
    UIView *finalView = [[UIView alloc] initWithFrame:self.frame];
    finalView.center = CGPointMake(tempX, finalView.center.y);
    finalView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:finalView];
    
    [finalView addSubview:self.progressBar];
    [finalView addSubview:self.progressBarOverlay];
    [finalView addSubview:self.continueBtn];
    [finalView addSubview:self.statusLabel];
    [finalView addSubview:self.pctProgressLabel];
    

    float scrollerContentWidth = startX+tempX+deltaX;
    
    self.scrollView.contentSize = CGSizeMake(scrollerContentWidth, self.bounds.size.height);
    
    UISwipeGestureRecognizer *leftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
    [leftRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self addGestureRecognizer:leftRecognizer];
    
    UISwipeGestureRecognizer *rightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    [rightRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self addGestureRecognizer:rightRecognizer];
    self.swipeEnabled = YES;
    
    self.pageTracker = [[CustomPageTracker alloc] initWithFrame:CGRectMake(0, self.frame.size.height-30, self.frame.size.width, 20)];
    [self.pageTracker totalPics:5 currPic:0];
    self.pageTracker.backgroundColor = [UIColor clearColor];
    self.pageTracker.highlightColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
    self.pageTracker.trackerColor = [UIColor colorWithRed:219.0f/255.0f green:225.0f/255.0f blue:232.0f/255.0f alpha:1.0f];
    [self.pageTracker highlightPic:(int)self.introCount];
    [self addSubview:self.pageTracker];
    
    if ([UIScreen isLegacyScreen]) {
        self.pageTracker.center = CGPointMake(self.pageTracker.center.x, self.pageTracker.center.y-80);
    }
 
    [self addSubview:self.doneBtn];
    [self addSubview:self.mainProgressBar];
    [self addSubview:self.mainProgressBarOverlay];
    
    self.loadingComplete = NO;

}

#pragma mark - Private

-(void)updateProgress:(NSString *)progress {
    
    float progressFloat = [progress floatValue];
    
    float progPct = progressFloat / 100;
    float frameWidth = self.progressBar.frame.size.width * progPct;
    
    self.progressBarOverlay.frame = CGRectMake(self.progressBarOverlay.frame.origin.x,
                                               self.progressBarOverlay.frame.origin.y,
                                               frameWidth,
                                               self.progressBarOverlay.frame.size.height);
    
    self.pctProgressLabel.text = [NSString stringWithFormat:@"%@%%", progress];
    
    if (self.fbInProgress) {
        float mainFrameWidth = self.mainProgressBar.frame.size.width * progPct;
        self.mainProgressBarOverlay.frame = CGRectMake(self.mainProgressBarOverlay.frame.origin.x,
                                                       self.mainProgressBarOverlay.frame.origin.y,
                                                       mainFrameWidth,
                                                       self.mainProgressBarOverlay.frame.size.height);
    }
}

- (void)simulateProgress {
    if (!self.loadingComplete) {
        NSLog(@"loading not complete!");
        self.mainProgressBarOverlay.frame = CGRectMake(0, self.mainProgressBarOverlay.frame.origin.y, self.mainProgressBarOverlay.frame.size.width+10, self.mainProgressBarOverlay.frame.size.height);
        [self performSelector:@selector(simulateProgress) withObject:nil afterDelay:.1];
        
    }
}



#pragma mark - UISwipeGestureRecognizer methods
-(void)swipeLeft {
    
    if (self.swipeEnabled) {
        float maxOffSet = 320*4;
        
        if (self.scrollView.contentOffset.x < maxOffSet) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:.25];
            self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x+320, 0);
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(swipeDone)];
            [UIView commitAnimations];
        }
        
        self.introCount++;
        /*
        if (!self.fbInProgress) {
            if (self.introCount < 4){
                float fakeProgress = 10 + self.introCount * 20;
                float fakePct = fakeProgress / 100;
                float mainFrameWidth = self.mainProgressBar.frame.size.width * fakePct;
                self.mainProgressBarOverlay.frame = CGRectMake(self.mainProgressBarOverlay.frame.origin.x,
                                                               self.mainProgressBarOverlay.frame.origin.y,
                                                               mainFrameWidth,
                                                               self.mainProgressBarOverlay.frame.size.height);
         
                
            }
        }
        */
        
        self.pageTracker.hidden = NO;
        self.pageTracker.trackerColor = [UIColor colorWithRed:219.0f/255.0f green:225.0f/255.0f blue:232.0f/255.0f alpha:1.0f];
        
        if (self.introCount >= 4) {
            self.introCount = 4;
            self.mainProgressBar.hidden = YES;
            self.mainProgressBarOverlay.hidden = YES;
            self.doneBtn.alpha = 0;
            self.mainProgressBar.alpha = 0;
            self.mainProgressBarOverlay.alpha = 0;
            self.pageTracker.trackerColor = [UIColor colorWithRed:51.0f/255.0f green:65.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
        }
        [self.pageTracker highlightPic:(int)self.introCount];
        [self bringSubviewToFront:self.pageTracker];
    }
}

-(void)swipeRight {
    
    if (self.swipeEnabled) {
        self.pageTracker.trackerColor = [UIColor colorWithRed:219.0f/255.0f green:225.0f/255.0f blue:232.0f/255.0f alpha:1.0f];
        self.pageTracker.hidden = NO;
        
        if (self.scrollView.contentOffset.x > 0) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:.25];
            self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x-320, 0);
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(swipeDone)];
            [UIView commitAnimations];
            self.introCount--;
            [self.pageTracker highlightPic:(int)self.introCount];
            [self bringSubviewToFront:self.pageTracker];
        }
        
            self.doneBtn.alpha = 1;
            self.mainProgressBar.alpha = 1;
            self.mainProgressBarOverlay.alpha = 1;
    }
}

-(void)swipeDone {
    self.swipeEnabled = YES;
}

#pragma mark - Completion methods

-(void)showDoneButton {
    self.loadingComplete = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.doneBtn.hidden = NO;
    self.continueBtn.hidden = NO;
    self.progressBarOverlay.hidden = YES;
    self.progressBar.hidden = YES;
    self.pctProgressLabel.hidden = YES;
    self.mainProgressBar.hidden = YES;

    self.mainProgressBarOverlay.frame = CGRectMake(self.mainProgressBarOverlay.frame.origin.x,
                                                   self.mainProgressBarOverlay.frame.origin.y,
                                                   self.mainProgressBar.frame.size.width,
                                                   self.mainProgressBarOverlay.frame.size.height);

    
    self.statusLabel.text = @"Your Spayce Account\nis now ready";
}

-(void)finished {
    self.mainProgressBarOverlay.hidden = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissIntro)]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self.delegate dismissIntro];
    }
}

@end
