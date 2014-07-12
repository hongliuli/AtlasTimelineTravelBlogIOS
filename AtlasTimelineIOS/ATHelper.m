//
//  ATHelper.m
//  AtlasTimelineIOS
//
//  Created by Hong on 2/6/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATConstants.h"
#import "ATUserVerifyViewController.h"
#import "ATViewController.h"
#import "ATEventDataStruct.h"

#define NEW_NOT_SAVED_FILE_PREFIX @"NEW"
#define THUMB_WIDTH 120
#define THUMB_HEIGHT 70
#define JPEG_QUALITY 0.5
#define THUMB_JPEG_QUALITY 0.3

@implementation ATHelper

NSDateFormatter* dateFormaterForMonth;
NSDateFormatter* dateLiterFormat;
NSCalendar* calendar;


UIPopoverController *verifyViewPopover;
+ (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}
+(BOOL) isStringNumber:(NSString *)numberStr
{
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [numberStr rangeOfCharacterFromSet:notDigits].location == NSNotFound;
}
+ (NSArray *)listFileAtPath:(NSString *)path
{
    NSArray *directoryContent1 = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    NSMutableArray* directoryContent = [NSMutableArray arrayWithArray:directoryContent1];
    return directoryContent;
}

//show month/day instead if passed in date is withing same year as focused date except for focused date itself
+ (NSString*)getYearPartSmart:(NSDate*)date
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];

    NSDate* focusedDate = appDelegate.focusedDate;
    NSString* yearPart = [ATHelper getYearPartHelper:date];
    NSString* focusedYearPart = [ATHelper getYearPartHelper: focusedDate];
    //if same year, show month/day instead except for focused date itself
    if (![date isEqualToDate:focusedDate] && [yearPart isEqualToString:focusedYearPart])
    {
        yearPart =  [ATHelper getFormatedMonthDate: date];
    }
    return yearPart;
}
+ (NSString*) getYearPartHelper:(NSDate*) date
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* format = appDelegate.dateFormater;
    NSString* ADStr = appDelegate.localizedAD;
    NSString* smallDateStr = [NSString stringWithFormat:@"01/01/0010 %@", ADStr];
    NSDate* smallDate = [format dateFromString:smallDateStr];
    NSString *dateString = [NSString stringWithFormat:@" %@", [format stringFromDate:date]];

    NSString* yearPart = [dateString substringFromIndex:7];
        //NSLog(@"   --- dateString is %@  yearPart=%@", dateString,yearPart);
    if ([smallDate compare:date] == NSOrderedAscending)
        yearPart = [yearPart substringWithRange:NSMakeRange(0,4)];
    return yearPart;
}
+ (NSString*) get10YearForTimeLink:(NSDate*) date
{
    return [[ATHelper getYearPartHelper:date ] substringToIndex:3];
}
+ (NSString*) get100YearForTimeLink:(NSDate*) date
{
    return [[ATHelper getYearPartHelper:date ] substringToIndex:2];
}
+ (NSString*) getYearMonthForTimeLink:(NSDate*) date
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* format = appDelegate.dateFormater;
    NSString* ADStr = appDelegate.localizedAD;
    NSString* smallDateStr = [NSString stringWithFormat:@"01/01/0010 %@", ADStr];
    NSDate* smallDate = [format dateFromString:smallDateStr];
    NSString *dateString = [NSString stringWithFormat:@" %@", [format stringFromDate:date]];
    NSString* yearPart = [dateString substringFromIndex:[dateString length]-7];
    NSString* monthPart = [dateString substringToIndex:3];
    if ([smallDate compare:date] == NSOrderedAscending)
        yearPart = [yearPart substringWithRange:NSMakeRange(0,4)];
    return [NSString stringWithFormat:@"%@%@", monthPart, yearPart ];
}

+ (NSString*) getFormatedMonthDate: (NSDate*) date
{
    NSString *month=@"";
    if (dateFormaterForMonth == nil)
    {
        dateFormaterForMonth = [[NSDateFormatter alloc] init];
        //_dateFormater.dateStyle = NSDateFormatterMediumStyle;
        [dateFormaterForMonth setDateFormat:@"MMM d"];
        NSLog(@" month formater instanced");
    }
    month = [dateFormaterForMonth stringFromDate:date];
    return month;
}

