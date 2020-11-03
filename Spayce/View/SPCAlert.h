//
//  SPCAlert.h
//  Spayce
//
//  Created by Pavel Dusatko on 7/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCAlert : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSError *error;

- (instancetype)initWithTitle:(NSString *)title error:(NSError *)error;

@end
