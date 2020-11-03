//
//  SPCTemplateViewController.m
//  Spayce
//
//  Created by Pavel Dusatko on 4/8/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTemplateViewController.h"

@interface SPCTemplateViewController ()

// Private interface

// Use generic names
// @Good - tableView
// @Bad - templateTableView
@property (nonatomic, strong) UITableView *tableView;
// Diferentiate if necessary
@property (nonatomic, weak) UITableViewCell *firstCell;
@property (nonatomic, weak) UITableViewCell *secondCell;

@property (nonatomic, assign) BOOL hasViewAppeared;

@end

@implementation SPCTemplateViewController

// Use pragma marks to separate code
// Always prefer following naming conventions
// 1. Use '-' rather than 2 line pragmas
// 2. Use 'object' name
// 3. Use 'documentation section name'
// 4. Fallback to custom text if non of the above apply

// @Good - #pragma mark - UITableViewDataSource (easily accessed by cmd-clicking)
// @Good - #pragma mark - NSObject - Creating, Copying, and Deallocating Objects (easily trackable in documentation)
// @Good - #pragma mark - Presenting view controllers (custom message)
// @Bad - #pragma mark Some text (doesn't separate sections by ommiting '-' sign)
// @Bad - #pragma mark View's lifecycle (cover's too much scope)
// @Bad - #pragma mark - Table view data source (can't access it's code by cmd-clicking)
// @Bad - #pragma mark - Orientation methods (should be UIViewController - Responding to View Rotation Events to reference the real origin)

// 1. Creating object should be at the top of the implementation file
// @Bad - Never refer to views before they're even loaded (wait for loadView/viewDidLoad)
#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

// Always put dealloc as the first method
- (void)dealloc {
    // do nothing
    
    // Remove observers
    // Remove KVO (using @try @catch)
}

// 2. Accessors should be the second top most section

#pragma mark - Accessors

// Prefer to lazy-load properties rather than settings them manually in code
// This brings too much code clutter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = nil;
    }
    return _tableView;
}

// 3. View's lifecycle should be separated into groups as defined in documentation

#pragma mark - UIViewController - Managing the View

- (void)loadView {
    [super loadView];
    
    // Always prefer to create view hierarchy in loadView
    // By using a correct combination of autoresizing masks
    // we do not need to update view's frames, etc. later
    // on in the lifecycle of our view controller (be smart)
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add observers
}

// viewWillAppear, viewDidAppear, viewWillDissapear & viewDidDissapear
// are not guaranteed to be called exactly once (usually twice depending
// on the current navigation hierarchy)
// Use flags to prevent bugs (introduced bellow)

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Add observers that we only require during the time
    // that our view controller is visible
    
    // Use flags to limit the amount of execution calls
    // for first time loads
    if (!self.hasViewAppeared) {
        self.hasViewAppeared = YES;
        
        // Do something only once
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove observers that we only required during the
    // time that our view controller was visible
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Restore the initial state of our view controller
    if (self.hasViewAppeared) {
        self.hasViewAppeared = NO;
    }
}

// 4. Delegates should be again grouped together with a proper signature

#pragma mark - UITableViewDataSource

#pragma mark - UIAlertViewDelegate

// 5. Use Private section for common actions that define internal business logic of view controller
// and are not directly accessed by any ui component

#pragma mark - Private

// 6. Use Actions section for all the actions that are directly accessible using ui components
// or are defined in public interface (header file) or are of IBAction types

#pragma mark - Actions

@end