//return Mar 23
+ (NSString*) getMonthDateInLetter:(NSDate *)date
{
    if (dateLiterFormat == nil)
    {
        dateLiterFormat=[[NSDateFormatter alloc] init];
        [dateLiterFormat setDateFormat:@"EEEE MMMM dd"];
    }
    
    
    NSString *dateLiterString=[dateLiterFormat stringFromDate:date];
    NSRange range = [dateLiterString rangeOfString:@" "];
    NSInteger idx = range.location + range.length;
    NSString* monthDateString = [dateLiterString substringFromIndex:idx];
    NSString* month3Letter = [monthDateString substringToIndex:3];
    
    range = [monthDateString rangeOfString:@" "];
    idx = range.location + range.length;
    NSString* dayString = [monthDateString substringFromIndex:idx];
    return [NSString stringWithFormat:@"%@ %@",month3Letter,dayString];
}
+ (NSString*) getMonthDateInTwoNumber:(NSDate *)date
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* format = appDelegate.dateFormater;
    NSString *dateString = [NSString stringWithFormat:@"%@", [format stringFromDate:date]];
    return [dateString substringToIndex:2];
}
+ (NSString*) getMonthSlashDateInNumber:(NSDate *)date
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* format = appDelegate.dateFormater;
    NSString *dateString = [NSString stringWithFormat:@"%@", [format stringFromDate:date]];
    return [dateString substringToIndex:5];
}

//Check UserDefaults to see if email/securitycode is there. if there, it is surely match to server
//if not, call server to create one, send to email, and ask user get from email and save to userDefaults (verify again before save to userDefaults)
+ (Boolean)checkUserEmailAndSecurityCode: (UIViewController*)sender
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefaults objectForKey:[ATConstants UserEmailKeyName]];
    if (userEmail != nil)
        return true;
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Need your email address as ID to login when access server!",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        [self startCreateUser: sender];
        return false;
    }
}
+ (void) startCreateUser: (UIViewController*)sender
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard * storyboard = appDelegate.storyBoard;
    ATUserVerifyViewController* verifyView = [storyboard instantiateViewControllerWithIdentifier:@"user_verify_view_id"];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        verifyViewPopover = [[UIPopoverController alloc] initWithContentViewController:verifyView];
        verifyViewPopover.popoverContentSize = CGSizeMake(370,280);

            [appDelegate.mapViewController.preferencePopover dismissPopoverAnimated:true];
        UIView *mapView = appDelegate.mapViewController.mapView;
        CGRect rect = CGRectMake(mapView.frame.size.width/2, mapView.frame.size.height/2, 1, 1);
        [verifyViewPopover presentPopoverFromRect:rect inView:mapView permittedArrowDirections:0 animated:YES];
    }
    else
    {
        //IMPORTANT following will messed up flow. it did push to verifyView, but back to a weired view, so need a tech illustrated in iOS5 tutor Page 180 to have a segue from WHOLE view to another view
       //[appDelegate.mapViewController.navigationController pushViewController:verifyView animated:true];
        
        //IMPORTANT User used method in iOS5 tutor page180 (remember the seque is from WHOLE view, not from a conrol), note sender will be preference or download view
        
        
        [sender presentViewController:verifyView animated:YES completion:nil];
        
        
        //[sender performSegueWithIdentifier:@"user_verify_seque_id" sender:nil];
        
    }
}
+ (void) closeCreateUserPopover
{
    if (verifyViewPopover != nil)
        [verifyViewPopover dismissPopoverAnimated:false];
}
+ (NSDate *)getYearStartDate:(NSDate*)date
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* format = appDelegate.dateFormater;
    NSString *dateString = [NSString stringWithFormat:@" %@", [format stringFromDate:date]];
    NSString* yearPart = [dateString substringFromIndex:[dateString length]-7];
    NSString* startDateStr = [NSString stringWithFormat:@"01/01/%@",yearPart];
    return [format dateFromString:startDateStr];
}

+ (NSDate *)getMonthStartDate:(NSDate*)date
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* format = appDelegate.dateFormater;
    NSString *dateString = [NSString stringWithFormat:@"%@", [format stringFromDate:date]];
    NSString* yearPart = [dateString substringFromIndex:[dateString length]-7];
    NSString* monthPart = [dateString substringToIndex:2];
    NSString* startDateStr = [NSString stringWithFormat:@"%@/01/%@",monthPart,yearPart];
    return [format dateFromString:startDateStr];
}

//This function is from Googling, it is a magic function to scroll NSDate across BC/AD, saved me a very difficult issue, so now I can show BC/AD
+ (NSDate *)dateByAddingComponentsRegardingEra:(NSDateComponents *)comps toDate:(NSDate *)date options:(NSUInteger)opts
{
    if (calendar == nil)
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    /*** comment out because iOS7 fixed era issue
    NSDateComponents *toDateComps = [calendar components:NSEraCalendarUnit fromDate:date];
    NSDateComponents *compsCopy = [comps copy];
    NSLog(@"-- toDate=%@, era=%d", date, [toDateComps era]);
    if ([toDateComps era] == 0) //B.C. era
    {
        if ([comps year] != NSUndefinedDateComponent) [compsCopy setYear:-[comps year]];
    }
    */
    return [calendar dateByAddingComponents:comps toDate:date options:opts];
}

