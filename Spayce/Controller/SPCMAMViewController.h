//
//  SPCMAMViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 2/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SPCMamCaptureControls.h"
#import "SPCImageEditingController.h"

@interface SPCMAMViewController : UIViewController <SPCImageEditingControllerDelegate>
@property (nonatomic, assign) BOOL hasMicPermission;
-(void)resetMAM;

@end

// Coachmark delegate & views
@protocol SPCMAMCoachmarkViewDelegate <NSObject>
- (void)didTapToEndOnCoachmarkView:(UIView *)mamCoachmarkView;
@end

@interface SPCMAMCaptureCoachmarkView : UIView
@property (weak, nonatomic) id<SPCMAMCoachmarkViewDelegate> delegate;
@end

@interface SPCMAMAdjustmentCoachmarkView : UIView
@property (weak, nonatomic) id<SPCMAMCoachmarkViewDelegate> delegate;
@end

