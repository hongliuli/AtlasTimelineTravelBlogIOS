//
//  ATViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 12/28/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ATDataController.h"
#import "ATTravelWebViewController.h"
#import "ATPreferenceViewController.h"
#import <StoreKit/StoreKit.h>
#import <iAd/iAd.h>
#import <MessageUI/MessageUI.h>
#import "ADClusterMapView.h"

@class ATAppDelegate;
@class ATEventAnnotation;
@class ATTimeScrollWindowNew;
@class ATTimeZoomLine;

@interface ATViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, UISearchDisplayDelegate, UISearchBarDelegate,UIAlertViewDelegate, MFMailComposeViewControllerDelegate, WKNavigationDelegate>
{
    ATDataController *dataController;

}


@property (strong, nonatomic) IBOutlet ADClusterMapView *mapView;
@property (nonatomic, retain, readonly) ATDataController *dataController;
@property (strong, nonatomic) IBOutlet CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet CLGeocoder *geoCoder;
@property (strong, nonatomic) IBOutlet CLLocation *location;
@property (strong, nonatomic) IBOutlet UIPopoverController* eventEditorPopover;
@property (strong, nonatomic) IBOutlet ATTravelWebViewController* webViewController;
@property (strong, nonatomic) ATEventAnnotation* selectedAnnotation;
@property (strong, nonatomic) UILabel* focusedEventLabel;
//@property (strong, nonatomic) UISlider * scaleSlider;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) ATTimeScrollWindowNew* timeScrollWindow;
@property (strong, nonatomic) UIPopoverController* preferencePopover; //store it in prepareSeque, used in ATHelper to dismiss it when start user verification popover
//following two will be changed when loaded EventListSorted and eventEditor update/deleted event with max/min dates
@property (strong, nonatomic) NSDate* startDate;
@property (strong, nonatomic) NSDate* endDate;
@property (strong, nonatomic) ATTimeZoomLine* timeZoomLine;

@property (strong, nonatomic) GADBannerView *gAdBannerView;
@property int mapViewShowWhatFlag; //see MAPVIEW_SHOW_xxxxx macros

- (void) prepareMapView;
- (NSString*) getImageIdentifier:(ATEventAnnotation*) ann :(NSString*) specialMarker;
- (Boolean) eventInPeriodRange:(NSDate*) eventDate;
- (float) getDistanceFromFocusedDate:(NSDate*) eventDate;
- (void) setSelectedPeriodLabel;
- (void) changeTimeScaleState;
- (void) setNewFocusedDateAndUpdateMap:(ATEventDataStruct*) ent needAdjusted:(BOOL)newdAdjust;
- (void) setNewFocusedDateAndUpdateMapWithNewCenter:(ATEventDataStruct*) ent :(int)zoomLevel;
- (void) refreshAnnotations;
- (void) cleanSelectedAnnotationSet; //see comments in .m file
- (void) showOverlays;
- (void) displayZoomLine;
- (void) cancelPreference;
- (void) refreshEventListView:(BOOL)callFromScrollTimewheel;
- (int) zoomLevel;
- (void) closeAuthorView;
- (void) hideTimeScrollAndNavigationBar:(BOOL)hideFlag;


@end
