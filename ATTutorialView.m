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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        // add subview etc here
    }
    return self;
}

- (void) updateDateText
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* fmt = appDelegate.dateFormater;
    dateFocused = @"[NO EVENT YET]";
    timeZoomLevelStr = @"1000 Years";
    if (appDelegate.focusedDate != nil)
        dateFocused = [fmt stringFromDate:appDelegate.focusedDate];
    dateFocused = [dateFocused substringToIndex:10];
    if (appDelegate.selectedPeriodInDays == 7)
        timeZoomLevelStr = @"1 week";
    else if (appDelegate.selectedPeriodInDays == 30)
        timeZoomLevelStr = @"1 month";
    else if (appDelegate.selectedPeriodInDays == 365)
        timeZoomLevelStr = @"1 year";
    else if (appDelegate.selectedPeriodInDays == 3650)
        timeZoomLevelStr = @"10 years";
    else if(appDelegate.selectedPeriodInDays == 36500)
        timeZoomLevelStr = @"100 years";
    if (updatableLabel != nil)
    {
        updatableLabel.text = [NSString stringWithFormat: @"2.   The selected date is %@ and the time zoom level is %@", dateFocused, timeZoomLevelStr];
        updatableLabel2.text = [NSString stringWithFormat: @"      So all events within %@ of %@ are colored as bellow, the darker the closer to it", timeZoomLevelStr, dateFocused];
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
    lbl.text = @"Record/navigate events on map in chronological order!";
    lbl.font = [UIFont fontWithName:@"Arial" size:24];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor lightTextColor];
    [self addSubview:lbl];
    
    [self updateDateText];
    
    //Call following in sequence because the based on currentYPosition
    [self addLongPressSection];
    
    [self addWhatIsHappeningSection];
    [self addRedGreenDotsSection];

    //////////////////////////////////////////[self addTimeZoomLevelSection2];
    [self addTimeZoomLevelSection1];
    //following are on same y level, so change currentYLocation once:
    currentYLocation = currentYLocation + itemHeight + 50*iPhoneSizeYFactor;
    [self addDoubleTapCenterSection:x_start + [ATConstants timeScrollWindowWidth]/3]; //this first so red shade go under pinch
    [self addTimeZoomLevelSection:x_start - 50 :@"TimewheelZoomOut.png" :@"Tap (-) or double-tab here to zoom out"];
    [self addTimeZoomLevelSection:x_start + [ATConstants timeScrollWindowWidth]/3-85 :@"gesture-pinch.png" :@"Pinch is another way of zooming Time Wheel"];
    [self addTimeZoomLevelSection:x_start + 2*[ATConstants timeScrollWindowWidth]/3   + 50:@"TimewheelZoomIn.png" :@"Tap (+) or double-tab here to zoom in"];
}

- (void) addLongPressSection
{
    currentYLocation = initialY;
    CGRect frm = CGRectMake(initialX, currentYLocation, itemWidth * iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = @"Add event:";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    
    UILabel* lblSearchAddress = [[UILabel alloc] initWithFrame:CGRectMake(frm.origin.x + 150*iPhoneSizeXFactor, frm.origin.y, 220*iPhoneSizeXFactor, 80*iPhoneSizeYFactor)];
    lblSearchAddress.text = @"Search Address     OR  ";
    lblSearchAddress.font = [UIFont fontWithName:@"Arial" size:20];
    lblSearchAddress.backgroundColor = [UIColor clearColor];
    lblSearchAddress.textColor = [UIColor whiteColor];
    [self addSubview:lblSearchAddress];
    
    //draw line
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    //Draw lines point to address box
    CGContextMoveToPoint(context, frm.origin.x + 220 *iPhoneSizeXFactor, frm.origin.y + 30);
    CGContextAddLineToPoint(context, [ATConstants screenWidth]/2 - 20, 0);
    CGContextMoveToPoint(context, [ATConstants screenWidth]/2 - 20, 0);
    CGContextAddLineToPoint(context, [ATConstants screenWidth]/2 - 40, 10);
    CGContextMoveToPoint(context, [ATConstants screenWidth]/2 - 20, 0);
    CGContextAddLineToPoint(context, [ATConstants screenWidth]/2 - 26, 15);
    CGContextStrokePath(context);

    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(frm.origin.x + 350*iPhoneSizeXFactor, frm.origin.y, imageSize, imageSize) ];
    [imgView setImage:[UIImage imageNamed:@"gesture-longpress.png"]]; //long press image
    [self addSubview:imgView];
    
    UILabel* lblLongPress = [[UILabel alloc] initWithFrame:CGRectMake(frm.origin.x + 410*iPhoneSizeXFactor, frm.origin.y, 250*iPhoneSizeXFactor, 80*iPhoneSizeYFactor)];
    lblLongPress.text = @"Long-press on a map location.";
    lblLongPress.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lblLongPress.backgroundColor = [UIColor clearColor];
    lblLongPress.textColor = [UIColor whiteColor];
    lblLongPress.lineBreakMode = NSLineBreakByWordWrapping;
    lblLongPress.numberOfLines=2;
    [self addSubview:lblLongPress];
}

