//
//  ATTutorialView.m
//  AtlasTimelineIOS
//
//  Created by Hong on 4/23/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATTutorialView.h"
#import "ATConstants.h"
#import "ATAppDelegate.h"
#import "ATHelper.h"
#import "ATEventDataStruct.h"

#define ALERT_FOR_SWITCH_APP_AFTER_LONG_PRESS 991

@implementation ATTutorialView

int initialX;
int initialY = 100;
int itemWidth = 500;
int itemHeight = 30;
int currentYLocation;


int x_start;
int y_start;
int x_end ;
int y_end ;

int fontBig;
int fontSmall;
int imageSize;
int imageAnn;
float iPhoneSizeXFactor;
float iPhoneSizeYFactor;
float iphoneSizeSpecialFactor;

NSString* dateFocused;
NSString* timeZoomLevelStr;

UILabel* updatableLabel;
UILabel* updatableLabel2;

NSMutableArray* appStoreUrlList;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        // add subview etc here
    }
    
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    if ([targetName hasPrefix:@"WorldHeritage"])
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Switch to Chronicle Map App",nil)
                                                       message: NSLocalizedString(@"Use Chronicle Map App to organize your upcoming travel plans or view past events on map with timeline",nil)
                                                      delegate: self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                             otherButtonTitles: NSLocalizedString(@"Switch Now",nil), nil];
        alert.tag = ALERT_FOR_SWITCH_APP_AFTER_LONG_PRESS;
        [alert show];
        return self;
    }
    
    NSString* serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com//resources/newappshortlist.html"];
    NSString* responseStr  = [ATHelper httpGetFromServer:serviceUrl :false];
    NSMutableArray* appNameList = [[NSMutableArray alloc] init];
    appStoreUrlList = [[NSMutableArray alloc] init];
    
    if (responseStr != nil && [responseStr length] > 100)
    {
        NSArray* appList = [responseStr componentsSeparatedByString:@"\n"];
        for (NSString* appStr in appList)
        {
            if (appStr != nil && [appStr length] > 20)
            {
                NSString* appStrTmp = [appStr stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                NSArray* appDetail = [appStrTmp componentsSeparatedByString:@"|"];
                [appNameList addObject:NSLocalizedString(appDetail[0],nil)];
                [appStoreUrlList addObject:appDetail[1]];
            }

        }
        [appNameList addObject:NSLocalizedString(@"More ...",nil)];
        [appStoreUrlList addObject:NSLocalizedString(@"http://www.chroniclemap.com/resources/allapplist.html",nil)]; //TODO have chinese url
    }


    if ([appNameList count] > 0)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @""
                            message: NSLocalizedString(@"Related Apps to download",nil)
                            delegate: self
                            cancelButtonTitle:NSLocalizedString(@"Not Now",nil)
                            otherButtonTitles: nil];
        NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        NSLog(@" --- this app bunle name is %@", appName);
        for( NSString *title in appNameList)  {
            if (![appName isEqualToString:title])
                [alert addButtonWithTitle:title];
        }
        [alert show];
    }
    
    return self;
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == ALERT_FOR_SWITCH_APP_AFTER_LONG_PRESS)
    {
        if (buttonIndex == 0) //Not Now
            return; //user clicked cancel button
        
        if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"chroniclemap://"]]) //ChronicleMap app custom URL
        {
            NSString* chronicleMapAppUrl = @"https://itunes.apple.com/us/app/chronicle-map-event-based/id649653093?ls=1&mt=8";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:chronicleMapAppUrl]]; //download ChronicleMap from app store
        }
        return;
    }
    
    if (buttonIndex == 0) //Not Now
        return; //user clicked cancel button
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appStoreUrlList[buttonIndex -1]]];

}

