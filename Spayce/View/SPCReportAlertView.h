//
//  SPCReportAlertView.h
//  Spayce
//
//  Created by Arria P. Owlia on 2/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCReportAlertView;
@protocol SPCReportAlertViewDelegate <NSObject>

@optional // But highly recommended
- (void)tappedOption:(NSString *)option onSPCReportAlertView:(SPCReportAlertView *)reportView;
- (void)tappedDismissTitle:(NSString *)dismissTitle onSPCReportAlertView:(SPCReportAlertView *)reportView;

@end

@interface SPCReportAlertView : UIView

// Delegate
@property (weak, nonatomic) id<SPCReportAlertViewDelegate> delegate;

// Properties
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSArray *stringOptions;
@property (strong, nonatomic) NSArray *stringDismissTitles;

// Custom Init
- (instancetype)initWithTitle:(NSString *)title stringOptions:(NSArray *)stringOptions dismissTitles:(NSArray *)dismissTitles andDelegate:(id<SPCReportAlertViewDelegate>)delegate;

// Actions
- (void)showAnimated:(BOOL)animated;
- (void)showInView:(UIView *)view animated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

@end
