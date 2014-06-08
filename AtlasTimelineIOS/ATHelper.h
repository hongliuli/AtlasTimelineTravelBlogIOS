//
//  ATHelper.h
//  AtlasTimelineIOS
//
//  Created by Hong on 2/6/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATHelper : NSObject
+ (BOOL)isStringNumber:(NSString*) numberStr;
+ (NSString *)applicationDocumentsDirectory;
+ (NSArray *)listFileAtPath:(NSString *)path;
+ (NSString*)getYearPartSmart:(NSDate*)date;
+ (NSString*) getYearPartHelper:(NSDate*) date;
+ (NSString*) getMonthDateInLetter:(NSDate*)date;
+ (NSString*) getMonthDateInTwoNumber:(NSDate*)date;
+ (NSString*) getMonthSlashDateInNumber:(NSDate *)date;
+ (Boolean)checkUserEmailAndSecurityCode:(UIViewController*)sender;
+ (void) closeCreateUserPopover;
+ (NSString*) getSelectedDbFileName;
+ (void) setSelectedDbFileName:(NSString*)fileName;
+ (UIColor *)darkerColorForColor:(UIColor *)c;
+ (NSDate *)dateByAddingComponentsRegardingEra:(NSDateComponents *)comps toDate:(NSDate *)date options:(NSUInteger)opts;
+ (NSDate *)getYearStartDate:(NSDate*)date;
+ (NSString*) get10YearForTimeLink:(NSDate*) date;
+ (NSString*) get100YearForTimeLink:(NSDate*) date;
+ (NSString*) getYearMonthForTimeLink:(NSDate*) date;
+ (NSDate *)getMonthStartDate:(NSDate*)date;
+ (void) createPhotoDocumentoryPath;
+ (NSString*) getRootDocumentoryPath;
+ (NSString*)getPhotoDocummentoryPath;
+ (NSString*)getNewUnsavedEventPhotoPath;
+ (UIImage*)imageResizeWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
+ (UIImage*)readPhotoFromFile:(NSString*)photoFileName eventId:photoDir;
+ (UIImage*)readPhotoThumbFromFile:(NSString*)eventId;
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert;
+ (NSString*) getMarkerNameFromDescText: (NSString*)descTxt;
+ (NSString*) clearMakerFromDescText: (NSString*)desc :(NSString*)markerName;
+ (NSString*) clearMakerAllFromDescText: (NSString*)desc;
+ (NSArray*) getEventListWithUniqueIds: (NSArray*)uniqueIds;
+ (NSString*) httpGetFromServer:(NSString*)serverUrl;
+ (void)startReplaceDb:(NSString*)selectedAtlasName :(NSArray*)downloadedJsonArray :(UIActivityIndicatorView*)spinner;
+ (BOOL)isBCDate:(NSDate*)date;

//set/get options
+ (BOOL) getOptionDateFieldKeyboardEnable;
+ (void) setOptionDateFieldKeyboardEnable:(BOOL)flag;
+ (BOOL) getOptionDisplayTimeLink;
+ (void) setOptionDisplayTimeLink:(BOOL)flag;
+ (BOOL) getOptionDateMagnifierModeScroll;
+ (void) setOptionDateMagnifierModeScroll:(BOOL)flag;
+ (BOOL) getOptionEditorFullScreen;
+ (void) setOptionEditorFullScreen:(BOOL)flag;
+ (BOOL) getOptionZoomToWeek;
+ (void) setOptionZoomToWeek:(BOOL)flag;


@end
