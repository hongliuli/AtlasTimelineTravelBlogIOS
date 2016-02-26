//
//  ATViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 12/28/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#define IN_APP_PURCHASED @"IN_APP_PURCHASED"
#define ALERT_FOR_SWITCH_LANGUAGE 1
#define ALERT_FOR_POPOVER_ERROR 2
#define ALERT_FOR_SWITCH_APP_AFTER_LONG_PRESS 4

#import <QuartzCore/QuartzCore.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "ATViewController.h"
#import "ATDefaultAnnotation.h"
#import "ATAnnotationSelected.h"
#import "ATAnnotationFocused.h"
#import "ATDataController.h"
#import "ATEventEntity.h"
#import "ATEventDataStruct.h"
#import "ATAppDelegate.h"
#import "ATConstants.h"
#import "ATTimeZoomLine.h"
#import "ATHelper.h"
#import "ATPreferenceEntity.h"
#import "ATTimeScrollWindowNew.h"
#import "ATTutorialView.h"
#import "ATInAppPurchaseViewController.h"
#import "ATEventListWindowView.h"
#import "ATCell.h"
#import "Toast+UIView.h"
#import "ADClusterAnnotation.h"

#import "SWRevealViewController.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395
#define ZOOM_LEVEL_TO_HIDE_DESC 3
#define ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE 5
#define ZOOM_LEVEL_TO_HIDE_EVENTLIST_VIEW 5
#define ZOOM_LEVEL_TO_SEND_WHITE_FLAG_BEHIND_IN_REGION_DID_CHANGE 9

#define DISTANCE_TO_HIDE 80

#define RESIZE_WIDTH 600
#define RESIZE_HEIGHT 450
#define THUMB_WIDTH 120
#define THUMB_HEIGHT 70
#define JPEG_QUALITY 0.5

#define FREE_VERSION_QUOTA 50

#define EDITOR_PHOTOVIEW_WIDTH 190
#define EDITOR_PHOTOVIEW_HEIGHT 160
#define NEWEVENT_DESC_PLACEHOLD NSLocalizedString(@"Write notes here",nil)
#define NEW_NOT_SAVED_FILE_PREFIX @"NEW"

#define TIME_LINK_DASH_LINE_STYLE_FOR_SAME_DEPTH 1
#define TIME_LINK_SOLID_LINE_STYLE 2

//TODO Following should be in configuration settings
#define TIME_LINK_DEPTH 6
#define TIME_LINK_MAX_NUMBER_OF_DAYS_BTW_TWO_EVENT 30
#define MAX_NUMBER_OF_TIME_LINKS_IN_SAME_DEPTH_GROUP 10 //Must be even number. the purpose is to reduce too many line if too may events in same group

#define MAPVIEW_HIDE_ALL 1
#define MAPVIEW_SHOW_PHOTO_LABEL_ONLY 2
#define MAPVIEW_SHOW_ALL 3

#define HAVE_IMAGE_INDICATOR 100

#define AD_Y_POSITION_IPAD 60
#define AD_Y_POSITION_PHONE 40

#define PHOTO_META_FILE_NAME @"MetaFileForOrderAndDesc"

#define PHOTO_META_SORT_LIST_KEY @"sort_key"
#define PHOTO_META_DESC_MAP_KEY @"desc_key"

@interface MFTopAlignedLabel : UILabel

@end




@implementation ATViewController
{
    NSString* selectedAnnotationIdentifier;
    int debugCount;
    CGRect focusedLabelFrame;
    NSMutableArray* timeScaleArray;
    
    NSMutableArray* selectedAnnotationNearestLocationList; //do not add to annotationToShowImageSet if too close
    NSMutableDictionary* annotationToShowImageSet;//hold uilabels for selected annotation's description
    NSMutableDictionary* tmpLblUniqueIdMap;
    int tmpLblUniqueMapIdx;
    NSMutableSet* selectedAnnotationViewsFromDidAddAnnotation;
    NSDate* regionChangeTimeStart;
    ATDefaultAnnotation* newAddedPin;
    UIButton *locationbtn;
    UIButton *switchEventListViewModeBtn;
    CGRect timeScrollWindowFrame;
    ATTutorialView* tutorialView;
    
    ATInAppPurchaseViewController* purchase; // have to be global because itself has delegate to use it self
    ADClusterAnnotation* selectedEventAnnotation;
    int timeLinkDepthDirectionFuture;
    int timeLinkDepthDirectionPast;
    NSMutableArray* overlaysToBeCleaned ;
    
    ATAnnotationFocused* focusedAnnotationIndicator;
    int currentTapTouchKey;
    bool currentTapTouchMove;
    UIButton *btnLess;
    ATEventListWindowView* eventListView;
    
    NSMutableArray* filteredEventListSorted;
    NSMutableArray* originalEventListSorted;
    
    NSDate* tmpDateHold;
    
    ATEventDataStruct* currentSelectedEvent;
    MKAnnotationView* selectedEventAnnInEventListView;
    MKAnnotationView* selectedEventAnnOnMap;
    ADClusterAnnotation* selectedEventAnnDataOnMap;
    
    BOOL switchEventListViewModeToVisibleOnMapFlag;
    NSMutableArray* eventListInVisibleMapArea;
    
    
    NSMutableArray* animationCameras;
    
    BOOL firstTimeShowFlag;
    
    NSString* prevSelectedEventId;
    
    NSString* languageToSelect;
    UIBarButtonItem *settringButton;
    
    NSDate* lastLongpresstie;
    
    NSDate* lastUpdateMapInRegionDidChange;
    int prevZoomLevel;
    
    BOOL waitPageLoadFlag;
    NSString* prevBlogUrl;
}

@synthesize mapView = _mapView;

- (ATDataController *)dataController { //initially I want to have a singleton of dataController here, but not good if user change database file source, instance it ever time. It is ok here because only called every time user choose to delete/insert
    dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    return dataController;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.rightSideMenuRevealedFlag = FALSE;
    switchEventListViewModeToVisibleOnMapFlag = false; //eventListView for timewheel is more reasonable, so make it as default always, even not save to userDefault
    
    [ATHelper createPhotoDocumentoryPath];
    //ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.locationManager = [[CLLocationManager alloc] init];
    //add for ios8
    self.locationManager.delegate = self;
    if ([ATHelper isAtLeastIOS8]) {
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
    
    self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
    int searchBarHeight = [ATConstants searchBarHeight];
    int searchBarWidth = [ATConstants searchBarWidth];
    [self.navigationItem.titleView setFrame:CGRectMake(0, 0, searchBarWidth, searchBarHeight)];
    
    //Find this spent me long time: searchBar used titleView place which is too short, thuse tap on searchbar right side keyboard will not show up, now it is good
    [self calculateSearchBarFrame];
    
    SWRevealViewController *revealController = [self revealViewController];
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    // create a custom navigation bar button and set it to always says "Back"
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = NSLocalizedString(@"Back",nil);
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    
    //add two button at right (can not do in storyboard for multiple button): setting and Help, available in iOS5
    //   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    //   {
    
    settringButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ios-menu-icon.png"]  style:UIBarButtonItemStylePlain target:self action:@selector(settingsClicked:)];
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    UIImage* imaged = [UIImage imageNamed:[targetName stringByAppendingString:@"-45.png"]];
    UIBarButtonItem* aboutButton = [[UIBarButtonItem alloc] initWithImage:[imaged imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:nil target:self action:@selector(aboutClicked:)];

    self.navigationItem.rightBarButtonItems = @[settringButton];
    self.navigationItem.leftBarButtonItems = @[aboutButton];
    //   }
    
    // Do any additional setup after loading the view, typically from a nib.
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPressGesture:)];
    lpgr.minimumPressDuration = 0.8;  //user must press for 0.8 seconds
    [_mapView addGestureRecognizer:lpgr];
    
    // tap to show/hide timeline navigator
    UITapGestureRecognizer *tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [_mapView addGestureRecognizer:tapgr];
    
    annotationToShowImageSet = [[NSMutableDictionary alloc] init];
    tmpLblUniqueIdMap = [[NSMutableDictionary alloc] init];
    tmpLblUniqueMapIdx = 1;
    selectedAnnotationNearestLocationList = [[NSMutableArray alloc] init];
    regionChangeTimeStart = [[NSDate alloc] init];
    [self prepareMapView];
    //if(IOS_7)
    //{
    self.searchDisplayController.searchBar.searchBarStyle = UISearchBarStyleMinimal; //otherwise, there will be a gray background around search bar
    //}

    // I did not use iOS7's self.canDisplayBannerAds to automatically display adds, not sure why
    [self initgAdBanner];
    
    if (switchEventListViewModeBtn == nil)
        switchEventListViewModeBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    else
        [switchEventListViewModeBtn removeFromSuperview];
    switchEventListViewModeBtn.frame = CGRectMake(10, 73, 100, 30);
    [switchEventListViewModeBtn.titleLabel setFont:[UIFont fontWithName:@"Arial-Bold" size:25]];
    [[switchEventListViewModeBtn layer] setBorderWidth:2.0f];
    
    [self setSwitchButtonMapMode];
    
    [switchEventListViewModeBtn addTarget:self action:@selector(switchEventListViewMode:) forControlEvents:UIControlEventTouchUpInside];
    
    [switchEventListViewModeBtn.layer setCornerRadius:7.0f];
    [self.mapView addSubview:switchEventListViewModeBtn];
    eventListInVisibleMapArea = nil;
    [self refreshEventListView:false];
    
}
-(void) viewDidAppear:(BOOL)animated
{
    firstTimeShowFlag = true;
    [self displayTimelineControls]; //MOTHER FUCKER, I struggled long time when I decide to put timescrollwindow at bottom. Finally figure out have to put this code here in viewDidAppear. If I put it in viewDidLoad, then first time timeScrollWindow will be displayed in other places if I want to display at bottom, have to put it here
    [self.timeZoomLine showHideScaleText:false];
    [ATHelper setOptionDateFieldKeyboardEnable:false]; //always set default to not allow keyboard
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    originalEventListSorted = appDelegate.eventListSorted;
    filteredEventListSorted = [NSMutableArray arrayWithCapacity:[originalEventListSorted count]];
    //[self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"List",nil)];
    [self.searchDisplayController.searchBar setPlaceholder:NSLocalizedString(@"搜索标签，标题", nil)];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* promptNewBlog = [userDefaults objectForKey:@"PROMPT_NEW_BLOG"];
    if (promptNewBlog != nil && [promptNewBlog isEqualToString:@"YES"])
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"有新的博文"
                                                                       message:@"请切换到［在期间里］，然后左刷时间轮到最后，新的博文就会出现在左旁列表。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* action1 = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [userDefaults setObject:@"NO" forKey:@"PROMPT_NEW_BLOG"];
        }];
        UIAlertAction* action2 = [UIAlertAction actionWithTitle:@"下次再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:action1];
        [alert addAction:action2];
        [self presentViewController:alert animated:YES completion:nil];
    }
    if (eventListView == nil) //viewDidAppear will be called when navigate back (such as from timeline/search view and full screen event editor, so need to check. Always be careful of viewDidAppear to not duplicate instances
    {
        eventListView = [[ATEventListWindowView alloc] initWithFrame:CGRectMake(0,100, 0, 0)];
        [eventListView.tableView setBackgroundColor:[UIColor clearColor] ];// colorWithRed:1 green:1 blue:1 alpha:0.7]];
        [self.mapView addSubview:eventListView];
    }
    [self refreshEventListView:false];
    
}

-(void)setSwitchButtonTimeMode
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.mapModeFlag = false;
    switchEventListViewModeToVisibleOnMapFlag = false;
    [switchEventListViewModeBtn setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [switchEventListViewModeBtn setTitle:NSLocalizedString(@"By Time",nil) forState:UIControlStateNormal];
    [[switchEventListViewModeBtn layer] setBorderColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor];
    [self refreshAnnotations];
}
-(void)setSwitchButtonMapMode
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.mapModeFlag = true;
    switchEventListViewModeToVisibleOnMapFlag = true;
    [switchEventListViewModeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [switchEventListViewModeBtn setTitle:NSLocalizedString(@"By Map",nil) forState:UIControlStateNormal];
    [[switchEventListViewModeBtn layer] setBorderColor:[UIColor redColor].CGColor];
    [self refreshAnnotations];
}

-(void) aboutClicked:(id)sender
{
    [self displayPageOnRightRevealPanel:@"http://blog.sina.com.cn/huazitt"];
}

