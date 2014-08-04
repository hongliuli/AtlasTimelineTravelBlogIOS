//
//  ATViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 12/28/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#define SCREEN_WIDTH ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)
#define SCREEN_HEIGHT ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? [[UIScreen mainScreen] bounds].size.height : [[UIScreen mainScreen] bounds].size.width)

#define IN_APP_PURCHASED @"IN_APP_PURCHASED"
#define ALERT_FOR_SWITCH_AUTHO_MODE 1
#define ALERT_FOR_POPOVER_ERROR 2

#define AUTHOR_MODE_KEY @"AUTHOR_MODE_KEY"

#import <QuartzCore/QuartzCore.h>

#import "ATViewController.h"
#import "ATDefaultAnnotation.h"
#import "ATAnnotationSelected.h"
#import "ATAnnotationFocused.h"
#import "ATDataController.h"
#import "ATEventEntity.h"
#import "ATEventDataStruct.h"
#import "ATEventEditorTableController.h"
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

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395
#define ZOOM_LEVEL_TO_HIDE_DESC 3
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


@interface MFTopAlignedLabel : UILabel

@end




@implementation ATViewController
{
    NSString* selectedAnnotationIdentifier;
    int debugCount;
    CGRect focusedLabelFrame;
    NSMutableArray* timeScaleArray;
    int mapViewShowWhatFlag; //see MAPVIEW_SHOW_xxxxx macros
    
    NSMutableArray* selectedAnnotationNearestLocationList; //do not add to selectedAnnotationSet if too close
    NSMutableDictionary* selectedAnnotationSet;//hold uilabels for selected annotation's description
    NSMutableDictionary* tmpLblUniqueIdMap;
    int tmpLblUniqueMapIdx;
    NSMutableSet* selectedAnnotationViewsFromDidAddAnnotation;
    NSDate* regionChangeTimeStart;
    ATDefaultAnnotation* newAddedPin;
    UIButton *locationbtn;
    CGRect timeScrollWindowFrame;
    ATTutorialView* tutorialView;
    
    ATInAppPurchaseViewController* purchase; // have to be global because itself has delegate to use it self
    ATEventAnnotation* selectedEventAnnotation;
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
    
    MKAnnotationView* viewForEditorSizeChange;
    UIView* authorView;
    NSDate* tmpDateHold;
}

@synthesize mapView = _mapView;

- (ATDataController *)dataController { //initially I want to have a singleton of dataController here, but not good if user change database file source, instance it ever time. It is ok here because only called every time user choose to delete/insert
    dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    return dataController;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [ATHelper createPhotoDocumentoryPath];
    //ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.locationManager = [[CLLocationManager alloc] init];
    mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
    int searchBarHeight = [ATConstants searchBarHeight];
    int searchBarWidth = [ATConstants searchBarWidth];
    [self.navigationItem.titleView setFrame:CGRectMake(0, 0, searchBarWidth, searchBarHeight)];

    //Find this spent me long time: searchBar used titleView place which is too short, thuse tap on searchbar right side keyboard will not show up, now it is good
	[self calculateSearchBarFrame];
    
    // create a custom navigation bar button and set it to always says "Back"
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = NSLocalizedString(@"Back",nil);
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    
    //add two button at right (can not do in storyboard for multiple button): setting and Help, available in iOS5
    //   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    //   {
    UIBarButtonItem *settringButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(settingsClicked:)];
    
    //NOTE the trick to set background image for a bar buttonitem
    UIButton *helpbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    helpbtn.frame = CGRectMake(0, 0, 30, 30);
    [helpbtn setImage:[UIImage imageNamed:@"help.png"] forState:UIControlStateNormal];
    [helpbtn addTarget:self action:@selector(tutorialClicked:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithCustomView:helpbtn];
    self.navigationItem.rightBarButtonItems = @[settringButton, helpButton];
    //   }
    
    
	// Do any additional setup after loading the view, typically from a nib.
    // tap to show/hide timeline navigator
    UITapGestureRecognizer *tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [_mapView addGestureRecognizer:tapgr];
    
    selectedAnnotationSet = [[NSMutableDictionary alloc] init];
    tmpLblUniqueIdMap = [[NSMutableDictionary alloc] init];
    tmpLblUniqueMapIdx = 1;
    selectedAnnotationNearestLocationList = [[NSMutableArray alloc] init];
    regionChangeTimeStart = [[NSDate alloc] init];
    [self prepareMapView];
    //if(IOS_7)
    //{
    self.searchDisplayController.searchBar.searchBarStyle = UISearchBarStyleMinimal; //otherwise, there will be a gray background around search bar
    //}
    //author mode
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* currentAuthorMode = [userDefault valueForKey:AUTHOR_MODE_KEY];
    
    if (currentAuthorMode == nil || [currentAuthorMode isEqualToString:@"VIEW_MODE"])
    {
        [self closeAuthorView];
    }
    else
    {
        [self startAuthorView];
    }
    // I did not use iOS7's self.canDisplayBannerAds to automatically display adds, not sure why
    [self initiAdBanner];
    [self initgAdBanner];
    

}
-(void) viewDidAppear:(BOOL)animated
{
    [self displayTimelineControls]; //MOTHER FUCKER, I struggled long time when I decide to put timescrollwindow at bottom. Finally figure out have to put this code here in viewDidAppear. If I put it in viewDidLoad, then first time timeScrollWindow will be displayed in other places if I want to display at bottom, have to put it here
    [self.timeZoomLine showHideScaleText:false];
    [ATHelper setOptionDateFieldKeyboardEnable:false]; //always set default to not allow keyboard
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    originalEventListSorted = appDelegate.eventListSorted;
    filteredEventListSorted = [NSMutableArray arrayWithCapacity:[originalEventListSorted count]];
    [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"List",nil)];
    [self.searchDisplayController.searchBar setPlaceholder:NSLocalizedString(@"Search Event", nil)];

    
    if ([appDelegate.eventListSorted count] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add your first event",nil) message:NSLocalizedString(@"No event file. Developer problem",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
    }
    if (eventListView == nil) //viewDidAppear will be called when navigate back (such as from timeline/search view and full screen event editor, so need to check. Always be careful of viewDidAppear to not duplicate instances
    {
        eventListView = [[ATEventListWindowView alloc] initWithFrame:CGRectMake(0,20, 0, 0)];
        [eventListView.tableView setBackgroundColor:[UIColor clearColor] ];// colorWithRed:1 green:1 blue:1 alpha:0.7]];
        [self.mapView addSubview:eventListView];
    }
    [self refreshEventListView];
    
}


-(void) settingsClicked:(id)sender  //IMPORTANT only iPad will come here, iPhone has push segue on storyboard
{
    NSString* currentVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    currentVer = [NSString stringWithFormat:@"Current Version: %@",currentVer ];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* currentAuthorMode = [userDefault valueForKey:AUTHOR_MODE_KEY];
    NSString* buttonText = NSLocalizedString(@"To View Mode",nil);
    if (currentAuthorMode == nil || [currentAuthorMode isEqualToString:@"VIEW_MODE"])
        buttonText = NSLocalizedString(@"To Author Mode",nil);
        
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:currentVer message:NSLocalizedString(
            @"This App is supported by ChronicleMap App, which is a popular App to record personal life stories! (Download app from Apple Store)\n\nIf you have a historical story to tell as this app does, you can help us to build more and more Apps. You will own the App and get a sizable portion of revenue. All you have to do is to write story in text in a simple format.\n\nDetail see www.chroniclemap.com/authorarea",nil)
            delegate:self
            cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
            otherButtonTitles:buttonText, NSLocalizedString(@"Feedback to Author",nil),nil];
    alert.tag = ALERT_FOR_SWITCH_AUTHO_MODE;
    [alert show];
}

