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

#import <QuartzCore/QuartzCore.h>

#import "ATViewController.h"
#import "ATDefaultAnnotation.h"
#import "ATAnnotationSelected.h"
#import "ATAnnotationAfter1.h"
#import "ATAnnotationAfter2.h"
#import "ATAnnotationAfter3.h"
#import "ATAnnotationAfter4.h"
#import "ATAnnotationPast1.h"
#import "ATAnnotationPast2.h"
#import "ATAnnotationPast3.h"
#import "ATAnnotationPast4.h"
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

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395
#define ZOOM_LEVEL_TO_HIDE_DESC 4
#define JPEG_QUALITY 0.5
#define THUMB_JPEG_QUALITY 0.3
#define DISTANCE_TO_HIDE 80

#define RESIZE_WIDTH 600
#define RESIZE_HEIGHT 450
#define THUMB_WIDTH 120
#define THUMB_HEIGHT 70

#define FREE_VERSION_QUOTA 50

#define EDITOR_PHOTOVIEW_WIDTH 190
#define EDITOR_PHOTOVIEW_HEIGHT 160
#define NEWEVENT_DESC_PLACEHOLD @"Write notes here"
#define NEW_NOT_SAVED_FILE_PREFIX @"NEW"

@interface MFTopAlignedLabel : UILabel

@end




@implementation ATViewController
{
    NSString* selectedAnnotationIdentifier;
    int debugCount;
    CGRect focusedLabelFrame;
    NSMutableArray* timeScaleArray;
    int timelineWindowShowFlag; //1 is show, 0 is hide. Change by tap gesture

    NSMutableArray* selectedAnnotationNearestLocationList; //do not add to selectedAnnotationSet if too close
    NSMutableDictionary* selectedAnnotationSet;//hold uilabels for selected annotation's description
    NSDate* regionChangeTimeStart;
    ATDefaultAnnotation* newAddedPin;
    UIButton *locationbtn;
    CGRect timeScrollWindowFrame;
    ATTutorialView* tutorialView;

    NSMutableArray* selectedAnnotationBringToFrontList;
    ATInAppPurchaseViewController* purchase; // have to be global because itself has delegate to use it self
    ATEventAnnotation* selectedEventAnnotation;
}

@synthesize mapView = _mapView;

