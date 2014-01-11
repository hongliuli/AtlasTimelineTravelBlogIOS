//
//  ATTimeZoomLine.h
//  AtlasTimelineIOS
//
//  Created by Hong on 2/12/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATViewController.h"

@interface ATTimeZoomLine : UIView

@property ATViewController* mapViewController;
@property float scaleLenForDisplay;

- (void)changeScaleText:(NSString*)text; //called in mapview controller
- (void)changeDateText:(NSString*)yearText :(NSString*)monthText; //called in timeWindowNew
- (void)showHideScaleText:(BOOL)showFlag; //called in scroll window when start scroll and stop scroll
- (void)showHideInAnimation;
- (void)changeScaleLabelsDateFormat:(NSDate*)startDay :(NSDate*)endDay;
- (void)changeTimeScaleState:(NSDate*)startDate :(NSDate*)endDate :(int)periodIndays :(NSDate*)focusedDate;
- (void) hideMagnifier;

@end