-(void) currentLocationClicked:(id)sender
{
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [self.locationManager startUpdatingLocation];
    
    CLLocation *newLocation = [self.locationManager location];
    CLLocationCoordinate2D centerCoordinate;
    centerCoordinate.latitude = newLocation.coordinate.latitude;
    centerCoordinate.longitude = newLocation.coordinate.longitude;
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:centerCoordinate andZoomLevel:14];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self.mapView setRegion:region animated:YES];
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
    if (alertView.tag == ALERT_FOR_SWITCH_AUTHO_MODE) {
        if (buttonIndex == 1) //switch view/author mode
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Only available in iPad Version",nil)
                                                                message:NSLocalizedString(@"",nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                      otherButtonTitles:nil];
                [alert show];
                return;
            }
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            NSString* currentAuthorMode = [userDefault valueForKey:AUTHOR_MODE_KEY];
            
            if (currentAuthorMode == nil || [currentAuthorMode isEqualToString:@"VIEW_MODE"])
            {
                BOOL loginFlag = [ATHelper checkUserEmailAndSecurityCode:self];
                if (!loginFlag)
                    return;
                [self startAuthorView];
            }
            else
            {
                [self closeAuthorView];
            }
        }
        if (buttonIndex == 2) //Feedback to
        {
            NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
            //NSArray *toReceipients = @[@"aa@aa.com"];
            NSArray *toReceipients = @[NSLocalizedString(@"AuthorEmail",nil)]; //AuthorEmail is in Localizable.String file
            NSArray *ccReceipients = @[@"support@chroniclemap.com"]; //AuthorEmail is in Localizable.String file
            MFMailComposeViewController* mailComposer = [[MFMailComposeViewController alloc]init];
            mailComposer.mailComposeDelegate = self;
            [mailComposer setToRecipients:toReceipients];
            [mailComposer setCcRecipients:ccReceipients];
            [mailComposer setSubject:NSLocalizedString(targetName,nil)];
            //[mailComposer setMessageBody:@"Testing message for the test mail" isHTML:NO];
            [self presentModalViewController:mailComposer animated:YES];
        }
    }
    if (buttonIndex == 0 && alertView.tag == ALERT_FOR_POPOVER_ERROR)
    {
        NSLog(@"----- refreshAnn after popover error");
        [self refreshAnnotations];
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
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void)handleTapOnTutorial:(UIGestureRecognizer *)gestureRecognizer
{
    [self closeTutorialView];
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
        int eventListSize = [eventList count];
        ATEventDataStruct* entStruct = eventList[eventListSize -1]; //if no bookmark, always use earlist
        if (bookmarkIdxStr != nil)
        {
            int bookmarkIdx = [bookmarkIdxStr intValue];
            if (bookmarkIdx >= eventListSize)
                bookmarkIdx = eventListSize - 1;
            entStruct = eventList[bookmarkIdx];
        }
        appDelegate.focusedDate = entStruct.eventDate;
        appDelegate.focusedEvent = entStruct;  //appDelegate.focusedEvent is added when implement here
        [self setNewFocusedDateAndUpdateMapWithNewCenter : entStruct :4]; //initially set map zoom to a reasonable zoom level so annotation marker icon can show
        [self showOverlays];
    }
    
    //add annotation. ### this is the loop where we can adding NSLog to print individual items
    for (ATEventDataStruct* ent in eventList) {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake((CLLocationDegrees)ent.lat, (CLLocationDegrees)ent.lng);
        ATAnnotationSelected *eventAnnotation = [[ATAnnotationSelected alloc] initWithLocation:coord];
        eventAnnotation.uniqueId = ent.uniqueId;
        if (ent.eventDate == nil)
            NSLog(@"---- nil date");
        eventAnnotation.address = ent.address;
        eventAnnotation.description=ent.eventDesc;
        eventAnnotation.eventDate=ent.eventDate;
        eventAnnotation.eventType = ent.eventType;
        [self.mapView addAnnotation:eventAnnotation];
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
    int eventCount = [eventList count];
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
    if (self.timeZoomLine != nil)
        [self displayTimelineControls];//which one is better: [self.timeZoomLine changeScaleLabelsDateFormat:self.startDate :self.endDate ];
    //NSLog(@"   ############## setConfigu startDate=%@    endDate=%@   startDateFormated=%@", self.startDate, self.endDate, [appDelegate.dateFormater stringFromDate:self.startDate]);
}

