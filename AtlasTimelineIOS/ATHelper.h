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

//Date related
+ (NSString*)getYearPartSmart:(NSDate*)date;
+ (NSString*) getYearPartHelper:(NSDate*) date;
+ (NSString*) getMonthDateInLetter:(NSDate*)date;
+ (NSString*) getMonthDateInTwoNumber:(NSDate*)date;
+ (NSString*) getMonthSlashDateInNumber:(NSDate *)date;
+ (NSDate *)dateByAddingComponentsRegardingEra:(NSDateComponents *)comps toDate:(NSDate *)date options:(NSUInteger)opts;
+ (NSDate *)getYearStartDate:(NSDate*)date;
+ (NSString*) get10YearForTimeLink:(NSDate*) date;
+ (NSString*) get100YearForTimeLink:(NSDate*) date;
+ (NSString*) getYearMonthForTimeLink:(NSDate*) date;
+ (NSDate *)getMonthStartDate:(NSDate*)date;

+ (Boolean)checkUserEmailAndSecurityCode:(UIViewController*)sender;
+ (void) closeCreateUserPopover;
+ (UIColor *)darkerColorForColor:(UIColor *)c;
+ (BOOL)isBCDate:(NSDate*)date;
+ (NSDictionary*) getScaleStartEndDate:(NSDate*)focusedDate;

//File and document path related
+ (NSString*) getSelectedDbFileName;
+ (void) setSelectedDbFileName:(NSString*)fileName;
+ (void) createPhotoDocumentoryPath;
+ (NSString*) getRootDocumentoryPath;
+ (NSString*)getRootBundlePath;
+ (NSString*)getPhotoDocummentoryPath;
+ (NSString*)getNewUnsavedEventPhotoPath;
+ (BOOL) isAtLeastIOS8;

//photo related
+ (UIImage*)imageResizeWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
+ (UIImage*)readPhotoFromFile:(NSString*)photoFileName eventId:photoDir;
+ (UIImage*)readPhotoThumbFromFile:(NSString*)eventId thumbUrl:(NSString*)thumbUrl;
+ (NSString*) getPhotoNameFromDescForWorldHeritage:descText;

//misc
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert;
+ (NSString*) getMarkerNameFromDescText: (NSString*)descTxt;
+ (NSString*) clearMakerFromDescText: (NSString*)desc :(NSString*)markerName;
+ (NSString*) clearMakerAllFromDescText: (NSString*)desc;
+ (NSArray*) getEventListWithUniqueIds: (NSArray*)uniqueIds;
+ (NSString*) httpGetFromServer:(NSString*)serverUrl;
+ (NSString*) httpGetFromServer:(NSString*)serverUrl :(BOOL)alertError;
+ (void)startReplaceDb:(NSString*)selectedAtlasName :(NSArray*)downloadedJsonArray :(UIActivityIndicatorView*)spinner;
+ (NSString*) getBlogUrlFromEventDesc:(NSString*) descText;
+ (NSString*) getBlogThumbUrlFromEventDesc:(NSString*) descText;
+ (NSString*) getBlogDescFromEventDesc:(NSString*) descText;

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