- (void) updateDateText
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* fmt = appDelegate.dateFormater;
    dateFocused = @"[NO EVENT YET]";
    timeZoomLevelStr = NSLocalizedString(@"1000 Years",nil);
    if (appDelegate.focusedDate != nil)
        dateFocused = [fmt stringFromDate:appDelegate.focusedDate];
    dateFocused = [dateFocused substringToIndex:10];
    if (appDelegate.selectedPeriodInDays == 7)
        timeZoomLevelStr = NSLocalizedString(@"1 Week",nil);
    else if (appDelegate.selectedPeriodInDays == 30)
        timeZoomLevelStr = NSLocalizedString(@"1 Month",nil);
    else if (appDelegate.selectedPeriodInDays == 365)
        timeZoomLevelStr = NSLocalizedString(@"1 Year",nil);
    else if (appDelegate.selectedPeriodInDays == 3650)
        timeZoomLevelStr = NSLocalizedString(@"10 Years",nil);
    else if(appDelegate.selectedPeriodInDays == 36500)
        timeZoomLevelStr = NSLocalizedString(@"100 Years",nil);
    if (updatableLabel != nil)
    {
        updatableLabel.text = [NSString stringWithFormat: NSLocalizedString(@"2.   The selected date is %@ and the time zoom level is %@",nil), dateFocused, timeZoomLevelStr];
        updatableLabel2.text = [NSString stringWithFormat: NSLocalizedString(@"      So all events within %@ of %@ are colored as bellow, the darker the closer to it",nil), timeZoomLevelStr, dateFocused];
    }
    CGRect originalFrame = updatableLabel.frame;
    [updatableLabel setFrame:CGRectMake(0, originalFrame.origin.y, 0, 0)];
    [UIView transitionWithView:updatableLabel
                      duration:0.5f
                       options:UIViewAnimationCurveEaseInOut
                    animations:^(void) {
                        [updatableLabel setFrame:originalFrame];
                    }
                    completion:^(BOOL finished) {
                        // Do nothing
                        [updatableLabel setHidden:false];
                    }];
    CGRect originalFrame2 = updatableLabel2.frame;
    [updatableLabel2 setFrame:CGRectMake(0, originalFrame2.origin.y, 0, 0)];
    [UIView transitionWithView:updatableLabel2
                      duration:0.5f
                       options:UIViewAnimationCurveEaseInOut
                    animations:^(void) {
                        [updatableLabel2 setFrame:originalFrame2];
                    }
                    completion:^(BOOL finished) {
                        // Do nothing
                        [updatableLabel2 setHidden:false];
                    }];
}

//REMEBER: UIView do not have viewDidLoad() method, it is in viewController/
//         So, avoid using drawRect unless need draw graph, otheriwse addSubview buttons/text/labels in controller to this view
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    x_start = [ATConstants timeScrollWindowX] - 5;
    y_start = self.bounds.size.height - [ATConstants timeScrollWindowHeight] -5 ;
    x_end = x_start + [ATConstants timeScrollWindowWidth] + 5;
    y_end = self.bounds.size.height; // [ATConstants screenHeight] ;
    
    fontBig = 26;
    fontSmall = 16;
    imageSize=55;
    imageAnn=30;
    iPhoneSizeXFactor = 1;
    iphoneSizeSpecialFactor = 1;
    iPhoneSizeYFactor = 1;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        iphoneSizeSpecialFactor = 2;
        iPhoneSizeXFactor = 0.6;
        iPhoneSizeYFactor = 0.4;
        initialY = 20;
        itemHeight = 30;
        itemWidth = 140;
        fontBig = 18;
        fontSmall = 9;
        imageSize = 30;
        imageAnn = 23;
        x_start = x_start + 10;
    }
    initialX = x_start;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    // Draw the base.
    CGContextSetLineWidth(context, 1.0);
    //Draw lines around time window
    CGContextMoveToPoint(context, x_start, y_end);
    CGContextAddLineToPoint(context, x_start, y_start);
    CGContextAddLineToPoint(context, x_end, y_start);
    CGContextAddLineToPoint(context, x_end, y_end);

    CGContextStrokePath(context);
    
    /*
    CGRect frm = CGRectMake(x_start + 40, y_start - 10, itemWidth, itemHeight);
    timeWindowLabel = [[UILabel alloc] initWithFrame:frm];
    timeWindowLabel.text = @"Time Window";
    timeWindowLabel.font = [UIFont fontWithName:@"Arial" size:34];
    timeWindowLabel.backgroundColor = [UIColor clearColor];
    timeWindowLabel.textColor = [UIColor whiteColor];
    [self addSubview:timeWindowLabel];
    */
    
    CGRect titleFrame = CGRectMake(initialX, initialY - 120, itemWidth + 100, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:titleFrame];
    lbl.text = NSLocalizedString(@"Record/navigate events on map in chronological order!",nil);
    lbl.font = [UIFont fontWithName:@"Arial" size:24];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor lightTextColor];
    [self addSubview:lbl];
    
    [self updateDateText];
    
    //Call following in sequence because the based on currentYPosition
    [self addLongPressSection];
    
    [self addWhatIsHappeningSection];
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    if (![targetName hasPrefix:@"WorldHeritage"])
    {
        [self addRedGreenDotsSection];
    }

    //////////////////////////////////////////[self addTimeZoomLevelSection2];
    [self addTimeZoomLevelSection1];
    //following are on same y level, so change currentYLocation once:
    currentYLocation = currentYLocation + itemHeight + 50*iPhoneSizeYFactor;

    int centerX = x_start + [ATConstants timeScrollWindowWidth]/3;
    int adjust = 90;
    if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
        adjust = 50;

    [self addTimeZoomLevelSection:x_start - adjust :@"arrow-left-icon.png" :NSLocalizedString(@"Left Arrow:\nQuick move to earlier period having event(s)",nil) :currentYLocation];
    [self addTimeZoomLevelSection:centerX - 120 :nil :NSLocalizedString(@"Double-Tap Left side to zoom-out Time Wheel",nil) :currentYLocation + 30];
    [self addTimeZoomLevelSection:centerX :@"gesture-pinch.png" :NSLocalizedString(@"Pinch is another way of zooming Time Wheel",nil) :currentYLocation + 60];
    [self addTimeZoomLevelSection:centerX + 120 :nil :NSLocalizedString(@"Double-Tap Right side to zoom-in Time Wheel",nil) :currentYLocation + 30];
    [self addTimeZoomLevelSection:x_start + 2*[ATConstants timeScrollWindowWidth]/3   + 100:@"arrow-right-icon.png" :NSLocalizedString(@"Right Arrow:\nQuick move to next period having event(s)",nil) :currentYLocation];
}