- (void) cleanSelectedAnnotationSet
{
    if (selectedAnnotationSet != nil)
    {
        for (id key in selectedAnnotationSet) {
            UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
            [tmpLbl removeFromSuperview];
        }
        [selectedAnnotationSet removeAllObjects];
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
        //MKZoomScale currentZoomScale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
        //NSLog(@" zoom level: %f",currentZoomScale);
        CLLocationCoordinate2D currentCenter = [self.mapView centerCoordinate];
        
        CLLocation *pointFrom=[[CLLocation alloc]initWithLatitude:ent.lat longitude:ent.lng];
        CLLocation *pointTo=[[CLLocation alloc]initWithLatitude:currentCenter.latitude longitude:currentCenter.longitude];
        CLLocationDistance distance=[pointFrom distanceFromLocation:pointTo]; //distance in meter
        
        MKCoordinateRegion myRegion = MKCoordinateRegionMakeWithDistance(self.mapView.centerCoordinate, distance, 0);
        CGRect myRect = [self.mapView convertRegion: myRegion toRectToView: nil];
        
        float distanceOnScreen = myRect.size.width;
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
            distanceOnScreen = myRect.size.height;
        //NSLog(@"distance on screen is %f",distanceOnScreen);
        if (distanceOnScreen > 10000) //for long distance in screen size, do not animate which is too slow
            [self.mapView setCenterCoordinate:centerCoordinate animated:NO];
        else
            [self.mapView setCenterCoordinate:centerCoordinate animated:YES];
    }
    else
    {
        // use the zoom level to compute the region
        MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
        MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
        
        // set the region like normal
        [self.mapView setRegion:region animated:YES];
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
    
    //NOTE the trick to set background image for a bar buttonitem
    if (locationbtn == nil)
        locationbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    else
        [locationbtn removeFromSuperview];
    locationbtn.frame = CGRectMake([ATConstants screenWidth] - 50, 90, 30, 30);
    [locationbtn setImage:[UIImage imageNamed:@"currentLocation.jpg"] forState:UIControlStateNormal];
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
    timeZoomLineFrame = CGRectMake(timeWindowX - 15,self.view.bounds.size.height - [ATConstants timeScrollWindowHeight] - 18, timeWindowWidth + 30,10);
    if (self.timeZoomLine != nil)
        [self.timeZoomLine removeFromSuperview]; //incase orientation change
    self.timeZoomLine = [[ATTimeZoomLine alloc] initWithFrame:timeZoomLineFrame];
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
- (void) mapViewShowHideAction
{
    if ([selectedAnnotationSet count] == 0) //if no selected nodes, use 2 step show/hide to have better user experience
    {
        if (mapViewShowWhatFlag == MAPVIEW_SHOW_ALL || mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
        {
            mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
            self.timeScrollWindow.hidden = true;
            eventListView.hidden = true;
            self.timeZoomLine.hidden = true;
            [self hideDescriptionLabelViews];
            self.navigationController.navigationBarHidden = true;
            [self showAdAtTop:true];
        }
        else if (mapViewShowWhatFlag == MAPVIEW_HIDE_ALL || mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
        {
            mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
            self.timeScrollWindow.hidden=false;
            eventListView.hidden = false;
            self.timeZoomLine.hidden = false;
            [self showDescriptionLabelViews:self.mapView];
            self.navigationController.navigationBarHidden = false;
            [self showAdAtTop:false];
        }
    }
    else //if has selected nodes, use 3-step show/hide
    {
        if (mapViewShowWhatFlag == MAPVIEW_SHOW_ALL)
        {
            mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
            self.timeScrollWindow.hidden = true;
            eventListView.hidden = true;
            self.timeZoomLine.hidden = true;
            [self hideDescriptionLabelViews];
            self.navigationController.navigationBarHidden = true;
            [self showAdAtTop:true];
        }
        else if (mapViewShowWhatFlag == MAPVIEW_HIDE_ALL)
        {
            mapViewShowWhatFlag = MAPVIEW_SHOW_PHOTO_LABEL_ONLY;
            self.timeScrollWindow.hidden=true;
            eventListView.hidden = true;
            self.timeZoomLine.hidden = true;
            [self showDescriptionLabelViews:self.mapView];
            self.navigationController.navigationBarHidden = true;
            [self showAdAtTop:true];
        }
        else if (mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
        {
            mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
            self.timeScrollWindow.hidden=false;
            eventListView.hidden = false;
            self.timeZoomLine.hidden = false;
            [self showDescriptionLabelViews:self.mapView];
            self.navigationController.navigationBarHidden = false;
            [self showAdAtTop:false];
        }
    }
}
- (void)handleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    NSTimeInterval interval = [[[NSDate alloc] init] timeIntervalSinceDate:regionChangeTimeStart];
    // NSLog(@"my tap ------regionElapsed=%f", interval);
    if (interval < 0.5)  //When scroll map, tap to stop scrolling should not flip the display of timeScrollWindow and description views
        return;
    if ([gestureRecognizer numberOfTouches] == 1)
    {
        [self mapViewShowHideAction];
    }
}

- (void) addPinToMap:(NSString*)locatedAt :(CLLocationCoordinate2D) touchMapCoordinate
{
    ATDefaultAnnotation *pa = [[ATDefaultAnnotation alloc] initWithLocation:touchMapCoordinate];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    pa.eventDate = appDelegate.focusedDate;
    pa.description=NEWEVENT_DESC_PLACEHOLD;
    pa.address = locatedAt;
    [_mapView addAnnotation:pa];
    if (newAddedPin != nil)
    {
        [_mapView removeAnnotation:newAddedPin];
        newAddedPin = pa;
    }
    else
        newAddedPin = pa;
    
    [self mapViewShowHideAction]; //select annotation will flip it, so double flip
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    ATDefaultAnnotation* ann = (ATDefaultAnnotation*)annotation;
    
    
    // Following will filter out MKUserLocation annotation
    if ([annotation isKindOfClass:[ATDefaultAnnotation class]]) //ATDefaultAnnotation is when longPress
    {
        selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate :nil]; //keep this line here, do not move inside
        // try to dequeue an existing pin view first
        MKPinAnnotationView* pinView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:[ATConstants DefaultAnnotationIdentifier]];
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView* customPinView = [[MKPinAnnotationView alloc]
                                                  initWithAnnotation:annotation reuseIdentifier:[ATConstants DefaultAnnotationIdentifier]];
            customPinView.pinColor = MKPinAnnotationColorPurple;
            customPinView.animatesDrop = YES;
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
        {
            //NSLog(@"+++++++++ reused default annotation +++++ at address %@", [annotation title]);
            pinView.annotation = annotation;
        }
        return pinView;
    }
    else if ([annotation isKindOfClass:[ATAnnotationSelected class]]) //all that read from db will be ATAnnotationSelected type
    {
        NSString* specialMarkerName = [ATHelper getMarkerNameFromDescText: ann.description];
        
        selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate: specialMarkerName]; //keep this line here
        MKAnnotationView* annView;
        annView = [self getImageAnnotationView:selectedAnnotationIdentifier :annotation];
        annView.annotation = annotation;
        NSString *key=[NSString stringWithFormat:@"%f|%f",ann.coordinate.latitude, ann.coordinate.longitude];
        //keey list of red  annotations
        BOOL isSpecialMarkerInFocused = false;
        if (specialMarkerName != nil && ![selectedAnnotationIdentifier isEqualToString:[ATConstants WhiteFlagAnnotationIdentifier]] )
        {
            //Remember special marker annotation identifier has alpha value delimited by ":" if not selected. Selected do not have :
            if ([selectedAnnotationIdentifier rangeOfString:@":"].location == NSNotFound)
                isSpecialMarkerInFocused = true;
        }
        if ([selectedAnnotationIdentifier isEqualToString: [ATConstants SelectedAnnotationIdentifier]] || isSpecialMarkerInFocused)
        {
            UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
            if (tmpLbl == nil)
            {
                //CGPoint windowPoint = [annView convertPoint:[annView center] toView:self.mapView];
                CGPoint annotationViewPoint = [theMapView convertCoordinate:annView.annotation.coordinate
                                                              toPointToView:theMapView];
                
                //NSLog(@"x=%f  y=%f",annotationViewPoint.x, annotationViewPoint.y);
                tmpLbl = [[UILabel alloc] initWithFrame:CGRectMake(annotationViewPoint.x -20, annotationViewPoint.y+5, THUMB_WIDTH, THUMB_HEIGHT)]; //todo MFTopAlignedLabel
                if (ann.eventType == EVENT_TYPE_HAS_PHOTO) //somehow it is a big number before save to db, need more study why not 1
                {
                    UIImage* img = [ATHelper readPhotoThumbFromFile:ann.uniqueId];
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
                        tmpLbl.layer.borderColor = [UIColor brownColor].CGColor;
                        tmpLbl.layer.borderWidth = 1;
                    }
                    else
                    {
                        //xxxxxx TODO if user switch source from server, photo may not be in local yet, then
                        //             should display text only and add download request in download queue
                        // ########## This is a important lazy download concept #############
                        tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
                        tmpLbl.text = [NSString stringWithFormat:@" %@", [ATHelper clearMakerAllFromDescText: ann.description ]];
                        tmpLbl.layer.cornerRadius = 8;
                        tmpLbl.layer.borderColor = [UIColor redColor].CGColor;
                        tmpLbl.layer.borderWidth = 1;
                    }
                }
                else
                {
                    tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
                    tmpLbl.text = [NSString stringWithFormat:@" %@", [ATHelper clearMakerAllFromDescText: ann.description ]];
                    tmpLbl.layer.cornerRadius = 8;
                    //If the event has photo before but the photos do not exist anymore, then show text with red board
                    //If this happen, the photo may in Dropbox. if not  in dropbox, then it lost forever.
                    //To change color, add a photo and delete it, then it will change to brown border
                    tmpLbl.layer.borderColor = [UIColor brownColor].CGColor;
                    tmpLbl.layer.borderWidth = 1;
                }
                
                tmpLbl.userInteractionEnabled = YES;
                [tmpLblUniqueIdMap setObject:annView forKey:[NSNumber numberWithInt:tmpLblUniqueMapIdx ]];
                tmpLbl.tag = tmpLblUniqueMapIdx;
                tmpLblUniqueMapIdx++;
                //tmpLbl.textAlignment = UITextAlignmentCenter;
                tmpLbl.lineBreakMode = NSLineBreakByWordWrapping;
                
                
                [self setDescLabelSizeByZoomLevel:tmpLbl];
                if ([self zoomLevel] <= ZOOM_LEVEL_TO_HIDE_DESC)
                    tmpLbl.hidden = true;
                else
                    tmpLbl.hidden=false;
                
                [selectedAnnotationSet setObject:tmpLbl forKey:key];
                [self.view addSubview:tmpLbl];
                
            }
            else //if already in the set, need make sure it will be shown
            {
                if (ann.eventType == EVENT_TYPE_NO_PHOTO)
                    tmpLbl.text = [ATHelper clearMakerAllFromDescText: ann.description ]; //need to change to take care of if user updated description in event editor
                
                if ([self zoomLevel] <= ZOOM_LEVEL_TO_HIDE_DESC)
                    tmpLbl.hidden = true;
                else
                    tmpLbl.hidden=false;
            }
        }
        else
        {
            UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
            if ( tmpLbl != nil)
            {
                [selectedAnnotationSet removeObjectForKey:key];
                [tmpLbl removeFromSuperview];
            }
        }
        /*
         if ([selectedAnnotationIdentifier isEqualToString:[ATConstants WhiteFlagAnnotationIdentifier]])
         {
         [[annView superview] sendSubviewToBack:annView];
         }
         */
        //annView.hidden = false;
        return annView;
    }
    else if ([annotation isKindOfClass:[ATAnnotationFocused class]]) //Focused annotation is added when tab focused
    {
        MKAnnotationView* annView = [self getImageAnnotationView:@"focusedFlag.png" :annotation];
        annView.annotation = annotation;
        return annView;
    }
    
    return nil;
}

