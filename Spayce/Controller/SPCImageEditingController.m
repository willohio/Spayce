//
//  SPCImageEditingController.m
//  Spayce
//
//  Created by Christopher Taylor on 5/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCImageEditingController.h"

@interface SPCImageEditingController ()

@property (nonatomic, strong) UIView *clippingView;
@property (nonatomic, strong) UIImageView *previewImgView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *filterScrollView;
@property (nonatomic, strong) UIView *highlightLine;

@property (nonatomic, strong) UIScrollView *customizeFilterScrollView;
@property (nonatomic, strong) UIView *sliderContainer;
@property (nonatomic, strong) UISlider *filterSlider;
@property (nonatomic, strong) UILabel *filterTitleLabel;

@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *saveChangesBtn;
@property (nonatomic, assign) CGFloat heightAdj;

@end

@implementation SPCImageEditingController

-(void)dealloc {
    NSLog(@"SPCImageEditingController dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.heightAdj = 0;
    if (self.view.bounds.size.width < 375) {
        self.heightAdj = 20;
    }
    
    self.view.backgroundColor = [UIColor colorWithRed:34.0f/255.0f green:40.0f/255.0f blue:46.0f/255.0f alpha:1.0f];

    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.doneBtn];
    
    [self.view addSubview:self.clippingView];
    [self.clippingView addSubview:self.scrollView];
    [self.scrollView addSubview:self.previewImgView];
    
    [self.view addSubview:self.filterScrollView];
    [self.view addSubview:self.customizeFilterScrollView];
    
    [self.view addSubview:self.sliderContainer];
    [self.sliderContainer addSubview:self.filterSlider];
    [self.sliderContainer addSubview:self.filterTitleLabel];
    [self.sliderContainer addSubview:self.cancelBtn];
    [self.sliderContainer addSubview:self.saveChangesBtn];

    [self updateFilterPreviews];
    
    //restore any previous zooming
    float zScale = self.previewImgView.image.size.width / self.sourceImage.cropSize;
    float offsetX = zScale * self.sourceImage.originX;
    float offsetY = zScale * self.sourceImage.originY;
    
    //NSLog(@"zScale %f",zScale);
    //NSLog(@"offsetX %f",offsetX);
    //NSLog(@"offsetY %f",offsetY);
    
    self.scrollView.minimumZoomScale = 1;
    
    if (self.previewImgView.image.size.width > self.previewImgView.image.size.height) {
        self.scrollView.minimumZoomScale = self.previewImgView.image.size.width / self.sourceImage.image.size.height;
    }
    
    
    self.scrollView.zoomScale = zScale;
    self.scrollView.contentOffset = CGPointMake(offsetX, offsetY);
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors

-(UIImage *)compositeImage {
    if (!_compositeImage) {
        _compositeImage = self.sourceImage.image;
    }
    return _compositeImage;
}

-(UIImage *)doubleCompositeImage {
    if (!_doubleCompositeImage) {
        _doubleCompositeImage = self.compositeImage;
    }
    return _doubleCompositeImage;
}

-(UIImageView *)previewImgView {
    if (!_previewImgView) {
        _previewImgView = [[UIImageView alloc] initWithImage:self.sourceImage.image];
    }
    return _previewImgView;
}

-(UIView *)clippingView {
    if (!_clippingView) {
        _clippingView = [[UIView alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, self.view.frame.size.width)];
        _clippingView.clipsToBounds = YES;
        _clippingView.userInteractionEnabled = YES;
        _clippingView.backgroundColor = [UIColor redColor];
    }
    return _clippingView;
}

-(UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.sourceImage.image.size.width, self.sourceImage.image.size.width)];
        _scrollView.backgroundColor = [UIColor blackColor];
        _scrollView.scrollEnabled = YES;
        _scrollView.userInteractionEnabled = YES;
        _scrollView.bounces = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
       
        float imgWidth = self.sourceImage.image.size.width;
        float initialScale = self.view.frame.size.width/imgWidth;
        
        _scrollView.transform = CGAffineTransformMakeScale(initialScale, initialScale);
        _scrollView.center = CGPointMake(self.clippingView.frame.size.width/2,self.clippingView.frame.size.height/2);
        _scrollView.contentSize = CGSizeMake(self.sourceImage.image.size.width, self.sourceImage.image.size.height);
        _scrollView.zoomScale = 1;
        _scrollView.minimumZoomScale = 1;
        _scrollView.maximumZoomScale = 8.0f;
        _scrollView.bouncesZoom = YES;
        _scrollView.delegate = self;
        
    }
    return _scrollView;
}

