//
//  SPCSpoofLocationViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 12/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSpoofLocationViewController.h"

@interface SPCSpoofLocationViewController ()

@property (nonatomic, assign) BOOL spoofOn;
@property (nonatomic, strong) NSString *spoofLatStr;
@property (nonatomic, strong) NSString *spoofLongStr;
@property (nonatomic, strong) UISwitch *spoofSwitch;
@property (nonatomic, strong) UITextField *latTextField;
@property (nonatomic, strong) UITextField *longTextField;

@end

@implementation SPCSpoofLocationViewController

-(void)dealloc {
    // Cancel any previous requests that were set to execute on a delay!!
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Spoof Location";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor colorWithRed:222.0f/255.0f green:222.0f/255.0f blue:222.0f/255.0f alpha:1.0f];
    
    //retrieve last defaults set
    
    self.spoofOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"spoofOn"];
    self.spoofLatStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"spoofLatStr"];
    self.spoofLongStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"spoofLongStr"];
    
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 200, 40 )];
    tempLabel.text = @"Spoofing active";
    tempLabel.font = [UIFont spc_mediumSystemFontOfSize:20];
    [self.view addSubview:tempLabel];
    
    UILabel *tempLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, 200, 40 )];
    tempLabel1.text = @"Latitude";
    tempLabel1.font = [UIFont spc_mediumSystemFontOfSize:20];
    [self.view addSubview:tempLabel1];
  
    UILabel *tempLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(20, 200, 200, 40 )];
    tempLabel2.text = @"Longitude";
    tempLabel2.font = [UIFont spc_mediumSystemFontOfSize:20];
    [self.view addSubview:tempLabel2];
    
    
    [self.view addSubview:self.walkSwitch];
    [self.view addSubview:self.latTextField];
    [self.view addSubview:self.longTextField];
    
    self.latTextField.text = self.spoofLatStr;
    self.longTextField.text = self.spoofLongStr;
    
}

#pragma mark - Accessors

-(UISwitch *)walkSwitch {
    
    if (!_spoofSwitch) {
        _spoofSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(240, 110, 60, 60)];
        [_spoofSwitch addTarget: self action: @selector(flipSwitch:) forControlEvents: UIControlEventValueChanged];
        [_spoofSwitch setOn:self.spoofOn];
    }
    return _spoofSwitch;
}

-(UITextField *)latTextField {
    if (!_latTextField) {
        _latTextField = [[UITextField alloc] initWithFrame:CGRectMake(240, 165, 80, 30)];
        _latTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        _latTextField.backgroundColor = [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:242.0f/255.0f alpha:1.0f];
        _latTextField.delegate = self;
    }
    return _latTextField;
}

-(UITextField *)longTextField {
    if (!_longTextField) {
        _longTextField = [[UITextField alloc] initWithFrame:CGRectMake(240, 205, 80, 30)];
        _longTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        _longTextField.backgroundColor = [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:242.0f/255.0f alpha:1.0f];
        _longTextField.delegate = self;
    }
    return _longTextField;
}


#pragma mark - UITextField delegate 

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self performSelector:@selector(updateLatLong) withObject:text afterDelay:0.1];
    return YES;
}

#pragma mark - Actions 

-(void)flipSwitch:(id)sender {
    

    UISwitch *spoofSwitch = (UISwitch *) sender;
    self.spoofOn = spoofSwitch.on;
    
    [[NSUserDefaults standardUserDefaults] setBool:self.spoofOn forKey:@"spoofOn"];
    NSLog(@"%@", spoofSwitch.on ? @"Spoofing On" : @"Spoofing Off");
}

-(void)updateLatLong {
    [[NSUserDefaults standardUserDefaults] setObject:self.latTextField.text forKey:@"spoofLatStr"];
    [[NSUserDefaults standardUserDefaults] setObject:self.longTextField.text forKey:@"spoofLongStr"];
}

@end
