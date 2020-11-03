//
//  SPCMessageManager.h
//  Spayce
//
//  Created by Christopher Taylor on 3/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Enums.h"

@interface SPCMessageManager : NSObject

@property (nonatomic, assign) NSInteger unreadThreadCount;

+ (SPCMessageManager *)sharedInstance;

-(void)getInitalUnreadCount;
-(void)updateThreadsAfterPNS;

-(void)getMessageThreadsWithCompletionHandler:(void (^)(NSArray *threadsArray))completionHandler
                                 errorHandler:(void (^)(NSError *error))errorHandler;


-(void)sendMessage:(NSString *)messageString
          toThread:(NSString *)threadKeyStr
withCompletionHandler:(void (^)(BOOL *success))completionHandler
      errorHandler:(void (^)(NSError *error))errorHandler;

-(void)sendMessage:(NSString *)messageString
      toRecipients:(NSString *)recipientsKeyStr
withCompletionHandler:(void (^)(NSString *msgKeyStr, NSString *threadKeyStr))completionHandler
      errorHandler:(void (^)(NSError *error))errorHandler;

-(void)getMessagesBefore:(NSTimeInterval)nowMS
               threadKey:(NSString *)threadKey
   withCompletionHandler:(void (^)(NSArray *messages,NSString *pagingKeyStr))completionHandler
            errorHandler:(void (^)(NSError *error))errorHandler;

-(void)getMessagesSince:(NSTimeInterval)sinceMS
               threadKey:(NSString *)threadKey
   withCompletionHandler:(void (^)(NSArray *messages))completionHandler
            errorHandler:(void (^)(NSError *error))errorHandler;

-(void)getMessagesWithPageKey:(NSString *)pageKey
                    threadKey:(NSString *)threadKey
        withCompletionHandler:(void (^)(NSArray *messages, NSString *pagingKeyStr))completionHandler
                 errorHandler:(void (^)(NSError *error))errorHandler;

-(void)getThreadForUser:(NSString *)userToken
  withCompletionHandler:(void (^)(NSString *threadKeyStr))completionHandler
           errorHandler:(void (^)(NSError *error))errorHandler;

-(void)markAllThreadsRead:(NSTimeInterval)beforeMS;

-(void)deleteThread:(NSString *)threadKeyStr
         beforeDate:(NSTimeInterval)nowMS
withCompletionHandler:(void (^)(BOOL success))completionHandler
       errorHandler:(void (^)(NSError *error))errorHandler;

-(void)muteThread:(NSString *)threadKeyStr
withCompletionHandler:(void (^)(BOOL success))completionHandler
     errorHandler:(void (^)(NSError *error))errorHandler;

-(void)unmuteThread:(NSString *)threadKeyStr
withCompletionHandler:(void (^)(BOOL success))completionHandler
       errorHandler:(void (^)(NSError *error))errorHandler;

@end