- (ATDataController *)dataController { //initially I want to have a singleton of dataController here, but not good if user change database file source, instance it ever time. It is ok here because only called every time user choose to delete/insert
    dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    return dataController;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    selectedAnnotationBringToFrontList = [[NSMutableArray alloc] init];
    [ATHelper createPhotoDocumentoryPath];
    self.locationManager = [[CLLocationManager alloc] init];
    timelineWindowShowFlag = 1;
    int searchBarHeight = [ATConstants searchBarHeight];
    int searchBarWidth = [ATConstants searchBarWidth];
    [self.navigationItem.titleView setFrame:CGRectMake(0, 0, searchBarWidth, searchBarHeight)];

    //Find this spent me long time: searchBar used titleView place which is too short, thuse tap on searchbar right side keyboard will not show up, now it is good
	[self calculateSearchBarFrame];
    
    // create a custom navigation bar button and set it to always says "Back"
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = @"Back";
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    
    //add two button at right (can not do in storyboard for multiple button): setting and Help, available in iOS5
 //   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
 //   {
        UIBarButtonItem *settringButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(settingsClicked:)];
        
        //NOTE the trick to set background image for a bar buttonitem
        UIButton *helpbtn = [UIButton buttonWithType:UIButtonTypeCustom];
        helpbtn.frame = CGRectMake(0, 0, 30, 30);
        [helpbtn setImage:[UIImage imageNamed:@"help.png"] forState:UIControlStateNormal];
        [helpbtn addTarget:self action:@selector(tutorialClicked:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithCustomView:helpbtn];
        self.navigationItem.rightBarButtonItems = @[settringButton, helpButton];
 //   }

    
	// Do any additional setup after loading the view, typically from a nib.
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(handleLongPressGesture:)];
    lpgr.minimumPressDuration = 0.3;  //user must press for 0.5 seconds
    [_mapView addGestureRecognizer:lpgr];
    // tap to show/hide timeline navigator
    UITapGestureRecognizer *tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [_mapView addGestureRecognizer:tapgr];

    selectedAnnotationSet = [[NSMutableDictionary alloc] init];
    selectedAnnotationNearestLocationList = [[NSMutableArray alloc] init];
    regionChangeTimeStart = [[NSDate alloc] init];
    [self prepareMapView];
}
-(void) viewDidAppear:(BOOL)animated
{
    [self displayTimelineControls]; //MOTHER FUCKER, I struggled long time when I decide to put timescrollwindow at bottom. Finally figure out have to put this code here in viewDidAppear. If I put it in viewDidLoad, then first time timeScrollWindow will be displayed in other places if I want to display at bottom, have to put it here
    [self.timeZoomLine showHideScaleText:false];
}
-(void) settingsClicked:(id)sender  //IMPORTANT only iPad will come here, iPhone has push segue on storyboard
{
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There is a new version!"
                                                        message:@"Please update from App Store"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
            [alert show];
        }
    }
    
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
        button.frame = CGRectMake([ATConstants screenWidth] - 120, 20, 110, 30);
        
        [button.layer setCornerRadius:7.0f];
        //[button.layer:YES];
        [button setTitle:@"Online Help" forState:UIControlStateNormal];
        button.titleLabel.backgroundColor = [UIColor blueColor];
        button.backgroundColor = [UIColor blueColor];
        [button addTarget:self action:@selector(onlineHelpClicked:) forControlEvents:UIControlEventTouchUpInside];
        [tutorialView addSubview: button];
        
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
    

    NSLog(@"=============== Map View loaded");
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.searchBar.delegate = self;
    self.mapView.delegate = self; //##### HONG #####: without this, vewForAnnotation() will not be called, google it
        
    //get data from core data and added annotation to mapview
    // currently start from the first one, later change to start with latest one
    NSArray * eventList = appDelegate.eventListSorted;
    if ([eventList count] > 0)
    {
        ATEventDataStruct* entStruct = eventList[0];

        [self setMapCenter:entStruct :[ATConstants defaultZoomLevel]];
    }

    //add annotation. ### this is the loop where we can adding NSLog to print individual items
    for (ATEventDataStruct* ent in eventList) {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake((CLLocationDegrees)ent.lat, (CLLocationDegrees)ent.lng);
        ATAnnotationSelected *eventAnnotation = [[ATAnnotationSelected alloc] initWithLocation:coord];
        eventAnnotation.uniqueId = ent.uniqueId;
        
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
        [self.timeZoomLine changeScaleLabelsDateFormat:self.startDate :self.endDate ];
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
}
- (void)setMapCenter:(ATEventDataStruct*)ent :(int)zoomLevel
{
    // clamp large numbers to 28
    CLLocationCoordinate2D centerCoordinate;
    centerCoordinate.latitude=ent.lat;
    centerCoordinate.longitude=ent.lng;
    zoomLevel = MIN(zoomLevel, 28);
    
    // use the zoom level to compute the region
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self.mapView setRegion:region animated:YES];
}

//orientation change will call following, need to removeFromSuperview when call addSubview
- (void)displayTimelineControls
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate* existingFocusedDate = appDelegate.focusedDate;
    
    CGRect timeZoomLineFrame;


    int timeWindowWidth = [ATConstants timeScrollWindowWidth];
    int timeWindowX = [ATConstants timeScrollWindowX];

    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];

    focusedLabelFrame = CGRectMake(timeWindowX - 43 + timeWindowWidth/2, timeWindowY, 50, 30);
    
    timeScrollWindowFrame = CGRectMake(timeWindowX,timeWindowY, timeWindowWidth,[ATConstants timeScrollWindowHeight]);
    timeZoomLineFrame = CGRectMake(timeWindowX - 15,self.view.bounds.size.height - [ATConstants timeScrollWindowHeight] - 18, timeWindowWidth + 30,10);
    
    //Add scrollable time window
    [self addTimeScrollWindow];

    if (self.timeZoomLine != nil)
        [self.timeZoomLine removeFromSuperview]; //incase orientation change
    self.timeZoomLine = [[ATTimeZoomLine alloc] initWithFrame:timeZoomLineFrame];
    self.timeZoomLine.backgroundColor = [UIColor clearColor];
    self.timeZoomLine.mapViewController = self;
    [self.view addSubview:self.timeZoomLine];

    [self changeTimeScaleState];
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
    [self.timeZoomLine changeScaleLabelsDateFormat:self.startDate :self.endDate ];
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
    [self.timeZoomLine changeTimeScaleState:self.startDate :self.endDate :appDelegate.selectedPeriodInDays :appDelegate.focusedDate];
}