+ (NSString*) getSelectedDbFileName
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* source = [userDefaults objectForKey:@"SELECTED_DATA_SOURCE"];
    if (source == nil)
        source = [ATConstants defaultSourceName];
    return source;
}

+ (void) setSelectedDbFileName:(NSString *)fileName
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.sourceName = fileName;
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:fileName forKey:@"SELECTED_DATA_SOURCE"];
    [userDefaults synchronize];
    [self createPhotoDocumentoryPath];
}

//call when app start and switch download source. call everytime startup is ok even the path already exists
+ (void) createPhotoDocumentoryPath
{
    NSString* documentsDirectory = [self getPhotoDocummentoryPath];
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    [[NSFileManager defaultManager] createDirectoryAtPath:[ATHelper getNewUnsavedEventPhotoPath] withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil)
        NSLog(@"Error in createPhotoDocumentoryPath=%@, Error= %@", [ATHelper getNewUnsavedEventPhotoPath],[error localizedDescription]);
}
+ (NSString*)getRootDocumentoryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

//   http://www.iosmanual.com/tutorials/how-to-add-bundle-files-in-to-the-project-framework/
+ (NSString*)getRootBundlePath
{
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    //NSLog(@"------- mainBundle = %@, target=%@",[[NSBundle mainBundle] bundlePath],targetName);
    NSString* photoDir = [NSString stringWithFormat:@"PhotosFor%@", targetName ];
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:photoDir];
}
+ (NSString*)getPhotoDocummentoryPath
{
    //TODO save to private libray or public document should be configurable?  No I put it in private
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString* sourceName = appDelegate.sourceName;
    if (sourceName == nil)
    {  //ATHelper.getSelectedDbFileName will get for userDefault, may be expensive, so cache sourceName in appDelegate
        sourceName = [ATHelper getSelectedDbFileName];
        appDelegate.sourceName = sourceName;
    }
    if (appDelegate.authorMode)
        return [[self getRootDocumentoryPath] stringByAppendingPathComponent:sourceName];
    else
        return [self getRootBundlePath];
}

+ (NSString*)getNewUnsavedEventPhotoPath
{
    return  [[[self getRootDocumentoryPath] stringByAppendingPathComponent:@"myEvents"] stringByAppendingPathComponent:@"newPhotosTmp"];
}

+ (UIColor *)darkerColorForColor:(UIColor *)c
{
    float r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2, 0.0)
                               green:MAX(g - 0.2, 0.0)
                                blue:MAX(b - 0.2, 0.0)
                               alpha:a];
    return nil;
}

+(UIImage*)readPhotoFromFile:(NSString*)photoFileName eventId:photoDir
{
    if ([photoFileName hasPrefix: NEW_NOT_SAVED_FILE_PREFIX]) //see EventEditor doneSelectPicture: where new added photos are temparirayly saved
    {
        photoFileName = [[ATHelper getNewUnsavedEventPhotoPath] stringByAppendingPathComponent:photoFileName];
    }
    else
    {
        photoFileName = [[[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:photoDir] stringByAppendingPathComponent:photoFileName];
    }
    return [UIImage imageWithContentsOfFile:photoFileName];
    
}

+(UIImage*)readPhotoThumbFromFile:(NSString*)eventId
{
    NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:eventId];
    NSString* thumbPath = [fullPathToFile stringByAppendingPathComponent:@"thumbnail"];
    UIImage* thumnailImage = [UIImage imageWithContentsOfFile:thumbPath];
    if (thumnailImage == nil)
    {
        //If thumbnail is null, create one with the first photo if there is one
        //This part of code is to solve the issue after user migrate to a new device and copy photos from dropbox where no thumbnail image in file
        NSError *error = nil;
        NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:eventId];
        NSString* photoForThumbnail = nil;
        NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
        if (tmpFileList != nil && [tmpFileList count] > 0)
        {
            photoForThumbnail = tmpFileList[0];
        }
        
        if (photoForThumbnail != nil )
        {
            UIImage* photo = [UIImage imageWithContentsOfFile: [fullPathToFile stringByAppendingPathComponent:photoForThumbnail ]];
            thumnailImage = [ATHelper imageResizeWithImage:photo scaledToSize:CGSizeMake(THUMB_WIDTH, THUMB_HEIGHT)];
            NSData* imageData = UIImageJPEGRepresentation(thumnailImage, JPEG_QUALITY);
            [imageData writeToFile:thumbPath atomically:NO];
        }
    }
    return thumnailImage;
}


