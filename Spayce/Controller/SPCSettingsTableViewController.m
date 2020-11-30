//
//  SPCSettingsTableViewController.m
//  Spayce
//
//  Created by William Santiago on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSettingsTableViewController.h"

// Model
#import "Asset.h"
#import "ProfileDetail.h"
#import "SPCAlertAction.h"
#import "UserProfile.h"

// View
#import "SPCInitialsImageView.h"
#import "SPCSettingsAccountCell.h"
#import "SPCSettingsActionCell.h"
#import "SPCSettingsHeaderView.h"
#import "SPCSettingsRegularCell.h"
#import "SPCSettingsSwitchCell.h"
#import "SPCDeleteAccountConfirmationView.h"

// Controller
#import "SPCAccountSettingsViewController.h"
#import "SPCBlockedUsersViewController.h"
#import "SPCAlertViewController.h"
#import "SPCMailComposeViewController.h"
#import "SPCVenueCodeViewController.h"
#import "SPCWebViewController.h"
#import "SPCSpoofLocationViewController.h"

// Manager
#import "SettingsManager.h"

// Category
#import "NSString+SPCAdditions.h"
#import "UIAlertView+SPCAdditions.h"
#import "UIColor+SPCAdditions.h"
#import "UITableView+SPXRevealAdditions.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"

// Utils
#import "APIUtils.h"

// Transition
#import "SPCAlertTransitionAnimator.h"

// Framework
#import <MessageUI/MessageUI.h>

static NSString *headerCellIdentifier = @"headerCellIdentifier";
static NSString *footerCellIdentifier = @"footerCellIdentifier";
static NSString *accountCellIdentifier = @"accountCellIdentifier";
static NSString *switchCellIdentifier = @"switchCellIdentifier";
static NSString *regularCellIdentifier = @"regularCellIdentifier";
static NSString *actionCellIdentifier = @"actionCellIdentifier";

@interface SPCSettingsTableViewController () <MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) NSIndexPath *accountSettingsCellIndexPath;

@property (nonatomic) NSInteger accountSettingsSectionIndex;
@property (nonatomic) NSInteger privacySettingsSectionIndex;
@property (nonatomic) NSInteger supportSectionIndex;
@property (nonatomic) NSInteger notificationsSectionIndex;
@property (nonatomic) NSInteger venueCodeSectionIndex;
@property (nonatomic) NSInteger otherSectionIndex;
@property (nonatomic) NSInteger deleteSectionIndex;
@property (nonatomic) NSInteger signOutSectionIndex;
@property (nonatomic) NSInteger totalNumberOfSections;
@property (nonatomic) NSInteger deleteAccountSucceededTag;
@property (nonatomic) BOOL privacySettingsSectionEnabled;
@property (nonatomic) BOOL notificationSectionEnabled;

@property (strong, nonatomic) SPCDeleteAccountConfirmationView *deleteAccountConfirmationView;

@end

@implementation SPCSettingsTableViewController

#pragma mark - View lifecycle

-(void)dealloc {
    // Remove observers!!!!
    self.addedLogoutNotification = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureNavigationBar];
    [self configureTableView]; // Here is where we configure which sections will be visible
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    
    [self registerForNotifications];
    
    self.deleteAccountSucceededTag = 100;
}

#pragma mark - Notifications

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileUpdated:) name:ContactAndProfileManagerPersonalProfileDidUpdateNotification object:nil];
}

