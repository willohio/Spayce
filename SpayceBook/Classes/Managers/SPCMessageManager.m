//
//  SPCMessageManager.m
//  Spayce
//
//  Created by Christopher Taylor on 3/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMessageManager.h"

// Singleton
#import "Singleton.h"

// Service
#import "APIService.h"

//Model
#import "SPCMessageThread.h"
#import "SPCMessage.h"


@implementation SPCMessageManager

SINGLETON_GCD(SPCMessageManager);


- (void)dealloc {
    //Do stuff?
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    self = [super init];
    if (self) {
        //add observers?
        self.unreadThreadCount = 0;
        [self getInitalUnreadCount];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCount:) name:@"updateUnreadThreadCount" object:nil];
    }
    
    return self;
}




-(void)getInitalUnreadCount {
    
        [self getMessageThreadsWithCompletionHandler:^(NSArray *threadsArray){
            //NSLog(@"threadsArray %@",threadsArray);
     
            NSUInteger newUnreadCount = 0;
            
            for (int i = 0; i < threadsArray.count; i++) {
                SPCMessageThread *thread = threadsArray[i];
                if (thread.hasUnreadMessages) {
                    newUnreadCount++;
                }
            }
            self.unreadThreadCount = newUnreadCount;
        }
                                                     errorHandler:^(NSError *fault){
                                                         NSLog(@"fault %@",fault);
                                                     }];
        
    
}

-(void)updateThreadsAfterPNS {
    
    [self getMessageThreadsWithCompletionHandler:^(NSArray *threadsArray){
 
        NSUInteger newUnreadCount = 0;
        
        for (int i = 0; i < threadsArray.count; i++) {
            SPCMessageThread *thread = threadsArray[i];
            if (thread.hasUnreadMessages) {
                newUnreadCount++;
            }
        }
        
        self.unreadThreadCount = newUnreadCount;

        //Make sure to update the display in our VCs too
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pollForThreadUpdates" object:nil];
    }
                                    errorHandler:^(NSError *fault){
                                        NSLog(@"fault %@",fault);
                                    }];

}


-(void)updateCount:(NSNotification *)notification {
    NSString *unreadString = (NSString *)[notification object];
    NSUInteger newUnreadCount = [unreadString integerValue];
    self.unreadThreadCount = newUnreadCount;
}

-(void)getMessageThreadsWithCompletionHandler:(void (^)(NSArray *threadsArray))completionHandler
                                 errorHandler:(void (^)(NSError *error))errorHandler {
    
            NSString *url = @"/chat/getThreads";
            
            [APIService makeApiCallWithMethodUrl:url
                                  andRequestType:RequestTypeGet
                                   andPathParams:nil
                                  andQueryParams:nil
                                  resultCallback:^(NSObject * result) {
                                      //NSLog(@"url:%@ result:%@",url,result);
                                      
                                      NSDictionary *JSON = (NSDictionary *)result;
                                      
                                      NSArray *threads = JSON[@"threads"];
                                      NSMutableArray *mutableThreads = [NSMutableArray arrayWithCapacity:threads.count];
                                      
                                      for (NSDictionary *attributes in threads) {
                                          SPCMessageThread *thread = [[SPCMessageThread alloc] initWithAttributes:attributes];
                                          [mutableThreads addObject:thread];
                                      }
                                      
                                      NSArray *threadsArray = [NSArray arrayWithArray:mutableThreads];
                                      
                                      if (completionHandler) {
                                          completionHandler(threadsArray);
                                      }
                                  }
                                   faultCallback:^(NSError *fault) {
                                       if (fault) {
                                           //NSLog(@"url:%@ fault:%@",url,fault);
                                       }
                                   }];
}

-(void)sendMessage:(NSString *)messageString
          toThread:(NSString *)threadKeyStr
withCompletionHandler:(void (^)(BOOL *success))completionHandler
  errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSString *url = [NSString stringWithFormat:@"/chat/sendMessage"];
    
    NSLog(@"%@ recipients thread key %@",url,threadKeyStr);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              //NSLog(@"url:%@ result:%@",url,result);
                              
                              
                          }
                           faultCallback:^(NSError *fault) {
                               //NSLog(@"url:%@ fault:%@",url,fault);
                               if (errorHandler) {
                                   errorHandler(fault);
                               }
                          }];
    
}


-(void)sendMessage:(NSString *)messageString
      toRecipients:(NSString *)recipientsKeyStr
