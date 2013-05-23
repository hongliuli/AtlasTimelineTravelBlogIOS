//
//  ATPreferenceEntity.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/23/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ATPreferenceEntity : NSManagedObject

@property (nonatomic, retain) NSString * preferenceName;
@property (nonatomic, retain) NSString * preferenceValue;

@end