- (void) addLongPressSection
{
    currentYLocation = initialY;
    CGRect frm = CGRectMake(initialX, currentYLocation, itemWidth * iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = NSLocalizedString(@"Add event:",nil);
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    //[self addSubview:lbl];
    
    UILabel* lblSearchAddress = [[UILabel alloc] initWithFrame:CGRectMake(frm.origin.x + 150*iPhoneSizeXFactor, frm.origin.y, 220*iPhoneSizeXFactor, 80*iPhoneSizeYFactor)];
    lblSearchAddress.text = NSLocalizedString(@"Search Address     OR  ",nil);
    lblSearchAddress.font = [UIFont fontWithName:@"Arial" size:20];
    lblSearchAddress.backgroundColor = [UIColor clearColor];
    lblSearchAddress.textColor = [UIColor whiteColor];
    //[self addSubview:lblSearchAddress];
    
    //draw line
    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(frm.origin.x + 350*iPhoneSizeXFactor, frm.origin.y, imageSize, imageSize) ];
    [imgView setImage:[UIImage imageNamed:@"gesture-longpress.png"]]; //long press image
    //[self addSubview:imgView];
    
    UILabel* lblLongPress = [[UILabel alloc] initWithFrame:CGRectMake(frm.origin.x + 410*iPhoneSizeXFactor, frm.origin.y, 250*iPhoneSizeXFactor, 80*iPhoneSizeYFactor)];
    lblLongPress.text = NSLocalizedString(@"Long-press on a map location.",nil);
    lblLongPress.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lblLongPress.backgroundColor = [UIColor clearColor];
    lblLongPress.textColor = [UIColor whiteColor];
    lblLongPress.lineBreakMode = NSLineBreakByWordWrapping;
    lblLongPress.numberOfLines=2;
    //[self addSubview:lblLongPress];
}