withCompletionHandler:(void (^)(NSString *msgKeyStr,NSString *threadKeyStr))completionHandler
      errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSLog(@"send message!");
    
    NSString *url = [NSString stringWithFormat:@"/chat/sendMessage"];
    
    NSLog(@"%@ recipients key %@",url,recipientsKeyStr);
    
    NSDictionary *params = @{ @"recipientKeys": recipientsKeyStr,
                              @"text": messageString
                              };
   
    NSLog(@"params %@",params);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              //NSLog(@"url:%@ params%@ result:%@",url,params,result);
                              
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              NSString *msgKey = [resultsDict objectForKey:@"messageKey"];
                              NSString *threadKey = [resultsDict objectForKey:@"threadKey"];
                              
                              if (completionHandler && msgKey.length > 0) {
                                  completionHandler(msgKey,threadKey);
                              }
                          }
                           faultCallback:^(NSError *fault) {
                                //NSLog(@"url:%@ params %@ fault:%@",url,params,fault);
                               if (errorHandler) {
                                   errorHandler(fault);
                               }
                           }];
}


-(void)getMessagesBefore:(NSTimeInterval)nowMS
               threadKey:(NSString *)threadKey
   withCompletionHandler:(void (^)(NSArray *messages, NSString *pagingKeyStr))completionHandler
      errorHandler:(void (^)(NSError *error))errorHandler {
        
    NSString *url = [NSString stringWithFormat:@"/chat/getThreadContentBefore"];
    
    NSNumber *nowNum = [NSNumber numberWithLongLong:nowMS];
    
    NSDictionary *params = @{ @"beforeDate": nowNum,
                              @"threadKey" : threadKey
                              };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              //NSLog(@"url:%@ params%@ result:%@",url,params,result);
                              NSDictionary *resultDict = (NSDictionary *)result;
                              
                              NSString *pagingKeyStr = @"";

                              //get our paging key if it exist
                              if ([resultDict objectForKey:@"nextPageKey"]) {
                                  pagingKeyStr = [resultDict objectForKey:@"nextPageKey"];
                              }

                              //get our messages
                              NSArray *msgsArray = [resultDict objectForKey:@"messages"];
                              NSMutableArray *messages = [[NSMutableArray alloc] init];
                              
                              for (int i = 0; i < msgsArray.count; i ++) {
                                  NSDictionary *attributes = msgsArray[i];
                                  SPCMessage *message = [[SPCMessage alloc] initWithAttributes:attributes];
                                  [messages addObject:message];
                              }
                              
                              NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:YES];
                              NSArray *descriptors = @[descriptor];
                              NSArray *sortedMsgs = [messages sortedArrayUsingDescriptors:descriptors];
                              
                              if (completionHandler) {
                                  completionHandler(sortedMsgs,pagingKeyStr);
                              }
                          }
                           faultCallback:^(NSError *fault) {
                               //NSLog(@"url:%@ params %@ fault:%@",url,params,fault);
                               if (errorHandler) {
                                   errorHandler(fault);
                               }
                           }];
}

-(void)getMessagesWithPageKey:(NSString *)pageKey
               threadKey:(NSString *)threadKey
   withCompletionHandler:(void (^)(NSArray *messages, NSString *pagingKeyStr))completionHandler
            errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSString *url = [NSString stringWithFormat:@"/chat/getThreadContentBefore"];

    NSDictionary *params = @{ @"pageKey": pageKey,
                              @"threadKey" : threadKey
                              };
    
    //NSLog(@"get message with page key?? %@",pageKey);
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              //NSLog(@"url:%@ params%@ result:%@",url,params,result);
                              NSDictionary *resultDict = (NSDictionary *)result;
                              
                              NSString *pagingKeyStr = @"";
                              
                              //get our paging key if it exist
                              if ([resultDict objectForKey:@"nextPageKey"]) {
                                  pagingKeyStr = [resultDict objectForKey:@"nextPageKey"];
                              }
                              
                              //get our messages
                              NSArray *msgsArray = [resultDict objectForKey:@"messages"];
                              NSMutableArray *messages = [[NSMutableArray alloc] init];
                              
                              for (int i = 0; i < msgsArray.count; i ++) {
                                  NSDictionary *attributes = msgsArray[i];
                                  SPCMessage *message = [[SPCMessage alloc] initWithAttributes:attributes];
                                  [messages addObject:message];
                              }
                              
                              NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:YES];
                              NSArray *descriptors = @[descriptor];
                              NSArray *sortedMsgs = [messages sortedArrayUsingDescriptors:descriptors];
                              
                              if (completionHandler) {
                                  completionHandler(sortedMsgs,pagingKeyStr);
                              }
                          }
                           faultCallback:^(NSError *fault) {
                               //NSLog(@"url:%@ params %@ fault:%@",url,params,fault);
                               if (errorHandler) {
                                   errorHandler(fault);
                               }
                           }];
}


