//
//  ATEvent.h
//  AtlasTimelineIOS
//
//  Created by Hong on 12/29/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATEvent : NSObject
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSDate *date;

@end