-(UILabel *)titleLabel {
    if (!_titleLabel){
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width-240)/2, 0, 240, 60)];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont spc_mediumSystemFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = NSLocalizedString(@"Filters", nil);
    }
    return _titleLabel;
}

-(UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 54, 60)];
        [_backBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _backBtn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
        [_backBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}


-(UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 50, 0, 50, 60)];
        _doneBtn.backgroundColor = [UIColor clearColor];
        [_doneBtn setTitle:@"Save" forState:UIControlStateNormal];
        _doneBtn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
        [_doneBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f]  forState:UIControlStateNormal];
        [_doneBtn addTarget:self action:@selector(finishedEditingImage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}

-(UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.sliderContainer.frame.size.height - 50, 50, 50)];
        UIImage *cancelImage = [UIImage imageNamed:@"filter-cancel"];
        [_cancelBtn setBackgroundImage:cancelImage forState:UIControlStateNormal];
        _cancelBtn.backgroundColor = [UIColor clearColor];
        [_cancelBtn addTarget:self action:@selector(cancelFilter) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

-(UIButton *)saveChangesBtn {
    if (!_saveChangesBtn) {
        _saveChangesBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.sliderContainer.frame.size.width - 50, self.sliderContainer.frame.size.height - 50, 50, 50)];
        _saveChangesBtn.backgroundColor = [UIColor clearColor];
        UIImage *saveImg = [UIImage imageNamed:@"filter-save"];
        [_saveChangesBtn setBackgroundImage:saveImg forState:UIControlStateNormal];
        [_saveChangesBtn addTarget:self action:@selector(updateCompositeImage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveChangesBtn;
}

-(UIView *)highlightLine {
    if (!_highlightLine) {
        _highlightLine = [[UIView alloc] initWithFrame:CGRectMake(0, 106, 80, 4)];
        _highlightLine.backgroundColor = [UIColor orangeColor];
    }
    
    return _highlightLine;
}

-(UIScrollView *) filterScrollView {
    if (!_filterScrollView) {
        _filterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.clippingView.frame), self.view.bounds.size.width-0, 110)];
        _filterScrollView.backgroundColor = [UIColor whiteColor];
        _filterScrollView.delegate = self;
        _filterScrollView.showsHorizontalScrollIndicator = NO;
        [_filterScrollView addSubview:self.highlightLine];

    }
    return _filterScrollView;
}

-(UIScrollView *) customizeFilterScrollView {
    if (!_customizeFilterScrollView) {
        _customizeFilterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,
                                                                           CGRectGetMaxY(self.filterScrollView.frame),
                                                                           self.view.bounds.size.width-0,
                                                                           (CGRectGetMaxY(self.view.frame)-CGRectGetMaxY(self.filterScrollView.frame)))];
        _customizeFilterScrollView.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f];
        _customizeFilterScrollView.delegate = self;
        _customizeFilterScrollView.showsHorizontalScrollIndicator = NO;
        
        NSArray *filterIconsArray = @[
                                      @"filter-brightness",
                                      @"filter-warmth",
                                      @"filter-contrast",
                                      @"filter-vignette",
                                      @"filter-saturation",
                                      @"filter-shadow",
                                      @"filter-highlight",
                                      @"filter-sharpen"];
        
        float btnOriginX = 0;
        
        for (int i = 0; i<[filterIconsArray count]; i++){
            
            btnOriginX = i * 60;
            
            UIImageView *filterView = [[UIImageView alloc] initWithFrame:CGRectMake(btnOriginX+5, 0, 50, 50)];
            [filterView setUserInteractionEnabled:YES];
            filterView.center = CGPointMake(filterView.center.x, _customizeFilterScrollView.frame.size.height/2);
            UIImage *iconImg = [UIImage imageNamed:filterIconsArray[i]];
            [filterView setImage:iconImg];
          
            UITapGestureRecognizer *grTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(customizeFilterWithFilter:)];
            [filterView setGestureRecognizers:@[grTap]];
          
            filterView.tag = i;
            filterView.clipsToBounds = NO;
            filterView.backgroundColor = [UIColor clearColor];
            [_customizeFilterScrollView addSubview:filterView];
        }
        
        _customizeFilterScrollView.contentSize = CGSizeMake(btnOriginX+60, 50);
    }
    return _customizeFilterScrollView;
}