- (void)profileUpdated:(NSNotification *)notification {
    [self.tableView reloadRowsAtIndexPaths:@[self.accountSettingsCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.totalNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRowsRet = 1;
    if (section == self.privacySettingsSectionIndex) {
        numberOfRowsRet = 1;
    } else if (section == self.supportSectionIndex) {
        numberOfRowsRet = 3;
    }
    return numberOfRowsRet;
}

- (UITableViewCell *)tableView:(UITableView *)tableView accountCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCSettingsAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:accountCellIdentifier forIndexPath:indexPath];
    
    NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:self.profile.profileDetail.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailLarge]];
    
    cell.customTextLabel.text = NSLocalizedString(@"My Account", nil);
    cell.customDetailTextLabel.text = [NSString stringWithFormat:@"%@ %@", self.profile.profileDetail.firstname, self.profile.profileDetail.lastname];
    [cell.customImageView configureWithText:self.profile.profileDetail.firstname.firstLetter.capitalizedString url:url];
    
    self.accountSettingsCellIndexPath = indexPath;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView switchCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCSettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:switchCellIdentifier forIndexPath:indexPath];
    
    SPCGroupedStyle style = SPCGroupedStyleSingle;
    UIImage *onImage;
    UIImage *offImage;
    NSString *title;
    NSString *description;
    BOOL on = NO;
    SwitchChangeHandler switchChangeHandler = nil;
    __weak typeof(self) weakSelf = self;
    
    if (indexPath.section == self.privacySettingsSectionIndex) {
        switch (indexPath.row) {
            case 0:
            {
                style = SPCGroupedStyleTop;
                onImage = [[UIImage imageNamed:@"settings-locked"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                offImage = [[UIImage imageNamed:@"settings-unlocked"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                
                title = NSLocalizedString(@"Make profile private", nil);
                description = NSLocalizedString(@"Your posts can still be discovered in Home.", nil);
                on = self.profile.profileDetail.profileLocked;
                switchChangeHandler = ^(id cellId, BOOL on) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    SPCSettingsSwitchCell *cell = cellId;
                    
                    strongSelf.profile.profileDetail.profileLocked = on;
                    [[SettingsManager sharedInstance] updateProfileLocked:on completionHandler:^(BOOL locked) {
                        NSLog(@"Profile locked on server: %d", locked);
                        if (locked != on) {
                            NSLog(@"Change to profile locked status was not reflected in server response");
                            cell.on = locked;
                            strongSelf.profile.profileDetail.profileLocked = locked;
                        }
                    } errorHandler:^(NSError *error) {
                        NSLog(@"Error changing profile locked status %@", error);
                        [UIAlertView showError:error];
                    }];
                };
                break;
            }
            default:
                break;
        }
    } else if (indexPath.section == self.notificationsSectionIndex) {
        onImage = offImage = [[UIImage imageNamed:@"settings-look-back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        title = NSLocalizedString(@"Look back", nil);
    }
    
    [cell configureWithStyle:style offImage:offImage onImage:onImage text:title description:description];
    cell.switchChangeHandler = switchChangeHandler;
    cell.on = on;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView regularCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCSettingsRegularCell *cell = [tableView dequeueReusableCellWithIdentifier:regularCellIdentifier forIndexPath:indexPath];
    
    SPCGroupedStyle style = SPCGroupedStyleSingle;
    UIImage *image;
    NSString *title;
    
    if (indexPath.section == self.supportSectionIndex) {
        switch (indexPath.row) {
            case 0:
                style = SPCGroupedStyleTop;
                image = [[UIImage imageNamed:@"settings-love"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                title = NSLocalizedString(@"Send love", nil);
                break;
            case 1:
                style = SPCGroupedStyleMiddle;
                image = [[UIImage imageNamed:@"settings-feedback"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                title = NSLocalizedString(@"Give feedback", nil);
                break;
            case 2:
                style = SPCGroupedStyleBottom;
                image = [[UIImage imageNamed:@"settings-about"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                title = NSLocalizedString(@"About Spayce", nil);
                break;
            default:
                break;
        }
    } else if (indexPath.section == self.venueCodeSectionIndex) {
        image = [[UIImage imageNamed:@"settings-venue"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        title = NSLocalizedString(@"Enter venue code", nil);
    } else if (indexPath.section == self.otherSectionIndex) {
        image = [[UIImage imageNamed:@"settings-blocked"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        title = NSLocalizedString(@"Blocked", nil);
    }
    
    [cell configureWithStyle:style image:image text:title];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCSettingsAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:actionCellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == self.signOutSectionIndex) {
        cell.customTextLabel.text = NSLocalizedString(@"Sign Out", nil);
    }
    else if (indexPath.section == self.deleteSectionIndex) {
        cell.customTextLabel.text = NSLocalizedString(@"Delete Account", nil);
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == self.accountSettingsSectionIndex) {
        return [self tableView:tableView accountCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == self.privacySettingsSectionIndex) {
        return [self tableView:tableView switchCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == self.supportSectionIndex) {
        return [self tableView:tableView regularCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == self.notificationsSectionIndex) {
        return [self tableView:tableView switchCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == self.venueCodeSectionIndex) {
        return [self tableView:tableView regularCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == self.otherSectionIndex) {
        return [self tableView:tableView regularCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == self.deleteSectionIndex) {
        return [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == self.signOutSectionIndex) {
        return [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
    } else {
        return nil;
    }
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == self.accountSettingsSectionIndex) {
        return NSLocalizedString(@"Account Settings", nil);
    } else if (section == self.privacySettingsSectionIndex) {
        return NSLocalizedString(@"Privacy", nil);
    } else if (section == self.supportSectionIndex) {
        return NSLocalizedString(@"Support", nil);
    } else if (section == self.notificationsSectionIndex) {
        return NSLocalizedString(@"Notifications", nil);
    } else if (section == self.venueCodeSectionIndex) {
        return NSLocalizedString(@"Venue code", nil);
    } else if (section == self.otherSectionIndex) {
        return NSLocalizedString(@"Other", nil);
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightRet = 55;
    if (indexPath.section == self.accountSettingsSectionIndex) {
        heightRet = 80;
    } else if (indexPath.section == self.privacySettingsSectionIndex) {
        return 80;
    }
    return heightRet;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self numberOfSectionsInTableView:tableView] - 1) {
        return 90;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section < [self numberOfSectionsInTableView:tableView] - 1) {
        UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerCellIdentifier];
        return headerView;
    }
    else {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section < [self numberOfSectionsInTableView:tableView] - 1) {
        UITableViewHeaderFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:footerCellIdentifier];
        return footerView;
    }
    else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
    headerView.textLabel.font = [UIFont spc_regularSystemFontOfSize:13];
    headerView.textLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    headerView.textLabel.textColor = [UIColor colorWithRed:174.0/255.0 green:177.0/255.0 blue:179.0/255.0 alpha:1.0];
    headerView.contentView.backgroundColor = [UIColor colorWithWhite:243.0/255.0 alpha:1.0];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *footerView = (UITableViewHeaderFooterView *)view;
    NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    NSString *build = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
    
    footerView.textLabel.font = [UIFont spc_regularSystemFontOfSize:13];
    footerView.textLabel.textAlignment = NSTextAlignmentCenter;
    footerView.textLabel.textColor = [UIColor colorWithRed:189.0/255.0 green:196.0/255.0 blue:206.0/255.0 alpha:1.0];
    footerView.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", version, build];
    footerView.contentView.backgroundColor = [UIColor colorWithWhite:243.0/255.0 alpha:1.0];
    footerView.userInteractionEnabled = YES;
    
    UIButton *spoofBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, footerView.frame.size.width, footerView.frame.size.height)];
    //[spoofBtn addTarget:self action:@selector(showSpoofSettings) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:spoofBtn];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == self.accountSettingsSectionIndex) {
        [self showAccount];
    } else if (indexPath.section == self.supportSectionIndex) {
        switch (indexPath.row) {
            case 0: {
                [self sendLove];
                break;
            }
            case 1: {
                [self giveFeedback];
                break;
            }
            case 2: {
                [self showAbout];
                break;
            }
            default:
                break;
        }
    } else if (indexPath.section == self.venueCodeSectionIndex) {
        [self enterVenueCode];
    } else if (indexPath.section == self.otherSectionIndex) {
        [self showBlocked];
    } else if (indexPath.section == self.deleteSectionIndex) {
        [self showDeleteAccountPrompt];
    } else if (indexPath.section == self.signOutSectionIndex) {
        [self logout];
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    return animator;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Configuration

- (void)configureNavigationBar {
    // Background and tint color
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    
    // Right 'Done' button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:14], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0x6ab1fb] } forState:UIControlStateNormal];
    
    // Title
    self.navigationItem.title = NSLocalizedString(@"Settings", nil);
    self.navigationController.navigationBar.titleTextAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                                     NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x292929],
                                                                     NSKernAttributeName : @(1.1f) };
    
    // Removing the shadow image. To do this, we must also set the background image
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,[[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:img forBarMetrics:UIBarMetricsDefault];
    
    // Adding the bottom separator
    CGFloat separatorSize = 1.0f / [UIScreen mainScreen].scale;
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.navigationController.navigationBar.frame) - separatorSize, CGRectGetWidth(self.navigationController.navigationBar.frame), separatorSize)];
    [separator setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f]];
    [self.navigationController.navigationBar addSubview:separator];
}

- (void)configureTableView {
    // Register cells for reuse
    [self.tableView registerClass:[SPCSettingsHeaderView class] forHeaderFooterViewReuseIdentifier:headerCellIdentifier];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:footerCellIdentifier];
    
    [self.tableView registerClass:[SPCSettingsAccountCell class] forCellReuseIdentifier:accountCellIdentifier];
    [self.tableView registerClass:[SPCSettingsSwitchCell class] forCellReuseIdentifier:switchCellIdentifier];
    [self.tableView registerClass:[SPCSettingsRegularCell class] forCellReuseIdentifier:regularCellIdentifier];
    [self.tableView registerClass:[SPCSettingsActionCell class] forCellReuseIdentifier:actionCellIdentifier];
    
    // Update appearance
    self.tableView.backgroundColor = [UIColor colorWithWhite:243.0/255.0 alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Disable sticky headers/footers
    CGFloat headerHeight = [self tableView:self.tableView heightForHeaderInSection: 0];
    CGFloat footerHeight = [self tableView:self.tableView heightForFooterInSection:[self numberOfSectionsInTableView:self.tableView] - 1];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), headerHeight)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), footerHeight)];
    self.tableView.contentInset = UIEdgeInsetsMake(-headerHeight, 0, -footerHeight, 0);
    
    // Our settings options are static, i.e. we set them at build time
    self.privacySettingsSectionEnabled = YES; // Set here in order to enable/disable
    self.notificationSectionEnabled = NO; // Set here in order to enable/disable
    int row = 0;
    self.accountSettingsSectionIndex = row++;
    self.privacySettingsSectionIndex = self.privacySettingsSectionEnabled ? row++ : -1;
    self.supportSectionIndex = row++;
    self.notificationsSectionIndex = self.notificationsSectionIndex ? row++ : -1;
    self.venueCodeSectionIndex = row++;
    self.otherSectionIndex = row++;
    self.signOutSectionIndex = row++;
    self.deleteSectionIndex = row++;
    self.totalNumberOfSections = row; // This number is not 0-based. Remove the '--' in order to make the Delete Account button appear once we've added support
}

#pragma mark - Actions

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showAccount {
    SPCAccountSettingsViewController *accountSettingsViewController = [[SPCAccountSettingsViewController alloc] init];
    accountSettingsViewController.profile = self.profile;
    [self.navigationController pushViewController:accountSettingsViewController animated:YES];
}

- (void)sendLove {
    UIAlertView *ratingAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Send love", nil)
                                                             message:[NSString stringWithFormat:NSLocalizedString(@"We love having you on Spayce %@! Would you leave a rating for us on the App Store?", nil), self.profile.profileDetail.firstname]
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"No Thanks", nil)
                                                    otherButtonTitles:NSLocalizedString(@"Sure!", nil), nil];
    ratingAlertView.tag = self.supportSectionIndex;
    
    [ratingAlertView show];
}

- (void)giveFeedback {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposer = [[SPCMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        [mailComposer setSubject:NSLocalizedString(@"Feedback", nil)];
        [mailComposer setMessageBody:@"Hey Spayce team,\n\nHere’s my feedback on the app:" isHTML: NO];
        [mailComposer setToRecipients:@[@"feedback@spayce.me"]];
        
        [self presentViewController:mailComposer animated:YES completion:nil];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Give feedback", nil)
                                    message:NSLocalizedString(@"Make sure your device is setup to send emails!", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

- (void)showAbout {
    SPCWebViewController *webViewController = [[SPCWebViewController alloc] init];
    webViewController.urlString = @"http://www.spayce.me";
    webViewController.title = NSLocalizedString(@"About Spayce", nil);
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)enterVenueCode {
    SPCVenueCodeViewController *venueCodeViewController = [[SPCVenueCodeViewController alloc] init];
    [self.navigationController pushViewController:venueCodeViewController animated:YES];
}

- (void)showBlocked {
    SPCBlockedUsersViewController *blockedUsersViewController = [[SPCBlockedUsersViewController alloc] init];
    [self.navigationController pushViewController:blockedUsersViewController animated:YES];
}

- (void)showDeleteAccountPrompt {
    self.deleteAccountConfirmationView = [[SPCDeleteAccountConfirmationView alloc] init];
    [self.deleteAccountConfirmationView.btnCancel addTarget:self action:@selector(tappedDeleteAccountCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.deleteAccountConfirmationView.btnDelete addTarget:self action:@selector(tappedDeleteAccountDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.deleteAccountConfirmationView showAnimated:YES];
}

- (void)tappedDeleteAccountCancelButton:(id)sender {
    [self.deleteAccountConfirmationView hideAnimated:YES];
}

- (void)tappedDeleteAccountDeleteButton:(id)sender {
    [self.deleteAccountConfirmationView showActivityIndicatorOnDelete:YES];
    
    __weak typeof(self) weakSelf = self;
    [[AuthenticationManager sharedInstance] deleteAccountWithUser:[AuthenticationManager sharedInstance].currentUser completionHandler:^(NSDictionary *result) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf.deleteAccountConfirmationView hideAnimated:YES];
        
        if (result) {
            if (nil != result[@"email"]) {
                NSString *emailAddress = result[@"email"];
                UIAlertView *succeededAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account Delete Request Received", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"A delete confirmation request email has been sent to: %@. You will now be logged out.", nil), emailAddress]
                                                                            delegate:strongSelf
                                                                   cancelButtonTitle:NSLocalizedString(@"Okay", nil)
                                                                   otherButtonTitles:nil];
                succeededAlertView.tag = strongSelf.deleteAccountSucceededTag;
                [succeededAlertView show];
            } else { // We don't have an email address to display to the user!?
                UIAlertView *succeededAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account Delete Request Received", nil)
                                                                             message:NSLocalizedString(@"You will now be logged out.", nil)
                                                                            delegate:strongSelf
                                                                   cancelButtonTitle:NSLocalizedString(@"Okay", nil)
                                                                   otherButtonTitles:nil];
                succeededAlertView.tag = strongSelf.deleteAccountSucceededTag;
                [succeededAlertView show];
            }
        } else {
            NSInteger errorCode = [result[@"errorCode"] integerValue];
            NSLog(@"Delete Account Request failed. Error Code: %ld", (long)errorCode);
            
            [strongSelf showDeleteAccountErrorAlert];
        }
    } errorHandler:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSLog(@"Delete Account Request failed. Error: %@", [error description]);
        
        [strongSelf.deleteAccountConfirmationView hideAnimated:YES];
        
        [strongSelf showDeleteAccountErrorAlert];
    }];
}

- (void)logout {
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    alertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Logout %@", nil), self.profile.profileDetail.firstname];
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Logout", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
        __weak typeof(self) weakSelf = self;
        
        [weakSelf finalizeLogout];
    }]];
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
    
    [self.navigationController presentViewController:alertViewController animated:YES completion:nil];
    
}

-(void)sendUserToAppStoreToRateApp {
    NSString *appUrlString = @"https://itunes.apple.com/us/app/spayce/id737705917?ls=1&mt=8";
    NSURL *appStoreURl = [NSURL URLWithString:appUrlString];
    [[UIApplication sharedApplication] openURL:appStoreURl];
}

-(void)showSpoofSettings {
    SPCSpoofLocationViewController *spoofViewController = [[SPCSpoofLocationViewController alloc] init];
    [self.navigationController pushViewController:spoofViewController animated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.cancelButtonIndex != buttonIndex) {
        if (alertView.tag == self.supportSectionIndex) {
            [self sendUserToAppStoreToRateApp];
        }
    }
    if (alertView.tag == self.deleteAccountSucceededTag) {
        [self finalizeLogout];
    }
}

#pragma mark - Helpers

- (void)showDeleteAccountErrorAlert {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"There was an error sending your request. Please try again.", nil)
                                message:nil
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"Okay", nil)
                      otherButtonTitles:nil] show];
}

- (void)finalizeLogout {
    if (!self.addedLogoutNotification) {
        self.addedLogoutNotification = YES;
        [[NSNotificationCenter defaultCenter] addObserverForName:kAuthenticationDidLogoutNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self dismiss];
        }];
    }
    
    [[AuthenticationManager sharedInstance] logout];
}

@end