-(void) settingsClicked:(id)sender  //IMPORTANT only iPad will come here, iPhone has push segue on storyboard
{
    /*
     NSString* currentVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
     currentVer = [NSString stringWithFormat:@"Current Version: %@",currentVer ];
     
     NSString* link = @"http://www.chroniclemap.com/";
     NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:2];
     NSURLResponse* response=nil;
     NSError* error=nil;
     NSData* data=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
     NSString* returnStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
     
     if(error == nil && returnStr != nil && [returnStr rangeOfString:@"Current Version:"].length > 0)
     {
     if ([returnStr rangeOfString:currentVer].length == 0)
     {
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"There is a new version!",nil)
     message:NSLocalizedString(@"Please update from App Store",nil)
     delegate:nil
     cancelButtonTitle:NSLocalizedString(@"OK",nil)
     otherButtonTitles:nil];
     [alert show];
     }
     }
     */
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    SWRevealViewController *revealController = [self revealViewController];
    UIViewController* controller = revealController.rightViewController;
    if (appDelegate.rightSideMenuRevealedFlag )
    { //if right side is preference already, just toggle it
        [revealController rightRevealToggle:nil];
        return;
    }
    
    //any other case need to reload preference
    revealController.rightViewRevealWidth = [ATConstants revealViewPreferenceWidth];
    UINavigationController* prefNavController = [appDelegate getPreferenceViewNavController];
    revealController.rightViewController = prefNavController;
    ATPreferenceViewController* prefController = prefNavController.childViewControllers[0];
    //TODO  need to get user purchased 锦囊
    //[prefController refreshDisplayStatusAndData];
    [[prefController tableView] reloadData];
    
    if (!appDelegate.rightSideMenuRevealedFlag)
    { //if was not shown (but not preference, which is eventEditor
        
        [revealController rightRevealToggle:nil];
    }
    
    
    // if (!appDelegate.rightSideMenuRevealedFlag)
    //    [revealController rightRevealToggle:nil];
}

-(void) setLanguageToSelectTitle
{
    languageToSelect = @"中文";
    NSString * language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2]; //return zh for chinese
    NSString* serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com/resources/poi_list.html"];
    if ([@"zh" isEqualToString:language])
        languageToSelect = @"English";
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* languageValue = [userDefault objectForKey:LanguageKey];
    if (languageValue != nil)
    {
        if ([ChineseValue isEqualToString:languageValue])
        {
            serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com/resources/poi_list_zh.html"];
            languageToSelect = @"English";
        }
        else{
            serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com/resources/poi_list.html"];
            languageToSelect = @"中文";
        }
    }
    NSString* menuText = languageToSelect;
    if ([@"English" isEqualToString:languageToSelect])
        menuText = @"EN";
    [settringButton setTitle:menuText];
    
    ///// Add conditions to remove chinese selection if a target do not have chinese
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    if ([targetName hasPrefix:@"CnetRoadTrip"])
    {
        [settringButton setImage:[UIImage imageNamed:@"ios-menu-icon.png"]];
        languageToSelect = nil;
    }
}

-(void) currentLocationClicked:(id)sender
{
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [self.locationManager startUpdatingLocation];
    
    CLLocationCoordinate2D currentCenterCoordinate;
    CLLocation *newLocation = [self.locationManager location];
    currentCenterCoordinate.latitude = newLocation.coordinate.latitude;
    currentCenterCoordinate.longitude = newLocation.coordinate.longitude;
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:currentCenterCoordinate andZoomLevel:14];
    MKCoordinateRegion region = MKCoordinateRegionMake(currentCenterCoordinate, span);
    
    // set the region like normal
    [self.mapView setRegion:region animated:YES];
    
}

-(void) switchEventListViewMode:(id)sender
{
    float x = 310;
    float y = 90;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        x = 250;
        y = 70;
    }

    
    if (switchEventListViewModeToVisibleOnMapFlag)
    {
        eventListInVisibleMapArea = nil; //IMPORTANT: refreshEventListView will use this is nil or not to decide if in map event list view mode, do not refresh if scroll timewheel
        [self setSwitchButtonTimeMode];
        [self.mapView makeToast:NSLocalizedString(@"Scroll timewheel to list events in the selected period",nil) duration:4.0 position:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        [self refreshEventListView:false];
    }
    else
    {
        [self setSwitchButtonMapMode];
        [self.mapView makeToast:NSLocalizedString(@"Scroll map to list events moving into the screen",nil) duration:4.0 position:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        [self updateEventListViewWithEventsOnMap];
    }
}

#pragma mark - CLLocationManagerDelegate

-(void) tutorialClicked:(id)sender //Only iPad come here. on iPhone will be frome inside settings and use push segue
{
    if (tutorialView != nil)
    {
        [self closeTutorialView];
    }
    else
    {
        tutorialView = [[ATTutorialView alloc] initWithFrame:CGRectMake(940,0,0,0)];
        [UIView transitionWithView:self.mapView
                          duration:0.5
                           options:UIViewAnimationTransitionFlipFromRight //any animation
                        animations:^ {
                            [tutorialView setFrame:self.view.frame];
                            tutorialView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
                            [self.mapView addSubview:tutorialView];
                        }
                        completion:nil];
        
        // Do any additional setup after loading the view, typically from a nib.
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handleTapOnTutorial:)];
        [tutorialView addGestureRecognizer:tap];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake([ATConstants screenWidth] - 120, 65, 110, 30);
        
        [button.layer setCornerRadius:7.0f];
        //[button.layer:YES];
        [button setTitle:NSLocalizedString(@"Online Help",nil) forState:UIControlStateNormal];
        button.titleLabel.backgroundColor = [UIColor blueColor];
        button.backgroundColor = [UIColor blueColor];
        [button addTarget:self action:@selector(onlineHelpClicked:) forControlEvents:UIControlEventTouchUpInside];
        [tutorialView addSubview: button];
        [[self.timeScrollWindow superview] bringSubviewToFront:self.timeScrollWindow];
        [[self.timeZoomLine superview] bringSubviewToFront:self.timeZoomLine];
    }
}

- (void) closeTutorialView
{
    if (tutorialView != nil)
    {
        [UIView transitionWithView:self.mapView
                          duration:0.5
                           options:UIViewAnimationTransitionCurlDown
                        animations:^ {
                            [tutorialView setFrame:CGRectMake(940,0,0,0)];
                        }
                        completion:^(BOOL finished) {
                            [tutorialView removeFromSuperview];
                            tutorialView = nil;
                        }];
    }
}

-(void) onlineHelpClicked:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://www.chroniclemap.com/onlinehelp"];
    
    if (![[UIApplication sharedApplication] openURL:url])
        
        NSLog(@"%@%@",@"Failed to open url:",[url description]);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //if (alertView.tag == ALERT_FOR_SAVE)
    if (alertView.tag == ALERT_FOR_SWITCH_LANGUAGE) {
        if (buttonIndex == 1)
        {
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            NSString* newLanguage = languageToSelect;
            if ([@"English" isEqualToString:newLanguage])
                [userDefaults setObject:EnglishValue forKey:LanguageKey];
            else
                [userDefaults setObject:ChineseValue forKey:LanguageKey];
            [userDefaults synchronize];
            ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
            appDelegate.eventListSorted = nil;
            originalEventListSorted = appDelegate.eventListSorted;
            filteredEventListSorted = [NSMutableArray arrayWithCapacity:[originalEventListSorted count]];
            [self setLanguageToSelectTitle];
            [self prepareMapView];
            [self refreshEventListView:false];
        }
    }
    if (buttonIndex == 0 && alertView.tag == ALERT_FOR_POPOVER_ERROR)
    {
        NSLog(@"----- refreshAnn after popover error");
        [self refreshAnnotations];
    }

    if (alertView.tag == ALERT_FOR_SWITCH_APP_AFTER_LONG_PRESS)
    {
        if (buttonIndex == 0) //Not Now
            return; //user clicked cancel button
        
        if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"chroniclemap://"]]) //ChronicleMap app custom URL
        {
            NSString* chronicleMapAppUrl = @"https://itunes.apple.com/us/app/chronicle-map-event-based/id649653093?ls=1&mt=8";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:chronicleMapAppUrl]]; //download ChronicleMap from app store
        }
    }
}

#pragma mark - mail compose delegate
-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result) {
        NSLog(@"Result : %d",result);
    }
    if (error) {
        NSLog(@"Error : %@",error);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)handleTapOnTutorial:(UIGestureRecognizer *)gestureRecognizer
{
    [self closeTutorialView];
}

- (void)handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer
{
    [self switchToChroniclemapApp];
}

- (void) switchToChroniclemapApp
{
    //Do not know why come here twice, so use a timer to prevent the second one
    NSTimeInterval interval = [[[NSDate alloc] init] timeIntervalSinceDate:lastLongpresstie];
    if (interval < 1)
        return;
    lastLongpresstie = [NSDate date];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Switch to Chronicle Map App",nil)
                                                   message: NSLocalizedString(@"Use Chronicle Map App to organize your upcoming travel plans or view past events on map with timeline",nil)
                                                  delegate: self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                         otherButtonTitles: NSLocalizedString(@"Switch Now",nil), nil];
    alert.tag = ALERT_FOR_SWITCH_APP_AFTER_LONG_PRESS;
    [alert show];
}


//// called it after switch database
- (void) prepareMapView
{
    //remove annotation is for switch db scenario
    NSArray * annotationsToRemove =  self.mapView.annotations;
    [ self.mapView removeAnnotations:annotationsToRemove ] ;
    
    
    //NSLog(@"=============== Map View loaded");
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.searchBar.delegate = self;
    self.mapView.delegate = self; //##### HONG #####: without this, vewForAnnotation() will not be called, google it
    
    //get data from core data and added annotation to mapview
    // currently start from the first one, later change to start with latest one
    NSArray * eventList = appDelegate.eventListSorted;
    if ([eventList count] > 0)
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString* bookmarkIdxStr = [userDefault valueForKey:@"BookmarkEventIdx"];
        NSUInteger eventListSize = [eventList count];
        ATEventDataStruct* entStruct = eventList[eventListSize -1]; //if no bookmark, always use earlist
        if (bookmarkIdxStr != nil)
        {
            NSUInteger bookmarkIdx = [bookmarkIdxStr intValue];
            if (bookmarkIdx >= eventListSize)
                bookmarkIdx = eventListSize - 1;
            entStruct = eventList[bookmarkIdx];
        }
        appDelegate.focusedDate = entStruct.eventDate;
        appDelegate.focusedEvent = entStruct;  //appDelegate.focusedEvent is added when implement here
        
        NSString* bookmarkedZoomLevelStr = [userDefault valueForKey:@"BookmarkMapZoomLevel"];
        int bookmarkedZoomLevel = 4;
        if (bookmarkedZoomLevelStr != nil)
        {
            bookmarkedZoomLevel = [bookmarkedZoomLevelStr intValue];
        }
        
        [self setNewFocusedDateAndUpdateMapWithNewCenter : entStruct :bookmarkedZoomLevel]; //initially set map zoom to a reasonable zoom level so annotation marker icon can show
        //[self showOverlays];
    }
    
    //add annotation. ### this is the loop where we can adding NSLog to print individual items
    NSMutableArray* annotations = [[NSMutableArray alloc] init];
    for (ATEventDataStruct* ent in eventList) {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake((CLLocationDegrees)ent.lat, (CLLocationDegrees)ent.lng);
        ATEventAnnotation *eventAnnotation = [[ATEventAnnotation alloc] initWithLocation:coord];
        eventAnnotation.uniqueId = ent.uniqueId;
        if (ent.eventDate == nil)
            NSLog(@"---- nil date");
        eventAnnotation.address = ent.address;
        eventAnnotation.description=ent.eventDesc;
        eventAnnotation.eventDate=ent.eventDate;
        eventAnnotation.eventType = ent.eventType;
        //NSLog(@"-- %@   %@    %@",eventAnnotation.uniqueId, eventAnnotation.description, eventAnnotation.eventDate);
        [annotations addObject:eventAnnotation];
    }
    @try {
        [self.mapView setAnnotations:annotations];
    }
    @catch (NSException * e) {
        NSLog(@"################## exception #####");
        NSLog(@"Exception: %@", e);
    }

    
    appDelegate.mapViewController = self; //my way of share object, used in ATHelper
    [self setTimeScrollConfiguration]; //I misplaced before above loop and get strange error
    [self displayTimelineControls]; //put it here so change db source will call it, but have to put in viewDidAppear as well somehow
}


