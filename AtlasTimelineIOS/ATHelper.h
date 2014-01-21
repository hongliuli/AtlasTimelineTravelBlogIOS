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
+ (Boolean)checkUserEmailAndSecurityCode:(UIViewController*)sender;
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
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert;
@end
