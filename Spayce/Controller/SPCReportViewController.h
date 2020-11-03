//
//  SPCReportViewController.h
//  Spayce
//
//  Created by Arria P. Owlia on 2/18/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCReportViewController;
@protocol SPCReportViewControllerDelegate <NSObject>

// reportObject passed in is invalid - called immediatedly following initWithReportObject:andReportType:
- (void)invalidReportObjectOnSPCReportViewController:(SPCReportViewController *)reportViewController;

// User tapped cancel button
- (void)canceledReportOnSPCReportViewController:(SPCReportViewController *)reportViewController;

// User tapped send button and report was successfully sent
- (void)sentReportOnSPCReportViewController:(SPCReportViewController *)reportViewController;

// user tapped send button and report was unsuccessful
- (void)sendFailedOnSPCReportViewController:(SPCReportViewController *)reportViewController;

@end

@interface SPCReportViewController : UIViewController

// Delegate
@property (weak, nonatomic) id<SPCReportViewControllerDelegate> delegate;

// Data
@property (nonatomic) SPCReportType reportType;
@property (strong, nonatomic) id reportObject;

// Init
- (instancetype)initWithReportObject:(id)object reportType:(SPCReportType)reportType andDelegate:(id<SPCReportViewControllerDelegate>)delegate;

// Class-Level report string from report type
+ (NSString *)stringFromReportType:(SPCReportType)reportType;

@end