//should be called when app start, add/delete ends events, zooming time
//Need change zoom level if need, focused date no change
- (void) setTimeScrollConfiguration
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSArray * eventList = appDelegate.eventListSorted;
    NSUInteger eventCount = [eventList count];
    //IMPORTANT  startDate's date part should always start as year's start day 01/01,so event count in each bucket will be accurate
    if (eventCount == 0) //startDate be this year's start date, end day is today
    {
        NSDate* today = [[NSDate alloc] init];
        self.startDate = [ATHelper getYearStartDate:today];
        dayComponent.day=15;
        self.endDate = [theCalendar dateByAddingComponents:dayComponent toDate:today options:0];
        appDelegate.focusedDate = today;
        appDelegate.selectedPeriodInDays = 30;
    }
    else if (eventCount == 1) //start date is that year's start day, end day is that day
    {
        ATEventDataStruct* event = eventList[0];
        NSDate* curentDate = event.eventDate;
        self.startDate = [ATHelper getYearStartDate:curentDate];
        dayComponent.day=15;
        self.endDate = [theCalendar dateByAddingComponents:dayComponent toDate:curentDate options:0];
        appDelegate.focusedDate = curentDate;
        appDelegate.selectedPeriodInDays = 30;
    }
    else
    {
        
        ATEventDataStruct* eventStart = eventList[eventCount -1];
        ATEventDataStruct* eventEnd = eventList[0];
        //add 5 year
        dayComponent.year = 0;
        dayComponent.month = -5;
        
        NSDate* newStartDt = [theCalendar dateByAddingComponents:dayComponent toDate:eventStart.eventDate options:0];
        
        self.startDate = [ATHelper getYearStartDate: newStartDt];
        self.endDate = eventEnd.eventDate;
        
        // following is to set intial time period based on event distribution after app start or updated edge events, but has exception, need more study (Studied and may found the bug need test)
        NSDateComponents *components = [theCalendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                                      fromDate:self.startDate
                                                        toDate:self.endDate
                                                       options:0];
        if (appDelegate.selectedPeriodInDays == 0) //for add/delete ending events, do not change time zoom level, following is for when app start
        {
            if (components.year > 1000)
                appDelegate.selectedPeriodInDays = 36500;
            else if (components.year > 100)
                appDelegate.selectedPeriodInDays = 3650;
            else if (components.year >= 2)
                appDelegate.selectedPeriodInDays = 365;
            else
                appDelegate.selectedPeriodInDays = 30;
        }
        
    }
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    if ([targetName hasPrefix:@"AtlasTravelReader"])
        appDelegate.selectedPeriodInDays = 365;
    
    if (self.timeZoomLine != nil)
        [self displayTimelineControls];//which one is better: [self.timeZoomLine changeScaleLabelsDateFormat:self.startDate :self.endDate ];
    //NSLog(@"   ############## setConfigu startDate=%@    endDate=%@   startDateFormated=%@", self.startDate, self.endDate, [appDelegate.dateFormater stringFromDate:self.startDate]);
}

- (void) cleanAnnotationToShowImageSet
{
    if (annotationToShowImageSet != nil)
    {
        for (id key in annotationToShowImageSet) {
            UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
            [tmpLbl removeFromSuperview];
        }
        [annotationToShowImageSet removeAllObjects];
        [selectedAnnotationNearestLocationList removeAllObjects];
    }
    [tmpLblUniqueIdMap removeAllObjects];
    tmpLblUniqueMapIdx = 1;
}
- (void)setMapCenter:(ATEventDataStruct*)ent :(int)zoomLevel
{
    // clamp large numbers to 28
    CLLocationCoordinate2D centerCoordinate;
    centerCoordinate.latitude=ent.lat;
    centerCoordinate.longitude=ent.lng;
    zoomLevel = MIN(zoomLevel, 28);
    
    if (zoomLevel < 0) //do not change zoom level if pass in negative zoom level. This used by Event List View select a event
    {
        if (switchEventListViewModeToVisibleOnMapFlag)
            [self.mapView setCenterCoordinate:centerCoordinate animated:YES];
        else
        {
            CLLocationCoordinate2D coord;
            coord.latitude = ent.lat;
            coord.longitude = ent.lng;
            [self goToCoordinate:coord];
        }
    }
    else
    {
        // use the zoom level to compute the region
        if ([ent.uniqueId isEqualToString:prevSelectedEventId]) //if select same event, them zoom in one step for better user experience
            zoomLevel++;
        MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
        MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
        
        // set the region like normal
        [self.mapView setRegion:region animated:YES];
        
        prevSelectedEventId = ent.uniqueId;
    }
}

//orientation change will call following, need to removeFromSuperview when call addSubview
- (void)displayTimelineControls
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate* existingFocusedDate = appDelegate.focusedDate;
    
    
    
    int timeWindowWidth = [ATConstants timeScrollWindowWidth];
    int timeWindowX = [ATConstants timeScrollWindowX];
    
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    
    focusedLabelFrame = CGRectMake(timeWindowX - 43 + timeWindowWidth/2, timeWindowY, 50, 30);
    
    timeScrollWindowFrame = CGRectMake(timeWindowX,timeWindowY, timeWindowWidth,[ATConstants timeScrollWindowHeight]);
    
    
    //Add scrollable time window
    [self addTimeScrollWindow];
    
    
    
    
    //add focused Label. it is invisible most time, only used for animation effect when click left callout on annotation
    if (appDelegate.focusedDate == nil)
        appDelegate.focusedDate = [[NSDate alloc] init];
    if (self.focusedEventLabel != nil)
        [self.focusedEventLabel removeFromSuperview];
    self.focusedEventLabel = [[UILabel alloc] initWithFrame:focusedLabelFrame];
    self.focusedEventLabel.text = [NSString stringWithFormat:@" %@",[appDelegate.dateFormater stringFromDate: appDelegate.focusedDate]];
    NSLog(@"%@",self.focusedEventLabel.text);
    [self.focusedEventLabel setFont:[UIFont fontWithName:@"Arial" size:13]];
    self.focusedEventLabel.textColor = [UIColor blackColor];
    self.focusedEventLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:1.0f];
    self.focusedEventLabel.layer.cornerRadius=5;
    [self.focusedEventLabel setHidden:true];
    [self.view addSubview:self.focusedEventLabel];
    
    //Following is to focused on today when start the apps
    if (existingFocusedDate != nil)
        appDelegate.focusedDate = existingFocusedDate;
    else
        appDelegate.focusedDate = [[NSDate alloc] init];
    [self.timeScrollWindow setNewFocusedDateFromAnnotation:appDelegate.focusedDate needAdjusted:FALSE];
    
    
    //TODO tmpXcode5ScreenWidth should be decommissioned when use xcode6
    int tmpXcode5ScreenWidth = [ATConstants screenWidth];
    
    //NOTE the trick to set background image for a bar buttonitem
    if (locationbtn == nil)
        locationbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    else
        [locationbtn removeFromSuperview];
    //locationbtn.frame = CGRectMake([ATConstants screenWidth] - 50, 90, 30, 30);
    locationbtn.frame = CGRectMake(tmpXcode5ScreenWidth - 50, 90, 30, 30);
    [locationbtn setImage:[UIImage imageNamed:@"currentLocation.png"] forState:UIControlStateNormal];
    [locationbtn addTarget:self action:@selector(currentLocationClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:locationbtn];
    
    [self displayZoomLine];
}

//called by above displayTimeLineControls, as well as when zoom time
- (void) displayZoomLine
{
    CGRect timeZoomLineFrame;
    int timeWindowWidth = [ATConstants timeScrollWindowWidth];
    int timeWindowX = [ATConstants timeScrollWindowX];
    timeZoomLineFrame = CGRectMake(timeWindowX,self.view.bounds.size.height - [ATConstants timeScrollWindowHeight], timeWindowWidth,30);
    if (self.timeZoomLine != nil)
        [self.timeZoomLine removeFromSuperview]; //incase orientation change
    self.timeZoomLine = [[ATTimeZoomLine alloc] initWithFrame:timeZoomLineFrame];
    self.timeZoomLine.userInteractionEnabled = false;
    self.timeZoomLine.backgroundColor = [UIColor clearColor];
    self.timeZoomLine.mapViewController = self;
    [self.view addSubview:self.timeZoomLine];
    [self.timeZoomLine changeScaleLabelsDateFormat:self.startDate :self.endDate ];
    [self changeTimeScaleState];
}

- (void) addTimeScrollWindow
{
    if (self.timeScrollWindow != nil)
        [self.timeScrollWindow removeFromSuperview];
    self.timeScrollWindow = [[ATTimeScrollWindowNew alloc] initWithFrame:timeScrollWindowFrame];
    self.timeScrollWindow.parent = self;
    [self.view addSubview:self.timeScrollWindow];
    if (self.timeZoomLine != nil)
    {
        self.timeZoomLine.hidden = false;
    }
}

- (void) changeTimeScaleState
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self setSelectedPeriodLabel];
    NSDate* startDate = self.startDate;
    NSDate* endDate = self.endDate;
    if (appDelegate.selectedPeriodInDays <=30)
    {
        startDate = [ATHelper getYearStartDate:appDelegate.focusedDate];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setYear:1];
        endDate = [gregorian dateByAddingComponents:dateComponents toDate:startDate  options:0];
        
    }
    [self.timeZoomLine changeTimeScaleState:startDate :endDate :appDelegate.selectedPeriodInDays :appDelegate.focusedDate];
}

- (void) setSelectedPeriodLabel
{
    [self.timeZoomLine changeScaleText];
}
/*
 - (NSString*) getSelectedPeriodLabel
 {
 
 ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
 NSString* retStr=@"";
 if (appDelegate.selectedPeriodInDays == 7)
 {
 retStr = @"Span: 1week";
 }
 else if (appDelegate.selectedPeriodInDays == 30)
 {
 retStr = @"Span: 1mon";
 }
 else if (appDelegate.selectedPeriodInDays == 365)
 {
 retStr = @"Span: 1yr";
 }
 else if (appDelegate.selectedPeriodInDays == 3650)
 {
 retStr = @"Span: 10yrs";
 }
 else if (appDelegate.selectedPeriodInDays == 36500)
 {
 retStr = @"Span: 100yrs";
 }
 else if (appDelegate.selectedPeriodInDays == 365000)
 {
 retStr = @"Span:1000yrs";
 }
 return retStr;
 }
 */
- (void) toggleMapViewShowHideAction
{
    if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL)
    {
        self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
        [self animatedHidePart1];
        //TODO may need option to see if hide ann icon or not
        [self hideDescriptionLabelViews];
        [self.navigationController setNavigationBarHidden:true animated:TRUE];
    }
    else if (self.mapViewShowWhatFlag == MAPVIEW_HIDE_ALL)
    {
        self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
        [self animatedShowPart1];
        //TODO may need option to see if hide ann icon or not
        [self showDescriptionLabelViews:self.mapView];
        [self.navigationController setNavigationBarHidden:false animated:TRUE];
    }
    /**** I decide to not use three-steps
     if ([annotationToShowImageSet count] == 0) //if no selected nodes, use 2 step show/hide to have better user experience
     {
     if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL || self.mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
     {
     self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
     [self animatedHidePart1];
     [self hideDescriptionLabelViews];
     [self.navigationController setNavigationBarHidden:true animated:TRUE];
     }
     else if (self.mapViewShowWhatFlag == MAPVIEW_HIDE_ALL || self.mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
     {
     self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
     [self animatedShowPart1];
     [self showDescriptionLabelViews:self.mapView];
     [self.navigationController setNavigationBarHidden:false animated:TRUE];
     }
     }
     else //if has selected nodes, use 3-step show/hide
     {
     if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL)
     {
     self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
     [self animatedHidePart1];
     [self hideDescriptionLabelViews];
     [self.navigationController setNavigationBarHidden:true animated:TRUE];
     }
     else if (self.mapViewShowWhatFlag == MAPVIEW_HIDE_ALL)
     {
     self.mapViewShowWhatFlag = MAPVIEW_SHOW_PHOTO_LABEL_ONLY;
     [self animatedHidePart1];
     [self showDescriptionLabelViews:self.mapView];
     [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
     }
     else if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
     {
     self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
     [self animatedShowPart1];
     [self showDescriptionLabelViews:self.mapView];
     [self.navigationController setNavigationBarHidden:false animated:TRUE];
     }
     }
     */
}
- (void) hideTimeScrollAndNavigationBar:(BOOL)hideFlag
{
    if (hideFlag)
    {
        self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
        [self animatedHideTimeScrollAndNavigationBarPart1];
        [self.navigationController setNavigationBarHidden:true animated:TRUE];
    }
    else
    {
        self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
        [self animatedShowTimeScrollAndNavigationBarPart1];
        [self.navigationController setNavigationBarHidden:false animated:TRUE];
    }
}


- (void) animatedHideTimeScrollAndNavigationBarPart1
{
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    int timeLineY = timeWindowY;
    [self showBanner:self.gAdBannerView];
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^(void) {
                         self.timeScrollWindow.alpha = 0;
                         self.timeZoomLine.alpha = 0;
                         CGRect frame = self.timeScrollWindow.frame;
                         frame.origin.y = timeWindowY + 30;
                         [self.timeScrollWindow setFrame:frame];
                         frame = self.timeZoomLine.frame;
                         frame.origin.y = timeLineY + 30;
                         [self.timeZoomLine setFrame:frame];
                     }
                     completion:NULL];
}
- (void) animatedShowTimeScrollAndNavigationBarPart1
{
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    int timeLineY = timeWindowY;
    [self hideBanner:self.gAdBannerView];
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^(void) {
                         self.timeScrollWindow.alpha = 1;
                         self.timeZoomLine.alpha = 1;
                         switchEventListViewModeBtn.alpha = 1;
                         eventListView.alpha = 1;
                         
                         CGRect frame = self.timeScrollWindow.frame;
                         frame.origin.y = timeWindowY;
                         [self.timeScrollWindow setFrame:frame];
                         frame = self.timeZoomLine.frame;
                         frame.origin.y = timeLineY;
                         [self.timeZoomLine setFrame:frame];
                     }
                     completion:NULL];
}