-(UIView *)sliderContainer {
    
    if (!_sliderContainer) {
        _sliderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, _customizeFilterScrollView.frame.origin.y, self.view.bounds.size.width, _customizeFilterScrollView.frame.size.height + self.heightAdj)];
        _sliderContainer.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:53.0f/255.0f blue:61.0f/255.0f alpha:1.0f];
        _sliderContainer.hidden = YES;
    }
    return _sliderContainer;
}

-(UILabel *)filterTitleLabel {
    if (!_filterTitleLabel) {
            _filterTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.sliderContainer.frame.size.height - 50, self.view.frame.size.width, 50)];
            _filterTitleLabel.textColor = [UIColor whiteColor];
            _filterTitleLabel.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:39.0f/255.0f blue:45.0f/255.0f alpha:1.0f];
            _filterTitleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
            _filterTitleLabel.textAlignment = NSTextAlignmentCenter;
            _filterTitleLabel.text = NSLocalizedString(@"", nil);
    }
    return _filterTitleLabel;
}

-(UISlider *)filterSlider {
 
    if (!_filterSlider) {
        float adjH = 5;
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            adjH = 17;
        }
        
        _filterSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, adjH, self.view.bounds.size.width-40, 30)];
        _filterSlider.maximumTrackTintColor = [UIColor colorWithRed:33.0f/255.0f green:39.0f/255.0f blue:45.0f/255.0f alpha:1.0f];
        _filterSlider.minimumTrackTintColor = [UIColor colorWithRed:155.0f/255.0f green:202.0f/255.0f blue:62.0f/255.0f alpha:1.0f];
        
        UIImage *thumbImage = [UIImage imageNamed:@"filter-slider-knob"];
        [_filterSlider setThumbImage:thumbImage forState:UIControlStateNormal];
        [_filterSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];
        [_filterSlider addTarget:self action:@selector(updateFilterValue) forControlEvents:UIControlEventValueChanged];
    }
    return _filterSlider;
}

#pragma mark - UIScrollViewDelegate 

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView != self.filterScrollView) {
        return  self.previewImgView;
    }
    return nil;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView {
    UIView *subView = scrollView.subviews[0];
    
    CGFloat offsetX = MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
    CGFloat offsetY = MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale  {
    //NSLog(@"scrollview offset x: %f offset y: %f scale %f",scrollView.contentOffset.x,scrollView.contentOffset.y,scrollView.zoomScale);
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView) {
        //NSLog(@"scrollview offset x: %f offset y: %f scale %f",scrollView.contentOffset.x,scrollView.contentOffset.y,scrollView.zoomScale);
    }
}

#pragma mark - Filter Actions