//All View is a UIResponder, all UIresponder objects can implement touchesBegan
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
    currentTapTouchKey = 0;
    currentTapTouchMove = false;
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithInt:touch.view.tag];
    if ([annViewKey intValue] > 0) //tag is set in viewForAnnotation when instance tmpLbl
        currentTapTouchKey = [annViewKey intValue];
}

//Only tap to start event editor, when swipe map and happen to swipe on photo, do not start event editor
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithInt:touch.view.tag];
    if ([annViewKey intValue] > 0 && [annViewKey intValue] == currentTapTouchKey)
        currentTapTouchMove = true;
}
//touchesEnded does not work, touchesCancelled works
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithInt:touch.view.tag];
    if ([annViewKey intValue] > 0 && [annViewKey intValue] == currentTapTouchKey && !currentTapTouchMove)
    {
        MKAnnotationView* annView = [tmpLblUniqueIdMap objectForKey:annViewKey];
        [self startEventEditor:annView];
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
        NSString* identifer = [self getImageIdentifier:ann.eventDate :specialMarkerName];
        //NSLog(@"  identifier is %@  date=%@",identifer, ann.eventDate);
        if ([identifer isEqualToString: [ATConstants WhiteFlagAnnotationIdentifier]])
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
    //NSLog(@"regione willChange size: %i    whiteFlag set count %i ", [selectedAnnotationSet count], [whiteFlagAnnotationSet count]);
    for (id key in selectedAnnotationSet) {
        UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
        // ATEventAnnotation* eventAnn = (ATEventAnnotation*)key;
        tmpLbl.hidden=true;
    }
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    //TODO could set option to enable/disable hide white flag, because if large nmber of selected note, then move map may be slow
    //     although currently we already have optimized it a lot
    if (selectedAnnotationViewsFromDidAddAnnotation != nil && [self zoomLevel] >= ZOOM_LEVEL_TO_SEND_WHITE_FLAG_BEHIND_IN_REGION_DID_CHANGE)
    {
        //NSLog(@"    in regionDidChange  size=%d",[selectedAnnotationViewsFromDidAddAnnotation count]);
        for (MKAnnotationView* annView in selectedAnnotationViewsFromDidAddAnnotation)
        {
            [[annView superview] bringSubviewToFront:annView];
        }
    }
    
    //NSLog(@"retion didChange, zoom level is %i", [self zoomLevel]);
    [self.timeZoomLine setNeedsDisplay];
    regionChangeTimeStart = [[NSDate alloc] init];
    [self showDescriptionLabelViews:mapView];
    [self.mapView bringSubviewToFront:eventListView]; //so eventListView will always cover map marker photo/txt icon (tmpLbl)
    
}
- (void) showDescriptionLabelViews:(MKMapView*)mapView
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *focuseKey=[NSString stringWithFormat:@"%f|%f",appDelegate.focusedEvent.lat, appDelegate.focusedEvent.lng];
    for (id key in selectedAnnotationSet) {
        NSArray *splitArray = [key componentsSeparatedByString:@"|"];
        UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude=[splitArray[0] doubleValue];
        coordinate.longitude = [splitArray[1] doubleValue];
        CGPoint annotationViewPoint = [mapView convertCoordinate:coordinate
                                                   toPointToView:mapView];
        if (mapViewShowWhatFlag == MAPVIEW_SHOW_ALL || mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
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
                continue;
            }
            else
            {
                [selectedAnnotationNearestLocationList addObject: [NSValue valueWithCGPoint:annotationViewPoint]];
            }
            
            [self setDescLabelSizeByZoomLevel:tmpLbl];
            CGSize size = tmpLbl.frame.size;
            [tmpLbl setFrame:CGRectMake(annotationViewPoint.x -20, annotationViewPoint.y+5, size.width, size.height)];
            if ([self zoomLevel] <= ZOOM_LEVEL_TO_HIDE_DESC)
                tmpLbl.hidden = true;
            else
                tmpLbl.hidden=false;
        }
    }
    [selectedAnnotationNearestLocationList removeAllObjects];
}

- (void) hideDescriptionLabelViews
{
    for (id key in selectedAnnotationSet) {
        UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
        tmpLbl.hidden=true;
    }
}
-(void) setDescLabelSizeByZoomLevel:(UILabel*)tmpLbl
{
    int zoomLevel = [self zoomLevel];
    CGSize expectedLabelSize = [tmpLbl.text sizeWithFont:tmpLbl.font
                                       constrainedToSize:tmpLbl.frame.size lineBreakMode:NSLineBreakByWordWrapping];
    tmpLbl.numberOfLines = 0;
    tmpLbl.font = [UIFont fontWithName:@"Arial" size:11];
    int labelWidth = 60;
    if (zoomLevel <= ZOOM_LEVEL_TO_HIDE_DESC)
    {
        tmpLbl.hidden = true; //do nothing, caller already hidden the label;
    }
    else if (zoomLevel <= 8)
    {
        tmpLbl.numberOfLines=4;
    }
    else if (zoomLevel <= 10)
    {
        tmpLbl.numberOfLines=4;
        labelWidth = 100;
    }
    else if (zoomLevel <= 13)
    {
        tmpLbl.font = [UIFont fontWithName:@"Arial" size:13];
        tmpLbl.numberOfLines=5;
        labelWidth = 100;
    }
    else
    {
        tmpLbl.font = [UIFont fontWithName:@"Arial" size:14];
        tmpLbl.numberOfLines=5;
        labelWidth = 120;
    }
    
    //HONG if height > CONSTANT, then do not change, I do not like biggerImage unless in a big zooing
    CGRect newFrame = tmpLbl.frame;
    newFrame.size.height = expectedLabelSize.height;
    newFrame.size.width=labelWidth;
    tmpLbl.frame = newFrame;
    //if (!CGColorGetPattern(tmpLbl.backgroundColor.CGColor))
    [tmpLbl sizeToFit];
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
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    //need use base class ATEventAnnotation here to handle call out for all type of annotation
    ATEventAnnotation* ann = [view annotation];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([control.accessibilityLabel isEqualToString: @"right"]){
        [self startEventEditor:view];
    }
    else if ([control.accessibilityLabel isEqualToString: @"left"]){
        //NSLog(@"left button clicked");
        
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
        selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate :ann.description];
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
        mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
        self.timeScrollWindow.hidden=false;
        eventListView.hidden = false;
        self.timeZoomLine.hidden = false;
        self.navigationController.navigationBarHidden = false;
        [self showAdAtTop:false];
        appDelegate.focusedEvent = ent;
        [self showOverlays];
        [self refreshEventListView];
        //bookmark selected event
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        int idx = [appDelegate.eventListSorted indexOfObject:ent];
        [userDefault setObject:[NSString stringWithFormat:@"%d",idx ] forKey:@"BookmarkEventIdx"];
    }
}