- (void) animatedHidePart1
{
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    int timeLineY = timeWindowY;
    int hideX = - [ATConstants eventListViewCellWidth] * 0.9;
    [self showBanner:self.gAdBannerView];
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^(void) {
                         self.timeScrollWindow.alpha = 0;
                         self.timeZoomLine.alpha = 0;
                         eventListView.alpha = 0.9; //ad-hoc notice: cannot be 1 because tmpLbl show/hide depends on this value is 1 or less
                         switchEventListViewModeBtn.alpha = 0;
                         CGRect frame = self.timeScrollWindow.frame;
                         frame.origin.y = timeWindowY + 30;
                         [self.timeScrollWindow setFrame:frame];
                         frame = self.timeZoomLine.frame;
                         frame.origin.y = timeLineY + 30;
                         [self.timeZoomLine setFrame:frame];
                         
                         frame = eventListView.frame;
                         frame.origin.x = hideX;
                         [eventListView setFrame:frame];
                         frame = switchEventListViewModeBtn.frame;
                         frame.origin.x = hideX;
                         [switchEventListViewModeBtn setFrame:frame];
                     }
                     completion:NULL];
}
- (void) animatedShowPart1
{
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    int timeLineY = timeWindowY;
    [self hideBanner:self.gAdBannerView];
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^(void) {
                         self.timeScrollWindow.alpha = 1;
                         self.timeZoomLine.alpha = 1;
                         switchEventListViewModeBtn.alpha = 1;
                         eventListView.alpha = 1;
                         
                         CGRect frame = self.timeScrollWindow.frame;
                         frame.origin.y = timeWindowY;
                         [self.timeScrollWindow setFrame:frame];
                         frame = self.timeZoomLine.frame;
                         frame.origin.y = timeLineY;
                         [self.timeZoomLine setFrame:frame];
                         
                         frame = eventListView.frame;
                         frame.origin.x = 0;
                         [eventListView setFrame:frame];
                         frame = switchEventListViewModeBtn.frame;
                         frame.origin.x = 10;
                         [switchEventListViewModeBtn setFrame:frame];
                     }
                     completion:NULL];
}

- (void)handleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    NSTimeInterval interval = [[[NSDate alloc] init] timeIntervalSinceDate:regionChangeTimeStart];
    // NSLog(@"my tap ------regionElapsed=%f", interval);
    if (interval < 0.5)  //When scroll map, tap to stop scrolling should not flip the display of timeScrollWindow and description views
        return;
    if ([gestureRecognizer numberOfTouches] == 1)
    {
        [self toggleMapViewShowHideAction];
    }
}

- (void) addPinToMap:(NSString*)locatedAt :(CLLocationCoordinate2D) touchMapCoordinate
{
    ATDefaultAnnotation *pa = [[ATDefaultAnnotation alloc] initWithLocation:touchMapCoordinate];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    pa.eventDate = appDelegate.focusedDate;
    pa.description=NEWEVENT_DESC_PLACEHOLD;
    pa.address = locatedAt;
    [_mapView setAnnotations:@[pa]];
    if (newAddedPin != nil)
    {
        [_mapView removeAnnotation:newAddedPin];
        newAddedPin = pa;
    }
    else
        newAddedPin = pa;
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)oriAnn
{
    ATEventAnnotation * annotation =  [self getFirstUnderlyingAnnFromADCluster:oriAnn];

    ATEventAnnotation* ann = (ATEventAnnotation*)annotation;
    
    NSString* specialMarkerName = [ATHelper getMarkerNameFromDescText: ann.description];
    selectedAnnotationIdentifier = [self getImageIdentifier:ann: specialMarkerName]; //keep this line here
    if (annotation == nil) //TODO this will happen a lot when map zoom at level 1 or 2, so always show wihie flag/small red dot if this happen. This is a bug of ADClusterMapView I belive
    {
        //NSLog(@" -- nil annotation");
        if (switchEventListViewModeToVisibleOnMapFlag)
            selectedAnnotationIdentifier = @"small-red-ball-icon.png";
        else
            selectedAnnotationIdentifier = @"small-white-flag.png";
    }
    MKAnnotationView* annView;
    annView = [self getImageAnnotationView:selectedAnnotationIdentifier :oriAnn];
    annView.annotation = oriAnn;
    NSString *key=[NSString stringWithFormat:@"%f|%f",ann.coordinate.latitude, ann.coordinate.longitude];
    //keey list of red  annotations
    BOOL isSpecialMarkerInFocused = false;
    if (specialMarkerName != nil && ![selectedAnnotationIdentifier isEqualToString:[ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag :ann.address]] )
    {
        //Remember special marker annotation identifier has alpha value delimited by ":" if not selected. Selected do not have :
        if ([selectedAnnotationIdentifier rangeOfString:@":"].location == NSNotFound)
            isSpecialMarkerInFocused = true;
    }
    
    /*
     * Show annotation tmpLbl for annotation which is darkest color in time mode.
     *      In map mode, show tmpLbl if annotation on map is less than 10
     */
    if (!switchEventListViewModeToVisibleOnMapFlag)
    {
        if ([selectedAnnotationIdentifier isEqualToString: [ATConstants SelectedAnnotationIdentifier]] || isSpecialMarkerInFocused)
        {
            [self addTmpLblToMap:oriAnn];
        }
        else
        {
            UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
            if ( tmpLbl != nil)
            {
                [annotationToShowImageSet removeObjectForKey:key];
                [tmpLbl removeFromSuperview];
            }
        }
    }
    else //in map mode
    {
        if ([self zoomLevel] >= ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE)
        {
            [self addTmpLblToMap:oriAnn];
        }
        else
        {
            UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
            if ( tmpLbl != nil)
            {
                [annotationToShowImageSet removeObjectForKey:key];
                [tmpLbl removeFromSuperview];
            }
        }
    }
    /*
     if ([selectedAnnotationIdentifier isEqualToString:[ATConstants WhiteFlagAnnotationIdentifier]])
     {
     [[annView superview] sendSubviewToBack:annView];
     }
     */
    //annView.hidden = false;
    
    if (currentSelectedEvent != nil)
    {
        if ([currentSelectedEvent.uniqueId isEqualToString:ann.uniqueId])
        {
            selectedEventAnnInEventListView = annView;
        }
    }
    return annView;
}

 //TODO following use number as cluster annotation basically works, but has these issues:
 //   1. number of cluster show not quite always right especially after merge, seems orignalAnnotations() has problem
 //   2. select from event list view to high-light selected annotation not working well
 //So I comment it out for now
/*
- (MKAnnotationView *)mapView:(ADClusterMapView *)mapView viewForClusterAnnotation:(id<MKAnnotation>)annotation {
    ADClusterAnnotation* cluster = (ADClusterAnnotation*)annotation;
    NSArray* annList =  [cluster originalAnnotations];
    int cnt = [annList count];

    BOOL hasFocusedEvent = FALSE;
    for (ATEventAnnotation* x in annList)
    {
        if ([x.uniqueId isEqualToString:currentSelectedEvent.uniqueId])
        {
            hasFocusedEvent = TRUE;
            break;
        }
    }
    if (hasFocusedEvent)
    {
        NSLog(@"##### focused is %@", currentSelectedEvent.eventDesc);
    }
    NSString* identifier = [NSString stringWithFormat:@"clusterIdentifier_%d",cnt];
    MKAnnotationView * pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if (!pinView) {
        
        
NSLog(@"--new-- %d, %@, %@", cnt,cluster.cluster.title, identifier);
        
        UILabel* letterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,50)];
        letterLabel.text = [NSString stringWithFormat:@"%d",cnt];
        if (cnt == 0) //when zoom map to level 1, originalAnnotations() will have error
            letterLabel.text = @"..";
        letterLabel.layer.cornerRadius = 50;
        letterLabel.textAlignment = NSTextAlignmentCenter;
        letterLabel.layer.borderWidth = 2;
        letterLabel.font = [UIFont fontWithName:@"Arial-Bold" size:14];
        letterLabel.textColor = [UIColor redColor];

        
        pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                               reuseIdentifier:identifier];
        pinView.image = [self imageForView:letterLabel];
        pinView.canShowCallout = YES;
    }
    else {
        NSLog(@"--reu-- %d, %@, %@", cnt,cluster.cluster.title, identifier);
        pinView.annotation = annotation;
    }
    if (hasFocusedEvent)
    {
        UILabel* tmp = [[UILabel alloc] initWithFrame:CGRectMake(0,30,90,30)];
        tmp.text = @"Selected";
        tmp.backgroundColor = [UIColor whiteColor];
        //[pinView setBackgroundColor:[UIColor blueColor]];
        //[pinView setSelected:TRUE animated:TRUE];
        [pinView showToast:tmp];
    }
    return pinView;
}
*/
- (NSInteger)numberOfClustersInMapView:(ADClusterMapView *)mapView {
    return 120; //change this to smaller number if use viewForCluster...
}

- (UIImage *)imageForView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    
    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];  // if we have efficient iOS 7 method, use it ...
    else
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];         // ... otherwise, fall back to tried and true methods
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

//All View is a UIResponder, all UIresponder objects can implement touchesBegan
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
    currentTapTouchKey = 0;
    currentTapTouchMove = false;
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithLong:touch.view.tag];
    if ([annViewKey intValue] > 0) //tag is set in viewForAnnotation when instance tmpLbl
        currentTapTouchKey = [annViewKey intValue];
}

//Only tap to start event editor, when swipe map and happen to swipe on photo, do not start event editor
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithLong:touch.view.tag];
    if ([annViewKey intValue] > 0 && [annViewKey intValue] == currentTapTouchKey)
        currentTapTouchMove = true;
}
//touchesEnded does not work, touchesCancelled works
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithLong:touch.view.tag];
    if ([annViewKey intValue] > 0 && [annViewKey intValue] == currentTapTouchKey && !currentTapTouchMove)
    {
        MKAnnotationView* annView = [tmpLblUniqueIdMap objectForKey:annViewKey];
        
        selectedEventAnnOnMap = annView;
        selectedEventAnnDataOnMap = [annView annotation];
        [self startEventEditor:touch.view]; //changed from annView to touch.view for iOS 9
        [self toggleMapViewShowHideAction];
        [self refreshFocusedEvent];
    }
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    //didAddAnnotationViews is called when focused to date or move timewheel caused by addAnnotation:removedAnntationSet
    //views size usually is the number of ann on screen
    //NSLog(@"------ view size is %d ",[views count]);
    for (MKAnnotationView* annView in views)
    {
        ATEventAnnotation* ann = [annView annotation];
        if (![ann isKindOfClass:[ATAnnotationSelected class]])
            continue;
        if (ann.eventDate == nil)
            continue;
        NSString* specialMarkerName = [ATHelper getMarkerNameFromDescText: ann.description];
        NSString* identifer = [self getImageIdentifier:ann :specialMarkerName];
        //NSLog(@"  identifier is %@  date=%@",identifer, ann.eventDate);
        if ([identifer isEqualToString: [ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag :ann.address]])
            [[annView superview] sendSubviewToBack:annView];
        if ([identifer isEqualToString: [ATConstants SelectedAnnotationIdentifier]])
        {
            if (selectedAnnotationViewsFromDidAddAnnotation == nil)
            {
                selectedAnnotationViewsFromDidAddAnnotation = [[NSMutableSet alloc] init]; //cleaned in refreshAnnotation
            }
            [selectedAnnotationViewsFromDidAddAnnotation addObject:annView];
            [[annView superview] bringSubviewToFront:annView];
        }
    }
    //Above is try to hide white flag behind selected, works partially, but still have problem when zoom map. not sure what is reason
    
    
    [self showDescriptionLabelViews:self.mapView];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if (!firstTimeShowFlag) //always show all menus when first time show the view
    {
        [self hideDescriptionLabelViews];
        [self hideTimeScrollAndNavigationBar:true];
    }
    else
    {
        [self hideTimeScrollAndNavigationBar:false];
        firstTimeShowFlag = false;
    }
}

