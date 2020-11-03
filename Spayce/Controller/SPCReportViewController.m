//
//  SPCReportViewController.m
//  Spayce
//
//  Created by Arria P. Owlia on 2/18/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCReportViewController.h"

// Framework
#import "Flurry.h"

// Model
#import "Memory.h"
#import "Comment.h"
#import "Venue.h"

// Manager
#import "MeetManager.h"
#import "VenueManager.h"

@interface SPCReportViewController() <UITextViewDelegate>

// Header
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *sendButton;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

// Text View
@property (strong, nonatomic) UITextView *textView;

// State
@property (nonatomic) BOOL isSendingReport;

@end

@implementation SPCReportViewController

- (instancetype)initWithReportObject:(id)object reportType:(SPCReportType)reportType andDelegate:(id<SPCReportViewControllerDelegate>)delegate {
    if (self = [super init]) {
        self.reportType = reportType;
        self.reportObject = object;
        self.delegate = delegate;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Background Color
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Header, with buttons
    [self.view addSubview:self.headerView];
    
    // Text field
    [self.view addSubview:self.textView];
    
    // Notify our delegate if we do not have a valid report object
    if (![self.reportObject isKindOfClass:[Memory class]] && ![self.reportObject isKindOfClass:[Comment class]] && ![self.reportObject isKindOfClass:[Venue class]]) {
        if ([self.delegate respondsToSelector:@selector(invalidReportObjectOnSPCReportViewController:)]) {
            [self.delegate invalidReportObjectOnSPCReportViewController:self];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Hide navigation controller
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}

#pragma mark - Actions

- (void)tappedCancelButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(canceledReportOnSPCReportViewController:)]) {
        [self.delegate canceledReportOnSPCReportViewController:self];
    }
}

// This method is not configured to reset the view once complete. If we want to reset the view once the report is sent/failed/etc, we must update this implementation.
- (void)tappedSendButton:(id)sender {
    if (nil != self.reportObject) {
        [self setSendButtonEnabled:NO];
        self.sendButton.hidden = YES;
        [self.activityIndicator startAnimating];
        self.textView.textColor = [UIColor grayColor];
        [self.textView resignFirstResponder];
        self.isSendingReport = YES;
        
        if ([self.reportObject isKindOfClass:[Memory class]]) {
            Memory *memory = (Memory *)self.reportObject;
            
            [Flurry logEvent:@"MEM_REPORTED"];
            [MeetManager reportMemoryWithMemoryId:memory.recordID reportType:self.reportType text:self.textView.text resultCallback:^(NSDictionary *results) {
                if ([self.delegate respondsToSelector:@selector(sentReportOnSPCReportViewController:)]) {
                    [self.delegate sentReportOnSPCReportViewController:self];
                }
            } faultCallback:^(NSError *fault) {
                if ([self.delegate respondsToSelector:@selector(sendFailedOnSPCReportViewController:)]) {
                    [self.delegate sendFailedOnSPCReportViewController:self];
                }
            }];
        } else if ([self.reportObject isKindOfClass:[Comment class]]) {
            Comment *comment = (Comment *)self.reportObject;
            
            [MeetManager reportCommentWithCommentId:comment.recordID reportType:self.reportType text:self.textView.text resultCallback:^{
                if ([self.delegate respondsToSelector:@selector(sentReportOnSPCReportViewController:)]) {
                    [self.delegate sentReportOnSPCReportViewController:self];
                }
            } faultCallback:^(NSError *fault) {
                if ([self.delegate respondsToSelector:@selector(sendFailedOnSPCReportViewController:)]) {
                    [self.delegate sendFailedOnSPCReportViewController:self];
                }
            }];
        } else if ([self.reportObject isKindOfClass:[Venue class]]) {
            Venue *venue = (Venue *)self.reportObject;
            
            [Flurry logEvent:@"VENUE_REPORTED"];
            [[VenueManager sharedInstance] reportOrCorrectVenue:venue reportType:self.reportType text:self.textView.text completionHandler:^(BOOL success) {
                if (success) {
                    if ([self.delegate respondsToSelector:@selector(sentReportOnSPCReportViewController:)]) {
                        [self.delegate sentReportOnSPCReportViewController:self];
                    }
                } else {
                    if ([self.delegate respondsToSelector:@selector(sendFailedOnSPCReportViewController:)]) {
                        [self.delegate sendFailedOnSPCReportViewController:self];
                    }
                }
            }];
        } else {
            if ([self.delegate respondsToSelector:@selector(invalidReportObjectOnSPCReportViewController:)]) {
                [self.delegate invalidReportObjectOnSPCReportViewController:self];
            }
        }
    }
}

- (void)setSendButtonEnabled:(BOOL)enabled {
    if (enabled) {
        self.sendButton.alpha = 1.0f;
        self.sendButton.enabled = YES;
    } else {
        self.sendButton.alpha = 0.3f;
        self.sendButton.enabled = NO;
    }
}

- (void)updateSendButtonWithFinalText:(NSString *)text {
    if (0 < text.length && NO == [text isEqualToString:SPCREPORT_PLACEHOLDER_TEXT]) {
        [self setSendButtonEnabled:YES];
    } else {
        [self setSendButtonEnabled:NO];
    }
}

#pragma mark - Accessors - UI

