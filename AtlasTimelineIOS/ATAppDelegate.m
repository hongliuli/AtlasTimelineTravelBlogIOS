//
//  ATAppDelegate.m
//  AtlasTimelineIOS
//
//  Created by Hong on 12/28/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "ATAppDelegate.h"
#import "ATimelineTableViewController.h"
#import "ATDataController.h"
#import "ATConstants.h"
#import "ATEventEntity.h"
#import "ATEventDataStruct.h"
#import "ATHelper.h"
#import "iRate.h"


#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

@interface ATAppDelegate ()
//TODO should add data store initialize here and pass data store to ATTimelineTableViewController, or the controller come to here to get data store
@property (nonatomic, strong) NSArray *periods;

@end

@implementation ATAppDelegate

@synthesize window=window_, periods=_periods;

- (NSDateFormatter *)dateFormater {
	
    if (_dateFormater != nil) {
        return _dateFormater;
    }
    _dateFormater = [[NSDateFormatter alloc] init];
    //_dateFormater.dateStyle = NSDateFormatterMediumStyle;
    [_dateFormater setDateFormat:@"MM/dd/yyyy GG"];
    return _dateFormater;
}
- (NSString *)localizedAD {
	
    if (_localizedAD != nil) {
        return _localizedAD;
    }
    NSDate* today = [NSDate date];
    NSString* todayStr = [self.dateFormater stringFromDate:today];
    //NSLog(@"######### AD is %@",[todayStr substringFromIndex:11]);
    return [todayStr substringFromIndex:11];
}

+ (void)initialize
{
    //configure iRate
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 15;
    
    //For testing
    //[iRate sharedInstance].previewMode = YES;
    
    /*
     //These ivars have the following meaning: wait 5 days before asking a review from the user and wait for at least 10 application usage. If the user tap Remind me later, then wait 3 days before asking a review again. Very nice.
     [iRate sharedInstance].appStoreID = 3333333;
     [iRate sharedInstance].applicationName=@"xxxx";
     [iRate sharedInstance].daysUntilPrompt = 5;
     [iRate sharedInstance].usesUntilPrompt = 10;
     [iRate sharedInstance].remindPeriod = 3;
     [iRate sharedInstance].message = NSLocalizedString(@"striRateMessage_KEY", striRateMessage);
     [iRate sharedInstance].NSLocalizedString(@"strrateButtonLabel_KEY", strrateButtonLabel);
     */
    
}

//this will easy to change database file name by just set eventListSorted to null
- (NSArray*) eventListSorted {
    if (_eventListSorted != nil)
        return _eventListSorted;
    _eventListSorted =[[NSMutableArray alloc] initWithCapacity:100];
    
    NSArray* eventsFromStr = nil;
    if (self.authorMode)
    {
        eventsFromStr = [self readEventsFromInternet];
        if (eventsFromStr == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Read Event String from Internet error",nil) message:NSLocalizedString(@"Please contact support@chroniclemap.com to learn how to upload your authored contents",nil)
                                                           delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
            if (![userEmail isEqualToString:@"hongliuli@yahoo.com"])
                [self.mapViewController closeAuthorView];
            eventsFromStr = [self readEventsFromBundleFile]; //fallback to events in bundle file
        }
    }
    else
        eventsFromStr = [self readEventsFromBundleFile];
    if (eventsFromStr == nil)
    {
        NSLog(@"   read from file or internet error ======");
        return nil;
    }
    for (ATEventDataStruct* ent in eventsFromStr) {
        
        ATEventDataStruct* entData = [[ATEventDataStruct alloc] init];
        entData.address = ent.address;
        entData.eventDate = ent.eventDate;
        entData.eventDesc = ent.eventDesc;
        //NSLog(@"event date=%@   eventType=%i",entData.eventDate, entData.eventType);
        entData.uniqueId = ent.uniqueId;
        entData.lat = ent.lat;
        entData.lng = ent.lng;
        
        //Every events must have photos, otherwise eventListView will has a empty space
        entData.eventType = EVENT_TYPE_HAS_PHOTO;
        
        [_eventListSorted addObject:entData];
    }
    
    
    return _eventListSorted;
}