//After map scroll/zoom finish
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    //     although currently we already have optimized it a lot
    /*
     if (selectedAnnotationViewsFromDidAddAnnotation != nil && [self zoomLevel] >= ZOOM_LEVEL_TO_SEND_WHITE_FLAG_BEHIND_IN_REGION_DID_CHANGE)
     {
     //NSLog(@"    in regionDidChange  size=%d",[selectedAnnotationViewsFromDidAddAnnotation count]);
     for (MKAnnotationView* annView in selectedAnnotationViewsFromDidAddAnnotation)
     {
     [[annView superview] bringSubviewToFront:annView];
     }
     }
     */
    //******************** get annotations on the screen map and show in event list view
    //Do following if 1) map mode for event viewlist
    //                2) map zoom level is at state level
    //                3) eventlistview is not hidden
    
    eventListInVisibleMapArea = nil;
    if (switchEventListViewModeToVisibleOnMapFlag)
    {
        [self updateEventListViewWithEventsOnMap];
    }
    //******************
    
    if (animated) //means not caused by user scroll on map
    {
        [self goToNextCamera];
    }
    
    //NSLog(@"retion didChange, zoom level is %i", [self zoomLevel]);
    [self.timeZoomLine setNeedsDisplay];
    regionChangeTimeStart = [[NSDate alloc] init];
    //[self showDescriptionLabelViews:mapView];
    [self.mapView bringSubviewToFront:eventListView]; //so eventListView will always cover map marker photo/txt icon (tmpLbl)
    
    //show annotation info window programmatically, especially for when select on event list view
    if (currentSelectedEvent != nil)
    {
        ADClusterAnnotation* oriAnn = selectedEventAnnInEventListView.annotation;
        ATEventAnnotation* ann =  [self getFirstUnderlyingAnnFromADCluster:oriAnn];
        [self.mapView selectAnnotation:ann animated:YES];
        
        selectedEventAnnInEventListView = nil;
        currentSelectedEvent = nil;
    }
    
    //bookmark zoom level so app restart will restore state
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:[NSString stringWithFormat:@"%d",[self zoomLevel] ] forKey:@"BookmarkMapZoomLevel"];
    [userDefault synchronize];
    
    if (switchEventListViewModeToVisibleOnMapFlag)
    {
        //must have this, otherwise, in map mode, when deeply zoom-in, tmpLbl may not show because the way addTmpLbl() works in map mode
        if ([self zoomLevel] > ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE && prevZoomLevel <= ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE)
            [self refreshAnnotations];
    }
    else
    {
        //must have this, otherwise in timemode, tmpLbl will not move when move map
        if ([self zoomLevel] > ZOOM_LEVEL_TO_HIDE_EVENTLIST_VIEW)
            [self refreshAnnotations];
    }
    prevZoomLevel = [self zoomLevel];
    
}

-(ATEventAnnotation*) getFirstUnderlyingAnnFromADCluster:(ADClusterAnnotation*)oriAnn
{
    ATEventAnnotation * annotation = nil;
    if ([oriAnn isKindOfClass:[ADClusterAnnotation class]])
    {
        ADClusterAnnotation* annotation1 = (ADClusterAnnotation*)oriAnn;
        if ([oriAnn cluster] != nil) //TODO many not need this check
            annotation = [annotation1 originalAnnotations][0];
    }
    else
    {
        NSLog(@" ####### viewForAnnotation is not ADClusterAnnotation class");
    }
    return annotation;
}

-(void) addTmpLblToMap:(ADClusterAnnotation*)oriAnn
{
    ATEventAnnotation * annotation = [self getFirstUnderlyingAnnFromADCluster:oriAnn];
    MKAnnotationView* annView;
    annView = [self getImageAnnotationView:selectedAnnotationIdentifier :oriAnn];
    annView.annotation = oriAnn;
    NSString *key=[NSString stringWithFormat:@"%f|%f",annotation.coordinate.latitude, annotation.coordinate.longitude];
    UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
    if (tmpLbl == nil)
    {
        CGPoint annotationViewPoint = [self.mapView convertCoordinate:annView.annotation.coordinate
                                                        toPointToView:self.mapView];
        
        //NSLog(@"x=%f  y=%f",annotationViewPoint.x, annotationViewPoint.y);
        tmpLbl = [[UILabel alloc] initWithFrame:CGRectMake(annotationViewPoint.x -20, annotationViewPoint.y+5, THUMB_WIDTH, THUMB_HEIGHT)]; //todo MFTopAlignedLabel
        if (annotation.eventType == EVENT_TYPE_HAS_PHOTO) //somehow it is a big number before save to db, need more study why not 1
        {
            NSString* photoFileName = annotation.uniqueId;
            NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];

            UIImage* img = [ATHelper readPhotoThumbFromFile:photoFileName thumbUrl:[ATHelper getBlogThumbUrlFromEventDesc: annotation.description]];
            if (img != nil)
            {
                UIImageView* imgView = [[UIImageView alloc]initWithImage: img];
                [imgView setAlpha:0.85];
                imgView.tag = HAVE_IMAGE_INDICATOR; //later used to get subview
                /*
                 imgView.contentMode = UIViewContentModeScaleAspectFill;
                 imgView.clipsToBounds = YES;
                 imgView.layer.cornerRadius = 8;
                 imgView.layer.borderColor = [UIColor brownColor].CGColor;
                 imgView.layer.borderWidth = 1;
                 */
                
                //[imgView setFrame:CGRectMake(-30, -25, 100, 80)];
                tmpLbl.text = @"                             \r\r\r\r\r\r";
                tmpLbl.backgroundColor = [UIColor clearColor];
                imgView.frame = CGRectMake(imgView.frame.origin.x, imgView.frame.origin.y, tmpLbl.frame.size.width, tmpLbl.frame.size.height);
                //[tmpLbl setAutoresizesSubviews:true];
                [tmpLbl addSubview: imgView];
                tmpLbl.layer.cornerRadius = 8;
                tmpLbl.layer.borderWidth = 1;
            }
            else
            {
                //xxxxxx TODO if user switch source from server, photo may not be in local yet, then
                //             should display text only and add download request in download queue
                // ########## This is a important lazy download concept #############
                tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
                tmpLbl.text = [NSString stringWithFormat:@" %@", [ATHelper clearMakerAllFromDescText: annotation.description ]];
                tmpLbl.layer.cornerRadius = 8;
                tmpLbl.layer.borderWidth = 1;
            }
        }
        else
        {
            tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
            NSArray* tmpArr = [annotation.description componentsSeparatedByString:@"http"];
            tmpLbl.text = tmpArr[0];
            tmpLbl.layer.cornerRadius = 8;
            tmpLbl.layer.borderWidth = 1;
        }
        tmpLbl.layer.borderColor = [UIColor lightGrayColor].CGColor;
        tmpLbl.userInteractionEnabled = YES;
        [tmpLblUniqueIdMap setObject:annView forKey:[NSNumber numberWithInt:tmpLblUniqueMapIdx ]];
        tmpLbl.tag = tmpLblUniqueMapIdx;
        tmpLblUniqueMapIdx++;
        //tmpLbl.textAlignment = UITextAlignmentCenter;
        tmpLbl.lineBreakMode = NSLineBreakByWordWrapping;
        
        
        [self setDescLabelSizeByZoomLevel:tmpLbl];
        if ([self showAnnotationTmpLbl])
            tmpLbl.hidden = true;
        //tmpLbl.alpha = 0;
        else
            //tmpLbl.hidden=false;
            tmpLbl.hidden=false;
        
        [annotationToShowImageSet setObject:tmpLbl forKey:key];
        [self.view addSubview:tmpLbl];
        
    }
}

- (BOOL)showAnnotationTmpLbl
{
    BOOL ret = false;
    if (switchEventListViewModeToVisibleOnMapFlag)
        ret = [self zoomLevel] <= ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE;
    else
        ret = [self zoomLevel] <= ZOOM_LEVEL_TO_HIDE_DESC;
    return ret;
}

//////// From WWDC 2013 video "Map Kit in Perspective"
-(void)goToNextCamera
{
    if (animationCameras.count == 0) {
        return;
    }
    MKMapCamera * nextCamera = [animationCameras firstObject];
    [animationCameras removeObjectAtIndex:0];
    ////***** IMPORTANT change I made: NSAnimationContext from the video does not work, I found use UIView animateWithDuration
    [UIView animateWithDuration:1.0f animations:^{
        self.mapView.camera = nextCamera;;
    } completion:NULL];
    
}
-(void) performShortCmeraAnimation:(MKMapCamera*)end
{
    CLLocationCoordinate2D startingCoordinate = self.mapView.centerCoordinate;
    MKMapPoint startingPoint = MKMapPointForCoordinate(startingCoordinate);
    MKMapPoint endingPoint = MKMapPointForCoordinate(end.centerCoordinate);
    
    MKMapPoint midPoint = MKMapPointMake(startingPoint.x + ((endingPoint.x - startingPoint.x)/2.0),
                                         startingPoint.y + ((endingPoint.y -startingPoint.y)/2.0));
    CLLocationCoordinate2D midCoordinate = MKCoordinateForMapPoint(midPoint);
    CLLocationDistance midAltitude = end.altitude *4;
    
    MKMapCamera *midCamera = [MKMapCamera cameraLookingAtCenterCoordinate:end.centerCoordinate
                                                        fromEyeCoordinate:midCoordinate eyeAltitude:midAltitude];
    animationCameras = [[NSMutableArray alloc] init];
    [animationCameras addObject:midCamera];
    [animationCameras addObject:end];
    [self goToNextCamera]; //this will kickout animation
}
-(void) performLongCmeraAnimation:(MKMapCamera*)end
{
    MKMapCamera *start = self.mapView.camera;
    CLLocation *startLocation = [[CLLocation alloc] initWithCoordinate:start.centerCoordinate
                                                              altitude:start.altitude
                                                    horizontalAccuracy:0
                                                      verticalAccuracy:0
                                                             timestamp:nil];
    CLLocation *endLocation = [[CLLocation alloc] initWithCoordinate:end.centerCoordinate
                                                            altitude:end.altitude
                                                  horizontalAccuracy:0
                                                    verticalAccuracy:0
                                                           timestamp:nil];
    CLLocationDistance distance = [startLocation distanceFromLocation:endLocation];
    CLLocationDistance midAltitude = distance;
    MKMapCamera *midCamera1 = [MKMapCamera cameraLookingAtCenterCoordinate:start.centerCoordinate
                                                         fromEyeCoordinate:start.centerCoordinate
                                                               eyeAltitude:midAltitude];
    MKMapCamera *midCamera2 = [MKMapCamera cameraLookingAtCenterCoordinate:end.centerCoordinate
                                                         fromEyeCoordinate:end.centerCoordinate
                                                               eyeAltitude:midAltitude];
    animationCameras = [[NSMutableArray alloc] init];
    [animationCameras addObject:midCamera1];
    [animationCameras addObject:midCamera2];
    [self goToNextCamera];
    
}
-(void)goToCoordinate:(CLLocationCoordinate2D)coord
{
    //TODO end point eyeAltitude should vary according to start/end distance. If distance is too small then eyeAltitude should narro to 500
    MKMapCamera *end = [MKMapCamera cameraLookingAtCenterCoordinate:coord
                                                  fromEyeCoordinate:coord
                                                        eyeAltitude:40000];
    
    
    MKMapCamera *start = self.mapView.camera;
    CLLocation *startLocation = [[CLLocation alloc] initWithCoordinate:start.centerCoordinate
                                                              altitude:start.altitude
                                                    horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
    CLLocation *endLocation = [[CLLocation alloc] initWithCoordinate:end.centerCoordinate
                                                            altitude:end.altitude
                                                  horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
    CLLocationDistance distance = [startLocation distanceFromLocation:endLocation];
    
    //TODO disable swirl effect when close
    if (distance <300) //if click on same event (or event close to eachother, zoom in)
    {
        end.altitude = 500;
        end.pitch = 55; //show 3d effect so building will show
    }
    else if (distance <1500) //if click on same event (or event close to eachother, zoom in)
    {
        end.altitude = 3000;
    }
    else if (distance <3000) //if click on same event (or event close to eachother, zoom in)
    {
        end.altitude = 5400;
    }
    //now filter based on distance
    if (distance < 50000) {
        [self.mapView setCamera:end animated:YES];
        return;
    }
    if (distance < 150000) {
        [self performShortCmeraAnimation:end];
        return;
    }
    [self performLongCmeraAnimation:end];
}
//////// end code from WWDC "Map Kit In Perspective"

- (void)updateEventListViewWithEventsOnMap
{
    if (eventListInVisibleMapArea == nil)
        eventListInVisibleMapArea = [[NSMutableArray alloc] init];
    else
        [eventListInVisibleMapArea removeAllObjects];
    
    if ([self zoomLevel] >= ZOOM_LEVEL_TO_HIDE_EVENTLIST_VIEW)
    {
        
        NSSet *nearbySet = [self.mapView annotationsInMapRect:self.mapView.visibleMapRect];
        NSMutableArray* uniqueIdSet = [[NSMutableArray alloc] init];
        for(MKAnnotationView* annView in nearbySet)
        {
            if ([annView isKindOfClass:[MKUserLocation class]])
                continue; //filter out MKUserLocation pin
            if ([annView isKindOfClass:[ADClusterAnnotation class]])
            {
                ADClusterAnnotation* annView1 = (ADClusterAnnotation*)annView;
                
                ATEventAnnotation* ann = [self getFirstUnderlyingAnnFromADCluster:annView1];
                if (ann.uniqueId != nil)
                    [uniqueIdSet addObject:ann.uniqueId];
            }
        }
        //big performance hit
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSArray* allEvents = [appDelegate eventListSorted];
        NSInteger sizeInMap = [uniqueIdSet count];
    
        int cnt = 0;
        for(ATEventDataStruct* evt in allEvents)
        {
            if ([uniqueIdSet containsObject: evt.uniqueId])
            {
                [eventListInVisibleMapArea insertObject:evt atIndex:0];
                cnt ++;
            }
            if (cnt == sizeInMap) //to improve performance for most case
                break;
        }
        
    }
    if (eventListView.hidden == false)
        [self refreshEventListView:false];
    
}
- (void) showDescriptionLabelViews:(MKMapView*)mapView
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *focuseKey=[NSString stringWithFormat:@"%f|%f",appDelegate.focusedEvent.lat, appDelegate.focusedEvent.lng];
    for (id key in annotationToShowImageSet) {
        NSArray *splitArray = [key componentsSeparatedByString:@"|"];
        UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
        if ([key isEqualToString:focuseKey])
        {
            tmpLbl.backgroundColor = [UIColor colorWithRed:1.0 green:0.7 blue:0.7 alpha:0.4];
            tmpLbl.layer.borderColor = [UIColor redColor].CGColor;
        }
        else
        {
            tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
            tmpLbl.layer.borderColor = [UIColor lightGrayColor].CGColor;
        }
        CLLocationCoordinate2D coordinate;
        coordinate.latitude=[splitArray[0] doubleValue];
        coordinate.longitude = [splitArray[1] doubleValue];
        CGPoint annotationViewPoint = [mapView convertCoordinate:coordinate
                                                   toPointToView:mapView];
        if (TRUE) //self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL || self.mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
        {  //because mapRegion will call this function, so only show label this condition match
            bool tooCloseToShowFlag = false;
            
            for (NSValue* val in selectedAnnotationNearestLocationList)
            {
                CGPoint p = [val CGPointValue];
                CGFloat xDist = (annotationViewPoint.x - p.x);
                CGFloat yDist = (annotationViewPoint.y - p.y);
                CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
                if (distance < DISTANCE_TO_HIDE)
                {
                    tooCloseToShowFlag = true;
                    break;
                }
            }
            if (tooCloseToShowFlag && ![key isEqualToString:focuseKey])
            {
                tmpLbl.hidden = true;
                tmpLbl.alpha = 0.3;
                continue;
            }
            else
            {
                tmpLbl.hidden = false;
                [selectedAnnotationNearestLocationList addObject: [NSValue valueWithCGPoint:annotationViewPoint]];
            }
            
            [self setDescLabelSizeByZoomLevel:tmpLbl];
            CGSize size = tmpLbl.frame.size;
            [tmpLbl setFrame:CGRectMake(annotationViewPoint.x -20, annotationViewPoint.y+5, size.width, size.height)];
            if ([self showAnnotationTmpLbl])
            {
                
                tmpLbl.hidden = true;
                tmpLbl.alpha = 0.3;
            }
            else
            {
                float alpha = 1.0;
                if (eventListView.alpha < 1)
                    alpha = 0.2; //intentionally make it 0.2 instead of 0.3 after move map in hide mode
                [UIView animateWithDuration:0.5
                                      delay:0.0
                                    options:UIViewAnimationCurveEaseOut
                                 animations:^(void) {
                                     tmpLbl.alpha = alpha;
                                     tmpLbl.hidden = false; //// add after retreat
                                 }
                                 completion:NULL];
            }

        }
    }
    [selectedAnnotationNearestLocationList removeAllObjects];
}

- (void) hideDescriptionLabelViews
{
    for (id key in annotationToShowImageSet) {
        UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void) {
                             tmpLbl.alpha = 0.3;
                         }
                         completion:NULL];
    }
}
-(void) setDescLabelSizeByZoomLevel:(UILabel*)tmpLbl
{
    int zoomLevel = [self zoomLevel];
    CGSize expectedLabelSize = [tmpLbl.text sizeWithFont:tmpLbl.font
                                       constrainedToSize:tmpLbl.frame.size lineBreakMode:NSLineBreakByWordWrapping];
    tmpLbl.numberOfLines = 0;
    tmpLbl.font = [UIFont fontWithName:@"Arial" size:11];
    int labelWidth = 50;
    int labelHeight = 42;
    if ([self showAnnotationTmpLbl])
    {
        //tmpLbl.hidden = true; //do nothing, caller already hidden the label;
        tmpLbl.alpha = 0;
    }
    else if (zoomLevel <= 8)
    {
        tmpLbl.numberOfLines=4;
    }
    else if (zoomLevel <= 10)
    {
        tmpLbl.numberOfLines=4;
        labelWidth = 60;
        labelHeight = 47;
    }
    else if (zoomLevel <= 13)
    {
        tmpLbl.font = [UIFont fontWithName:@"Arial" size:13];
        tmpLbl.numberOfLines=5;
        labelWidth = 90;
        labelHeight = 68;
    }
    else
    {
        tmpLbl.font = [UIFont fontWithName:@"Arial" size:14];
        tmpLbl.numberOfLines=5;
        labelWidth = 100;
        labelHeight = 70;
    }
    
    //HONG if height > CONSTANT, then do not change, I do not like biggerImage unless in a big zooing
    CGRect newFrame = tmpLbl.frame;
    newFrame.size.height = labelHeight;
    newFrame.size.width=labelWidth;
    
    tmpLbl.frame = newFrame;
    //Add above labelHeight and remove this line for iOS 9 otherwise height will always 0 --- [tmpLbl sizeToFit];
    UIImageView* imgView = (UIImageView*)[tmpLbl viewWithTag:HAVE_IMAGE_INDICATOR];
    if (imgView != nil)
    {
        imgView.frame = CGRectMake(imgView.frame.origin.x, imgView.frame.origin.y, tmpLbl.frame.size.width, tmpLbl.frame.size.height);
    }
    
}