- (void) addWhatIsHappeningSection
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* fmt = appDelegate.dateFormater;
    NSString* date1 = @"N/A";
    NSString* date2 = @"N/A";
    ATEventDataStruct* evt1 = nil;
    ATEventDataStruct* evt2 = nil;

    NSUInteger eventCnt = [appDelegate.eventListSorted count];
    if (eventCnt > 1)
    {
        evt1 = appDelegate.eventListSorted[eventCnt - 1];
        evt2 = appDelegate.eventListSorted[0];
        
        date1 = [fmt stringFromDate:evt1.eventDate];
        date2 = [fmt stringFromDate:evt2.eventDate];
    }
    else if (eventCnt == 1)
    {
        evt1 = appDelegate.eventListSorted[0];
        evt2 = appDelegate.eventListSorted[0];
        
        date1 = [fmt stringFromDate:evt1.eventDate];
        date2 = [fmt stringFromDate:evt2.eventDate];
    }
    if (evt1 != nil)
    {
        if (![ATHelper isBCDate:evt1.eventDate])
            date1 = [date1 substringToIndex:10];
        if (![ATHelper isBCDate:evt2.eventDate])
            date2 = [date2 substringToIndex:10];
    }

    currentYLocation = currentYLocation + 2.5 *itemHeight - 5 *iPhoneSizeYFactor;
    CGRect frm = CGRectMake(initialX, currentYLocation, itemWidth * iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = NSLocalizedString(@"This is what is on the Map:",nil);
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    
    currentYLocation = currentYLocation + 2 * itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation - 30*iPhoneSizeYFactor, 600*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: NSLocalizedString(@"1.   Totally there are %d events span from %@ to %@",nil), eventCnt, date1, date2];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    
    currentYLocation = currentYLocation + itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation - 30*iPhoneSizeYFactor, 600*iPhoneSizeXFactor, itemHeight);
    updatableLabel = [[UILabel alloc] initWithFrame:frm];
    updatableLabel.text = [NSString stringWithFormat: NSLocalizedString(@"2.   The selected date is %@ and the time zoom level is %@",nil), dateFocused, timeZoomLevelStr];
    updatableLabel.lineBreakMode = NSLineBreakByWordWrapping;
    updatableLabel.numberOfLines=3;
    updatableLabel.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    updatableLabel.backgroundColor = [UIColor clearColor];
    updatableLabel.textColor = [UIColor whiteColor];
    [self addSubview:updatableLabel];
    
    currentYLocation = currentYLocation + 0.6*itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation - 30*iPhoneSizeYFactor, 700*iPhoneSizeXFactor, itemHeight);
    updatableLabel2 = [[UILabel alloc] initWithFrame:frm];
    updatableLabel2.text = [NSString stringWithFormat: NSLocalizedString(@"      So all events within %@ of %@ are colored as bellow, the darker the closer to it",nil), timeZoomLevelStr, dateFocused];
    updatableLabel2.lineBreakMode = NSLineBreakByWordWrapping;
    updatableLabel2.numberOfLines=3;
    updatableLabel2.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    updatableLabel2.backgroundColor = [UIColor clearColor];
    updatableLabel2.textColor = [UIColor whiteColor];
    [self addSubview:updatableLabel2];
    
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    if ([targetName hasPrefix:@"WorldHeritage"] && appDelegate.mapModeFlag)
    {
        lbl.text = [NSString stringWithFormat: NSLocalizedString(@"1.   Red Dot for CULTURE Heritage, Green Dot for NATURAL Heritage",nil)];
        updatableLabel.text = [NSString stringWithFormat: NSLocalizedString(@"2.   The selected period is 3 years around %@",nil), [ATHelper getYearPartHelper: appDelegate.focusedDate]];
        updatableLabel2.text = [NSString stringWithFormat: NSLocalizedString(@"      The sites recognized by UNESCO in this period are in following larger red dot:",nil)];
        currentYLocation = currentYLocation + 0.3 * itemHeight;
        CGRect frameColorImage = CGRectMake(initialX + 20*iPhoneSizeXFactor + 50, currentYLocation, imageAnn, imageAnn);
        UIImageView* annImage1 = [[UIImageView alloc] initWithFrame:frameColorImage ];
        [annImage1 setImage:[UIImage imageNamed:@"marker-heritage-selected.png"]];
        [self addSubview:annImage1];
    }
    else
    {
        currentYLocation = currentYLocation + 0.3 * itemHeight;
        CGRect frameColorImage = CGRectMake(initialX + 20*iPhoneSizeXFactor + 50, currentYLocation, imageAnn, imageAnn);
        UIImageView* annImage1 = [[UIImageView alloc] initWithFrame:frameColorImage ];
        [annImage1 setImage:[UIImage imageNamed:@"marker-bf-4.png"]];
        [self addSubview:annImage1];
        UIImageView* annImage2 = [[UIImageView alloc] initWithFrame:CGRectMake(frameColorImage.origin.x + 50, frameColorImage.origin.y, imageAnn, imageAnn) ];
        [annImage2 setImage:[UIImage imageNamed:@"marker-bf-3.png"]];
        [self addSubview:annImage2];
        UIImageView* annImage3 = [[UIImageView alloc] initWithFrame:CGRectMake(frameColorImage.origin.x + 100, frameColorImage.origin.y, imageAnn, imageAnn) ];
        [annImage3 setImage:[UIImage imageNamed:@"marker-bf-2.png"]];
        [self addSubview:annImage3];
        UIImageView* annImage4 = [[UIImageView alloc] initWithFrame:CGRectMake(frameColorImage.origin.x + 150, frameColorImage.origin.y, imageAnn, imageAnn) ];
        [annImage4 setImage:[UIImage imageNamed:@"marker-bf-2.png"]];
        [self addSubview:annImage4];
        UIImageView* annImage5 = [[UIImageView alloc] initWithFrame:CGRectMake(frameColorImage.origin.x + 200, frameColorImage.origin.y, imageAnn, imageAnn) ];
        [annImage5 setImage:[UIImage imageNamed:@"marker-selected.png"]];
        [self addSubview:annImage5];
        UIImageView* annImage6 = [[UIImageView alloc] initWithFrame:CGRectMake(frameColorImage.origin.x + 250, frameColorImage.origin.y, imageAnn, imageAnn) ];
        [annImage6 setImage:[UIImage imageNamed:@"marker-af-1.png"]];
        [self addSubview:annImage6];
        UIImageView* annImage7 = [[UIImageView alloc] initWithFrame:CGRectMake(frameColorImage.origin.x + 300, frameColorImage.origin.y, imageAnn, imageAnn) ];
        [annImage7 setImage:[UIImage imageNamed:@"marker-af-2.png"]];
        [self addSubview:annImage7];
        UIImageView* annImage8 = [[UIImageView alloc] initWithFrame:CGRectMake(frameColorImage.origin.x + 350, frameColorImage.origin.y, imageAnn, imageAnn) ];
        [annImage8 setImage:[UIImage imageNamed:@"marker-af-3.png"]];
        [self addSubview:annImage8];
        UIImageView* annImage9 = [[UIImageView alloc] initWithFrame:CGRectMake(frameColorImage.origin.x + 400, frameColorImage.origin.y, imageAnn, imageAnn) ];
        [annImage9 setImage:[UIImage imageNamed:@"marker-af-4.png"]];
        [self addSubview:annImage9];
    }
}