- (void) startEventEditor:(MKAnnotationView*)view
{
    viewForEditorSizeChange = view;
    ATEventAnnotation* ann = [view annotation];
    selectedEventAnnotation = ann;
    self.selectedAnnotation = ann;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard* storyboard = appDelegate.storyBoard;

    //if (self.eventEditor == nil) {
    //I just learned from iOS5 tutor pdf, there is a way to create segue for accessory buttons, I do not want to change, Will use it in iPhone storyboard
    self.eventEditor = [storyboard instantiateViewControllerWithIdentifier:@"event_editor_id"];
    self.eventEditor.delegate = self;
    //}
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        BOOL optionIPADFullScreen = [ATHelper getOptionEditorFullScreen];
        if (optionIPADFullScreen)
        {
            [self.navigationController presentViewController:self.eventEditor animated:YES completion:nil];
        }
        else
        {
            self.eventEditorPopover = [[UIPopoverController alloc] initWithContentViewController:self.eventEditor];
            self.eventEditorPopover.popoverContentSize = CGSizeMake(380,480);
            
            //Following view.window=nil case is weird. When tap on text/image to start eventEditor, system will crash after around 10 times. Googling found it will happen when view.window=nil, so have to alert user and call refreshAnn in alert delegate to fix it. (will not work without put into alert delegate)
            if (view.window != nil)
                [self.eventEditorPopover presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A minor error occurs",nil)
                                                                message:NSLocalizedString(@"Please try again!",nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                      otherButtonTitles:nil];
                alert.tag = ALERT_FOR_POPOVER_ERROR;
                [alert show];
            }
        }
    }
    else {
        //[self performSegueWithIdentifier:@"eventeditor_segue_id" sender:nil];
        //[self.navigationController presentModalViewController:self.eventEditor animated:YES]; //pushViewController: self.eventEditor animated:YES];
        [self.navigationController presentViewController:self.eventEditor animated:YES completion:nil];
    }
    //has to set value here after above presentXxxxx method, otherwise the firsttime will display empty text
    [self.eventEditor resetEventEditor];
    
    
    self.eventEditor.coordinate = ann.coordinate;
    if ([ann.description isEqualToString:NEWEVENT_DESC_PLACEHOLD])
    {
        self.eventEditor.description.textColor = [UIColor lightGrayColor];
    }
    
    self.eventEditor.description.text = ann.description;
    self.eventEditor.address.text= ann.address;
    self.eventEditor.address.editable = false;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    self.eventEditor.dateTxt.text = [dateFormatter stringFromDate:ann.eventDate];
    tmpDateHold = ann.eventDate;

    self.eventEditor.eventType = ann.eventType;
    self.eventEditor.hasPhotoFlag = EVENT_TYPE_NO_PHOTO; //not set to ann.eventType because we want to use this flag to decide if need save image again
    self.eventEditor.eventId = ann.uniqueId;
    //self.eventEditor.view.backgroundColor = [UIColor clearColor];//  [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3]; //this will make full screen editor black

    [ATEventEditorTableController setEventId:ann.uniqueId];
    //if (ann.eventType == EVENT_TYPE_HAS_PHOTO)
    [self.eventEditor createPhotoScrollView: ann.uniqueId ];
    [self showOverlays]; //added in Reader version
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
    [self.mapView addAnnotation:focusedAnnotationIndicator];
    
    
    //following prepare mkPoi

    NSArray* overlays = [self prepareOverlays:focusedEvent];

    //TODO ### have problem here for Reader
    [overlaysToBeCleaned addObjectsFromArray:overlays];

    
    
    // http://stackoverflow.com/questions/15061207/how-to-draw-a-straight-line-on-an-ios-map-without-moving-the-map-using-mkmapkit
    //add line by line, instead add all lines in one MKPolyline object, because I want to draw color differently in viewForOverlay
    int size = [overlays count];
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
    [self.mapView addAnnotations:annotationsToRemove];
    [self cleanSelectedAnnotationSet];
    if (tutorialView != nil)
        [tutorialView updateDateText];
    //[2014-01-06]
    //*** By moving following to didAddAnnotation(), I solved the issue that forcuse an event to date cause all image to show, because above [self.mapView addAnnotations:...] will run parallel to bellow [self showDescr..] while this depends on selectedAnnotationSet prepared in viewForAnnotation, thuse cause problem
    //[self showDescriptionLabelViews:self.mapView];
}

- (NSString*)getImageIdentifier:(NSDate *)eventDate :(NSString*)specialMarkerName
{
    // NSLog(@"  --------------- %u", debugCount);
    //debugCount = debugCount + 1;

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
            return [ATConstants WhiteFlagAnnotationIdentifier];
        
        return pngNameWithAlpha;
    }
    // For regular marker, I tried to use alpha instead of different marker image, but the looks on view is bad, so keep it following way
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
        return [ATConstants WhiteFlagAnnotationIdentifier]; //Do not show if outside range, but tap annotation is added, just not show and tap will cause annotation show
    if (segmentDistance >= -2 && segmentDistance < -1)
        return [ATConstants Past1AnnotationIdentifier];
    if (segmentDistance >= -3 && segmentDistance < -2)
        return [ATConstants Past2AnnotationIdentifier];
    if (segmentDistance >= -4 && segmentDistance < -3)
        return [ATConstants Past3AnnotationIdentifier];
    if (segmentDistance>= - 5 && segmentDistance < -4 )
        return [ATConstants Past4AnnotationIdentifier];
    if (segmentDistance < -5 )
        return [ATConstants WhiteFlagAnnotationIdentifier]; //do not show if outside range,  but tap annotation is added, just not show and tap will cause annotation show
    return nil;
}

- (float)getDistanceFromFocusedDate:(NSDate*)eventDate
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSTimeInterval interval = [eventDate timeIntervalSinceDate:appDelegate.focusedDate];
    float dayInterval = interval/86400;
    float segmentInDays = appDelegate.selectedPeriodInDays;
    /** These logic is for my previouse thining that all point be shown, and color phase depends on selectedPeriodInDays
     float segmentDistance = dayInterval/segmentInDays;
     ***/
    
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