- (int) zoomLevel {
    MKCoordinateRegion region = self.mapView.region;
    
    double centerPixelX = [self longitudeToPixelSpaceX: region.center.longitude];
    double topLeftPixelX = [self longitudeToPixelSpaceX: region.center.longitude - region.span.longitudeDelta / 2];
    
    double scaledMapWidth = (centerPixelX - topLeftPixelX) * 2;
    CGSize mapSizeInPixels = self.mapView.bounds.size;
    double zoomScale = scaledMapWidth / mapSizeInPixels.width;
    double zoomExponent = log(zoomScale) / log(2);
    double zoomLevel = 21 - zoomExponent;
    
    return zoomLevel;
}
- (MKAnnotationView*) getImageAnnotationView:(NSString*)annotationIdentifier :(id <MKAnnotation>)annotation
{
        MKAnnotationView* annView = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (!annView)
        {
            MKAnnotationView* customPinView = [[MKAnnotationView alloc]
                                               initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
            // NSLog(@"========= img %@",annotationIdentifier);
            NSInteger alphaValueLoc = [annotationIdentifier rangeOfString:@":"].location;
            float alphaValue = 1.0;
            if ( alphaValueLoc != NSNotFound)
            {
                NSString* origianlStr = annotationIdentifier;
                annotationIdentifier = [annotationIdentifier substringToIndex:alphaValueLoc];
                NSString* alphaValueStr = [origianlStr substringFromIndex:alphaValueLoc + 1];
                alphaValue = [alphaValueStr floatValue];
                //NSLog(@" ---- ann=%@,  alpha=%@",annotationIdentifier, alphaValueStr);
            }
            UIImage *markerImage = [UIImage imageNamed:annotationIdentifier];
            customPinView.image = markerImage;
            [customPinView setAlpha:alphaValue]; //introduced when add static marker (hinted by description text ==start== etc
            customPinView.canShowCallout = YES;
            
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            rightButton.accessibilityLabel=@"right";
            customPinView.rightCalloutAccessoryView = rightButton;
            
            UIButton* leftButton = [UIButton buttonWithType:UIButtonTypeInfoLight ];
            [leftButton setTintColor:[UIColor clearColor]];
            [leftButton setBackgroundImage:[UIImage imageNamed:@"focuseIcon.png"] forState:UIControlStateNormal];
            
            leftButton.accessibilityLabel=@"left";
            customPinView.leftCalloutAccessoryView = leftButton;
            
            return customPinView;
        }
        else
            //NSLog(@"+++++++++ resuse %@ annotation at %@",annotationIdentifier, [annotation title]);

        return annView;
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    selectedEventAnnOnMap = view;
    selectedEventAnnDataOnMap = [view annotation];
    if ([control.accessibilityLabel isEqualToString: @"right"]){
        [self startEventEditor:view];
    }
    [self refreshFocusedEvent];
}

- (void) refreshFocusedEvent
{
    //if (selectedEventAnnOnMap == nil || switchEventListViewModeToVisibleOnMapFlag)
    //    return; //do not focuse when popup event editor in map event list mode for two reason:
    // 1. conceptually it is not neccessary   2. there is a small but if do so
    //MKMapView* mapView = self.mapView;
    MKAnnotationView* view = selectedEventAnnOnMap;
    //need use base class ATEventAnnotation here to handle call out for all type of annotation
    ATEventAnnotation* ann = [self getFirstUnderlyingAnnFromADCluster:[view annotation]];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    /********** remove annimation of focuse event, I think it is not neccessary
     //get view location of an annotation
     CGPoint annotationViewPoint = [mapView convertCoordinate:view.annotation.coordinate
     toPointToView:mapView];
     CGRect newFrame = CGRectMake(annotationViewPoint.x,annotationViewPoint.y,0,0);//self.focusedEventLabel.frame;
     self.focusedEventLabel.frame = newFrame;
     self.focusedEventLabel.text = [NSString stringWithFormat:@" %@",[appDelegate.dateFormater stringFromDate: ann.eventDate]];
     [self.focusedEventLabel setHidden:false];
     [UIView transitionWithView:self.focusedEventLabel
     duration:0.5f
     options:UIViewAnimationCurveEaseInOut
     animations:^(void) {
     self.focusedEventLabel.frame = focusedLabelFrame;
     }
     completion:^(BOOL finished) {
     // Do nothing
     [self.focusedEventLabel setHidden:true];
     }];
     ***********/
    selectedAnnotationIdentifier = [self getImageIdentifier:ann :ann.description];
    ATEventDataStruct* ent = [[ATEventDataStruct alloc] init];
    ent.address = ann.address;
    ent.lat = ann.coordinate.latitude;
    ent.lng = ann.coordinate.longitude;
    ent.eventDate = ann.eventDate;
    ent.eventType = ann.eventType;
    ent.eventDesc = ann.description;
    ent.uniqueId = ann.uniqueId;
    appDelegate.focusedEvent = ent;
    
    [self setNewFocusedDateAndUpdateMap:ent needAdjusted:TRUE]; //No reason, have to do focusedRow++ when focused a event in time wheel
    self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
    self.timeScrollWindow.hidden=false;
    eventListView.hidden = false;
    switchEventListViewModeBtn.hidden = false;
    self.timeZoomLine.hidden = false;
    self.navigationController.navigationBarHidden = false;
    appDelegate.focusedEvent = ent;
    [self refreshEventListView:false];
    //bookmark selected event
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSUInteger idx = [appDelegate.eventListSorted indexOfObject:ent];
    [userDefault setObject:[NSString stringWithFormat:@"%lu",(unsigned long)idx ] forKey:@"BookmarkEventIdx"];
    [userDefault synchronize];
}

- (void) startEventEditor:(UIView*)view
{
    ATEventAnnotation* ann = [self getFirstUnderlyingAnnFromADCluster: selectedEventAnnDataOnMap]; // [view annotation];
    if (ann == nil)
        return;
    NSArray* tmp = [ann.description componentsSeparatedByString:@"\n"];
    NSString* blogUrl = tmp[1];
    
    [self displayPageOnRightRevealPanel:blogUrl];
}

- (void) displayPageOnRightRevealPanel:(NSString*) blogUrl
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (self.webViewController == nil)
    {
        self.webViewController = [[ATTravelWebViewController alloc] init];
        self.webViewController.webView.navigationDelegate = self;
    }
    else
        [self.webViewController setFrame];

    SWRevealViewController *revealController = [self revealViewController];
    //
    //TODO if current revealed right side is preference, then do nothing?
    //
    revealController.rightViewController = self.webViewController;
    revealController.rightViewRevealWidth = [ATConstants revealViewEventEditorWidth];
    
    if (!appDelegate.rightSideMenuRevealedFlag)
        [revealController rightRevealToggle:nil];
    else
    {
        [revealController rightRevealToggle:nil];
        [revealController rightRevealToggle:nil];
    }

    //[self.navigationController pushViewController:self.webViewController animated:true];

    //has to set value here after above presentXxxxx method, otherwise the firsttime will display empty text
    
    NSString* htmlStr = @"<html><style type=\"text/css\" media=\"screen\"><!--#content\
    {\
    position: absolute;\
    top: 50%;\
    left: 50%;\
    width: 400px;\
    height: 70px\
    }\
    --></style>\
    </head>\
    <body>\
    <div id=\"content\">\
        <center><img src=\"Hourglass-icon.png\"></center>\
        <br>\
        <font color=\"DarkGray\" size=\"11\">Loading ... <br>正在加载 。。。</font>\
    </div>\
    </body>\
    </html>";
    
    if ([blogUrl isEqualToString: prevBlogUrl])
        return;
    else
        prevBlogUrl = blogUrl;
    
    waitPageLoadFlag = true;
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    [self.webViewController.webView loadHTMLString:htmlStr baseURL:baseURL];

}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (waitPageLoadFlag)
    {
        waitPageLoadFlag = false;
        NSURL *url = [NSURL URLWithString:prevBlogUrl];
        NSURLRequest *requestURL = [NSURLRequest requestWithURL:url];
        [self.webViewController.webView loadRequest:requestURL];
    }
}
- (void)webView:(WKWebView *)webView
didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSString* htmlStr = @"<html><style type=\"text/css\" media=\"screen\"><!--#content\
    {\
    position: absolute;\
    top: 50%;\
    left: 50%;\
    width: 300px;\
    height: 70px\
    }\
    --></style>\
    </head>\
    <body>\
    <div id=\"content\">\
    <font color=\"DarkGray\" size=\"11\">Network Unavailable<br>没有网路联接</font>\
    </div>\
    </body>\
    </html>";
    [self.webViewController.webView stopLoading];
    prevBlogUrl = @"";
    [self.webViewController.webView loadHTMLString:htmlStr baseURL:  nil];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error
{
     NSLog(@"22222");
}