- (UIView *) headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
        _headerView.backgroundColor = [UIColor whiteColor];
        
        self.titleLabel.frame = CGRectMake(0, 22, self.view.frame.size.width, 50);
        [_headerView addSubview:self.titleLabel];
        
        self.cancelButton.frame = CGRectMake(0, CGRectGetHeight(_headerView.frame) - 45.0f, 60, 44);
        [_headerView addSubview:self.cancelButton];
        
        self.sendButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - 65, CGRectGetHeight(_headerView.frame) - 37.0f, 60, 30);
        [_headerView addSubview:self.sendButton];
        
        self.activityIndicator.frame = self.sendButton.frame;
        [_headerView insertSubview:self.activityIndicator belowSubview:self.sendButton];
        
        CGFloat separatorHeight = 1.0f / [UIScreen mainScreen].scale;
        UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(0, _headerView.frame.size.height - separatorHeight, self.view.bounds.size.width, separatorHeight)];
        sepView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
        [_headerView addSubview:sepView];
    }
    
    return _headerView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = [[self class] stringFromReportType:self.reportType];
        _titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
    }
    return _titleLabel;
}

- (UIButton *)cancelButton {
    if (nil == _cancelButton) {
        _cancelButton = [[UIButton alloc] init];
        _cancelButton.backgroundColor = [UIColor clearColor];
        NSDictionary *cancelStringAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14.0f],
                                                  NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x4cb0fb] };
        NSAttributedString *cancelString = [[NSAttributedString alloc] initWithString:@"Cancel" attributes:cancelStringAttributes];
        [_cancelButton setAttributedTitle:cancelString forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(tappedCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cancelButton;
}

- (UIButton *)sendButton {
    if (nil == _sendButton) {
        _sendButton = [[UIButton alloc] init];
        _sendButton.layer.cornerRadius = 2.0f;
        _sendButton.layer.masksToBounds = YES;
        NSDictionary *sendStringAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14.0f],
                                                NSForegroundColorAttributeName : [UIColor whiteColor] };
        NSAttributedString *sendString = [[NSAttributedString alloc] initWithString:@"Send" attributes:sendStringAttributes];
        [_sendButton setAttributedTitle:sendString forState:UIControlStateNormal];
        [_sendButton setBackgroundColor:[UIColor colorWithRGBHex:0x4cb0fb]];
        [_sendButton addTarget:self action:@selector(tappedSendButton:) forControlEvents:UIControlEventTouchUpInside];
        [self updateSendButtonWithFinalText:_textView.text];
    }
    
    return _sendButton;
}

- (UITextView *)textView {
    if (nil == _textView) {
        CGFloat sidePadding = 10.0f;
        CGFloat topPadding = 10.0f;
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(sidePadding, CGRectGetMaxY(self.headerView.frame) + topPadding, CGRectGetWidth(self.view.frame) - 2 * sidePadding, 500)];
        _textView.tintColor = [UIColor colorWithRGBHex:0x4cb0fb];
        _textView.font = [UIFont fontWithName:@"OpenSans" size:14.0f];
        _textView.text = SPCREPORT_PLACEHOLDER_TEXT;
        _textView.selectedRange = NSMakeRange(0, 0);
        _textView.textColor = [UIColor lightGrayColor];
        _textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textView.autocorrectionType = UITextAutocorrectionTypeYes;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.delegate = self;
    }
    
    return _textView;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (nil == _activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    return _activityIndicator;
}

#pragma mark - UITextViewDelegate

static NSString *SPCREPORT_PLACEHOLDER_TEXT = @"In a few lines, tell us what's bothering you...";
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    static const NSInteger MAX_CHARACTER_COUNT = 500;
    BOOL shouldChangeText = YES;
    
    // Here, we check and make sure that the total text is under 500 characters
    if ([textView isEqual:self.textView] && NO == self.isSendingReport) {
        if ([text isEqualToString:@"\n"]) {
            // Return/Send key pressed
            [self tappedSendButton:nil];
            shouldChangeText = NO;
        } else {
            shouldChangeText = NO;
            NSMutableString *textViewText = [NSMutableString stringWithString:textView.text];
            [textViewText replaceCharactersInRange:range withString:text];
            
            NSString *finalTextString = textView.text;
            
            if (MAX_CHARACTER_COUNT > textViewText.length) {
                shouldChangeText = YES;
                finalTextString = textViewText;
            }
            
            // Update the send button
            [self updateSendButtonWithFinalText:finalTextString];
        }
    }
    
    return shouldChangeText;
}

- (void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.textView]) {
        // First, handle the placeholder text. We should set it if there is no text in the field
        // We should remove it if it is a substring of the full text, beginning at index 0
        if (0 >= textView.text.length) {
            textView.text = SPCREPORT_PLACEHOLDER_TEXT;
            textView.selectedRange = NSMakeRange(0, 0);
        } else if (SPCREPORT_PLACEHOLDER_TEXT.length < textView.text.length && NSNotFound != [textView.text rangeOfString:SPCREPORT_PLACEHOLDER_TEXT].location) {
            NSRange placeholderRange = [textView.text rangeOfString:SPCREPORT_PLACEHOLDER_TEXT];
            textView.text = [textView.text stringByReplacingCharactersInRange:placeholderRange withString:@""];
        }
        
        // Now, handle the color. Placeholder color if the displayed text is the placeholder
        // Black color otherwise
        if ([SPCREPORT_PLACEHOLDER_TEXT isEqualToString:textView.text]) {
            textView.textColor = [UIColor lightGrayColor];
        } else {
            textView.textColor = [UIColor blackColor];
        }
    }
}

#pragma mark - Helpers

+ (NSString *)stringFromReportType:(SPCReportType)reportType {
    NSString *strType = @"";
    if (SPCReportTypeAbuse == reportType) {
        strType = @"Abuse";
    } else if (SPCReportTypeSpam == reportType) {
        strType = @"Spam";
    } else if (SPCReportTypePersonal == reportType) {
        strType = @"Pertains To Me";
    } else if (SPCReportTypeIncorrect == reportType) {
        strType = @"Doesn't Exist";
    }
    
    return strType;
}

@end
