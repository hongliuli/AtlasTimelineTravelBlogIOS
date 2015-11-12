//
//  ADMapPointAnnotation.m
//  ClusterDemo
//
//  Created by Patrick Nollet on 11/10/12.
//  Copyright (c) 2012 Applidium. All rights reserved.
//

#import "ADMapPointAnnotation.h"

@implementation ADMapPointAnnotation

- (id)initWithAnnotation:(id<MKAnnotation>)annotation {
    self = [super init];
    if (self) {
        @try{
        _mapPoint = MKMapPointForCoordinate(annotation.coordinate);
        _annotation = annotation;
        }
        @catch (NSException* e)
        {
            NSLog(@" ############ catch exception");
        }
    }
    return self;
}

@end