- (void) addWhatIsHappeningSection
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* fmt = appDelegate.dateFormater;
    NSString* date1 = @"N/A";
    NSString* date2 = @"N/A";

    int eventCnt = [appDelegate.eventListSorted count];
    if (eventCnt > 1)
    {
        ATEventDataStruct* evt1 = appDelegate.eventListSorted[eventCnt - 1];
        ATEventDataStruct* evt2 = appDelegate.eventListSorted[0];
        
        date1 = [fmt stringFromDate:evt1.eventDate];
        date2 = [fmt stringFromDate:evt2.eventDate];
    }
    else if (eventCnt == 1)
    {
        ATEventDataStruct* evt1 = appDelegate.eventListSorted[0];
        ATEventDataStruct* evt2 = appDelegate.eventListSorted[0];
        
        date1 = [fmt stringFromDate:evt1.eventDate];
        date2 = [fmt stringFromDate:evt2.eventDate];
    }
    
    if ([date1 rangeOfString:@"AD"].location != NSNotFound)
        date1 = [date1 substringToIndex:10];
    if ([date2 rangeOfString:@"AD"].location != NSNotFound)
        date2 = [date2 substringToIndex:10];

    currentYLocation = currentYLocation + 2.5 *itemHeight - 5 *iPhoneSizeYFactor;
    CGRect frm = CGRectMake(initialX, currentYLocation, itemWidth * iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = @"This is what is happening on your screen:";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    
    currentYLocation = currentYLocation + 2 * itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation - 30*iPhoneSizeYFactor, 600*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: @"1.   Totally there are %d events span from %@ to %@", eventCnt, date1, date2];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    
    currentYLocation = currentYLocation + itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation - 30*iPhoneSizeYFactor, 600*iPhoneSizeXFactor, itemHeight);
    updatableLabel = [[UILabel alloc] initWithFrame:frm];
    updatableLabel.text = [NSString stringWithFormat: @"2.   The selected date is %@ and the time zoom level is %@", dateFocused, timeZoomLevelStr];
    updatableLabel.lineBreakMode = NSLineBreakByWordWrapping;
    updatableLabel.numberOfLines=3;
    updatableLabel.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    updatableLabel.backgroundColor = [UIColor clearColor];
    updatableLabel.textColor = [UIColor whiteColor];
    [self addSubview:updatableLabel];
    
    currentYLocation = currentYLocation + 0.6*itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation - 30*iPhoneSizeYFactor, 700*iPhoneSizeXFactor, itemHeight);
    updatableLabel2 = [[UILabel alloc] initWithFrame:frm];
    updatableLabel2.text = [NSString stringWithFormat: @"      So all events within %@ of %@ are colored as bellow, the darker the closer to it", timeZoomLevelStr, dateFocused];
    updatableLabel2.lineBreakMode = NSLineBreakByWordWrapping;
    updatableLabel2.numberOfLines=3;
    updatableLabel2.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    updatableLabel2.backgroundColor = [UIColor clearColor];
    updatableLabel2.textColor = [UIColor whiteColor];
    [self addSubview:updatableLabel2];
    
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

- (void) addRedGreenDotsSection
{
    currentYLocation = currentYLocation + itemHeight + 10;
    CGRect frm = CGRectMake(initialX, currentYLocation, itemWidth*iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, initialY + 3 * itemHeight, itemWidth * iphoneSizeSpecialFactor, itemHeight)];
    lbl.text = @"Red Dot and Green Dot on Time Wheel";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [lbl setFrame:frm];
    [self addSubview:lbl];
    
    currentYLocation = currentYLocation + itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation , 600*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: @"1.   A red dot indicates the existence of events at that point of time"];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    currentYLocation = currentYLocation + itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation , 600*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: @"2.   A green dot means the events at that point of time are currently on screen"];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    currentYLocation = currentYLocation + 0.6 * itemHeight;
    frm = CGRectMake(initialX+ 20*iPhoneSizeXFactor , currentYLocation , 700*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: @"     Green dot is helpful to find events/photos quickly. Learn more from Tip 2 in [Online Help]"];
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

    lbl.text = @"Zoom the time:";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [lbl setFrame:frm];
    [self addSubview:lbl];
    
    frm = CGRectMake(initialX+ 180*iPhoneSizeXFactor , currentYLocation , 500*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: @"Zoom-out to reach far-away time more quickly."];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=3;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    
    currentYLocation = currentYLocation + 0.6 * itemHeight;
    frm = CGRectMake(initialX+ 180*iPhoneSizeXFactor , currentYLocation , 500*iPhoneSizeXFactor, itemHeight);
    lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = [NSString stringWithFormat: @"Available zoom-levels: Month / Year  /10 Yrs / 100 Yrs / 1000 Yrs"];
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

- (void) addTimeZoomLevelSection:(int)xStart :(NSString*)gestureImageName :(NSString*)text
{
    int scrollWindowWidth = [ATConstants timeScrollWindowWidth];
    int scrollWindowHeight = [ATConstants timeScrollWindowHeight];
    
    int lineX = xStart + scrollWindowWidth/3 - 150*iPhoneSizeXFactor;

    //Upper Label description
    CGRect lblFrame = CGRectMake(lineX - 50*iPhoneSizeXFactor, currentYLocation -30, 145*iPhoneSizeXFactor, 2*itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:lblFrame];
    lbl.text = text;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=2;
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

    CGContextMoveToPoint(context, lineX, currentYLocation + 20);
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
    lbl.text = @"Double-tap at center to center on today";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall - 2];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=2;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor redColor];
    [self addSubview:lbl];
    
    //Time Window Label description
    CGRect timeWindowFrame = CGRectMake(initialX, y_start - 40, itemWidth + 100, itemHeight);
    UILabel* timeWindowLbl = [[UILabel alloc] initWithFrame:timeWindowFrame];
    timeWindowLbl.text = @"Time Wheel";
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