//delegate required implementation
- (void)deleteEvent{
    [self mapViewShowHideAction]; //de-select annotation will flip it, so double flip
    //delete the selectedAnnotation, also delete from db if has uniqueId in the selectedAnnotation
    [self.dataController deleteEvent:self.selectedAnnotation.uniqueId];
    [self.mapView removeAnnotation:self.selectedAnnotation];
    ATEventDataStruct* tmp = [[ATEventDataStruct alloc] init];
    tmp.uniqueId = self.selectedAnnotation.uniqueId;
    tmp.eventDate = self.selectedAnnotation.eventDate;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* list  = appDelegate.eventListSorted;
    
    NSString *key=[NSString stringWithFormat:@"%f|%f",self.selectedAnnotation.coordinate.latitude, self.selectedAnnotation.coordinate.longitude];
    //remove photo/text icon as well if there are
    UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
    if (tmpLbl != nil)
        [tmpLbl removeFromSuperview];
    [selectedAnnotationSet removeObjectForKey:key];//in case this is
    int index = [list indexOfObject:tmp]; //implemented isEqual
    if (index != NSNotFound)
        [list removeObjectAtIndex:index];
    NSLog(@"   delete object at index %i",index);
    
    [self deletePhotoFilesByEventId:tmp.uniqueId];//put all phot into deletedPhotoQueue
    if (index == 0 || index == [list count]) //do not -1 since it already removed the element
    {
        [self setTimeScrollConfiguration];
        [self displayTimelineControls];
    }
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
    if (self.timeZoomLine != nil)
        [self.timeZoomLine setNeedsDisplay];
    [self refreshEventListView];
}
- (void)cancelEvent{
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
}
- (void)restartEditor{
    [self cancelEvent];
    [self startEventEditor:viewForEditorSizeChange];
}
- (void)cancelPreference{
    if (self.preferencePopover != nil)
        [self.preferencePopover dismissPopoverAnimated:true];
}
- (void)updateEvent:(ATEventDataStruct*)newData newAddedList:(NSArray *)newAddedList deletedList:(NSArray*)deletedList thumbnailFileName:(NSString*)thumbNailFileName{
    //update annotation by remove/add, then update database or added to database depends on if have id field in selectedAnnotation
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];

    [self mapViewShowHideAction]; //de-select annotation will flip it, so double flip
    newData.lat = self.selectedAnnotation.coordinate.latitude;
    newData.lng = self.selectedAnnotation.coordinate.longitude;
    
    newData.uniqueId = self.selectedAnnotation.uniqueId;
    newData.eventDate = tmpDateHold;
    
    [self writePhotoToFile:newData.uniqueId newAddedList:newAddedList deletedList:deletedList photoForThumbNail:thumbNailFileName];//write file before add nodes to map, otherwise will have black photo on map
    if ([newAddedList count] > 0) //this is for adding photo in reader, in real reader, we hardly come here
    {
        int evtIndex = [appDelegate.eventListSorted indexOfObject:newData]; //implemented isEqual
        if (evtIndex != NSNotFound)
        {
            ATEventDataStruct* evt = appDelegate.eventListSorted[evtIndex];
            evt.eventType = EVENT_TYPE_HAS_PHOTO;
        }
    }
    NSString *key=[NSString stringWithFormat:@"%f|%f",newData.lat, newData.lng];
    UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
    if (tmpLbl != nil)
    {
        [tmpLbl removeFromSuperview];
        [selectedAnnotationSet removeObjectForKey:key]; //so when update a event with new photo or text, the new photo/text will occure immediately because all annotations will be redraw for possible date change
    }
    if ([deletedList count] > 0 && [self.eventEditor.photoScrollView.photoList count] == 0)
    { //This is to fix floating photo if removed last photo in an event
        NSString *key=[NSString stringWithFormat:@"%f|%f", selectedEventAnnotation.coordinate.latitude, selectedEventAnnotation.coordinate.longitude];
        [selectedAnnotationSet removeObjectForKey:key];
    }
    
    //Need remove/add annotation or following will work?
    [self.selectedAnnotation setDescription:newData.eventDesc];
    [self.selectedAnnotation setAddress:newData.address];
    [self.selectedAnnotation setEventDate:newData.eventDate];
    [self.selectedAnnotation setEventType:newData.eventType];
    //---I want to update info in annotation pop, but following will drop a new pin and no popup
    //---Following always add pin annotation because selectedAnnotation does not what type of annotation
    [self.mapView removeAnnotation:self.selectedAnnotation];
    ATAnnotationSelected *ann = [[ATAnnotationSelected alloc] init];
    ann.uniqueId = newData.uniqueId;
    [ann setCoordinate:self.selectedAnnotation.coordinate];
    ann.address = newData.address;
    ann.description=newData.eventDesc;
    ann.eventDate=tmpDateHold;
    ann.eventType=newData.eventType;
    [self.mapView addAnnotation:ann];
    
   
    
     appDelegate.focusedDate = ann.eventDate;
    [self setNewFocusedDateAndUpdateMap:newData needAdjusted:FALSE];
    [self setTimeScrollConfiguration];
    [self displayTimelineControls];
    
    if (self.timeZoomLine != nil)
        [self.timeZoomLine setNeedsDisplay];
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
    [self refreshEventListView];
}

//Save photo to file. Called by updateEvent after write event to db
//I should put image process functions such as resize/convert to JPEG etc in ImagePickerController
//put it here is because we have to save image here since we only have uniqueId and some other info here
-(void)writePhotoToFile:(NSString*)eventId newAddedList:(NSArray*)newAddedList deletedList:(NSArray*)deletedList photoForThumbNail:(NSString*)photoForThumbnail
{
    NSString *newPhotoTmpDir = [ATHelper getNewUnsavedEventPhotoPath];
    NSString *photoFinalDir = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:eventId];
    //TODO may need to check if photo directory with this eventId exist or not, otherwise create as in ATHealper xxxxxx
    if (newAddedList != nil && [newAddedList count] > 0)
    {
        for (NSString* fileName in newAddedList)
        {
            NSString* tmpFileNameForNewPhoto = [NSString stringWithFormat:@"%@%@", NEW_NOT_SAVED_FILE_PREFIX,fileName];
            NSString* newPhotoTmpFile = [newPhotoTmpDir stringByAppendingPathComponent:tmpFileNameForNewPhoto];
            NSString* newPhotoFinalFileName = [photoFinalDir stringByAppendingPathComponent:fileName];
            NSError *error;
            BOOL eventPhotoDirExistFlag = [[NSFileManager defaultManager] fileExistsAtPath:photoFinalDir isDirectory:false];
            if (!eventPhotoDirExistFlag)
                [[NSFileManager defaultManager] createDirectoryAtPath:photoFinalDir withIntermediateDirectories:YES attributes:nil error:&error];
            [[NSFileManager defaultManager] moveItemAtPath:newPhotoTmpFile toPath:newPhotoFinalFileName error:&error];
            //Add to newPhotoQueue for sync to dropbox
            [[self dataController] insertNewPhotoQueue:[eventId stringByAppendingPathComponent:fileName]];
        }
        NSError* error;
        //remove the dir then recreate to clean up this temp dir
        [[NSFileManager defaultManager] removeItemAtPath:newPhotoTmpDir error:&error];
        if (error == nil)
            [[NSFileManager defaultManager] createDirectoryAtPath:newPhotoTmpDir withIntermediateDirectories:YES attributes:nil error:&error];
    }
    NSString* thumbPath = [photoFinalDir stringByAppendingPathComponent:@"thumbnail"];
    if (photoForThumbnail == nil)
    {
        //check if thumbnail exist or not, if not write first photo as thumbnail. This is to make sure there is a thumbnail, for example added the first photo but not select any as a thumbnail yet
        
        BOOL isDir;
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:thumbPath isDirectory:&isDir];
        if (!fileExist && newAddedList != nil && [newAddedList count] > 0)
            photoForThumbnail = newAddedList[0];
    }
    if (photoForThumbnail != nil ) //EventEditor must make sure indexForThmbnail is < 0 if no change to thumbNail
    {
        if ([photoForThumbnail hasPrefix:NEW_NOT_SAVED_FILE_PREFIX])
            photoForThumbnail = [photoForThumbnail substringFromIndex:[NEW_NOT_SAVED_FILE_PREFIX length]];//This is the case when user select new added photo as icon
        UIImage* photo = [UIImage imageWithContentsOfFile: [photoFinalDir stringByAppendingPathComponent:photoForThumbnail ]];
        UIImage* thumbImage = [ATHelper imageResizeWithImage:photo scaledToSize:CGSizeMake(THUMB_WIDTH, THUMB_HEIGHT)];
        NSData* imageData = UIImageJPEGRepresentation(thumbImage, JPEG_QUALITY);
        // NSLog(@"---------last write success:%i thumbnail file size=%i",ret, imageData.length);
        [imageData writeToFile:thumbPath atomically:NO];
    }
    if (deletedList != nil && [deletedList count] > 0)
    {
        NSError *error;
        for (NSString* fileName in deletedList)
        {
            NSString* deletePhotoFinalFileName = [photoFinalDir stringByAppendingPathComponent:fileName];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:deletePhotoFinalFileName];
            //NSLog(@"Path to file: %@", deletePhotoFinalFileName);
            //NSLog(@"File exists: %d", fileExists);
            //NSLog(@"Is deletable file at path: %d", [[NSFileManager defaultManager] isDeletableFileAtPath:deletePhotoFinalFileName]);
            if (fileExists)
            {
                BOOL success = [[NSFileManager defaultManager] removeItemAtPath:deletePhotoFinalFileName error:&error];
                if (!success)
                    NSLog(@"Error: %@", [error localizedDescription]);
                else
                   [[self dataController] insertDeletedPhotoQueue:[eventId stringByAppendingPathComponent:fileName]];
            }
        }
    }
}