- (void) setSelectedPeriodLabel
{
    [self.timeZoomLine changeScaleText:[self getSelectedPeriodLabel]];
}

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

- (void) flipTimelineWindowDisplay
{
    if (timelineWindowShowFlag == 1)
    {
        timelineWindowShowFlag = 0;
        self.timeScrollWindow.hidden = true;
        self.timeZoomLine.hidden = true;
        [self hideDescriptionLabelViews];
    }
    else
    {
        timelineWindowShowFlag = 1;
        self.timeScrollWindow.hidden=false;
        self.timeZoomLine.hidden = false;
        [self showDescriptionLabelViews:self.mapView];
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
        [self flipTimelineWindowDisplay];
    }
}

- (void)handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer
{
    
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)   // UIGestureRecognizerStateEnded)
        return;
    
     //NSLog(@"--- to be processed State is %d", gestureRecognizer.state);
    CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];
    
    //Following is to do not create annotation when tuch upper part of the map because of the timeline related controls.
    if ((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && touchPoint.y <= 120 && touchPoint.x > 300 && touchPoint.x < 650)
        ||
        (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation) && touchPoint.y <=105))
        return;
    
    CLLocationCoordinate2D touchMapCoordinate =
    [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
    double lat = touchMapCoordinate.latitude;
    double lng = touchMapCoordinate.longitude;

    self.location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
    //NSLog(@" inside gesture lat is %f", self.location.coordinate.latitude);
    
    //Have to initialize locally here, this is the requirement of CLGeocode
    //######## I have spend many days to figure it out on Jan 11, 2013 weekend
    self.geoCoder = [[CLGeocoder alloc] init];
    
    
    //reverseGeocodeLocation will take long time in very special case, such as when FreedomPop up/down, so use following stupid way to check network first, need more test on train

    NSString* link = @"http://www.google.com";
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:2];
    NSURLResponse* response=nil;
    NSError* error=nil;
    NSData* data=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    //NSString* URLString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if(data == nil || error != nil)
        [self addPinToMap:@"Unknow" :touchMapCoordinate];
    else 
        [self.geoCoder reverseGeocodeLocation: self.location completionHandler:
         ^(NSArray *placemarks, NSError *error) {
             //NSLog(@"reverseGeocoder:completionHandler: called lat=%f",self.location.coordinate.latitude);
             if (error) {
                 NSLog(@"Geocoder failed with error: %@", error);
             }
             NSString *locatedAt = @"Unknown";
             if (placemarks && placemarks.count > 0)
             {
                 //Get nearby address
                 CLPlacemark *placemark = [placemarks objectAtIndex:0];
                 //String to hold address
                 locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
             }
            [self addPinToMap:locatedAt :touchMapCoordinate];
      //  /*** following is for testing add to db for each longpress xxxxxxxx TODO
       // [self.dataController addEventEntityAddress:locatedAt description:@"desc by touch" date:[NSDate date] lat:touchMapCoordinate.latitude lng:touchMapCoordinate.longitude];
     //    */
         }];

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
    
    [self flipTimelineWindowDisplay]; //select annotation will flip it, so double flip
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    ATDefaultAnnotation* ann = (ATDefaultAnnotation*)annotation;

    
    // Following will filter out MKUserLocation annotation
    if ([annotation isKindOfClass:[ATDefaultAnnotation class]]) //ATDefaultAnnotation is when longPress
    {
        selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate]; //keep this line here, do not move inside 
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
            [leftButton setImage:[UIImage imageNamed:@"focusedIcon.png"] forState:UIControlStateNormal];
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
        selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate]; //keep this line here
        MKAnnotationView* annView = [self getImageAnnotationView:selectedAnnotationIdentifier :annotation];
        annView.annotation = annotation;
        NSString *key=[NSString stringWithFormat:@"%f|%f",ann.coordinate.latitude, ann.coordinate.longitude];
        //keey list of red  annotations
        if ([selectedAnnotationIdentifier isEqualToString: [ATConstants SelectedAnnotationIdentifier]])
        {
            [selectedAnnotationBringToFrontList addObject:annView];
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
                    UIImage* img = [self readPhotoThumbFromFile:ann.uniqueId];
                    if (img != nil)
                    {
                        UIImageView* imgView = [[UIImageView alloc]initWithImage: img];
                        imgView.tag = 100; //later used to get subview
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
                        //[tmpLbl setClipsToBounds:true];
                        //imgView.center = CGPointMake(tmpLbl.frame.size.width/2, tmpLbl.frame.size.height/2);
                    
                    }
                    else
                    {
                        //xxxxxx TODO if user switch source from server, photo may not be in local yet, then
                        //             should display text only and add download request in download queue
                        // ########## This is a important lazy download concept #############
                        tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
                        tmpLbl.text = [NSString stringWithFormat:@" %@", ann.description ];
                        tmpLbl.layer.cornerRadius = 8;
                        tmpLbl.layer.borderColor = [UIColor redColor].CGColor;
                        tmpLbl.layer.borderWidth = 1;
                    }
                }
                else
                {
                    tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
                    tmpLbl.text = [NSString stringWithFormat:@" %@", ann.description ];
                    tmpLbl.layer.cornerRadius = 8;
                    //If the event has photo before but the photos do not exist anymore, then show text with red board
                    //If this happen, the photo may in Dropbox. if not  in dropbox, then it lost forever.
                    //To change color, add a photo and delete it, then it will change to brown border
                    tmpLbl.layer.borderColor = [UIColor brownColor].CGColor;
                    tmpLbl.layer.borderWidth = 1;
                }
                
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
                    tmpLbl.text = ann.description; //need to change to take care of if user updated description in event editor
                
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
        return annView;
    }
    
    return nil;
}