//always start from focusedEvent
- (void) showOverlays
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    ATEventDataStruct* focusedEvent = appDelegate.focusedEvent;
    
    if (overlaysToBeCleaned != nil)
        [self.mapView removeOverlays:overlaysToBeCleaned];
    if (focusedEvent == nil)
        return;
    
    if (overlaysToBeCleaned == nil)
        overlaysToBeCleaned = [[NSMutableArray alloc] init];
    else
        [overlaysToBeCleaned removeAllObjects];
    
    //first draw a circle on selected event
    CLLocationCoordinate2D workingCoordinate;
    workingCoordinate.latitude = focusedEvent.lat;
    workingCoordinate.longitude = focusedEvent.lng;
    if (focusedAnnotationIndicator == nil)
        focusedAnnotationIndicator = [[ATAnnotationFocused alloc] init];
    else
        [self.mapView removeAnnotation:focusedAnnotationIndicator];
    focusedAnnotationIndicator.coordinate = workingCoordinate;
    /////TODO exception with cluster [self.mapView addAnnotation:focusedAnnotationIndicator];
    
    
    //following prepare mkPoi
    
    NSArray* overlays = [self prepareOverlays:focusedEvent];
    
    //TODO ### have problem here for Reader
    [overlaysToBeCleaned addObjectsFromArray:overlays];
    
    
    
    // http://stackoverflow.com/questions/15061207/how-to-draw-a-straight-line-on-an-ios-map-without-moving-the-map-using-mkmapkit
    //add line by line, instead add all lines in one MKPolyline object, because I want to draw color differently in viewForOverlay
    NSUInteger size = [overlays count];
    for(int i = 0; i < size; i++)
    {
        MKPolygon* polygon = overlays[i];
        [self.mapView addOverlay:polygon];
    }
}

- (NSArray*) prepareOverlays:(ATEventDataStruct*)ent
{
    NSMutableArray* returnOverlays = [[NSMutableArray alloc] init];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray* overlays = [appDelegate.overlayCollection objectForKey:ent.uniqueId];
    if (overlays == nil)
        return nil;
    for (NSArray* polygonLines in overlays)
    {
        if (polygonLines == nil || [polygonLines count] == 0)
            continue;
        NSArray* shareOverlayArray = polygonLines;
        if ([polygonLines count] == 1) //this will be case for ShareOverlay key
        {
            NSString* key = [polygonLines[0] lowercaseString]; //make key case insensitive
            shareOverlayArray = [appDelegate.sharedOverlayCollection objectForKey:key];
            if (shareOverlayArray == nil || [shareOverlayArray count] <= 2)
            {
                NSLog(@"  ##### shareOverlay %@ has data issue ", polygonLines[0]);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ShareOverlay data issue with following shareOverlay key:",nil) message:NSLocalizedString(polygonLines[0],nil)
                                                               delegate:self  cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                [alert show];
            }
        }
        //MKMapPoint* overlayRegion2D = malloc(sizeof(CLLocationCoordinate2D) * [regionLineArray count]);
        CLLocationCoordinate2D* overlayRegion2D = malloc(sizeof(CLLocationCoordinate2D) * [shareOverlayArray count]);
        
        for (int i=0; i<[shareOverlayArray count];i++)
        {
            NSString* lineStr = shareOverlayArray[i];
            //in AppDelegate, lineStr are processed to be valid, so no need to check nil, empty here
            NSArray* latlng = [lineStr componentsSeparatedByString:@","];
            if (latlng == nil)
            {
                NSLog(@" ###### ATViewController latlng data has error %@",lineStr);
                CLLocationCoordinate2D workingCoordinate;
                workingCoordinate.latitude = 0.0;
                workingCoordinate.longitude = 0.0;
                //overlayRegion2D[i] = MKMapPointForCoordinate(workingCoordinate);
                overlayRegion2D[i] = workingCoordinate;
            }
            else
            {
                //Note, do not know why, the kml file has lat/lng in postion 1, 0
                double lat = [latlng[1] doubleValue];
                double lng = [latlng[0] doubleValue];
                CLLocationCoordinate2D workingCoordinate;
                
                workingCoordinate.latitude = lat;
                workingCoordinate.longitude = lng;
                //overlayRegion2D[i] = MKMapPointForCoordinate(workingCoordinate);
                overlayRegion2D[i] = workingCoordinate;
            }
        }
        
        MKPolygon* polygon = [MKPolygon polygonWithCoordinates:overlayRegion2D count:[shareOverlayArray count]];
        free(overlayRegion2D);
        [returnOverlays addObject:polygon];
    }
    return returnOverlays;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if([overlay isKindOfClass:[MKPolygon class]]){
        MKPolygonView *view = [[MKPolygonView alloc] initWithOverlay:overlay];
        view.lineWidth=0;
        view.strokeColor=[UIColor clearColor];
        view.fillColor=[[UIColor blackColor] colorWithAlphaComponent:0.3];
        return view;
    }
    return nil;
}

//I could not explain, but for tap left annotation button to focuse date, have to to do focusedRow++ in ATTimeScrollWindowNew
- (void) setNewFocusedDateAndUpdateMap:(ATEventDataStruct*) ent needAdjusted:(BOOL)needAdjusted
{
    currentSelectedEvent = ent;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.focusedDate = ent.eventDate;
    [self.timeScrollWindow setNewFocusedDateFromAnnotation:ent.eventDate needAdjusted:needAdjusted];
    [self refreshAnnotations];
    //[self setMapCenter:ent];
}
- (void) setNewFocusedDateAndUpdateMapWithNewCenter:(ATEventDataStruct*) ent :(int)zoomLevel
{
    [self setNewFocusedDateAndUpdateMap:ent needAdjusted:FALSE];
    [self setMapCenter:ent :zoomLevel];
}
//Mostly called from time wheel (ATTimeScrollWindowNew
- (void) refreshAnnotations //Refresh based on new forcusedDate / selectedPeriodInDays
{
    selectedAnnotationViewsFromDidAddAnnotation = nil;
    //NSLog(@"refreshAnnotation called");
    NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy ] ;
    //TODO filter out those annotation outside the periodRange ...
    [ annotationsToRemove removeObject:self.mapView.userLocation ] ;
    [ self.mapView removeAnnotations:annotationsToRemove ] ;
    if (annotationsToRemove != nil)
    {
        //NSLog(@"########  annotationRemoved #######");
        [self.mapView setAnnotations:annotationsToRemove];
    }
    [self cleanAnnotationToShowImageSet];
    if (tutorialView != nil)
        [tutorialView updateDateText];
    //[2014-01-06]
    //*** By moving following to didAddAnnotation(), I solved the issue that forcuse an event to date cause all image to show, because above [self.mapView addAnnotations:...] will run parallel to bellow [self showDescr..] while this depends on annotationToShowImageSet prepared in viewForAnnotation, thuse cause problem
    //[self showDescriptionLabelViews:self.mapView];
}

- (NSString*)getImageIdentifier:(ATEventAnnotation *)ann :(NSString*)specialMarkerName
{
    // NSLog(@"  --------------- %u", debugCount);
    //debugCount = debugCount + 1;
    NSDate* eventDate = ann.eventDate;
    
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.focusedDate == nil) //set in annotation Left button click
        appDelegate.focusedDate = [[NSDate alloc] init];
    float segmentDistance = fabsf([self getDistanceFromFocusedDate:eventDate]);
    if (specialMarkerName != nil)
    {
        NSString* pngNameWithAlpha = [NSString stringWithFormat:@"marker_%@", specialMarkerName ];
        UIImage *tempImage = [UIImage imageNamed:pngNameWithAlpha];
        if (!tempImage) {
            pngNameWithAlpha = @"marker_star.png";
        }
        //if off-focuse, append image alpha value
        if (segmentDistance > 1 && segmentDistance <=2)
            pngNameWithAlpha = [NSString stringWithFormat:@"%@:0.7",pngNameWithAlpha];
        else if (segmentDistance > 2 && segmentDistance <=3)
            pngNameWithAlpha = [NSString stringWithFormat:@"%@:0.6",pngNameWithAlpha];
        else if (segmentDistance > 3 && segmentDistance <=4)
            pngNameWithAlpha = [NSString stringWithFormat:@"%@:0.5",pngNameWithAlpha];
        else if (segmentDistance > 4 && segmentDistance <= 5)
            pngNameWithAlpha = [NSString stringWithFormat:@"%@:0.4",pngNameWithAlpha ];
        else if (segmentDistance > 5)
            return [ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag :ann.address];
        
        return pngNameWithAlpha;
    }
    // For regular marker, I tried to use alpha instead of different marker image, but the looks on view is bad, so keep it following way
    
    if (switchEventListViewModeToVisibleOnMapFlag)
    {
        if (segmentDistance <= 5 && segmentDistance >= -5)
            return @"marker-heritage-selected.png";
        else
            return [ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag :ann.address];
    }
    else
    {
        if (segmentDistance >= -1 && segmentDistance <= 1)
            return [ATConstants SelectedAnnotationIdentifier];
        if (segmentDistance > 1 && segmentDistance <=2)
            return [ATConstants After1AnnotationIdentifier];
        if (segmentDistance > 2 && segmentDistance <=3)
            return [ATConstants After2AnnotationIdentifier];
        if (segmentDistance > 3 && segmentDistance <= 4)
            return [ATConstants After3AnnotationIdentifier];
        if (segmentDistance > 4 && segmentDistance <=5)
            return [ATConstants After4AnnotationIdentifier];
        if (segmentDistance > 5)
            return [ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag :ann.address]; //Do not show if outside range, but tap annotation is added, just not show and tap will cause annotation show
        if (segmentDistance >= -2 && segmentDistance < -1)
            return [ATConstants Past1AnnotationIdentifier];
        if (segmentDistance >= -3 && segmentDistance < -2)
            return [ATConstants Past2AnnotationIdentifier];
        if (segmentDistance >= -4 && segmentDistance < -3)
            return [ATConstants Past3AnnotationIdentifier];
        if (segmentDistance>= - 5 && segmentDistance < -4 )
            return [ATConstants Past4AnnotationIdentifier];
        if (segmentDistance < -5 )
            return [ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag :ann.address]; //do not show if outside range,  but tap annotation is added, just not show and tap will cause annotation show
    }
    return nil;
}

- (float)getDistanceFromFocusedDate:(NSDate*)eventDate
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSTimeInterval interval = [eventDate timeIntervalSinceDate:appDelegate.focusedDate];
    float dayInterval = interval/86400;
    float segmentInDays = appDelegate.selectedPeriodInDays;
    
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    if ([targetName hasPrefix:@"AtlasTravelReader"])
    {
        if (segmentInDays == 365)
            segmentInDays = 1095; //3yr
    }
    
    //Here, only show events withing selectedPeriodInDays, color phase will be selectedPeriodInDays/8
    float lenthOfEachSegment = segmentInDays/10 ; //or 8?
    return dayInterval / lenthOfEachSegment;  //if return value is greate than segmentInDays, then it beyong date rante
}

- (Boolean)eventInPeriodRange:(NSDate*)eventDate
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    float segmentInDays = appDelegate.selectedPeriodInDays;
    float distanceFromForcusedDate = [self getDistanceFromFocusedDate:eventDate];
    if (fabsf(distanceFromForcusedDate) > segmentInDays)
        return false;
    else
        return true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"=============== Memory warning in ATViewController");
    // Dispose of any resources that can be recreated.
}

- (void)cancelPreference{
    if (self.preferencePopover != nil)
        [self.preferencePopover dismissPopoverAnimated:true];
}

