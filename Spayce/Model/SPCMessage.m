//
//  SPCMessage.m
//  Spayce
//
//  Created by Christopher Taylor on 3/19/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMessage.h"

//Framework
#import <CoreText/CoreText.h>

//Manager
#import "AuthenticationManager.h"

//Model
#import "User.h"
#import "UserProfile.h"

//Utils
#import "TranslationUtils.h"


@implementation SPCMessage

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        [self setWithAttributes:attributes];
    }
    return self;
}

- (void)setWithAttributes:(NSDictionary *)attributes {
    _messageText = (NSString *)[TranslationUtils valueOrNil:attributes[@"text"]];
    
    if ([attributes objectForKey:@"author"]) {
        _author = [[Person alloc] initWithAttributes:attributes[@"author"]];
    }
    else {
        NSString *authorKey = (NSString *)[TranslationUtils valueOrNil:attributes[@"authorKey"]];
        NSDictionary *authorDiction = @{ @"userToken": authorKey };
        _author = [[Person alloc] initWithAttributes:authorDiction];
    }

    if ([attributes objectForKey:@"messageKey"]) {
        _keyStr = (NSString *)[TranslationUtils valueOrNil:attributes[@"messageKey"]];
    }
    
    [self initializeDateCreatedWithAttributes:attributes];
    _messageHeight = [self heightForMsgText:_messageText];

}

- (void)initializeDateCreatedWithAttributes:(NSDictionary *)attributes
{
    NSNumber *dateCreated = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"createdDate"]];
    
    if (dateCreated) {
        NSTimeInterval miliseconds = [dateCreated doubleValue];
        NSTimeInterval seconds = miliseconds/1000;
        _createdDate = [NSDate dateWithTimeIntervalSince1970:seconds];
    }
    
    // formatted string
    NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
    [localDateFormatter setDateFormat:@"ccc, LLL d, h:mm a"];
    localDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    self.displayDate = [localDateFormatter stringFromDate: _createdDate];
    
    NSDateFormatter *localTimeFormatter = [[NSDateFormatter alloc] init];
    [localTimeFormatter setDateFormat:@"h:mm a"];
    localTimeFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    self.displayTime = [localTimeFormatter stringFromDate:_createdDate];
    
    
}

-(BOOL)currUserIsAuthor {
    BOOL isAuthor = NO;
    
    if ( [[AuthenticationManager sharedInstance].currentUser.userToken isEqualToString:self.author.userToken]) {
        isAuthor = YES;
    }
    
    return isAuthor;
}


- (CGFloat)heightForMsgText:(NSString *)msgText {
    if (_messageHeight == 0) {
        
        float maxWidth = 200;
    
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            maxWidth = 240;
        }
        
        //5.5"
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            maxWidth = 300;
        }
        
        CGSize constraint = CGSizeMake(maxWidth, 20000);
        NSMutableAttributedString * cellText;
        NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor blackColor],
                                      NSFontAttributeName: [UIFont fontWithName:@"OpenSans" size:17]};
        
        // Account for memory text if it exists
        if (msgText.length > 0) {
            cellText = [[NSMutableAttributedString alloc] initWithString:msgText attributes:attributes];
        }
        else {
            cellText = [[NSMutableAttributedString alloc] initWithString:@"" attributes:attributes];
        }
 
        // Add line spacing
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:1.0];
        [cellText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, cellText.length)];
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithAttributedString:cellText];
        
        //using core text to correctly handle sizing for emoji
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
        CGSize targetSize = CGSizeMake(constraint.width, CGFLOAT_MAX);
        CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [attrString length]), NULL, targetSize, NULL);
        CFRelease(framesetter);
        _messageHeight = ceilf(fitSize.height);
        
        if (_messageHeight < 40) {
            _messageHeight = 40;
        }
        else {
            _messageHeight = _messageHeight + 26; //only add the extra vertical padding if we need it!
        }
        
        _messageWidth = ceilf(fitSize.width + 26);
        if (_messageWidth < 40) {
            _messageWidth = 40;
        }
    }
    return _messageHeight;
}

@end