-(void)filterSourceImageWithFilter:(id)sender {
  
    // 'sender' is a UITapGestureRecognizer *
    UIView *filterView = ((UITapGestureRecognizer *)sender).view;
    int filterType = (int)filterView.tag;
    self.highlightLine.center = CGPointMake(filterView.center.x, self.highlightLine.center.y);
    self.sliderContainer.hidden = YES;
    self.customizeFilterScrollView.hidden = NO;
    self.customizeFilterScrollView.frame = CGRectMake(0, self.view.frame.size.height - self.customizeFilterScrollView.frame.size.height, self.view.bounds.size.width, self.customizeFilterScrollView.frame.size.height);
    self.filterScrollView.frame = CGRectMake(0, self.customizeFilterScrollView.frame.origin.y - self.filterScrollView.frame.size.height, self.view.bounds.size.width, self.filterScrollView.frame.size.height);
    
    NSArray *filtersArray = @[
            @"None", //special case
            @"CIPhotoEffectChrome",
            @"CIPhotoEffectFade",
            @"CIPhotoEffectInstant",
            @"CIPhotoEffectMono",
            @"CIPhotoEffectNoir",
            @"CIPhotoEffectProcess",
            @"CIPhotoEffectTonal",
            @"CIPhotoEffectTransfer"
    ];
    
    if (filterType < filtersArray.count) {
        
        if (filterType == 0) {
            self.previewImgView.image = self.sourceImage.image;
            self.doubleCompositeImage = self.compositeImage;
        }
        else {
        
          //  self.filterSlider.hidden = YES;
            
            UIImage *inputUIImage = self.compositeImage;
            CIImage *inputImage = [CIImage imageWithCGImage:[inputUIImage CGImage]];
            
            NSString *filterName = filtersArray[filterType];
            CIFilter *filter = [CIFilter filterWithName:filterName];
            [filter setValue:inputImage forKey:kCIInputImageKey];
            
            CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
            UIImage *image = [UIImage imageWithCGImage:cgImage];
            CGImageRelease(cgImage);
            
            self.previewImgView.image = image;
            self.doubleCompositeImage = self.previewImgView.image;
        }
    }
}

-(void)customizeFilterWithFilter:(id)sender {
  
    // 'sender' is a UITapGestureRecognizer *
    UIView *filterView = ((UITapGestureRecognizer *)sender).view;
    int filterType = (int)filterView.tag;
    
    self.sliderContainer.hidden = NO;
    self.customizeFilterScrollView.hidden = YES;

    self.sliderContainer.frame = CGRectMake(0, self.view.bounds.size.height - self.sliderContainer.frame.size.height, self.view.bounds.size.width, self.sliderContainer.frame.size.height);
    self.filterScrollView.frame = CGRectMake(0, self.sliderContainer.frame.origin.y - self.filterScrollView.frame.size.height, self.view.bounds.size.width, self.filterScrollView.frame.size.height);

    NSArray *filterTitlesArray = @[@"Brightness", @"Warmth", @"Contrast", @"Vignette", @"Saturation", @"Shadows", @"Highlights", @"Sharpen"];
    
    self.customFilterType = filterTitlesArray[filterType];
    
    float defaultValue = 0;
    
    if ([self.customFilterType isEqualToString:@"Contrast"]) {
        defaultValue = 0;
    }
    
    if ([self.customFilterType isEqualToString:@"Saturation"]) {
        defaultValue = .5;
    }
    [self.filterSlider setValue:defaultValue animated:NO];
    [self updateFilterValue];
    
    
}