-(void)deletePhotoFilesByEventId:(NSString*)eventId
{
    // Find the path to the documents directory
    if (eventId == nil || [eventId length] == 0)
        return;  //Bug fix. This bug is in ver1.0. When remove drop-pin, fileName is empty,so it will remove whole document directory such as myEvents, very bad bug
    NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:eventId];
    NSError *error;
    NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
    //all photo files under this event id directory should be removed
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fullPathToFile error:&error];
    if (success) {
        if (tmpFileList != nil && [tmpFileList count] > 0)
        {
            for (NSString* file in tmpFileList)
            {
                [[self dataController] insertDeletedPhotoQueue:[eventId stringByAppendingPathComponent:file]];
                [[NSFileManager defaultManager] removeItemAtPath:[fullPathToFile stringByAppendingPathComponent:file] error:&error];
            }
            [[self dataController] insertDeletedEventPhotoQueue:eventId];
        }
        NSLog(@"Error removing document path: %@", error.localizedDescription);
    }
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
        ATDefaultAnnotation *pa = [[ATDefaultAnnotation alloc] initWithLocation:searchPoint];
        pa.eventDate = [NSDate date];
        pa.description=NEWEVENT_DESC_PLACEHOLD;//@"add by search";
        pa.address = theSearchBar.text; //TODO should get from placemarker
        [_mapView addAnnotation:pa];
        
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
    //when click on annotation, all timewheel/image will flip just as tap on map, so I will flip it back so keep same state as before tap on annotation
    if (mapViewShowWhatFlag == 3)
        mapViewShowWhatFlag = 1;
    else
        mapViewShowWhatFlag ++;
    [self mapViewShowHideAction];
}
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    //NSLog(@"de-selected anno");
    // if (mapViewShowWhatFlag == 1) //since select will always show it, deselect will do opposit always
    if (mapViewShowWhatFlag == 3)
        mapViewShowWhatFlag = 1;
    else
        mapViewShowWhatFlag ++;
    [self mapViewShowHideAction];
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


- (void) refreshEventListView
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSDictionary* scaleDateDic = [ATHelper getScaleStartEndDate:appDelegate.focusedDate];
    NSDate* scaleStartDay = [scaleDateDic objectForKey:@"START"];
    NSDate* scaleEndDay = [scaleDateDic objectForKey:@"END"];
    
    int offset = 60;

    if ([self.startDate compare:scaleStartDay] == NSOrderedDescending)
        scaleStartDay = self.startDate;
    if ([self.endDate compare:scaleEndDay] == NSOrderedAscending)
        scaleEndDay = self.endDate;
    //NSLog(@" === scaleStartDate = %@,  scaleEndDay = %@", scaleStartDay, scaleEndDay);
    NSArray* allEventSortedList = appDelegate.eventListSorted;
    //try to move evetlistview to right side screenWidht - eventListViewCellWidth, but a lot of trouble, not know why
    //  even make x to 30, it will move more than 30, besides, not left side tap works
    CGRect newFrame = CGRectMake(0,offset,0,0);
    int numOfCellOnScreen = 0;
    
    NSMutableArray* eventListViewList = [[NSMutableArray alloc] init];
    
    int cnt = [allEventSortedList count];
    if (cnt == 0 )
    {
        [eventListView setFrame:newFrame];
        [eventListView.tableView setFrame:newFrame];
        [eventListView refresh:eventListViewList];
        return;
    }
    ATEventDataStruct* latestEvent = allEventSortedList[0];
    ATEventDataStruct* earlistEvent = allEventSortedList[cnt -1];
    
    //case special: where startDate/EndDate range is totally outside the event date range, or even no event at all
    if ([scaleStartDay compare:latestEvent.eventDate] == NSOrderedDescending || [scaleEndDay compare: earlistEvent.eventDate] == NSOrderedAscending)
    {
        [eventListView setFrame:newFrame];
        [eventListView.tableView setFrame:newFrame];
        [eventListView refresh: eventListViewList];
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
    //above logic will remain startDateIdx/endDateIdx to be -1 if no events
    cnt = [eventListViewList count]; //Inside ATEventListWindow, this will add two rows for arrow button, one at top, one at bottom
    if (cnt > 0)
    {
        numOfCellOnScreen = cnt;
        if (cnt > [ATConstants eventListViewCellNum])
            numOfCellOnScreen = [ATConstants eventListViewCellNum];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
                offset = offset - 10;
            else
                offset = offset - 20;
        }
        int extra = 0;
        if (cnt == 1)
            extra = 60;
        else if (cnt == 2)
            extra = 80;
        else if (cnt == 3 && UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
            extra = 120;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            extra = 60; //previouse it was 0, now change to 40 after add up/down arrow, so have extra space to show partial arrow button
        newFrame = CGRectMake(0,offset,[ATConstants eventListViewCellWidth],numOfCellOnScreen * [ATConstants eventListViewCellHeight] + extra);
    }
    eventListView.hidden = false;
    
    //important Tricky: bottom part of event list view is not clickable, thuse down arrow button always not clickable, add some height will works
    CGRect aaa = newFrame;
    aaa.size.height = aaa.size.height + 100; //Very careful: if add too much such as 500, it seems work, but left side of timewheel will click through when event list view is long. adjust this value to test down arrow button and left side of timewheel
    [eventListView setFrame:aaa];
    
    [eventListView.tableView setFrame:newFrame];
    [eventListView refresh: eventListViewList];
}
- (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

- (void) startAuthorView
{
    if (authorView == nil)
    {
        authorView = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
        [authorView.layer setCornerRadius:10.0f];
    }
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@"UPDATE_MODE" forKey:AUTHOR_MODE_KEY];
    appDelegate.authorMode = true;
    [userDefault synchronize];

    [UIView transitionWithView:self.mapView
                      duration:0.5
                       options:UIViewAnimationTransitionFlipFromRight //any animation
                    animations:^ {
                        [authorView setFrame:CGRectMake([ATConstants screenWidth] - 300, 130, 300, 80)];
                        authorView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:0.7 alpha:0.6];
                        authorView.layer.shadowColor = [UIColor grayColor].CGColor;
                        authorView.layer.shadowOffset = CGSizeMake(15,15);
                        authorView.layer.shadowOpacity = 1;
                        authorView.layer.shadowRadius = 10.0;
                        [self.mapView addSubview:authorView];
                        //[self partialInitEpisodeView];
                    }
                    completion:^(BOOL finished) {[self partialInitAuthorView];}];
    [appDelegate emptyEventList]; //this will cause eventListSorted to be generated again from internet
    [self refreshAnnotations];
    [self refreshEventListView];
}

