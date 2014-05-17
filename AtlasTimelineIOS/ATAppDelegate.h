//
//  ATAppDelegate.h
//  AtlasTimelineIOS
//
//  Created by Hong on 12/28/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATViewController.h"

@interface ATAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) NSString* sourceName;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ATViewController *mapViewController; //my way of share the objects, used in ATHelper
@property(strong, nonatomic) NSDateFormatter* dateFormater;
@property(strong, nonatomic) NSString* localizedAD;

//eventList is the center of performance issue, seems we need to load all events
@property(strong, nonatomic) NSMutableArray* eventListSorted;
@property(strong, nonatomic) NSMutableArray* friendList; //just put here to pass it from friendPickerView to friendAddView
@property(strong, nonatomic) NSString* episodeToBeShared;//just to pass it to FriendPickerView
@property int selectedPeriodInDays;
@property(strong, nonatomic) NSDate* focusedDate;
@property(strong, nonatomic) UIStoryboard* storyBoard;

@property NSString* optionEnableDateMagnifierMove;

-(void) emptyEventList;

@end
