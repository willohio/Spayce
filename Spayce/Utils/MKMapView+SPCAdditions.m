//
//  MKMapView+SPCAdditions.m
//  Spayce
//
//  Created by William Santiago on 4/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "MKMapView+SPCAdditions.h"

@implementation MKMapView (SPCAdditions)

- (void)spc_hideCalloutsAnimated:(BOOL)animated {
    [self.selectedAnnotations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self deselectAnnotation:obj animated:animated];
    }];
}

@end