- (NSDictionary*) overlayCollection {
    return _overlayCollection; //initialized in eventListSorted
}

- (NSDictionary*) sharedOverlayCollection {
    return _sharedOverlayCollection; //initialized in eventListSorted
}

-(void) emptyEventList
{
    //used in ATPreferenceViewController when switch offline source
    [_eventListSorted removeAllObjects];
    _eventListSorted = nil;
}

- (NSArray*) readEventsFromBundleFile
{
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString* eventFileName = [NSString stringWithFormat:@"EventsFileFor%@", targetName ];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:eventFileName ofType:@"txt"];
    NSArray* eventArray = nil;
    NSLog(@"========== readEvents filepath:%@,  fileNm=%@",filePath,eventFileName);
    if (filePath) {
        NSString *eventsString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
        if (eventsString != nil)
            eventArray = [self createdEventListFromString:eventsString];
    }
    return eventArray;
}

- (NSArray*) readEventsFromInternet
{
    //read content from web and reload into db
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self.mapViewController];
    if (!successFlag)
        return nil;
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    //continues to get from server
    NSString* userId = userEmail;
    
    //download whatever this user uploaded into author_content table
    NSURL* serviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/downloadauthorcontents?user_id=%@&security_code=%@",[ATConstants ServerURL], userId, securityCode]];
    
    NSData* downloadedData = [NSData dataWithContentsOfURL:serviceUrl];

    if (downloadedData == nil)
    {
        return nil;
    }
    else
    {
        NSString* contentStr = [[NSString alloc] initWithData:downloadedData encoding:NSUTF8StringEncoding];
        return [self createdEventListFromString:contentStr];
    }

}

