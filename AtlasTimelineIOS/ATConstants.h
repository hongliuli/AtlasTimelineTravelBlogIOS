//
//  ATConstants.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATConstants : NSObject

+ (NSString*)selectedPeriodKey;
+ (NSString*)period7Day;
+ (NSString*)periodMonth;
+ (NSString*)periodYear;
+ (NSString*)period10Year;
+ (NSString*)period100Year;
+ (NSString*)period1000Year;

+ (NSString*) DefaultAnnotationIdentifier;
+ (NSString*) SelectedAnnotationIdentifier;
+ (NSString*) Past1AnnotationIdentifier;
+ (NSString*) Past2AnnotationIdentifier;
+ (NSString*) Past3AnnotationIdentifier;
+ (NSString*) Past4AnnotationIdentifier;
+ (NSString*) After1AnnotationIdentifier;
+ (NSString*) After2AnnotationIdentifier;
+ (NSString*) After3AnnotationIdentifier;
+ (NSString*) After4AnnotationIdentifier;
+ (NSString*) WhiteFlagAnnotationIdentifier;
+ (int) screenWidth;
+ (int) screenHeight;
+ (int) timeScrollNumOfDateLabels;
+ (int) timeScrollWindowWidth;
+ (int) timeScrollWindowHeight;
+ (int) timeScrollWindowX;
+ (int) timeScrollWindowY;// = 38;
+ (int) timeZoomerY;// = 18;
+ (int) sliderWidth;
+ (int) timeSliderX;
+ (int) searchBarHeight;
+ (int) searchBarWidth;
+ (BOOL) isLandscapeInPhone;

+ (int) timeScrollCellWidth;
+ (int) timeScrollCellHeight;
+ (int) photoScrollCellWidth;
+ (int) photoScrollCellHeight;
+ (int) defaultZoomLevel;
+ (int) timeScrollBigDateFont;

+ (NSString*) defaultSourceName;
+ (NSString*) UserEmailKeyName;
+ (NSString*) UserSecurityCodeKeyName;
+ (NSString*) ServerURL;
+ (NSString*) EpisodeDictionaryKeyName;

@end
