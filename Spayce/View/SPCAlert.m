//
//  SPCAlert.m
//  Spayce
//
//  Created by Pavel Dusatko on 7/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAlert.h"

@interface SPCAlert ()

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSError *error;

@end

@implementation SPCAlert

#pragma mark - Initialization

- (instancetype)initWithTitle:(NSString *)title error:(NSError *)error {
    self = [super init];
    if (self) {
        _title = title;
        _error = error;
    }
    return self;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[SPCAlert class]]) {
        return NO;
    }
    return [self isEqualToAlert:(SPCAlert *)object];
}

- (BOOL)isEqualToAlert:(SPCAlert *)alert {
    if (!alert) {
        return NO;
    }
    
    BOOL haveEqualTitles = (!self.title && !alert.title) || [self.title isEqual:alert.title];
    BOOL haveEqualErrors = (!self.error && !alert.error) || [self.error isEqual:alert.error];
    
    return haveEqualTitles && haveEqualErrors;
}

- (NSUInteger)hash {
    return [self.title hash] ^ [self.error hash];
}

@end