- (NSArray*) createdEventListFromString:(NSString*)eventsString
{
    NSMutableArray* eventList = [[NSMutableArray alloc] initWithCapacity:400];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    
    if (_overlayCollection == nil)
        _overlayCollection = [[NSMutableDictionary alloc] init];
    if (_sharedOverlayCollection == nil)
        _sharedOverlayCollection = [[NSMutableDictionary alloc] init];
    
    ATEventDataStruct* lastEvent = nil;
    if (eventsString != nil)
    {
        //[Date] must be the first Metadata for each event in file, and must already sorted?
        NSArray* eventStrList = [eventsString componentsSeparatedByString: @"[Date]"];
        
        NSMutableArray* uniqueIdCollection = [[NSMutableArray alloc] init];
        int partOfUniqueId = 0;
        for (NSString* eventStr in eventStrList)
        {
            if ([@"" isEqualToString:eventStr] || [@"\n" isEqualToString:eventStr])
                continue;
            ATEventDataStruct* evt = [[ATEventDataStruct alloc] init];
            //###### event in file must have order [Date]2001-01-01 -> [Tags] -> [Loc] -> [Desc] -> [Overlay]..[Overlay]..[Overlay]
            NSString* tmp = [eventStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString* datePart = [tmp substringToIndex:10];
            evt.eventDate = [dateFormat dateFromString:datePart];
            if (evt.eventDate == nil)
            {
                NSLog(@"  ##### readEventsFromFile convert date %@ failed", datePart);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Read Event File date error",nil) message:NSLocalizedString(datePart,nil)
                                                               delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                [alert show];
                return nil;
            }
            NSRange addrFromRange = [tmp rangeOfString:@"[Tags]" options: NSCaseInsensitiveSearch];
            NSRange locFromRange = [tmp rangeOfString:@"[Loc]" options: NSCaseInsensitiveSearch];
            if (addrFromRange.location == NSNotFound) {
                NSLog(@"  ##### readFromFile - [Tags] was not found in %@", tmp);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Read Event File Addr error",nil) message:NSLocalizedString(tmp,nil)
                                                               delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                [alert show];
                return nil;
            }
            if (locFromRange.location == NSNotFound) {
                NSLog(@"  ##### readFromFile - [Loc] was not found in %@", tmp);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Read Event File Loc error",nil) message:NSLocalizedString(tmp,nil)
                                                               delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                [alert show];
                return nil;
            }
            tmp = [tmp substringFromIndex:addrFromRange.location];
            //now [Tags] start from 0
            locFromRange = [tmp rangeOfString:@"[Loc]" options: NSCaseInsensitiveSearch];
            NSRange addrRange = NSMakeRange(6, locFromRange.location - 6);
            evt.address = [tmp substringWithRange:addrRange];
            tmp = [tmp substringFromIndex:locFromRange.location];
            
            //now [Loc] start from 0
            NSRange descFromRange = [tmp rangeOfString:@"[Desc]"];
            if (descFromRange.location == NSNotFound) {
                NSLog(@" ##### readFromFile - [Desc] was not found in %@", tmp);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Read Event File Desc error",nil) message:NSLocalizedString(tmp,nil)
                                                               delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                [alert show];
                return nil;
            }
            NSRange locRange = NSMakeRange(5, descFromRange.location - 5);
            NSString* loc = [tmp substringWithRange:locRange];
            loc = [loc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray* latlng = [loc componentsSeparatedByString:@","];
            if (latlng == nil || [latlng count] != 2)
            {
                NSLog(@" ###### [loc] data has error %@",tmp);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Read Event File Loc error",nil) message:NSLocalizedString(tmp,nil)
                                                               delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                [alert show];
                return nil;
            }
            evt.lat = [latlng[0] doubleValue];
            evt.lng = [latlng[1] doubleValue];
            
            tmp = [tmp substringFromIndex:descFromRange.location];
            
            //now tmp start from [Desc]
            NSRange overlayFromRange = [tmp rangeOfString:@"[Overlay]" options: NSCaseInsensitiveSearch];
            if (overlayFromRange.location == NSNotFound)
                evt.eventDesc = [tmp substringFromIndex:6];
            else
            {
                NSRange descRange = NSMakeRange(6, overlayFromRange.location - 6);
                evt.eventDesc = [tmp substringWithRange:descRange];
            }
            lastEvent = evt;
            
            //because photo are stored in directory named with uniqueId, so after initial
            //    run, uniqueId should not be changed, otherwise photo may be lost
            NSString* uniqueId = datePart;
            if ([uniqueIdCollection containsObject:uniqueId])
                uniqueId = [NSString stringWithFormat:@"%@_%d", datePart, partOfUniqueId];
            [uniqueIdCollection addObject:uniqueId];
            evt.uniqueId = uniqueId;
            partOfUniqueId++; //this will make sure generated uniqueId is unique when events have same date
            [eventList addObject:evt];
            
            //Now process overlay.  [Overlay]number,number number,number ..
            //                      [Overlay]number,number number,number ..
            //                      [Overlay]shareOverlayKey  the overlay is in [ShareOverlay]
            if (overlayFromRange.location != NSNotFound) {
                
                tmp = [tmp substringFromIndex:overlayFromRange.location];
                tmp = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                //Now tmp contains only overlay data, no meta no space. store overlay
                NSArray* overlays = [tmp
                                     componentsSeparatedByString:@"[Overlay]"];
                if ( overlays == nil || [overlays count] == 0)
                {
                    NSLog(@" ##### [Overlay] data has error %@",tmp);
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Read Event File Overlay error",nil) message:NSLocalizedString(tmp,nil)
                                                                   delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                    [alert show];
                    return nil;
                }
                NSMutableArray* overlayList = [[NSMutableArray alloc] init];
                
                for (NSString* overlayDataStr in overlays)
                {
                    if (overlayDataStr == nil || [overlayDataStr length] == 0)
                        continue;
                    //in a [Region], polygon lines can be separated by " " or "\n" or compbination
                    NSString* allSpaceSepStr = [overlayDataStr stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                    NSArray* lines = [allSpaceSepStr componentsSeparatedByString:@" "]; //Google's "My Map" export KML data is separated by space
                    NSMutableArray* processedLines = [[NSMutableArray alloc] init];
                    if (lines == nil || [lines count] == 0)
                        continue;
                    for (NSString* lineStr in lines)
                    {
                        if (lineStr == nil || [lineStr length] == 0)
                            continue;
                        NSString* line = [lineStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        [processedLines addObject:line];
                    }
                    [overlayList addObject:processedLines]; //shareOverlay key should also add in as one line
                }
                [_overlayCollection setObject:overlayList forKey:uniqueId];
            }

        }
        //Here is to parse whole file again to get shareOverlay data (ShareOverlay data will be put at end of file)
        //Data format [ShareOverlay]key1 number,number number,number
        //            [ShareOverlay]key2 number,number number,number ...
        int firstShareOverlayLoc = [eventsString rangeOfString:@"[ShareOverlay]"].location;
        if (firstShareOverlayLoc != NSNotFound)
        {
            if (lastEvent != nil) //remove [ShareOverlay] part from the last event
            {
                int lastEventShareOverlayLoc = [lastEvent.eventDesc rangeOfString:@"[ShareOverlay]"].location;
                if (lastEventShareOverlayLoc != NSNotFound)
                    lastEvent.eventDesc = [lastEvent.eventDesc substringToIndex:lastEventShareOverlayLoc];
            }
            eventsString = [eventsString substringFromIndex:firstShareOverlayLoc];
            NSArray* shareOverlayList = [eventsString componentsSeparatedByString: @"[ShareOverlay]"];
            for (NSString* polygonLinesStr in shareOverlayList)
            {
                if (polygonLinesStr == nil || [polygonLinesStr isEqualToString:@""])
                    continue;
                
                //in a [ShareRegion], first is key, then polygon lines. Separater can be separated by " " or "\n' (or combination)
                NSString* tmp = [polygonLinesStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                tmp = [tmp stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                
                NSArray* lines = [tmp componentsSeparatedByString:@" "]; //Google's "My Map" export KML data is separated by space
                NSMutableArray* polygonLines = [[NSMutableArray alloc] init];
                for (int i = 0; i< [lines count]; i++)
                {
                    NSString* line = [lines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString* key = nil;
                    if (i == 0) //first one must be key
                    {
                        key = [line lowercaseString]; //make shareOverlay key case insenstive. see ATViewController where fetch the key
                        if (key == nil || [key isEqualToString:@""])
                        {
                            NSLog(@"  ####### SharedOverlay key has error %@", line);
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"read file sharedOverlay key has error",nil) message:line
                                                                           delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                            [alert show];
                        }
                        [_sharedOverlayCollection setObject:polygonLines forKey:key];
                    }
                    else
                    {
                        if (line == nil || [line isEqualToString:@""])
                            continue;
                        [polygonLines addObject:line];
                    }
                }
            }
        }
    }
    
    
    
    NSArray* ret = [eventList sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first = [(ATEventDataStruct*)a eventDate];
        NSDate *second = [(ATEventDataStruct*)b eventDate];
        return [first compare:second]== NSOrderedAscending;
    }];
    return ret;

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ATViewController *controller;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
    }
    else
    {
        self.storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    }
    controller = [self.storyBoard instantiateInitialViewController];
    [self.window setRootViewController:controller];
    //NSLog(@" -------dropbox root is %@", kDBRootDropbox);
    DBSession* dbSession =[[DBSession alloc] initWithAppKey:@"vmngs8cprefdyi3"
                                                  appSecret:@"o9ct42rr0696dzq" root:kDBRootDropbox]; // either kDBRootAppFolder or kDBRootDropbox;
    [DBSession setSharedSession:dbSession];
    
    [[DBSession sharedSession] unlinkAll];//IMPORTANT: so each restart will ask user login to drobox. Without this, once login to dropbox from app, even reinstall app will not ask to login again, there is no way to switch dropbox account
    
    return YES;
}
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