//to put those white annotation behind the darkest annotation
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for (MKAnnotationView *view in selectedAnnotationBringToFrontList)
    {
        [[view superview] bringSubviewToFront:view];
    }
    [selectedAnnotationBringToFrontList removeAllObjects];
    //didAddAnnotationViews is called when focused to date or move timewheel caused by addAnnotation:removedAnntationSet
    [self showDescriptionLabelViews:self.mapView];
}


- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    //NSLog(@"regione willChange size: %i", [selectedAnnotationSet count]);
    for (id key in selectedAnnotationSet) {
        UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
       // ATEventAnnotation* eventAnn = (ATEventAnnotation*)key;
        tmpLbl.hidden=true;
    }
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{

    //NSLog(@"retion didChange, zoom level is %i", [self zoomLevel]);
    [self showDescriptionLabelViews:mapView];
    [self.timeZoomLine setNeedsDisplay];
    regionChangeTimeStart = [[NSDate alloc] init];
    
}
- (void) showDescriptionLabelViews:(MKMapView*)mapView
{
    if (timelineWindowShowFlag == 0) //why this?
        return;
    for (id key in selectedAnnotationSet) {
        NSArray *splitArray = [key componentsSeparatedByString:@"|"];
        UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude=[splitArray[0] doubleValue];
        coordinate.longitude = [splitArray[1] doubleValue];
        CGPoint annotationViewPoint = [mapView convertCoordinate:coordinate
                                                   toPointToView:mapView];
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
        if (tooCloseToShowFlag)
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
    UIImageView* imgView = (UIImageView*)[tmpLbl viewWithTag:100];
    if (imgView != nil)
    {
        imgView.frame = CGRectMake(imgView.frame.origin.x, imgView.frame.origin.y, tmpLbl.frame.size.width, tmpLbl.frame.size.height);
    }
        
}

- (NSUInteger) zoomLevel {
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
            UIImage *markerImage = [UIImage imageNamed:annotationIdentifier];
            customPinView.image = markerImage;
            customPinView.canShowCallout = YES;
            
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            rightButton.accessibilityLabel=@"right";
            customPinView.rightCalloutAccessoryView = rightButton;
            UIButton* leftButton = [UIButton buttonWithType:UIButtonTypeInfoLight ];
            [leftButton setImage:[UIImage imageNamed:@"focusedIcon.png"] forState:UIControlStateNormal];
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
    selectedEventAnnotation = ann;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard* storyboard = appDelegate.storyBoard;
    NSDateFormatter *dateFormater = appDelegate.dateFormater;
    self.selectedAnnotation = (ATEventAnnotation*)[view annotation];
    //TODO need to see if it is run on iPad or iPhone

    if ([control.accessibilityLabel isEqualToString: @"right"]){
        if (self.eventEditor == nil) {
            //I just learned from iOS5 tutor pdf, there is a way to create segue for accessory buttons, I do not want to change, Will use it in iPhone storyboard
            self.eventEditor = [storyboard instantiateViewControllerWithIdentifier:@"event_editor_id"];
            self.eventEditor.delegate = self;
        }
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.eventEditorPopover = [[UIPopoverController alloc] initWithContentViewController:self.eventEditor];
            self.eventEditorPopover.popoverContentSize = CGSizeMake(380,480);
            [self.eventEditorPopover presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        else {
            //[self performSegueWithIdentifier:@"eventeditor_segue_id" sender:nil];
            [self.navigationController presentModalViewController:self.eventEditor animated:YES]; //pushViewController: self.eventEditor animated:YES];
        }
        //has to set value here after above presentXxxxx method, otherwise the firsttime will display empty text
        [self.eventEditor resetEventEditor];
        
        //***********************************************
        //TODO xxxxxx THIS PART is for from ver1.2 to ver3, that is from single photo to multiple photo, to copy old version photo to directory structure
        //     Should remove this part in later version
        if (ann.uniqueId != nil)
        {
            NSString *photoPath = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:ann.uniqueId];
            NSString *photoTmpPath = [NSString stringWithFormat:@"%@_tmp",photoPath];
            NSString *photoNewPath = [photoPath stringByAppendingPathComponent:@"movedFromSinglePhotoVersion"]; //file name does not matter
            NSString *thumbPath = [photoPath stringByAppendingPathComponent:@"thumbnail"]; //file name does not matter
            NSError *error;
            BOOL isDir;
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            BOOL eventPhotoExistFlag = [fileMgr fileExistsAtPath:photoPath isDirectory:&isDir];
            if (eventPhotoExistFlag && !isDir )
            {
                [fileMgr moveItemAtPath:photoPath toPath:photoTmpPath error:&error];
                [fileMgr createDirectoryAtPath:photoPath withIntermediateDirectories:YES attributes:nil error:&error];
                [fileMgr moveItemAtPath:photoTmpPath toPath:photoNewPath error:&error];
                
                UIImage* photo = [UIImage imageWithContentsOfFile: photoNewPath];
                UIImage* thumbImage = [ATHelper imageResizeWithImage:photo scaledToSize:CGSizeMake(THUMB_WIDTH, THUMB_HEIGHT)];
                NSData* imageData = UIImageJPEGRepresentation(thumbImage, JPEG_QUALITY);
                // NSLog(@"---------last write success:%i thumbnail file size=%i",ret, imageData.length);
                [imageData writeToFile:thumbPath atomically:NO];
                [self.dataController insertNewPhotoQueue:[ann.uniqueId stringByAppendingPathComponent:@"movedFromSinglePhotoVersion"]];
            }
        }
        //*************************************************
        
        
        self.eventEditor.coordinate = ann.coordinate;
        if ([ann.description isEqualToString:NEWEVENT_DESC_PLACEHOLD])
        {
            self.eventEditor.description.textColor = [UIColor lightGrayColor];
        }

        self.eventEditor.description.text = ann.description;
        self.eventEditor.address.text=ann.address;
        self.eventEditor.dateTxt.text = [NSString stringWithFormat:@"%@",
                                         [dateFormater stringFromDate:ann.eventDate]];
        self.eventEditor.eventType = ann.eventType;
        self.eventEditor.hasPhotoFlag = EVENT_TYPE_NO_PHOTO; //not set to ann.eventType because we want to use this flag to decide if need save image again
        self.eventEditor.eventId = ann.uniqueId;
        [ATEventEditorTableController setEventId:ann.uniqueId];
        //if (ann.eventType == EVENT_TYPE_HAS_PHOTO)
        [self.eventEditor createPhotoScrollView: ann.uniqueId ];
        
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
        selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate];
        ATEventDataStruct* ent = [[ATEventDataStruct alloc] init];
        ent.address = ann.address;
        ent.lat = ann.coordinate.latitude;
        ent.lng = ann.coordinate.longitude;
        ent.eventDate = ann.eventDate;
        ent.eventType = ann.eventType;
        ent.eventDesc = ann.description;
        
        [self setNewFocusedDateAndUpdateMap:ent needAdjusted:TRUE]; //No reason, have to do focusedRow++ when focused a event in time wheel
        timelineWindowShowFlag = 1;
        self.timeScrollWindow.hidden=false;
        self.timeZoomLine.hidden = false;

    }
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
    //NSLog(@"refreshAnnotation called");
    NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy ] ;
    //TODO filter out those annotation outside the periodRange ...
    [ annotationsToRemove removeObject:self.mapView.userLocation ] ;
    [ self.mapView removeAnnotations:annotationsToRemove ] ;
    [self.mapView addAnnotations:annotationsToRemove];
    //[2014-01-06]
    //*** By moving following to didAddAnnotation(), I solved the issue that forcuse an event to date cause all image to show, because above [self.mapView addAnnotations:...] will run parallel to bellow [self showDescr..] while this depends on selectedAnnotationSet prepared in viewForAnnotation, thuse cause problem
    //[self showDescriptionLabelViews:self.mapView];
}