//not thread safe
+ (UIImage*)imageResizeWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}

+ (UIColor *) colorWithHexString: (NSString *) stringToConvert{
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor blackColor];
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString length] != 6) return [UIColor blackColor];
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

//find xxxx in desc text : ...<<xxxx>>...
+ (NSString*) getMarkerNameFromDescText: (NSString*)descTxt
{
    NSString* returnStr = nil;
    NSInteger loc = [descTxt rangeOfString:@"<<"].location;
    if ( loc != NSNotFound) {
        NSString* str = [descTxt substringFromIndex:loc +2 ];
        NSInteger loc2 = [str rangeOfString:@">>"].location;
        if (loc2 != NSNotFound)
        {
            str = [str substringToIndex:loc2];
            if ([str rangeOfString:@" "].location == NSNotFound) //can not have space between == ... == then
                returnStr = str;
        }
    }
    return returnStr;
}

+ (NSString*) clearMakerFromDescText: (NSString*)desc :(NSString*)markerName
{
    if (markerName != nil)
    {
        NSInteger loc = [desc rangeOfString:@"\n<<"].location;
        if (loc == NSNotFound)
            markerName = [NSString stringWithFormat:@"<<%@>>",markerName ];
        else
            markerName = [NSString stringWithFormat:@"\n<<%@>>",markerName ];
        return [desc stringByReplacingOccurrencesOfString:markerName withString:@""];
    }
    else
        return desc;
}

+ (NSString*) clearMakerAllFromDescText: (NSString*)desc
{
    NSString* markerName = [self getMarkerNameFromDescText:desc];
    return[self clearMakerFromDescText:desc :markerName];
}

+ (NSArray*) getEventListWithUniqueIds: (NSArray*)uniqueIds
{
    NSMutableArray* returnList = [[NSMutableArray alloc] initWithCapacity:[uniqueIds count]];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray* fullEventList = appDelegate.eventListSorted;
    for (ATEventDataStruct* evt in fullEventList)
    {
        if ([uniqueIds containsObject:evt.uniqueId] )
            [returnList addObject:evt];
    }
    return returnList;
}

+(NSString*) httpGetFromServer:(NSString *)serverUrl
{
    serverUrl = [serverUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //will handle chinese etc

    NSURL* serviceUrl = [NSURL URLWithString:serverUrl];
    NSMutableURLRequest * serviceRequest = [NSMutableURLRequest requestWithURL:serviceUrl cachePolicy:0 timeoutInterval:5];
    //NSLog(@"request is: %@",serverUrl);
    //Get Responce hear----------------------
    NSURLResponse *response;
    NSError *error;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:serviceRequest returningResponse:&response error:&error];
    if (urlData == nil)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connect Server Fail!",nil) message:NSLocalizedString(@"Network may not be available, Please try later!",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return nil;
    }
    NSString* responseStr = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
    if ([responseStr hasPrefix:@"<html>"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connect Server Fail!",nil) message:NSLocalizedString(@"Temporary network problem, Please try again!",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return nil;
    }
    return responseStr;
}

