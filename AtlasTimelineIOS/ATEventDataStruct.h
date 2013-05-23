//
//  ATEventDataStruct.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/19/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATEventDataStruct : NSObject

@property (nonatomic, retain) NSString * uniqueId;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSDate * eventDate;
@property (nonatomic, retain) NSString * eventDesc;
@property int eventType;
@property double lat;
@property double lng;

@end
