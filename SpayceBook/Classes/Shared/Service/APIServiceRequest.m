//
//  APIServiceRequest.m
//  SpayceBook
//
//  Created by Dmitry Miller on 7/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "APIServiceRequest.h"

// Utility
#import "APIService.h"
#import "APIUtils.h"
#import "CollectionUtils.h"
#import "FaultUtils.h"

@implementation APIServiceRequest

NSString * APIServiceRequestDidStartNotification = @"APIServiceRequestDidStart";
NSString * APIServiceRequestDidEndNotification   = @"APIServiceRequestDidEnd";

- (id)init
{
    self = [super init];

    if (self != nil)
    {
        initiated = NO;
        self.timeoutInterval = 40;
    }

    return self;
}

- (NSURLRequest *)buildRequest {
    NSAssert(!initiated, @"Cannot initiate a request that is already active");
    initiated = YES;

    NSMutableString * fullUrl = [[NSMutableString alloc] initWithString:self.url];

    if (self.pathParams.count > 0)
    {
        [fullUrl appendString:@"/"];
        [fullUrl appendString:[CollectionUtils listFromCollection:self.pathParams withSeparator:@"/"]];
    }

    NSString *pathUrl = [fullUrl stringByReplacingOccurrencesOfString:[APIService baseUrl] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, fullUrl.length)];

    if (self.type == RequestTypeGet || self.type == RequestTypeDelete) //|| (self.type == RequestTypePost && nil != self.queryParams))
    {
        NSString * queryString = [APIUtils queryStringForParams:self.queryParams];

        if(queryString.length > 0)
        {
            [fullUrl appendString:@"?"];
            [fullUrl appendString:queryString];
        }
    }

    //NSLog(@"Call API - %@", fullUrl);

    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:fullUrl]
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                        timeoutInterval:self.timeoutInterval];

    if (self.type == RequestTypeGet)
    {
        req.HTTPMethod = @"GET";
    }
    else if (self.type == RequestTypePost)
    {
        req.HTTPMethod = @"POST";
    }
    else if (self.type == RequestTypePut)
    {
        req.HTTPMethod = @"PUT";
    }
    else if (self.type == RequestTypeDelete)
    {
        req.HTTPMethod = @"DELETE";
    }

    if (self.type != RequestTypeGet)
    {
        NSString *queryStr = [APIUtils queryStringForParams:self.queryParams];
        req.HTTPBody = [queryStr dataUsingEncoding:NSUTF8StringEncoding];
    }

    [req addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (!self.foreignAPI) {
        [req addValue:[APIService getXAuthHeader:pathUrl] forHTTPHeaderField:HEADER_AUTH_KEY];
        [req addValue:[APIService getXDeviceHeader] forHTTPHeaderField:HEADER_DEVICE_KEY];
    }

    return req;
}

- (void)start:(NSOperationQueue *)operationQueue
{
    NSURLRequest *req = [self buildRequest];

    [[NSNotificationCenter defaultCenter] postNotificationName:APIServiceRequestDidStartNotification object:self];

    __weak typeof(self)weakSelf = self;

    [NSURLConnection sendAsynchronousRequest:req
                                       queue:operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *fault)
                                {
                                    [[NSNotificationCenter defaultCenter] postNotificationName:APIServiceRequestDidEndNotification object:self];

                                    __strong typeof(weakSelf)strongSelf = weakSelf;
                                    if (!strongSelf) {
                                        return;
                                    }

                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if(fault != nil)
                                        {
                                            if (strongSelf.faultCallback) {
                                                strongSelf.faultCallback(fault);
                                            }
                                        }
                                        else if (data != nil)
                                        {
                                            NSError *parseError = nil;

                                            NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                                                           options:kNilOptions
                                                                                                             error:&parseError];

                                            if (parseError != nil)
                                            {
                                                if (strongSelf.faultCallback) {
                                                    strongSelf.faultCallback(parseError);
                                                }
                                            }
                                            else
                                            {
                                                NSNumber *errorCode = [parsedResponse isKindOfClass:[NSDictionary class]] ? parsedResponse[@"errorCode"] : @(0);
                                                NSString *description = parsedResponse[@"description"];
                                                
                                                if ([errorCode intValue] != 0)
                                                {
                                                    if (strongSelf.faultCallback) {
                                                        if (description && ![description isEqualToString:@""]) {
                                                            strongSelf.faultCallback([FaultUtils generalErrorWithCode:errorCode title:nil description:description]);
                                                        } else {
                                                            strongSelf.faultCallback([FaultUtils generalErrorWithCode:errorCode]);
                                                        }
                                                    }
                                                }
                                                else
                                                {
                                                    NSObject *value = [parsedResponse isKindOfClass:[NSDictionary class]] ? parsedResponse[@"content"] : nil;
                                                    
                                                    if (strongSelf.resultCallback) {
                                                        strongSelf.resultCallback(value != nil ? value : parsedResponse);
                                                    }
                                                }
                                            }
                                        }
                                    });
                                }
     ];
}

@end