+ (void)startReplaceDb:(NSString*)selectedAtlasName :(NSArray*)downloadedJsonArray :(UIActivityIndicatorView*)spinner
{
    //NSLog(@"Start replace db called");
    if (spinner != nil)
        [spinner startAnimating];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int cnt = [downloadedJsonArray count];
    NSMutableArray* newEventList = [[NSMutableArray alloc] initWithCapacity:cnt];
    NSDateFormatter* usDateformater = [appDelegate.dateFormater copy];
    //always use USLocale to save date in JSON, so always use it to read. this resolve a big issue when user upload with one local and download with another local setting.
    // See ATPreferenceViewController startUploadJson
    [usDateformater setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    
    if (downloadedJsonArray!=nil && [downloadedJsonArray count]>0)
    {//This part is for backward compability in case user already saved localized NSDate string to server
        NSDictionary* tmpDic = downloadedJsonArray[0];
        NSString* dateStr =[tmpDic objectForKey:@"eventDate"];
        if ([dateStr rangeOfString:@" AD"].location == NSNotFound)
            usDateformater = appDelegate.dateFormater; //do not apply USLocalize
    }

    for (NSDictionary* dict in downloadedJsonArray)
    {
        ATEventDataStruct* evt = [[ATEventDataStruct alloc] init];
        evt.uniqueId = [dict objectForKey:@"uniqueId"];
        evt.eventDesc = [dict objectForKey:@"eventDesc"];
        evt.eventDate = [usDateformater dateFromString:[dict objectForKey:@"eventDate"]];
        evt.address = [dict objectForKey:@"address"];
        //evt.lat = [[numFormatter numberFromString:[dict objectForKey:@"lat"]] doubleValue];
        //evt.lng = [[numFormatter numberFromString:[dict objectForKey:@"lng"]] doubleValue];
        evt.lat = [[dict objectForKey:@"lat"] doubleValue];
        evt.lng = [[dict objectForKey:@"lng"] doubleValue];
        evt.eventType = [[dict objectForKey:@"eventType"] intValue];
        [newEventList addObject:evt];
        // NSLog(@"%@    desc %@", [dict objectForKey:@"eventDate"],[dict objectForKey:@"eventDesc"]);
    }
    
    [ATHelper setSelectedDbFileName:selectedAtlasName];
    ATDataController* dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    [appDelegate.eventListSorted removeAllObjects];
    appDelegate.eventListSorted = newEventList;
    [dataController deleteAllEvent]; //only meaniful for myTrips database
    
    for (ATEventDataStruct* evt in newEventList)
    {
        [dataController addEventEntityAddress:evt.address description:evt.eventDesc date:evt.eventDate lat:evt.lat lng:evt.lng type:evt.eventType uniqueId:evt.uniqueId];
    }
    [appDelegate emptyEventList];
    [appDelegate.mapViewController cleanSelectedAnnotationSet];
    [appDelegate.mapViewController prepareMapView];
    if (spinner != nil)
        [spinner stopAnimating];
}
+ (BOOL)isBCDate:(NSDate*)date
{
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
 
    //era value 1 for AD, 0 for BC
    if ([otherDay era] <= 0)
        return true;
    else
        return false;
}


//---- set/get options
+ (BOOL) getOptionDateFieldKeyboardEnable
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flag = [userDefault objectForKey:@"DateFieldKeyboardEnable"];
    if (flag == nil || [flag isEqualToString:@"N"]) //default is N
        return false;
    else
        return true;
}
+ (void) setOptionDateFieldKeyboardEnable:(BOOL)flag
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flagStr = @"N";
    if (flag)
        flagStr = @"Y";
    [userDefault setObject:flagStr forKey:@"DateFieldKeyboardEnable"];
}
+ (BOOL) getOptionDisplayTimeLink
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flag = [userDefault objectForKey:@"DisPlayTimeLink"];
    if (flag == nil || [flag isEqualToString:@"Y"]) //default is Y
        return true;
    else
        return false;
}
+ (void) setOptionDisplayTimeLink:(BOOL)flag
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flagStr = @"N";
    if (flag)
        flagStr = @"Y";
    [userDefault setObject:flagStr forKey:@"DisPlayTimeLink"];
}

+ (BOOL) getOptionDateMagnifierModeScroll
{  //This option may readd many time when scroll, so read from memory instead from dis each time
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString* flag = appDelegate.optionEnableDateMagnifierMove;
    if (flag == nil || [@"NEEDINIT" isEqualToString: flag])
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        flag = [userDefault objectForKey:@"DateMagnifierMode"];
    }
    if (flag == nil || [flag isEqualToString:@"Y"]) //default is Y
        return true;
    else
        return false;
}
+ (void) setOptionDateMagnifierModeScroll:(BOOL)flag
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];

    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flagStr = @"N";
    appDelegate.optionEnableDateMagnifierMove = @"N";
    if (flag)
    {
        flagStr = @"Y";
        appDelegate.optionEnableDateMagnifierMove = @"Y";
    }
    [userDefault setObject:flagStr forKey:@"DateMagnifierMode"];
}

+ (BOOL) getOptionEditorFullScreen
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flag = [userDefault objectForKey:@"EditorFullScreen"];
    if (flag == nil || [flag isEqualToString:@"N"]) //default is N
        return false;
    else
        return true;
}
+ (void) setOptionEditorFullScreen:(BOOL)flag
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flagStr = @"N";
    if (flag)
        flagStr = @"Y";
    [userDefault setObject:flagStr forKey:@"EditorFullScreen"];
}
+ (BOOL) getOptionZoomToWeek
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flag = [userDefault objectForKey:@"ZoomToWeek"];
    if (flag == nil || [flag isEqualToString:@"N"]) //default is N
        return false;
    else
        return true;
}
+ (void) setOptionZoomToWeek:(BOOL)flag
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* flagStr = @"N";
    if (flag)
        flagStr = @"Y";
    [userDefault setObject:flagStr forKey:@"ZoomToWeek"];
}

@end
