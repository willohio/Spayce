//
//  SPCMessage.h
//  Spayce
//
//  Created by Christopher Taylor on 3/19/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"

@interface SPCMessage : NSObject

@property (nonatomic, strong) Person *author;
@property (nonatomic, strong) NSString *messageText;
@property (nonatomic, strong) NSDate *createdDate;
@property (nonatomic, assign) BOOL currUserIsAuthor;
@property (nonatomic, strong) NSString *displayDate;
@property (nonatomic, strong) NSString *displayTime;
@property (nonatomic, assign) CGFloat messageHeight;
@property (nonatomic, assign) CGFloat messageWidth;
@property (nonatomic, strong) NSString *picUrl;
@property (nonatomic, strong) NSString *keyStr;


- (id)initWithAttributes:(NSDictionary *)attributes;
-(BOOL)currUserIsAuthor;

@end
