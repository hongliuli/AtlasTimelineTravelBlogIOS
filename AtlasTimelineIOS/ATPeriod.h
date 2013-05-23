//
//  ATPeriods.h
//  AtlasTimelineIOS
//
//  Created by Hong on 12/29/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATPeriod : NSObject

@property (nonatomic, strong) NSString *periodName;  //year for now
@property (nonatomic, strong) NSArray *events;
@property int sectionIndex;

@end