-(void)updateFilterPreviews {
    
    UIView *view;
    NSArray *subs = [self.filterScrollView subviews];
    
    for (view in subs) {
        if (view != self.highlightLine) {
            [view removeFromSuperview];
        }
    }

    NSArray *filterTitlesArray = @[@"Original", @"Chrome", @"Fade", @"Instant", @"Mono", @"Noir", @"Process", @"Tonal", @"Transfer"];
    NSArray *filtersArray = @[
            @"None", // special case
            @"CIPhotoEffectChrome",
            @"CIPhotoEffectFade",
            @"CIPhotoEffectInstant",
            @"CIPhotoEffectMono",
            @"CIPhotoEffectNoir",
            @"CIPhotoEffectProcess",
            @"CIPhotoEffectTonal",
            @"CIPhotoEffectTransfer"
    ];
    
    float btnOriginX = 0;
    
    for (int i = 0; i<[filterTitlesArray count]; i++){
        
        btnOriginX = i * 80;
        
        UIView *filterView = [[UIView alloc] initWithFrame:CGRectMake(btnOriginX, 0, 80, 110)];
        UITapGestureRecognizer *grTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(filterSourceImageWithFilter:)];
        [filterView setGestureRecognizers:@[grTap]];
      
        filterView.tag = i;
        filterView.clipsToBounds = NO;
        filterView.backgroundColor = [UIColor clearColor];
        [self.filterScrollView addSubview:filterView];
        
        UIView *clippingView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 70, 70)];
        clippingView.clipsToBounds = YES;
        clippingView.userInteractionEnabled = NO;
        [filterView addSubview:clippingView];
        
        if (i < filtersArray.count) {
            
            //display source image thumb
            if (i == 0) {
                UIImageView *tempPreviewImageView = [[UIImageView alloc] initWithImage:self.sourceImage.image];
                float scaleAdj = 70/tempPreviewImageView.frame.size.width;
                tempPreviewImageView.transform = CGAffineTransformMakeScale(scaleAdj, scaleAdj);
                tempPreviewImageView.center = CGPointMake(clippingView.frame.size.width/2, clippingView.frame.size.height/2);
                [clippingView addSubview:tempPreviewImageView];
            }
            
            //handle filtered thum previews
            else {
                
                UIImage *inputUIImage = self.compositeImage;
                CIImage *inputImage = [CIImage imageWithCGImage:[inputUIImage CGImage]];
                
                NSString *filterName = filtersArray[i];
                CIFilter *filter = [CIFilter filterWithName:filterName];
                [filter setValue:inputImage forKey:kCIInputImageKey];
                
                CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
                UIImage *image = [UIImage imageWithCGImage:cgImage];
                CGImageRelease(cgImage);
                
                UIImageView *tempPreviewImageView = [[UIImageView alloc] initWithImage:image];
                float scaleAdj = 70/tempPreviewImageView.frame.size.width;
                tempPreviewImageView.transform = CGAffineTransformMakeScale(scaleAdj, scaleAdj);
                tempPreviewImageView.center = CGPointMake(clippingView.frame.size.width/2, clippingView.frame.size.height/2);
                [clippingView addSubview:tempPreviewImageView];
            }
        }
        
        UIView *borderLine = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(filterView.frame)-1,0, 1, filterView.frame.size.height)];
        borderLine.backgroundColor = [UIColor colorWithWhite:125.0f/255.0f alpha:1.0f];
        [filterView addSubview:borderLine];
        
        UILabel *filterLbl = [[UILabel alloc] initWithFrame:CGRectMake(btnOriginX, 85, 80, 20)];
        NSString *filterTitle = [filterTitlesArray[i] uppercaseString];
        filterLbl.text = filterTitle;
        filterLbl.textColor = [UIColor colorWithWhite:128.0f/255.0f alpha:1.0f];
        filterLbl.backgroundColor = [UIColor clearColor];
        filterLbl.font = [UIFont spc_regularSystemFontOfSize:10];
        filterLbl.textAlignment = NSTextAlignmentCenter;
        filterLbl.tag = -1;
        [self.filterScrollView addSubview:filterLbl];
    }
    
    [self.filterScrollView bringSubviewToFront:self.highlightLine];
    self.filterScrollView.contentSize = CGSizeMake(btnOriginX+80, 50);
}