-(void)calculateSearchBarFrame
{
    int searchBarHeight = [ATConstants searchBarHeight];
    int searchBarWidth = [ATConstants searchBarWidth];
    //[self.navigationItem.titleView setFrame:CGRectMake(0, 0, searchBarWidth, searchBarHeight)];
    //searchBar size on storyboard could not adjust according ipad/iPhone/Orientation
    [self.searchBar setBounds:CGRectMake(0, 0, searchBarWidth, searchBarHeight)];
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //NSLog(@"Rodation detected");
    [self displayTimelineControls];
    [self calculateSearchBarFrame]; //in iPhone, make search bar wider in landscape
    [self closeTutorialView];
    
    CGRect frame = self.gAdBannerView.frame;
    frame.origin.y = [ATConstants screenHeight] - GAD_SIZE_320x50.height;
    self.gAdBannerView.frame = frame;
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [theSearchBar resignFirstResponder];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:theSearchBar.text completionHandler:^(NSArray *placemarks, NSError *error) {
        //Error checking
        
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        if (placemark == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search address failed!"
                                                            message:@"Either network is not available or can't find the address!"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        MKCoordinateRegion region;
        region.center.latitude = placemark.region.center.latitude;
        region.center.longitude = placemark.region.center.longitude;
        
        CLLocationCoordinate2D searchPoint = CLLocationCoordinate2DMake(region.center.latitude, region.center.longitude);
        ATEventAnnotation *pa = [[ATEventAnnotation alloc] initWithLocation:searchPoint];
        pa.eventDate = [NSDate date];
        pa.description=NEWEVENT_DESC_PLACEHOLD;//@"add by search";
        pa.address = theSearchBar.text; //TODO should get from placemarker
        [_mapView setAnnotations:@[pa]];
        
        MKCoordinateSpan span;
        double radius = placemark.region.radius / 1000; // convert to km
        
        //NSLog(@"[searchBarSearchButtonClicked] Radius is %f", radius);
        span.latitudeDelta = radius / 112.0;
        
        region.span = span;
        
        [self.mapView setRegion:region animated:YES];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {
    if ([segue.identifier isEqualToString:@"preference_id"]) {
        self.preferencePopover = [(UIStoryboardPopoverSegue *)segue popoverController];
    }
    /*if ([segue.identifier isEqualToString:@"iphone_settings"]) {
     [self performSegueWithIdentifier:@"iphone_settings" sender:self]; //preference_storyboard_id
     }*/
}

//select/deselect tap will interfare my tap gesture handler, so try to resume timeline window original show/hide status
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    //For callout caused by select from Event List View, then do not toggle
    //For callout caused by tap on annotation in map, need to toogle back because tap on annotation will first call tap gesture on mkmapview
    //Again, use regionChangeTimeStart to check: regionChangeTime is long, then must tap on annotation, otherwise, it should be tap on EventListView because it will trigger map scroll
    NSTimeInterval interval = [[[NSDate alloc] init] timeIntervalSinceDate:regionChangeTimeStart];
    if (interval > 0.3)  //When tap on annotation, last map scroll should been at least 0.2 seconds ago.
        [self toggleMapViewShowHideAction];
}
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    
}
- (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

- (double)latitudeToPixelSpaceY:(double)latitude
{
    return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

- (double)pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

- (double)pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}
- (MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)mapView
                             centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 andZoomLevel:(NSUInteger)zoomLevel
{
    // convert center coordiate to pixel space
    double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];
    
    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);
    
    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = mapView.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
    
    // find delta between left and right longitudes
    CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;
    
    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}


- (void) refreshEventListView:(BOOL)callFromScrollTimewheel
{
    if (callFromScrollTimewheel && switchEventListViewModeToVisibleOnMapFlag)
        return; //while in map eventListView mode, move timewheel will call this function as well, but do nothing. eventListInVisibleMapArea is set to nil in switch button action
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int offset = 110;
    //try to move evetlistview to right side screenWidht - eventListViewCellWidth, but a lot of trouble, not know why
    //  even make x to 30, it will move more than 30, besides, not left side tap works
    CGRect newFrame = eventListView.frame; // CGRectMake(0,offset,0,0);
    int numOfCellOnScreen = 0;
    
    
    NSMutableArray* eventListViewList = eventListInVisibleMapArea;
    
    if (eventListInVisibleMapArea == nil && switchEventListViewModeToVisibleOnMapFlag == false) //it means eventlistView will show events inside timewheel period
    {
        NSDictionary* scaleDateDic = [ATHelper getScaleStartEndDate:appDelegate.focusedDate];
        NSDate* scaleStartDay = [scaleDateDic objectForKey:@"START"];
        NSDate* scaleEndDay = [scaleDateDic objectForKey:@"END"];
        
        
        
        if ([self.startDate compare:scaleStartDay] == NSOrderedDescending)
            scaleStartDay = self.startDate;
        if ([self.endDate compare:scaleEndDay] == NSOrderedAscending)
            scaleEndDay = self.endDate;
        //NSLog(@" === scaleStartDate = %@,  scaleEndDay = %@", scaleStartDay, scaleEndDay);
        NSArray* allEventSortedList = appDelegate.eventListSorted;
        
        
        eventListViewList = [[NSMutableArray alloc] init];
        
        NSUInteger cnt = [allEventSortedList count];
        if (cnt == 0 )
        {
            [eventListView setFrame:newFrame];
            [eventListView.tableView setFrame:newFrame];
            [eventListView refresh:eventListViewList: switchEventListViewModeToVisibleOnMapFlag];
            return;
        }
        ATEventDataStruct* latestEvent = allEventSortedList[0];
        ATEventDataStruct* earlistEvent = allEventSortedList[cnt -1];
        
        //case special: where startDate/EndDate range is totally outside the event date range, or even no event at all
        if ([scaleStartDay compare:latestEvent.eventDate] == NSOrderedDescending || [scaleEndDay compare: earlistEvent.eventDate] == NSOrderedAscending)
        {
            [eventListView setFrame:newFrame];
            [eventListView.tableView setFrame:newFrame];
            [eventListView refresh: eventListViewList :switchEventListViewModeToVisibleOnMapFlag];
            return;
        }
        //come here when there start/end date range has intersect with allEventSorted
        BOOL completeFlag = false;
        for (int i=0; i<cnt;i++)
        {
            ATEventDataStruct* evt = allEventSortedList[i];
            if ([self date:evt.eventDate isBetweenDate :scaleStartDay andDate:scaleEndDay])
            {
                [eventListViewList insertObject:evt atIndex:0]; //so event will order by date in regular sequence
                completeFlag = true;
            }
            else
            {
                if (completeFlag == true)
                    break; //this is a trick to enhance performance. Do not continues because all in range has been added
            }
        }
    }
    //above logic will remain startDateIdx/endDateIdx to be -1 if no events
    NSUInteger cnt = [eventListViewList count]; //Inside ATEventListWindow, this will add two rows for arrow button, one at top, one at bottom
    if (cnt > 0)
    {
        numOfCellOnScreen = cnt;
        if (cnt > [ATConstants eventListViewCellNum])
            numOfCellOnScreen = [ATConstants eventListViewCellNum];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            CGRect newBtnFrame = switchEventListViewModeBtn.frame;
            
            if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
            {
                offset = offset - 10;
                newBtnFrame = CGRectMake(newBtnFrame.origin.x, 66, newBtnFrame.size.width, newBtnFrame.size.height);
            }
            else
            {
                offset = offset - 20;
                newBtnFrame = CGRectMake(newBtnFrame.origin.x, 58, newBtnFrame.size.width, newBtnFrame.size.height);
            }
            [switchEventListViewModeBtn setFrame:newBtnFrame];
        }
    }
    newFrame = CGRectMake(newFrame.origin.x ,offset,[ATConstants eventListViewCellWidth],numOfCellOnScreen * [ATConstants eventListViewCellHeight]);
    
    [self showDescriptionLabelViews:self.mapView];
    
    //important Tricky: bottom part of event list view is not clickable, thuse down arrow button always not clickable, add some height will works
    CGRect aaa = newFrame;
    aaa.size.height = aaa.size.height + 100; //Very careful: if add too much such as 500, it seems work, but left side of timewheel will click through when event list view is long. adjust this value to test down arrow button and left side of timewheel
    [eventListView setFrame:aaa];
    
    [eventListView.tableView setFrame:CGRectMake(0,0,newFrame.size.width,newFrame.size.height)];
    if (eventListViewList != nil)
        [eventListView refresh: eventListViewList :switchEventListViewModeToVisibleOnMapFlag];
}

- (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

-(void) photoDroboxClicked:(id)sender
{
    UIStoryboard * storyboard;
    ATPreferenceViewController *preference;
    
    //NOTE: following I have it seems strange that "preference_nav_id" is a NavagatorController not ATPreferenceViewController, but I have to do this way. When I do I phone, it will be simpler because I do not use popover, so no "preference_nav_id" navagatorController needed
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
        preference = [storyboard instantiateViewControllerWithIdentifier:@"preference_nav_id"];
        self.preferencePopover = [[UIPopoverController alloc] initWithContentViewController:preference];
        //IMPORTANT: preferenceViewController is on storyboard with specified size, so have to put 0, 0 for size, otherwise weired thing will happen. Also 700 is not idea for landscape
        [self.preferencePopover presentPopoverFromRect:CGRectMake(800,0,0,0)
                                                inView:self.mapView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else
    {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        preference = [storyboard instantiateViewControllerWithIdentifier:@"preference_storyboard_id"];
        [self.navigationController pushViewController:preference animated:true];
    }
}


/////// following is for search bar actions

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    static NSString *searchCellIdentifier = @"searchCellIdentifier";
    ATCell* cell = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        cell = (ATCell*)[tableView dequeueReusableCellWithIdentifier:searchCellIdentifier];
        
        if (cell == nil) {
            cell = [[ATCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:searchCellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        }
        ATEventDataStruct* ent = [filteredEventListSorted objectAtIndex:indexPath.row];
        cell.entity = ent;
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.text = [NSString stringWithFormat:@"[%@] - %@",[ATHelper getYearPartHelper:ent.eventDate], ent.eventDesc];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
    }
    
    return cell;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [filteredEventListSorted count];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [filteredEventListSorted removeAllObjects]; // First clear the filtered array.
    
    for (ATEventDataStruct *ent in originalEventListSorted)
    {
        if ([ent.eventDesc rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound
            || [ent.address rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound )
            //if (result == NSOrderedSame)
        {
            [filteredEventListSorted insertObject:ent atIndex:0]; //list in time from early to late
        }
        
    }
}


-(void)initgAdBanner
{
    if (!self.gAdBannerView)
    {
        CGRect rect = CGRectMake(0, [ATConstants screenHeight] - GAD_SIZE_320x50.height, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            rect = CGRectMake(0, [ATConstants screenHeight] - GAD_SIZE_320x50.height, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
        self.gAdBannerView = [[GADBannerView alloc] initWithFrame:rect];
        self.gAdBannerView.adUnitID = @"ca-app-pub-5383516122867647/8499480217";
        self.gAdBannerView.rootViewController = self;
        self.gAdBannerView.delegate = self;
        self.gAdBannerView.hidden = false;
        [self.view addSubview:self.gAdBannerView];
        
        GADRequest *request = [GADRequest request];
        request.testDevices = @[ @"efaa3c516e17269775eca5baa3d3118b"];
        [self.gAdBannerView loadRequest:request];
    }
}

-(void)hideBanner:(UIView*)banner
{
    if (banner && ![banner isHidden])
    {
        banner.hidden = TRUE;
    }
}
-(void)showBanner:(UIView*)banner
{
    if (banner && [banner isHidden])
    {
        banner.hidden = FALSE;
    }
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}
-(void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    float screenWidth = [ATConstants screenWidth];
    float searchResultWidth = 350;
    float x = screenWidth/2 - searchResultWidth/2;
    
    CGRect frame = CGRectMake(x, 40, searchResultWidth, 300);
    tableView.frame = frame;
}
//have to use accessary button instead of didSelect on row because tap on row have no gesture somehow
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"detail view clicked row is %i" , indexPath.row);
    ATEventDataStruct* ent = nil;
    
    ATCell *cell = (ATCell*)[tableView cellForRowAtIndexPath:indexPath];
    ent = cell.entity;
    
    
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.focusedDate = ent.eventDate;
    appDelegate.focusedEvent = ent;  //appDelegate.focusedEvent is added when implement here
    [self setNewFocusedDateAndUpdateMapWithNewCenter : ent :-1]; //do not change map zoom level
    [self showOverlays];
    [self refreshEventListView:false]; //so show checkIcon for selected row
    
    //bookmark selected event
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSInteger idx = [appDelegate.eventListSorted indexOfObject:ent];
    [userDefault setObject:[NSString stringWithFormat:@"%ld",idx ] forKey:@"BookmarkEventIdx"];
    [userDefault synchronize];
    
    
    [self.searchDisplayController setActive:NO];//this will dismiss search display table same as click cancel button
    
}

@end
