//
//  ATEventEntity.h
//  AtlasTimelineIOS
//
//  Created by Hong on 2/13/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ATEventEntity : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSDate * eventDate;
@property (nonatomic, retain) NSString * eventDesc;
@property (nonatomic, retain) NSNumber * eventType;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lng;
@property (nonatomic, retain) NSString * uniqueId;
@property (nonatomic, retain) NSNumber * iconType;

@end