//the purpose to have this to be called in completion:^ is to make animation together with all subviews
//(ATTutorialView has drawRect so no such issue)
- (void) partialInitAuthorView
{
    [[authorView subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UILabel* lblWording = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 180, 30)];
    lblWording.text = NSLocalizedString(@"Author Mode:",nil);
    [authorView addSubview:lblWording];
    

    UIButton *btnDropbox = [UIButton buttonWithType:UIButtonTypeSystem];
    btnDropbox.frame = CGRectMake(5, 40, 120, 40);
    [btnDropbox setTitle:NSLocalizedString(@"Sync Dropbox",nil) forState:UIControlStateNormal];
    btnDropbox.titleLabel.font = [UIFont fontWithName:@"Arial-Bold" size:15];
    [btnDropbox addTarget:self action:@selector(photoDroboxClicked:) forControlEvents:UIControlEventTouchUpInside];
    [authorView addSubview: btnDropbox];
    
    UIButton *btnBackToViewMode = [UIButton buttonWithType:UIButtonTypeSystem];
    btnBackToViewMode.frame = CGRectMake(125, 40, 60, 40);
    [btnBackToViewMode setTitle:NSLocalizedString(@"Quit",nil) forState:UIControlStateNormal];
    btnBackToViewMode.titleLabel.font = [UIFont fontWithName:@"Arial-Bold" size:17];
    [btnBackToViewMode addTarget:self action:@selector(quitClicked:) forControlEvents:UIControlEventTouchUpInside];
    [authorView addSubview: btnBackToViewMode];
    
    UIButton *btnLogout = [UIButton buttonWithType:UIButtonTypeSystem];
    btnLogout.frame = CGRectMake(180, 40, 120, 40);
    [btnLogout setTitle:NSLocalizedString(@"Logout&Quit",nil) forState:UIControlStateNormal];
    btnLogout.titleLabel.font = [UIFont fontWithName:@"Arial-Bold" size:17];
    [btnLogout addTarget:self action:@selector(logoutClicked:) forControlEvents:UIControlEventTouchUpInside];
    [authorView addSubview: btnLogout];
    
}

- (void) closeAuthorView
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (authorView != nil)
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:@"VIEW_MODE" forKey:AUTHOR_MODE_KEY];
        appDelegate.authorMode = false;
        [userDefault synchronize];
        [UIView transitionWithView:self.mapView
                          duration:0.5
                           options:UIViewAnimationTransitionCurlDown
                        animations:^ {
                            [authorView setFrame:CGRectMake(0,0,0,0)];
                        }
                        completion:^(BOOL finished) {
                            [authorView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                            [authorView removeFromSuperview];
                            authorView = nil;
                        }];
    }
    [appDelegate emptyEventList]; //this will cause eventListSorted to be generated again from internet
    [self refreshAnnotations];
    [self refreshEventListView];
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
-(void) quitClicked:(id)sender
{
    [self closeAuthorView];
}
-(void) logoutClicked:(id)sender
{
    [self closeAuthorView];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
    [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
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
-(void)initiAdBanner
{
    if (!self.iAdBannerView)
    {
        CGRect rect = CGRectMake(0, AD_Y_POSITION_IPAD, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            rect = CGRectMake(0, AD_Y_POSITION_PHONE, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
        self.iAdBannerView = [[ADBannerView alloc]initWithFrame:rect];
        self.iAdBannerView.delegate = self;
        self.iAdBannerView.hidden = TRUE;
        [self.view addSubview:self.iAdBannerView];
    }
}

-(void)initgAdBanner
{
    if (!self.gAdBannerView)
    {
        CGRect rect = CGRectMake(0, 60, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            rect = CGRectMake(0, AD_Y_POSITION_PHONE, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
        self.gAdBannerView = [[GADBannerView alloc] initWithFrame:rect];
        self.gAdBannerView.adUnitID = @"ca-app-pub-5383516122867647/8499480217";
        self.gAdBannerView.rootViewController = self;
        self.gAdBannerView.delegate = self;
        self.gAdBannerView.hidden = TRUE;
        [self.view addSubview:self.gAdBannerView];
    }
}

-(void)hideBanner:(UIView*)banner
{
    if (banner && ![banner isHidden])
    {
        [UIView beginAnimations:@"hideBanner" context:nil];
        banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height - 60);
        [UIView commitAnimations];
        banner.hidden = TRUE;
    }
}
-(void)showBanner:(UIView*)banner
{
    if (banner && [banner isHidden])
    {
        [UIView beginAnimations:@"showBanner" context:nil];
        banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height + 60);
        [UIView commitAnimations];
        banner.hidden = FALSE;
    }
}

//this function go with navigator show/hide
-(void)showAdAtTop:(BOOL)topFlag
{
    if (topFlag)
    {
        CGRect frame = self.iAdBannerView.frame;
        frame.origin.y = 0;
        self.iAdBannerView.frame = frame;
        frame = self.gAdBannerView.frame;
        frame.origin.y = 0;
        self.gAdBannerView.frame = frame;
    }
    else
    {
        int yPos = AD_Y_POSITION_IPAD;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            yPos = AD_Y_POSITION_PHONE;
        CGRect frame = self.iAdBannerView.frame;
        frame.origin.y = yPos;
        self.iAdBannerView.frame = frame;
        frame = self.gAdBannerView.frame;
        frame.origin.y = yPos;
        self.gAdBannerView.frame = frame;
    }
}
////////// iAd delegate
// Called before the add is shown, time to move the view
- (void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    NSLog(@"----- iAd load");
    [self hideBanner:self.gAdBannerView];
    [self showBanner:self.iAdBannerView];
}

// Called when an error occured
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"###### iAd error: %@", error);
    [self hideBanner:self.iAdBannerView];
    [self.gAdBannerView loadRequest:[GADRequest request]];
}

//////////gAd delegate
// Called before ad is shown, good time to show the add
- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    NSLog(@"------ Admob load");
    [self hideBanner:self.iAdBannerView];
    [self showBanner:self.gAdBannerView];
}

// An error occured
- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    NSLog(@"######## Admob error: %@", error);
    [self hideBanner:self.gAdBannerView];
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
    [self refreshEventListView]; //so show checkIcon for selected row
    
    //bookmark selected event
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    int idx = [appDelegate.eventListSorted indexOfObject:ent];
    [userDefault setObject:[NSString stringWithFormat:@"%d",idx ] forKey:@"BookmarkEventIdx"];
    [userDefault synchronize];
    
    
    [self.searchDisplayController setActive:NO];//this will dismiss search display table same as click cancel button
    
}

@end