- (NSString*)getImageIdentifier:(NSDate *)eventDate
{
   // NSLog(@"  --------------- %u", debugCount);
    //debugCount = debugCount + 1;
     ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.focusedDate == nil) //set in annotation Left button click
        appDelegate.focusedDate = [[NSDate alloc] init];
    float segmentDistance = [self getDistanceFromFocusedDate:eventDate];

   // NSLog(@"--- dist=%f",segmentDistance);
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
        return @"small-white-flag.png"; //do not show if outside range,  but tap annotation is added, just not show and tap will cause annotation show
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
    NSLog(@"=============== Memory warning");
    // Dispose of any resources that can be recreated.
}

//delegate required implementation
- (void)deleteEvent{
    [self flipTimelineWindowDisplay]; //de-select annotation will flip it, so double flip
    //delete the selectedAnnotation, also delete from db if has uniqueId in the selectedAnnotation
    [self.dataController deleteEvent:self.selectedAnnotation.uniqueId];
    [self.mapView removeAnnotation:self.selectedAnnotation];
    ATEventDataStruct* tmp = [[ATEventDataStruct alloc] init];
    tmp.uniqueId = self.selectedAnnotation.uniqueId;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* list  = appDelegate.eventListSorted;

    NSString *key=[NSString stringWithFormat:@"%f|%f",self.selectedAnnotation.coordinate.latitude, self.selectedAnnotation.coordinate.longitude];
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
}
- (void)cancelEvent{
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
}

