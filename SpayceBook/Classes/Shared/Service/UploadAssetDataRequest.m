//
//  UploadAssetDataRequest.m
//  SpayceBook
//
//  Created by Dmitry Miller on 7/7/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "UploadAssetDataRequest.h"
#import "APIUtils.h"
#import "FaultUtils.h"
#import "APIService.h"

NSString * UploadAssetDataRequestDidStartNotification = @"UploadDataAssetDidStart";
NSString * UploadAssetDataRequestDidEndNotification   = @"UploadDataAssetDidEnd";

const NSInteger totalMilliSeconds = 4000;

@interface UploadAssetDataRequest () <NSURLConnectionDelegate>
{
    NSTimer *_progressTimer;
    NSTimeInterval _startTime;
}
- (NSURLRequest *)buildRequest;
@end

@implementation UploadAssetDataRequest

- (NSURLRequest *)buildRequest {
    NSAssert(!initiated, @"Cannot initiate a request that is already active");
    initiated = YES;
    _startTime = [[NSDate date] timeIntervalSince1970];

    NSMutableString *actualUrl = [[NSMutableString alloc] initWithString:self.url];

    NSString *pathUrl = [self.url stringByReplacingOccurrencesOfString:[APIService baseUrl] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.url.length)];

    if (self.queryParams.count > 0)
    {
        [actualUrl appendString:@"?"];
        [actualUrl appendString:[APIUtils queryStringForParams:self.queryParams]];
    }

    NSLog(@"Call API - %@", actualUrl);

    // create the connection
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:actualUrl]
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:100];

    [postRequest addValue:[APIService getXAuthHeader:pathUrl] forHTTPHeaderField:HEADER_AUTH_KEY];
    [postRequest addValue:[APIService getXDeviceHeader] forHTTPHeaderField:HEADER_DEVICE_KEY];

    // change type to POST (default is GET)
    [postRequest setHTTPMethod:@"POST"];

    // just some random text that will never occur in the body
    NSString *stringBoundary = @"----------------------------d36c6e86e0f0";

    // header value, user session ID added
    NSString *headerBoundary = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];

    // set header
    [postRequest addValue:headerBoundary forHTTPHeaderField:@"Content-Type"];

    if (self.data != nil)
    {
        // create data
        NSMutableData *postBody = [NSMutableData data];

        // media part
        [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[NSData dataWithData:self.data]];
        //[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

        // final boundary
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

        // add body to post
        [postRequest setHTTPBody:postBody];
    }

    return postRequest;
}

- (NSURLRequest *)buildVideoRequest {
    NSAssert(!initiated, @"Cannot initiate a request that is already active");
    initiated = YES;
    _startTime = [[NSDate date] timeIntervalSince1970];
    
    NSMutableString *actualUrl = [[NSMutableString alloc] initWithString:self.url];
    
    NSString *pathUrl = [self.url stringByReplacingOccurrencesOfString:[APIService baseUrl] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.url.length)];
    
    if (self.queryParams.count > 0)
    {
        [actualUrl appendString:@"?"];
        [actualUrl appendString:[APIUtils queryStringForParams:self.queryParams]];
    }
    
    NSLog(@"Call API - %@", actualUrl);
    
    // create the connection
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:actualUrl]
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:100];
    
    [postRequest addValue:[APIService getXAuthHeader:pathUrl] forHTTPHeaderField:HEADER_AUTH_KEY];
    [postRequest addValue:[APIService getXDeviceHeader] forHTTPHeaderField:HEADER_DEVICE_KEY];
    
    // change type to POST (default is GET)
    [postRequest setHTTPMethod:@"POST"];
    
    // just some random text that will never occur in the body
    NSString *stringBoundary = @"----------------------------d36c6e86e0f0";
    
    // header value, user session ID added
    NSString *headerBoundary = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
    
    // set header
    [postRequest addValue:headerBoundary forHTTPHeaderField:@"Content-Type"];
    
    if (self.data != nil)
    {
        // create data
        NSMutableData *postBody = [NSMutableData data];
        
        // media part
        [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"vid.mp4\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[NSData dataWithData:self.data]];
        //[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        // final boundary
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        // add body to post
        [postRequest setHTTPBody:postBody];
    }
    
    return postRequest;
}