-(void)getMessagesSince:(NSTimeInterval)sinceMS
               threadKey:(NSString *)threadKey
   withCompletionHandler:(void (^)(NSArray *messages))completionHandler
            errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSString *url = [NSString stringWithFormat:@"/chat/getThreadContentSince"];
    
    NSNumber *sinceNum = [NSNumber numberWithLongLong:sinceMS];
    
    NSDictionary *params = @{ @"sinceDate": sinceNum ,
                              @"threadKey" : threadKey
                              };
    
    //NSLog(@"/chat/getThreadContentSince for thread: %@",threadKey);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              //NSLog(@"\nurl:%@ \nparams%@ \nresult:%@",url,params,result);
                              
                              NSDictionary *resultDict = (NSDictionary *)result;
                              NSArray *msgsArray = [resultDict objectForKey:@"messages"];
                              NSMutableArray *messages = [[NSMutableArray alloc] init];
                              
                              for (int i = 0; i < msgsArray.count; i ++) {
                                  NSDictionary *attributes = msgsArray[i];
                                  SPCMessage *message = [[SPCMessage alloc] initWithAttributes:attributes];
                                  NSLog(@"create a newly received message!!");
                                  [messages addObject:message];
                              }
                              
                              if (completionHandler) {
                                  completionHandler(messages);
                              }
                          }
                           faultCallback:^(NSError *fault) {
                               //NSLog(@"url:%@ params %@ fault:%@",url,params,fault);
                               if (errorHandler) {
                                   errorHandler(fault);
                               }
                           }];
}

-(void)getThreadForUser:(NSString *)userToken
  withCompletionHandler:(void (^)(NSString *threadKeyStr))completionHandler
           errorHandler:(void (^)(NSError *error))errorHandler {

    
    NSString *url = [NSString stringWithFormat:@"/chat/getExistingThread"];
    NSDictionary *params = @{ @"recipientKeys" : userToken
                              };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                             //NSLog(@"url:%@ params%@ result:%@",url,params,result);
                              NSDictionary *resultDict = (NSDictionary *)result;
                              NSString *threadKeySting =  [resultDict objectForKey:@"threadKey"];
                              
                              if (completionHandler && threadKeySting.length > 0) {
                                  completionHandler(threadKeySting);
                              }
                          }
                           faultCallback:^(NSError *fault) {
                               //NSLog(@"url:%@ params %@ fault:%@",url,params,fault);
                               if (errorHandler) {
                                   errorHandler(fault);
                               }
                           }];
    
}

-(void)markAllThreadsRead:(NSTimeInterval)beforeMS {
    
    NSString *url = [NSString stringWithFormat:@"/chat/markAllAsRead"];
    
    NSNumber *beforeNum = [NSNumber numberWithLongLong:beforeMS];
    NSDictionary *params = @{ @"beforeDate": beforeNum
                              };
    
    NSLog(@"markAllThreadsRead??");
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              //NSLog(@"url:%@ params%@ result:%@",url,params,result);
                               //update locally
                              
                              NSString *unreadStr = [NSString stringWithFormat:@"0"];
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUnreadThreadCount" object:unreadStr];
                            
                       
                          }
                           faultCallback:^(NSError *fault) {
                               //NSLog(@"url:%@ params %@ fault:%@",url,params,fault);
                          
                           }];

}

-(void)deleteThread:(NSString *)threadKeyStr
         beforeDate:(NSTimeInterval)beforeMS
withCompletionHandler:(void (^)(BOOL success))completionHandler
       errorHandler:(void (^)(NSError *error))errorHandler {
 
    
    NSString *url = [NSString stringWithFormat:@"/chat/markThreadContentAsDeleted"];
    
    NSNumber *beforeNum = [NSNumber numberWithLongLong:beforeMS];
    
    NSDictionary *params = @{ @"beforeDate": beforeNum ,
                              @"threadKey" : threadKeyStr
                              };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                            //NSLog(@"url:%@ params%@ result:%@",url,params,result);
                          }
                           faultCallback:^(NSError *fault) {
                           }];
}


-(void)muteThread:(NSString *)threadKeyStr
withCompletionHandler:(void (^)(BOOL success))completionHandler
     errorHandler:(void (^)(NSError *error))errorHandler {
    
    
    NSString *url = [NSString stringWithFormat:@"/chat/muteThread"];
    NSDictionary *params = @{ @"threadKey" : threadKeyStr
                              };
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSLog(@"url:%@ params%@ result:%@",url,params,result);
                              
                              if (completionHandler) {
                                  completionHandler(YES);
                              }
                          }
                           faultCallback:^(NSError *fault) {
                           }];
}

-(void)unmuteThread:(NSString *)threadKeyStr
withCompletionHandler:(void (^)(BOOL success))completionHandler
     errorHandler:(void (^)(NSError *error))errorHandler {
    
    
    NSString *url = [NSString stringWithFormat:@"/chat/unmuteThread"];
    NSDictionary *params = @{ @"threadKey" : threadKeyStr
                              };
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSLog(@"url:%@ params%@ result:%@",url,params,result);
                              
                              if (completionHandler) {
                                  completionHandler(YES);
                              }
                          }
                           faultCallback:^(NSError *fault) {
                           }];
}

@end
