//
//  AddressBookRequest.m
//  Spayce
//
//  Created by Pavel Dušátko on 2/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "AddressBookRequest.h"

// Utility
#import "APIService.h"
#import "FaultUtils.h"
#import "SBJson4.h"

NSString * AddressBookRequestDidStartNotification = @"AddressBookRequestDidStartNotification";
NSString * AddressBookRequestDidEndNotification = @"AddressBookRequestDidEndNotification";

@implementation AddressBookRequest {
    BOOL initiated;
}

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (id)init {
    self = [super init];
    if (self) {
        _timeoutInterval = 40;
    }
    
    return self;
}

#pragma mark - Private

- (NSURLRequest *)buildRequest {
    NSAssert(!initiated, @"Cannot initiate a request that is already active");
    initiated = YES;
    
    NSMutableString *urlString = [[NSMutableString alloc] initWithString:self.url];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.timeoutInterval];
    request.HTTPMethod = @"POST";
    
    if (self.addressBookDictionary) {
        SBJson4Writer *writer = [[SBJson4Writer alloc] init];
        NSString *jsonStr = [writer stringWithObject:self.addressBookDictionary];
        NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"jsonStr %@",jsonStr);
        request.HTTPBody = jsonData;
    }
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [request addValue:[APIService getXAuthHeader:@"/inviteFriends/addressbook"] forHTTPHeaderField:HEADER_AUTH_KEY];
    [request addValue:[APIService getXDeviceHeader] forHTTPHeaderField:HEADER_DEVICE_KEY];
    
    return request;
}

#pragma mark - Target-Action

- (void)start:(NSOperationQueue *)operationQueue {
    NSURLRequest *request = [self buildRequest];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AddressBookRequestDidStartNotification object:self];
    
    __weak typeof(self)weakSelf = self;
    
    NSLog(@"address book request");
    NSLog(@"%@",[request allHTTPHeaderFields]);
    NSLog(@"%@",[request valueForHTTPHeaderField:@"Accept"]);
    NSLog(@"%@",[request valueForHTTPHeaderField:@"Content-Type"]);
    NSLog(@"%@",[request valueForHTTPHeaderField:@"HEADER_AUTH_KEY"]);
    NSLog(@"%@",[request valueForHTTPHeaderField:@"HEADER_DEVICE_KEY"]);
    
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               __strong typeof(weakSelf)strongSelf = weakSelf;
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:AddressBookRequestDidEndNotification object:self];
                               
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (error) {
                                       if (strongSelf.errorHandler) {
                                           NSLog(@"JSON error %@",error);
                                           strongSelf.errorHandler(error);
                                       }
                                   } else if (data) {
                                       NSError *parseError = nil;
                                       NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
                                       
                                       NSLog(@"JSON response %@",response);
                                       NSLog(@"JSON parsedResponse %@",parsedResponse);
                                       NSLog(@"JSON raw data %@",data);
                                       
                                       if (parseError) {
                                           if (strongSelf.errorHandler) {
                                               NSLog(@"JSON parseError %@",parseError);
                                               strongSelf.errorHandler(error);
                                           }
                                       } else {
                                           NSNumber *errorCode = [parsedResponse isKindOfClass:[NSDictionary class]] ? parsedResponse[@"errorCode"] : @(0);
                                           NSString *description = parsedResponse[@"description"];
                                           
                                           if ([errorCode intValue] != 0) {
                                               if (strongSelf.errorHandler) {
                                                   if (description && ![description isEqualToString:@""]) {
                                                       NSLog(@"JSON error description %@",description);
                                                       strongSelf.errorHandler([FaultUtils generalErrorWithCode:errorCode title:nil description:description]);
                                                   } else {
                                                        NSLog(@"JSON errorCode %@",errorCode);
                                                       strongSelf.errorHandler([FaultUtils generalErrorWithCode:errorCode]);
                                                   }
                                               }
                                           } else {
                                               NSObject *value = [parsedResponse isKindOfClass:[NSDictionary class]] ? parsedResponse[@"content"] : nil;
                                                NSLog(@"JSON parsedResponse content %@",parsedResponse);
                                               
                                               if (strongSelf.completionHandler) {
                                                   strongSelf.completionHandler(value != nil ? value : parsedResponse);
                                               }
                                           }
                                       }
                                   }
                               });
                           }];
}

@end
