//
//  AddressBookRequest.h
//  Spayce
//
//  Created by Pavel Dušátko on 2/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * AddressBookRequestDidStartNotification;
extern NSString * AddressBookRequestDidEndNotification;

@interface AddressBookRequest : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSDictionary *addressBookDictionary;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, copy) void (^completionHandler)(NSObject *result);
@property (nonatomic, copy) void (^errorHandler)(NSError *error);

- (void)start:(NSOperationQueue *)operationQueue;

@end
