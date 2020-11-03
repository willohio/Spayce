//
//  SPCAlertViewController.m
//  Spayce
//
//  Created by Pavel Dusatko on 10/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAlertViewController.h"

// Model
#import "SPCAlertAction.h"

// View
#import "SPCAlertCell.h"

static NSString * CellIdentifier = @"ActionCell";

@interface SPCAlertViewController () <UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>

// Data
@property (nonatomic, strong) NSArray *actions;

// UI
@property (nonatomic) CGFloat containerViewHeight;
@property (nonatomic, strong) NSLayoutConstraint *containerViewBottomConstraint;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation SPCAlertViewController

#pragma mark - Accessors

- (CGFloat)containerViewHeight {
    CGFloat height = 0;
    for (int i = 0; i < self.actions.count; i++) {
        height += [self tableView:nil heightForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    height += [self tableView:nil heightForRowAtIndexPath:nil] + 2 * 10;
    return height;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _containerView;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = [UIColor colorWithRed:172.0/255.0 green:182.0/255.0 blue:198.0/255.0 alpha:1.0];
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _headerView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.image = self.alertImage;
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _imageView;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.minimumScaleFactor = 0.75;
        _textLabel.font = [UIFont spc_regularSystemFontOfSize:18];
        _textLabel.text = self.alertTitle;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _textLabel;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.scrollEnabled = NO;
    }
    return _tableView;
}

- (void)addAction:(SPCAlertAction *)action {
    NSMutableArray *mutableActions = [NSMutableArray arrayWithArray:self.actions];
    [mutableActions addObject:action];
    self.actions = [mutableActions copy];
}

#pragma mark - View's lifecycle

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    
    // View hierarchy
    
    [self.view addSubview:self.containerView];
    [self.containerView addSubview:self.headerView];
    [self.headerView addSubview:self.imageView];
    [self.headerView addSubview:self.textLabel];
    [self.containerView addSubview:self.tableView];
    
    // Container view
    
    self.containerViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.containerView
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeBottom
                                                                     multiplier:1.0
                                                                       constant:self.containerViewHeight];
    
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.containerView
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.view
                                  attribute:NSLayoutAttributeLeft
                                 multiplier:1.0
                                   constant:0.0]
     ];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.containerView
                                  attribute:NSLayoutAttributeRight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.view
                                  attribute:NSLayoutAttributeRight
                                 multiplier:1.0
                                   constant:0.0]
     ];
    [self.view addConstraint:self.containerViewBottomConstraint];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.containerView
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1.0
                                   constant:self.containerViewHeight]
     ];
    
    // Header view
    
    [self.containerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.headerView
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeLeft
                                 multiplier:1.0
                                   constant:0.0]
     ];
    [self.containerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.headerView
                                  attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1.0
                                   constant:0.0]
     ];
    [self.containerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.headerView
                                  attribute:NSLayoutAttributeRight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeRight
                                 multiplier:1.0
                                   constant:0.0]
     ];
    [self.containerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.headerView
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1.0
                                   constant:[self tableView:nil heightForRowAtIndexPath:nil]]
     ];
    
    // Image view
    
    [self.headerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.imageView
                                  attribute:NSLayoutAttributeCenterY
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.headerView
                                  attribute:NSLayoutAttributeCenterY
                                 multiplier:1.0
                                   constant:0.0]
     ];
    [self.headerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.imageView
                                  attribute:NSLayoutAttributeRight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.textLabel
                                  attribute:NSLayoutAttributeLeft
                                 multiplier:1.0
                                   constant:-10.0]
     ];
    [self.headerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.imageView
                                  attribute:NSLayoutAttributeWidth
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1.0
                                   constant:self.imageView.image.size.width]
     ];
    [self.headerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.imageView
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1.0
                                   constant:self.imageView.image.size.height]
     ];
    
    // Text label
    
    [self.headerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.textLabel
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.headerView
                                  attribute:NSLayoutAttributeCenterX
                                 multiplier:1.0
                                   constant:self.imageView.image.size.width - 5.0]
     ];
    [self.headerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.textLabel
                                  attribute:NSLayoutAttributeCenterY
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.headerView
                                  attribute:NSLayoutAttributeCenterY
                                 multiplier:1.0
                                   constant:0.0]
     ];
    [self.headerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.textLabel
                                  attribute:NSLayoutAttributeWidth
                                  relatedBy:NSLayoutRelationLessThanOrEqual
                                     toItem:self.headerView
                                  attribute:NSLayoutAttributeWidth
                                 multiplier:1.0
                                   constant:-2 * (self.imageView.image.size.width + 10)]
     ];
    [self.headerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.textLabel
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1.0
                                   constant:self.textLabel.font.lineHeight]
     ];
    
    // Table view
    
    [self.containerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.tableView
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeLeft
                                 multiplier:1.0
                                   constant:10.0]
     ];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.tableView
                                  attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.headerView
                                  attribute:NSLayoutAttributeBottom
                                 multiplier:1.0
                                   constant:10.0]
     ];
    [self.containerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.tableView
                                  attribute:NSLayoutAttributeRight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeRight
                                 multiplier:1.0
                                   constant:-10.0]
     ];
    [self.containerView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.tableView
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeBottom
                                 multiplier:1.0
                                   constant:-10.0]
     ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[SPCAlertCell class] forCellReuseIdentifier:CellIdentifier];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
    tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self animateIn];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.actions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCAlertCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    SPCAlertAction *action = self.actions[indexPath.row];
    [cell configureWithTitle:action.title subtitle:action.subtitle style:action.style image:action.image];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return 45;
    }
    
    SPCAlertAction *action = self.actions[indexPath.row];
    return action.subtitle ? 70.0 : 45.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self dismissViewControllerWithAction:self.actions[indexPath.row]];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return touch.view == self.view;
}

#pragma mark - Private

- (void)animateIn {
    // Layout subviews before animation
    [self.view layoutIfNeeded];
    
    // Update auto layout constraint
    self.containerViewBottomConstraint.constant = 0;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         // Animate background color
                         self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
                         
                         // Animate auto layout constraint
                         [self.view layoutIfNeeded];
                     } completion:nil];
}

- (void)animateOutWithCompletionHandler:(void (^)())completionHandler {
    // Update auto layout constraint
    self.containerViewBottomConstraint.constant = self.containerViewHeight;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         // Animate background color
                         self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
                         
                         // Animate auto layout constraint
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         if (completionHandler) {
                             completionHandler();
                         }
                     }];
}

- (void)dismissViewControllerWithAction:(SPCAlertAction *)action {
    [self animateOutWithCompletionHandler:^{
        [self dismissViewControllerAnimated:YES completion:^{
            if (action.handler) {
                action.handler(action);
            }
        }];
    }];
}

#pragma mark - Gestures

- (void)tapGestureRecognized:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self dismissViewControllerWithAction:nil];
    }
}

@end
