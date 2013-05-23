//
//  ATEventDataStruct.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/19/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATEventDataStruct.h"

@implementation ATEventDataStruct

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    ATEventDataStruct* tmp = (ATEventDataStruct*)other;
    return [self.uniqueId isEqualToString:tmp.uniqueId];
}

@end
