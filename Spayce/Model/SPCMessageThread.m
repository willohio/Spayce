//
//  SPCMessageThread.m
//  Spayce
//
//  Created by Christopher Taylor on 3/23/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "AuthenticationManager.h"
#import "User.h"

#import "SPCMessageThread.h"
#import "SPCMessage.h"

#import "TranslationUtils.h"

@implementation SPCMessageThread


- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        [self setWithAttributes:attributes];
    }
    return self;
}

- (void)setWithAttributes:(NSDictionary *)attributes {
    
    //set key str
    _keyStr = (NSString *)[TranslationUtils valueOrNil:attributes[@"threadKey"]];
    
    _isMuted = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"isMuted"];
    
    //set messages
    NSDictionary *messages = (NSDictionary *)[TranslationUtils valueOrNil:attributes[@"messages"]];
    NSArray *messagesArray = [messages objectForKey:@"messages"];
    NSMutableArray *workingMessages = [[NSMutableArray alloc] init];
    
    for (int j = 0; j < messagesArray.count; j++) {
        SPCMessage *tempMsg = [[SPCMessage alloc] initWithAttributes:messagesArray[j]] ;
        [workingMessages addObject:tempMsg];
    }
    
    _messages = [NSArray arrayWithArray:workingMessages];
    
    //set participants
    NSDictionary *participants = (NSDictionary *)[TranslationUtils valueOrNil:attributes[@"threadParticipants"]];
    NSArray *participiantArray = [participants objectForKey:@"friends"];
    NSMutableArray *workingParticipants = [[NSMutableArray alloc] init];
    
    User *currentUser = [AuthenticationManager sharedInstance].currentUser;
    
    for (int i = 0; i < participiantArray.count; i++) {
        Person *tempPerson = [[Person alloc] initWithAttributes:participiantArray[i]] ;
        if (![tempPerson.userToken isEqualToString:currentUser.userToken]) {
            [workingParticipants addObject:tempPerson];
        }
    }
    
    _participants = [NSArray arrayWithArray:workingParticipants];
 
    NSNumber *lastReadDate = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"userLastReadDate"]];
    
    if (lastReadDate) {
        NSTimeInterval miliseconds = [lastReadDate doubleValue];
        NSTimeInterval seconds = miliseconds/1000;
        _userLastReadDate = [NSDate dateWithTimeIntervalSince1970:seconds];
    }
    
    [self configureDates];
}


-(void)updateLastReadDate {
    
    NSTimeInterval nowIntervalS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]);
    _userLastReadDate = [NSDate dateWithTimeIntervalSince1970:nowIntervalS];
}

-(BOOL)hasUnreadMessages {
    BOOL unreadMsgs = NO;
    
    NSTimeInterval intervalSinceLastReadInSeconds = [self.userLastReadDate timeIntervalSince1970];
    
    for (int i = 0; i < self.messages.count; i++) {
        SPCMessage *msg = self.messages[i];
        NSTimeInterval intervalSinceCreatedInSeconds = [msg.createdDate timeIntervalSince1970];
        
        if (intervalSinceCreatedInSeconds > intervalSinceLastReadInSeconds) {
            
            if (![msg.author.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
                unreadMsgs = YES;
                break;
            }
        }
    }

    return unreadMsgs;
}


//Method used when creating a thread locally
- (void)configureWithParticipants:(NSArray *)participants andMessages:(NSArray *)messages threadID:(NSString *)keyStr {
    _participants = participants;
    _messages = messages;
    _keyStr = keyStr;
    
    [self configureDates];
}

- (void)configureDates {
   
    //get most recent message
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:YES];
    NSArray *descriptors = @[descriptor];
   
    if (_messages.count > 0) {
        NSArray *sortedMessages = [_messages sortedArrayUsingDescriptors:descriptors];
        _messages = [NSArray arrayWithArray:sortedMessages];
        SPCMessage *mostRecentMsg = sortedMessages[sortedMessages.count - 1];
        _dateOfMostRecentThreadActivity = mostRecentMsg.createdDate;
    }
}

- (NSString *)generateUpdatedDisplayDate {
    
    NSString *dateToDisplay = @"";
    
    NSTimeInterval nowIntervalS = (NSTimeIntervalSince1970 + [NSDate timeIntervalSinceReferenceDate]);
    NSTimeInterval seconds = [_dateOfMostRecentThreadActivity timeIntervalSince1970];
    
    NSTimeInterval delta = nowIntervalS - seconds;
    
    //NSLog(@"delta second %f",delta);
    
    //less than an minute old
    if (delta < 60) {
        NSInteger secondsElapsed = delta;
        dateToDisplay = [NSString stringWithFormat:@"%lis",secondsElapsed];
    }
    
    //less than an hour old
    else if (delta < (60 * 60)) {
        float minutesDelta = round(delta / 60);
        NSInteger minutesElapsed = minutesDelta;
        dateToDisplay = [NSString stringWithFormat:@"%lim",minutesElapsed];
    }
    
    //less than a day old
    else if (delta < (60 * 60 * 24)) {
        float hoursDelta = round(delta / 60 / 60);
        NSInteger hoursElapsed = hoursDelta;
        dateToDisplay = [NSString stringWithFormat:@"%lih",hoursElapsed];
        
    }
    
    //less than two days old
    else if ((delta) < (60 * 60 * 48)) {
        dateToDisplay = NSLocalizedString(@"Yesterday", nil);
        
    }
    
    
    //less than a week old
    else if (delta < (60 * 60 * 24 * 7)) {
        
        NSInteger seconds = [[NSTimeZone systemTimeZone] secondsFromGMT];
        NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
        [localDateFormatter setDateFormat:@"EEEE"];
        [localDateFormatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: seconds]];
        dateToDisplay = [localDateFormatter stringFromDate: _dateOfMostRecentThreadActivity];
        
    }
    //older than a week
    else {
        
        NSInteger seconds = [[NSTimeZone systemTimeZone] secondsFromGMT];
        NSDateFormatter *localDateFormatter = [[NSDateFormatter alloc] init];
        [localDateFormatter setDateFormat:@"M/d/YY"];
        [localDateFormatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: seconds]];
        dateToDisplay = [localDateFormatter stringFromDate: _dateOfMostRecentThreadActivity];
    }
    
    _displayDate = dateToDisplay;
    
    return dateToDisplay;
}



@end
