//
//  SPCImageEditingController.h
//  Spayce
//
//  Created by Christopher Taylor on 5/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCImageToCrop.h"

@protocol SPCImageEditingControllerDelegate <NSObject>

@optional

- (void)cancelEditing;
- (void)finishedEditingImage:(SPCImageToCrop *)newImage;

@end

@interface SPCImageEditingController : UIViewController <UIScrollViewDelegate> {
    
}
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, strong) SPCImageToCrop *sourceImage;
@property (nonatomic, strong) UIImage *compositeImage;
@property (nonatomic, strong) UIImage *doubleCompositeImage;
@property (nonatomic, strong) NSString *customFilterType;
@property (nonatomic, weak) NSObject <SPCImageEditingControllerDelegate> *delegate;

-(void)cleanUp;
-(void)updateForCall;
@end