- (void) addRedGreenDotsSection
{
    currentYLocation = currentYLocation + itemHeight + 10;
    CGRect frm = CGRectMake(initialX, currentYLocation, itemWidth*iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, initialY + 3 * itemHeight, itemWidth * iphoneSizeSpecialFactor, itemHeight)];
    lbl.text = NSLocalizedString(@"Red/Green Dot on Time Wheel:",nil);
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [lbl setFrame:frm];
    [self addSubview:lbl];
    
    currentYLocation = currentYLocation + itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation , 600*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: NSLocalizedString(@"1.   A red dot indicates the existence of events at that point of time",nil)];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    currentYLocation = currentYLocation + itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation , 600*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: NSLocalizedString(@"2.   A green dot means the events at that point of time are currently on screen",nil)];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    currentYLocation = currentYLocation + 0.6 * itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation , 700*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: NSLocalizedString(@"     Green dot is helpful to find events/photos quickly. Learn more from Tip 2 in [Online Help]",nil)];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
}

- (void) addTimeZoomLevelSection1
{
    currentYLocation = currentYLocation + 1.5 * itemHeight;
    CGRect frm = CGRectMake(initialX, currentYLocation, itemWidth*iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, currentYLocation, itemWidth * iphoneSizeSpecialFactor, itemHeight)];

    lbl.text = NSLocalizedString(@"Zoom the time:",nil);
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [lbl setFrame:frm];
    [self addSubview:lbl];
    
    frm = CGRectMake(initialX+ 180*iPhoneSizeXFactor , currentYLocation , 500*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat:NSLocalizedString(@"Zoom-out to reach far-away time more quickly.",nil)];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    
    currentYLocation = currentYLocation + 0.6 * itemHeight;
    frm = CGRectMake(initialX+ 180*iPhoneSizeXFactor , currentYLocation , 500*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: NSLocalizedString(@"Available zoom-levels: Month / Year  /10 Yrs / 100 Yrs / 1000 Yrs",nil)];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];

}

