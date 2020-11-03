//
//  SPCAddMemoryViewController.h
//  Spayce
//
//  Created by Pavel Dusatko on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCPostMemoryViewController.h"
#import "SPCImageEditingController.h"
#import "SPCCustomCameraControls.h"
#import "SPCPickLocationViewController.h"

@class Venue;

@interface SPCCaptureMemoryViewController : UIViewController <UIImagePickerControllerDelegate, SPCPostMemoryViewControllerDelegate,SPCImageEditingControllerDelegate, SPCCustomCameraControlsDelegate,SPCPickLocationViewControllerDelegate>


- (instancetype)initWithSelectedVenue:(Venue *)venue;

@end