- (NSURLRequest *)buildAudioRequest {
    NSAssert(!initiated, @"Cannot initiate a request that is already active");
    initiated = YES;
    _startTime = [[NSDate date] timeIntervalSince1970];
    
    NSMutableString *actualUrl = [[NSMutableString alloc] initWithString:self.url];
    
    NSString *pathUrl = [self.url stringByReplacingOccurrencesOfString:[APIService baseUrl] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.url.length)];
    
    if (self.queryParams.count > 0)
    {
        [actualUrl appendString:@"?"];
        [actualUrl appendString:[APIUtils queryStringForParams:self.queryParams]];
    }
    
    NSLog(@"Call API - %@", actualUrl);
    
    // create the connection
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:actualUrl]
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:100];
    
    [postRequest addValue:[APIService getXAuthHeader:pathUrl] forHTTPHeaderField:HEADER_AUTH_KEY];
    [postRequest addValue:[APIService getXDeviceHeader] forHTTPHeaderField:HEADER_DEVICE_KEY];
    
    // change type to POST (default is GET)
    [postRequest setHTTPMethod:@"POST"];
    
    // just some random text that will never occur in the body
    NSString *stringBoundary = @"----------------------------d36c6e86e0f0";
    
    // header value, user session ID added
    NSString *headerBoundary = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
    
    // set header
    [postRequest addValue:headerBoundary forHTTPHeaderField:@"Content-Type"];
    
    if (self.data != nil)
    {
        // create data
        NSMutableData *postBody = [NSMutableData data];
        
        // media part
        [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"sound.mp4\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[NSData dataWithData:self.data]];
        //[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        // final boundary
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        // add body to post
        [postRequest setHTTPBody:postBody];
    }
    
    return postRequest;
}

- (void)start:(NSOperationQueue *)operationQueue
{
    NSURLRequest *postRequest = [self buildRequest];

    [[NSNotificationCenter defaultCenter] postNotificationName:UploadAssetDataRequestDidStartNotification object:self];

    responseData = [[NSMutableData alloc] init];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:postRequest delegate:self startImmediately:NO];
    [conn start];

    _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
}

- (void)startVideo:(NSOperationQueue *)operationQueue
{
    NSLog(@"start video!");
    NSURLRequest *postRequest = [self buildVideoRequest];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UploadAssetDataRequestDidStartNotification object:self];
    
    responseData = [[NSMutableData alloc] init];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:postRequest delegate:self startImmediately:NO];
    [conn start];
    
    _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
}

- (void)startAudio:(NSOperationQueue *)operationQueue
{
    NSLog(@"start audio!");
    NSURLRequest *postRequest = [self buildAudioRequest];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UploadAssetDataRequestDidStartNotification object:self];
    
    responseData = [[NSMutableData alloc] init];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:postRequest delegate:self startImmediately:NO];
    [conn start];
    
    _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
}

- (void)updateProgress:(NSTimer *)timer
{
    if (self.progressCallback != nil)
    {
        NSInteger completedMilliSeconds = (int)(([[NSDate date] timeIntervalSince1970] - _startTime) * 1000.0f);
        
        // If we ran out of time start the progress bar over
        if (completedMilliSeconds >= totalMilliSeconds) {
            _startTime = [[NSDate date] timeIntervalSince1970];
        }
        
        if (self.progressCallback) {
            self.progressCallback(completedMilliSeconds, totalMilliSeconds);
        }
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)urlConnection didReceiveData:(NSData *)partialResponseData
{
    [responseData appendData:partialResponseData];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[NSNotificationCenter defaultCenter] postNotificationName:UploadAssetDataRequestDidEndNotification object:self];

    __unsafe_unretained UploadAssetDataRequest *thisObject = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            [_progressTimer invalidate];
            _progressTimer = nil;
            
            NSError *parseError = nil;
            
            //                NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSNonLossyASCIIStringEncoding];
            //                NSLog(@"%@", responseString);
            
            NSDictionary * parsedResponse = [NSJSONSerialization JSONObjectWithData:responseData
                                                                            options:kNilOptions
                                                                              error:&parseError];
            
            if (parseError != nil) {
                if (thisObject.faultCallback) {
                    thisObject.faultCallback(parseError);
                }
            }
            else {
                NSNumber *errorCode = [parsedResponse isKindOfClass:[NSDictionary class]] ? parsedResponse[@"errorCode"] : @(0);
                
                if ([errorCode intValue] != 0) {
                    if (thisObject.faultCallback) {
                        thisObject.faultCallback([FaultUtils generalErrorWithCode:errorCode title:nil description:parsedResponse[@"description"]]);
                    }
                }
                else {
                    NSObject * value = parsedResponse[@"content"];
                    
                    if (thisObject.resultCallback) {
                        thisObject.resultCallback(value);
                    }
                }
            }
        }
        @catch (NSException *exception) {
            if (thisObject.faultCallback) {
                thisObject.faultCallback(nil);
            }
        }
        @finally {
            if (thisObject.progressCallback) {
                thisObject.progressCallback(totalMilliSeconds, totalMilliSeconds);
            }
        }
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:UploadAssetDataRequestDidEndNotification object:self];

    if (self.faultCallback) {
        self.faultCallback(error);
    }

    [_progressTimer invalidate];
    _progressTimer = nil;

    if (self.progressCallback) {
        self.progressCallback(totalMilliSeconds, totalMilliSeconds);
    }
}

@end