- (void)updateEvent:(ATEventDataStruct*)newData newAddedList:(NSArray *)newAddedList deletedList:(NSArray*)deletedList thumbnailFileName:(NSString*)thumbNailFileName{
    //update annotation by remove/add, then update database or added to database depends on if have id field in selectedAnnotation
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* list  = appDelegate.eventListSorted;
    //For add event, check if the app has been purchased
    if (self.selectedAnnotation.uniqueId == nil && [list count] >= FREE_VERSION_QUOTA )
    {
        
        //solution in yahoo email, search"non-consumable"
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        if ([userDefault objectForKey:IN_APP_PURCHASED] == nil)
        {
            purchase = [[ATInAppPurchaseViewController alloc] init];
            [purchase processInAppPurchase];
        }
        //Check again if purchase has really done
        if ([userDefault objectForKey:IN_APP_PURCHASED] == nil)
            return;
    }

    [self flipTimelineWindowDisplay]; //de-select annotation will flip it, so double flip
    newData.lat = self.selectedAnnotation.coordinate.latitude;
    newData.lng = self.selectedAnnotation.coordinate.longitude;
    ATEventEntity* newEntity = [self.dataController updateEvent:self.selectedAnnotation.uniqueId EventData:newData];
    if (newEntity == nil)
        newData.uniqueId = self.selectedAnnotation.uniqueId;
    else
        newData.uniqueId = newEntity.uniqueId;

    [self writePhotoToFile:newData.uniqueId newAddedList:newAddedList deletedList:deletedList photoForThumbNail:thumbNailFileName];//write file before add nodes to map, otherwise will have black photo on map
    if ([deletedList count] > 0 && [self.eventEditor.photoScrollView.photoList count] == 0)
    { //This is to fix floating photo if removed last photo in an event
        NSString *key=[NSString stringWithFormat:@"%f|%f", selectedEventAnnotation.coordinate.latitude, selectedEventAnnotation.coordinate.longitude];
        [selectedAnnotationSet removeObjectForKey:key];
    }
    NSString *key=[NSString stringWithFormat:@"%f|%f",newData.lat, newData.lng];
    UILabel* tmpLbl = [selectedAnnotationSet objectForKey:key];
    if (tmpLbl != nil)
        [selectedAnnotationSet removeObjectForKey:key]; //so when update a event with new photo or text, the new photo/text will occure immediately because all annotations will be redraw for possible date change
    
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
    ann.eventDate=newData.eventDate;
    ann.eventType=newData.eventType;
    [self.mapView addAnnotation:ann];
    
    int newIndex  = NSNotFound;
    if (newEntity != nil) //we can  modify the logic, should use if selectedAnnotation.UniqueId == null to decide it is add action
    {
        //add in sorted order so timeline view can generate sections
        [list insertObject:newData atIndex:0];
        [list sortUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(ATEventEntity*)a eventDate];
            NSDate *second = [(ATEventEntity*)b eventDate];
            return [first compare:second]== NSOrderedAscending;
        }];
    }
    else //for update, still need to remove and add incase  date is updated
    {
        newIndex = [list indexOfObject:newData]; //implemented isEqual
        if (newIndex != NSNotFound)
            [list replaceObjectAtIndex:newIndex withObject:newData];
        [list sortUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(ATEventEntity*)a eventDate];
            NSDate *second = [(ATEventEntity*)b eventDate];
            return [first compare:second]== NSOrderedAscending;
        }];
    }
    
    appDelegate.focusedDate = ann.eventDate;
    [self setNewFocusedDateAndUpdateMap:newData needAdjusted:FALSE];
    
    //following check if new date is out of range when add.  or if it is update, then check if update on ends event
    if ( (newIndex != NSNotFound && (newIndex == 0 || newIndex == [list count] -1))
          || [self.startDate compare:newData.eventDate]==NSOrderedDescending || [self.endDate compare:newData.eventDate]==NSOrderedAscending)
    {
        [self setTimeScrollConfiguration];
        [self displayTimelineControls];
    }
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
    
    if (self.timeZoomLine != nil)
        [self.timeZoomLine setNeedsDisplay];
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
            [[NSFileManager defaultManager] removeItemAtPath:deletePhotoFinalFileName error:&error];
            if (error == nil)
                [[self dataController] insertDeletedPhotoQueue:[eventId stringByAppendingPathComponent:fileName]];
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

-(UIImage*)readPhotoThumbFromFile:(NSString*)eventId
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
        
        NSLog(@"[searchBarSearchButtonClicked] Radius is %f", radius);
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
    if ([segue.identifier isEqualToString:@"iphone_settings"]) {
        [self performSegueWithIdentifier:@"iphone_settings" sender:self];
    }
}

//select/deselect tap will interfare my tap gesture handler, so try to resume timeline window original show/hide status
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    //NSLog(@"selected anno");
    if (timelineWindowShowFlag == 0) //always show timewindow when select
        [self flipTimelineWindowDisplay];
}
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
   //NSLog(@"de-selected anno");
    if (timelineWindowShowFlag == 1) //since select will always show it, deselect will do opposit always
        [self flipTimelineWindowDisplay];
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

@end
