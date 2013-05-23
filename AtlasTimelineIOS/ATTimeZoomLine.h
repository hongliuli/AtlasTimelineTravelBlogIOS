//
//  ATTimeZoomLine.h
//  AtlasTimelineIOS
//
//  Created by Hong on 2/12/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATTimeZoomLine : UIView

@property float scaleLenForDisplay;

- (void)changeScaleText:(NSString*)text;
- (void)changeScaleLabelsDateFormat:(NSDate*)startDay :(NSDate*)endDay;
- (void)changeTimeScaleState:(NSDate*)startDate :(NSDate*)endDate :(int)periodIndays :(NSDate*)focusedDate;

@end
