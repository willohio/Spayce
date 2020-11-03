//
//  Singleton.h
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#ifndef SINGLETON_GCD
#define SINGLETON_GCD(classname)                            \
+ (classname *) sharedInstance                              \
{                                                           \
    static classname * instance = nil;                      \
    if(instance == nil)                                     \
    {                                                       \
        instance = [[classname alloc] init];                \
    }                                                       \
    return instance;                                        \
}                                                           \

#endif
