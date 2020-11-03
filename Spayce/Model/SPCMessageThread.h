//
//  SPCMessageThread.h
//  Spayce
//
//  Created by Christopher Taylor on 3/23/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCMessageThread : NSObject

@property (nonatomic, strong) NSString *keyStr;
@property (nonatomic, strong) NSArray *participants;  //Composed of Person objects
@property (nonatomic, strong) NSArray *messages;      //Composed of SPCMessage objects
@property (nonatomic, strong) NSDate *dateOfMostRecentThreadActivity;
@property (nonatomic, strong) NSString *displayDate;
@property (nonatomic, strong) NSDate *userLastReadDate;
@property (nonatomic, assign) BOOL hasUnreadMessages;
@property (nonatomic, assign) BOOL isMuted;

- (id)init;
- (id)initWithAttributes:(NSDictionary *)attributes;
- (void)configureWithParticipants:(NSArray *)participants andMessages:(NSArray *)messages threadID:(NSString *)keyStr;
- (NSString *)generateUpdatedDisplayDate;
- (void)configureDates;

-(void)updateLastReadDate;

@end
