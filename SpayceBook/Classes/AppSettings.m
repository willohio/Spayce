//
//  AppSettings.m
//  Spayce
//
//  Created by Howard Cantrell on 11/8/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "AppSettings.h"
#import "Flurry.h"

// View
#import "PXAlertView.h"

// General
#import "Singleton.h"

// Utility
#import "APIService.h"
#import "ImageUtils.h"

@interface AppSettings ()

@property (nonatomic, strong) NSString *updateUrl;

- (void)showUpdate:(NSString *)message action:(SEL)action cancel:(void (^)(void))cancelCallback;
- (void)onUpdateClick:(id)sender;
- (void)onForceClick:(id)sender;
- (void)openAppStore;

@end

@implementation AppSettings

SINGLETON_GCD(AppSettings);

- (void)loadAndCheckForUpdate
{
    __weak typeof(self)weakSelf = self;

    [APIService makeApiCallWithMethodUrl:@"/app/settings" // TODO: change to real API when it is finished
                          resultCallback:^(NSObject *result) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;

                              if (!strongSelf) {
                                  return;
                              }
                              
                              strongSelf.settings = [[NSDictionary alloc] initWithDictionary:(NSDictionary *)result];
                              NSDictionary *version = self.settings[@"version"];

                              strongSelf.updateUrl = self.settings[@"updateUrl"];

                              if (version != nil)
                              {
                                  NSInteger update = [version[@"update"] integerValue];
                                  NSInteger force = [version[@"force"] integerValue];

                                  NSInteger appVersion = [[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] integerValue];

                                  if (force >= appVersion) {
                                      // Force App Update
                                      [Flurry logEvent:@"UPDATE_FORCE"];

                                      NSDictionary *messages = self.settings[@"messages"];
                                      NSString *message = messages[@"force"];
                                      [strongSelf showUpdate:message action:@selector(onForceClick:) cancel:^{
                                          [strongSelf onForceClick:nil];
                                      }];
                                  }
                                  else if (update >= appVersion) {
                                      // Nag for Update
                                      [Flurry logEvent:@"UPDATE_NAG"];

                                      NSDictionary *messages = self.settings[@"messages"];
                                      NSString *message = messages[@"update"];
                                      [strongSelf showUpdate:message action:@selector(onUpdateClick:) cancel:^{}];
                                  }
                              }

                          } faultCallback:^(NSError *fault) {
                          }];
}

- (void)showUpdate:(NSString *)message action:(SEL)action cancel:(void (^)(void))cancelCallback
{
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 200)];
    contentView.backgroundColor = [UIColor whiteColor];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spayce-logo"]];
    imageView.frame = CGRectMake(0, 15, 270, 40);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [contentView addSubview:imageView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, 270, 20)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = @"Spayce has been updated!";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:titleLabel];

    if (!message)
    {
        message = @"Download the latest version today and get all the great new features!";
    }

    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 95, 230, 40)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.numberOfLines = 0;
    messageLabel.text = message;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [contentView addSubview:messageLabel];
    [messageLabel sizeToFit];

    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(70, messageLabel.frame.origin.y + messageLabel.frame.size.height + 15, 130, 40);

    contentView.frame = CGRectMake(0, 0, contentView.frame.size.width, actionButton.frame.origin.y + actionButton.frame.size.height + 15);

    [actionButton setTitle:NSLocalizedString(@"Update", nil) forState:UIControlStateNormal];
    actionButton.backgroundColor = [UIColor colorWithRGBHex:0x4ACBEB];
    actionButton.layer.cornerRadius = 4.0;
    actionButton.titleLabel.font = [UIFont systemFontOfSize:16];

    UIImage *selectedImage = [ImageUtils roundedRectImageWithColor:[UIColor colorWithRGBHex:0x4795AC] size:actionButton.frame.size corners:4.0f];
    [actionButton setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [actionButton setBackgroundImage:selectedImage forState:UIControlStateSelected];

    [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [actionButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:actionButton];

    [PXAlertView showAlertWithView:contentView completion:^(BOOL cancelled) {
        if (cancelCallback != nil) {
            cancelCallback();
        }
    }];
}

#pragma mark - Action Methods

- (void)onUpdateClick:(id)sender
{
    [self openAppStore];
}

- (void)onForceClick:(id)sender
{
    [self openAppStore];
    exit(0);
}

- (void)openAppStore
{
    NSURL *appStoreURL = [NSURL URLWithString:self.updateUrl];
    [[UIApplication sharedApplication] openURL:appStoreURL];
}

@end