-(void)updateFilterValue {
    float slideValue = _filterSlider.value;
    //NSLog(@"slideValue %f",slideValue);

    UIImage *inputUIImage = self.doubleCompositeImage;
    CIImage *inputImage = [CIImage imageWithCGImage:[inputUIImage CGImage]];
    UIImage *image;
    
    self.filterTitleLabel.text = self.customFilterType;
    
    if ([self.customFilterType isEqualToString:@"Brightness"]) {
        CIImage *outputImage = [self oldPhoto:inputImage updateBrightnessWithAmount:slideValue];
        
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    if ([self.customFilterType isEqualToString:@"Contrast"]) {
        CIImage *outputImage = [self oldPhoto:inputImage updateContrastWithAmount:slideValue];
        
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    if ([self.customFilterType isEqualToString:@"Warmth"]) {
        CIImage *outputImage = [self oldPhoto:inputImage updateWarmthWithAmount:slideValue];
        
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    if ([self.customFilterType isEqualToString:@"Saturation"]) {
        CIImage *outputImage = [self oldPhoto:inputImage updateSaturationWithAmount:slideValue];
        
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    if ([self.customFilterType isEqualToString:@"Highlights"]) {
        CIImage *outputImage = [self oldPhoto:inputImage updateHighlightsWithAmount:slideValue];
        
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    if ([self.customFilterType isEqualToString:@"Shadows"]) {
        CIImage *outputImage = [self oldPhoto:inputImage updateShadowsWithAmount:slideValue];
        
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    if ([self.customFilterType isEqualToString:@"Sharpen"]) {
        CIImage *outputImage = [self oldPhoto:inputImage updateSharpnessWithAmount:slideValue];
        
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    
    if ([self.customFilterType isEqualToString:@"Vignette"]) {
        CIImage *outputImage = [self oldPhoto:inputImage updateVignetteWithAmount:slideValue];
        
        CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
        image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    
    self.previewImgView.image = image;
}

-(CIImage *)oldPhoto:(CIImage *)img updateBrightnessWithAmount:(float)intensity {
    
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setValue:img forKey:kCIInputImageKey];
    [lighten setValue:@(intensity * .25) forKey:@"inputBrightness"];

    return lighten.outputImage;
}

-(CIImage *)oldPhoto:(CIImage *)img updateWarmthWithAmount:(float)intensity {
    
    
    CIFilter *warmth = [CIFilter filterWithName:@"CISepiaTone"];
    [warmth setValue:img forKey:kCIInputImageKey];
    [warmth setValue:@(intensity) forKey:@"inputIntensity"];
    
    return warmth.outputImage;
}

-(CIImage *)oldPhoto:(CIImage *)img updateContrastWithAmount:(float)intensity {
    
    float tempIntensity = 1 + intensity;
    
    CIFilter *contrast = [CIFilter filterWithName:@"CIColorControls"];
    [contrast setValue:img forKey:kCIInputImageKey];
    [contrast setValue:@(tempIntensity) forKey:@"inputContrast"];
    
    return contrast.outputImage;
}

-(CIImage *)oldPhoto:(CIImage *)img updateSaturationWithAmount:(float)intensity {
    
    CIFilter *saturate = [CIFilter filterWithName:@"CIColorControls"];
    [saturate setValue:img forKey:kCIInputImageKey];
    [saturate setValue:@(intensity) forKey:@"inputSaturation"];
    
    return saturate.outputImage;
}

-(CIImage *)oldPhoto:(CIImage *)img updateShadowsWithAmount:(float)intensity {
    
    CIFilter *shadows = [CIFilter filterWithName:@"CIHighlightShadowAdjust"];
    [shadows setValue:img forKey:kCIInputImageKey];
    [shadows setValue:@(intensity) forKey:@"inputShadowAmount"];
    [shadows setValue:@(.2)forKey:@"inputHighlightAmount"];
    return shadows.outputImage;
}

-(CIImage *)oldPhoto:(CIImage *)img updateHighlightsWithAmount:(float)intensity {
    
    CIFilter *highlight = [CIFilter filterWithName:@"CIHighlightShadowAdjust"];
    [highlight setValue:img forKey:kCIInputImageKey];
    [highlight setValue:@(intensity) forKey:@"inputHighlightAmount"];
    [highlight setValue:@(0) forKey:@"inputShadowAmount"];
    return highlight.outputImage;
}

-(CIImage *)oldPhoto:(CIImage *)img updateVignetteWithAmount:(float)intensity {
    
    CIFilter *vignette = [CIFilter filterWithName:@"CIVignette"];
    [vignette setValue:img forKey:kCIInputImageKey];
    [vignette setValue:@(intensity * 2) forKey:@"inputIntensity"];
    [vignette setValue:@(intensity * 40) forKey:@"inputRadius"];
    
    return vignette.outputImage;
}

-(CIImage *)oldPhoto:(CIImage *)img updateSharpnessWithAmount:(float)intensity {
    
    CIFilter *sharpness = [CIFilter filterWithName:@"CISharpenLuminance"];
    [sharpness setValue:img forKey:kCIInputImageKey];
    [sharpness setValue:@(intensity) forKey:@"inputSharpness"];
    
    return sharpness.outputImage;
}

-(void)updateCompositeImage {
    self.compositeImage = self.previewImgView.image;
    self.doubleCompositeImage = self.compositeImage;
    self.sliderContainer.hidden = YES;
    self.customizeFilterScrollView.hidden = NO;
    self.customizeFilterScrollView.frame = CGRectMake(0, self.view.frame.size.height - self.customizeFilterScrollView.frame.size.height, self.view.bounds.size.width, self.customizeFilterScrollView.frame.size.height);
    self.filterScrollView.frame = CGRectMake(0, self.customizeFilterScrollView.frame.origin.y - self.filterScrollView.frame.size.height, self.view.bounds.size.width, self.filterScrollView.frame.size.height);
    
    [self updateFilterPreviews];
}

-(void)cancelFilter {
    self.previewImgView.image = self.compositeImage;
    self.sliderContainer.hidden = YES;
    self.customizeFilterScrollView.hidden = NO;
    self.customizeFilterScrollView.frame = CGRectMake(0, self.view.frame.size.height - self.customizeFilterScrollView.frame.size.height, self.view.bounds.size.width, self.customizeFilterScrollView.frame.size.height);
    self.filterScrollView.frame = CGRectMake(0, self.customizeFilterScrollView.frame.origin.y - self.filterScrollView.frame.size.height, self.view.bounds.size.width, self.filterScrollView.frame.size.height);
    
}

#pragma mark - Navigation Actions

-(void)cancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelEditing)]){
        [self.delegate cancelEditing];
    }
}

-(void)finishedEditingImage {
    
    SPCImageToCrop *newImage = [[SPCImageToCrop alloc] initWithDefaultsAndImage:self.previewImgView.image];

    float originX = self.scrollView.contentOffset.x * (1 / self.scrollView.zoomScale);
    float originY = self.scrollView.contentOffset.y * (1 / self.scrollView.zoomScale);
    float cropWidth = self.previewImgView.image.size.width * (1 / self.scrollView.zoomScale);
    
    newImage.originX = originX;
    newImage.originY = originY;
    newImage.cropSize = cropWidth;
    
    NSLog(@"new image origin x %f origin y %f cropsize %f",originX,originX,cropWidth);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(finishedEditingImage:)]){
        [self.delegate finishedEditingImage:newImage];
    }
}

#pragma  mark - Orientation Methods

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark - UIStatusBar Styling
- (void)updateForCall {
    self.filterScrollView.center = CGPointMake(self.filterScrollView.center.x, self.filterScrollView.center.y - 20);
    self.sliderContainer.center = CGPointMake(self.sliderContainer.center.x, self.sliderContainer.center.y - 20);
    self.customizeFilterScrollView.center = CGPointMake(self.customizeFilterScrollView.center.x, self.customizeFilterScrollView.center.y - 20);
    
    self.filterSlider.center = CGPointMake(self.filterSlider.center.x, self.filterSlider.center.y - 5);
    
    self.filterTitleLabel.center = CGPointMake(self.filterTitleLabel.center.x, self.filterTitleLabel.center.y - 20);
    self.cancelBtn.center = CGPointMake(self.cancelBtn.center.x, self.cancelBtn.center.y - 20);
    self.saveChangesBtn.center = CGPointMake(self.saveChangesBtn.center.x, self.saveChangesBtn.center.y - 20);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)cleanUp {
    
    NSLog(@"clean up filters??");
    
    for (UIView *view in _filterScrollView.subviews) {
        if ([view isKindOfClass:[UIView class]]) {
            if (view.gestureRecognizers.count > 0) {
                NSLog(@"remove gesture recognizer?");
                [view removeGestureRecognizer:[view.gestureRecognizers objectAtIndex:0]];
            }
            
            for (UIView *subView in view.subviews) {
                for (UIView *subSubView in subView.subviews) {
                    if ([subSubView isKindOfClass:[UIImageView class]]) {
                        NSLog(@"need to remove an image?");
                        UIImageView *imgSubView = (UIImageView *)subSubView;
                        imgSubView.image =nil;
                        
                    }
                    [subSubView removeFromSuperview];
                }
                //NSLog(@"remove filter view sub sub!");
                [subView removeFromSuperview];
            }
            
            if (view != self.highlightLine) {
                //NSLog(@"remove filter view sub!");
                [view removeFromSuperview];
            }
            
        }

   }
    
    for (UIView *view in _scrollView.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            UIImageView *imgView = (UIImageView *)view;
            imgView.image =nil;
        }
        [view removeFromSuperview];
    }
    
    _clippingView = nil;
    _previewImgView.image = nil;
    _previewImgView = nil;
    _scrollView = nil;
    _filterScrollView = nil;
    _customizeFilterScrollView = nil;
    
}
     



@end