/*
- (void) addTimeZoomLevelSection2 //level wordings
{
    currentYLocation = currentYLocation + 2 *iPhoneSizeYFactor;
    CGRect lblFrame = CGRectMake(initialX+270*iPhoneSizeXFactor, initialY + 3 * itemHeight + 52*iPhoneSizeYFactor, itemWidth, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(1000*iPhoneSizeXFactor, initialY + 3 * itemHeight + 2, 0, 0)];

    lbl.text = @"1) Available zoom level are month/year/10 yrs/100 yrs/1000 yrs";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall-2];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [lbl setFrame:lblFrame];
    [self addSubview:lbl];
    
    lblFrame = CGRectMake(initialX+270*iPhoneSizeXFactor, initialY + 3 * itemHeight + 52*iPhoneSizeYFactor + 20, itemWidth, itemHeight);
    UILabel* lbl2 = [[UILabel alloc] initWithFrame:CGRectMake(1000*iPhoneSizeXFactor, initialY + 3 * itemHeight + 2, 0, 0)];
    
    lbl2.text = @"2) In MONTH zoom level, only one year summary, otherwise will be whole";
    lbl2.font = [UIFont fontWithName:@"Arial" size:fontSmall-2];
    lbl2.backgroundColor = [UIColor clearColor];
    lbl2.textColor = [UIColor whiteColor];
    [lbl2 setFrame:lblFrame];
    [self addSubview:lbl2];

}
 */

- (void) addTimeZoomLevelSection:(int)xStart :(NSString*)gestureImageName :(NSString*)text :(int)yEnd
{
    int scrollWindowWidth = [ATConstants timeScrollWindowWidth];
    int scrollWindowHeight = [ATConstants timeScrollWindowHeight];
    
    int lineX = xStart + scrollWindowWidth/3 - 150*iPhoneSizeXFactor;

    //Upper Label description
    CGRect lblFrame = CGRectMake(lineX - 50*iPhoneSizeXFactor, yEnd -30, 145*iPhoneSizeXFactor, 3*itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:lblFrame];
    lbl.text = text;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=4;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    if ([lbl.text rangeOfString:@"Pinch"].location != NSNotFound)
        lbl.textColor = [UIColor lightGrayColor];
    [self addSubview:lbl];
    
    //draw line
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    //Draw lines around time window

    CGContextMoveToPoint(context, lineX, yEnd + 20);
    CGContextAddLineToPoint(context, lineX, y_start + 5);
    CGContextStrokePath(context);
    
    //left side shade
    if ([text hasPrefix:@"Double"])
    {
        CGRect rectShade = CGRectMake(xStart, y_start, scrollWindowWidth/3, scrollWindowHeight + 5);
        UILabel* lblShade = [[UILabel alloc] initWithFrame:rectShade];
        lblShade.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.2];
        [self addSubview:lblShade];
    }
    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(lineX - 20, y_start + 10, imageSize, imageSize) ];
    [imgView setImage:[UIImage imageNamed:gestureImageName]]; 
    [self addSubview:imgView];
}

- (void) addDoubleTapCenterSection:(int)xStart
{
    int scrollWindowWidth = [ATConstants timeScrollWindowWidth];
    int scrollWindowHeight = [ATConstants timeScrollWindowHeight];
    
    int lineX = xStart + scrollWindowWidth/3 - 150*iPhoneSizeXFactor;
    
    //Upper Label description
    CGRect lblFrame = CGRectMake(lineX - 50*iPhoneSizeXFactor, currentYLocation + 40, 140*iPhoneSizeXFactor, 2*itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:lblFrame];
    lbl.text = NSLocalizedString(@"Double-tap at center to center on today",nil);
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall - 2];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=2;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor redColor];
    [self addSubview:lbl];
    
    //Time Window Label description
    CGRect timeWindowFrame = CGRectMake(initialX, y_start - 40, itemWidth + 100, itemHeight);
    UILabel* timeWindowLbl = [[UILabel alloc] initWithFrame:timeWindowFrame];
    timeWindowLbl.text = NSLocalizedString(@"Time Wheel",nil);
    timeWindowLbl.font = [UIFont fontWithName:@"Arial" size:24];
    timeWindowLbl.backgroundColor = [UIColor clearColor];
    timeWindowLbl.textColor = [UIColor whiteColor];
    [self addSubview:timeWindowLbl];
    
    //draw line
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    //Draw lines around time window
    
    CGContextMoveToPoint(context, lineX, currentYLocation + 80);
    CGContextAddLineToPoint(context, lineX, y_start + 5);
    CGContextStrokePath(context);
    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(lineX - 20, y_start + 10, imageSize, imageSize) ];
    [imgView setImage:[UIImage imageNamed:@"gesture-doubletap.png"]]; 
    [self addSubview:imgView];
    //left side shade
    CGRect rectShade = CGRectMake(xStart, y_start, scrollWindowWidth/3, scrollWindowHeight + 5);
    UILabel* lblShade = [[UILabel alloc] initWithFrame:rectShade];
    lblShade.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
    [self addSubview:lblShade];
}

@end
