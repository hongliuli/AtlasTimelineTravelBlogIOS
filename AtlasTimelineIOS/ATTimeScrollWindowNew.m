//
//  ATTimeScrollWindowNew
//  HorizontalTables
//
//  Created by Felipe Laso on 8/19/11.
//  Copyright 2011 Felipe Laso. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ATTimeScrollWindowNew.h"
#import "ATTimeScrollCell.h"
#import "ATAppDelegate.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATEventDataStruct.h"
#import "ATTimeZoomLine.h"
#import "ATConstants.h"
#import "Toast+UIView.h"

#define FIRST_TIME_CALL -999
//color from http://cloford.com/resources/colours/500col.htm
#define GROUP_BACKGROUND_COLOR_1 @"0x0000FF"
#define GROUP_BACKGROUND_COLOR_2 @"0x008B45"

#define SCROLL_DIRECTION_RIGHT 1
#define SCROLL_DIRECTION_LEFT 2

@implementation ATTimeScrollWindowNew
{
    float pinchVelocity; //minus is zoom out
    int yearElapsedFromToday;
    NSCalendar* calendar;
    NSDateFormatter *dateLiterFormat;
    NSDate* timeWindowStartDate;
    NSDate* timeWindowEndDate;
    
    int focusedRow; //set in cellForRow, used in zoom etc to scroll to focused date
    int prevRow;
    int currentNumberOfRow;
    
    float gradulColor;
    
    NSString* prevGroupLabelText;
    NSString* groupLabelBackgroundAlpha;
    NSString* prevYear;
    
    UIView* rightZoomAnimationView;
    UIView* leftZommAnimationView;
    
    NSInteger lastContentOffset;
    int scrollDirection;
    
    UIImageView* year100View;
    UIImageView* year10View;
    UIImageView* year1View;
    
    UIButton *btnZoomOut;
    UIButton *btnZoomIn;
}

@synthesize horizontalTableView = _horizontalTableView;


#pragma mark - Table View Data Source

- (id)initWithFrame:(CGRect)frame
{
    groupLabelBackgroundAlpha = GROUP_BACKGROUND_COLOR_1;
    prevGroupLabelText = nil;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ((self = [super initWithFrame:frame]))
    {
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        timeWindowStartDate = appDelegate.mapViewController.startDate;
        timeWindowEndDate = appDelegate.mapViewController.endDate;
        //NSLog(@"-------------ATTimeScrollWindowNew  initWithFrame called");
        float tableLength = frame.size.width;
        float tableWith = frame.size.height;
        //NSLog(@" table  length %f   width %f",tableLength, tableWith);
        self.horizontalTableView = [[UITableView alloc] initWithFrame:frame];
        //self.horizontalTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kCellHeight_iPad, kTableLength_iPad)];
        self.horizontalTableView.showsVerticalScrollIndicator = NO;
        self.horizontalTableView.showsHorizontalScrollIndicator = NO;
        self.horizontalTableView.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);
        [self.horizontalTableView setFrame:CGRectMake(0, 0, tableLength, tableWith)];
        
        self.horizontalTableView.rowHeight = [ATConstants timeScrollCellWidth];
        
        self.horizontalTableView.dataSource = self;
        self.horizontalTableView.delegate = self;
        UIView* topBorder = [[UIView alloc] initWithFrame:CGRectMake(-5,-5, frame.size.width + 10, 5)];
        topBorder.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"frame-top.png"]];
        UIView* bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(-5,frame.size.height, frame.size.width +10, 5)];
        bottomBorder.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"frame-bottom.png"]];
        UIView* leftBorder = [[UIView alloc] initWithFrame:CGRectMake(-5,0, 5, frame.size.height)];
        leftBorder.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"frame-left.png"]];
        UIView* rightBorder = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width,0, 5, frame.size.height)];
        rightBorder.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"frame-right.png"]];
        [self addSubview:topBorder];
        [self addSubview:bottomBorder];
        [self addSubview:leftBorder];
        [self addSubview:rightBorder];
        
        [self addSubview:self.horizontalTableView];
        yearElapsedFromToday = 0;
        
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self addGestureRecognizer:pinch];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        tap.numberOfTapsRequired =1;
        [self addGestureRecognizer:tap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        [tap requireGestureRecognizerToFail:doubleTap]; //This is the way make sure double tap will not do single tap action, resolve confilict
        
        //Add longpress purely to disable adding new event when longpress on scrollwindow, or to prevent longpress to mapview
        UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handleLongPressGesture:)];
        lpgr.minimumPressDuration = 0.3;  //user must press for 0.5 seconds
        [self addGestureRecognizer:lpgr];
        
        if (calendar == nil)
            calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        
        //initialize left/right animation zoom view
        leftZommAnimationView = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 50, [ATConstants timeScrollWindowHeight])];
        leftZommAnimationView.backgroundColor = [UIColor clearColor] ; //]colorWithRed:1 green:1 blue:0.8 alpha:1 ];
        [self addSubview:leftZommAnimationView];
        leftZommAnimationView.hidden=true;
        rightZoomAnimationView = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 50, [ATConstants timeScrollWindowHeight])];
        rightZoomAnimationView.backgroundColor = [UIColor clearColor] ; //]colorWithRed:1 green:1 blue:0.8 alpha:1 ];
        [self addSubview:rightZoomAnimationView];
        rightZoomAnimationView.hidden=true;
        
        leftZommAnimationView.layer.borderColor = [UIColor whiteColor].CGColor;
        leftZommAnimationView.layer.borderWidth = 0.3f;
        rightZoomAnimationView.layer.borderColor = [UIColor whiteColor].CGColor;
        rightZoomAnimationView.layer.borderWidth = 0.3f;
        leftZommAnimationView.backgroundColor = [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.1];
        rightZoomAnimationView.backgroundColor = [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.1];
        
        
        //NSDateFormatter* format = appDelegate.dateFormater;
        //startDate3000BC = [format dateFromString:@"01/01/3000 BC"]; //remember 6000 year is allowed start from -3000. otherwise calendar may not work
        prevRow = -1;
        dateLiterFormat=[[NSDateFormatter alloc] init];
        [dateLiterFormat setDateFormat:@"EEEE MMMM dd"];
        [self scrollToFocusedRow];
        
        int timewheelZoomButtonSize = 45;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && focusedRow + 1 > currentNumberOfRow)
            timewheelZoomButtonSize = 35;
        btnZoomOut = [UIButton buttonWithType:UIButtonTypeCustom];
        btnZoomOut.frame = CGRectMake(20, 2, timewheelZoomButtonSize, timewheelZoomButtonSize);
        [btnZoomOut setImage:[UIImage imageNamed:@"TimewheelZoomOut.png"] forState:UIControlStateNormal];
        [btnZoomOut addTarget:self action:@selector(zoomOutAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnZoomOut];
        
        btnZoomIn = [UIButton buttonWithType:UIButtonTypeCustom];
        btnZoomIn.frame = CGRectMake([ATConstants timeScrollWindowWidth] - 70, 2, timewheelZoomButtonSize, timewheelZoomButtonSize);
        [btnZoomIn setImage:[UIImage imageNamed:@"TimewheelZoomIn.png"] forState:UIControlStateNormal];
        [btnZoomIn addTarget:self action:@selector(zoomInAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnZoomIn];
        
    }
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timeWindowBackground.png"]];
    [tempImageView setAlpha:0.75];
    [tempImageView setFrame:self.horizontalTableView.frame];
    
    self.horizontalTableView.backgroundView = tempImageView;
    self.horizontalTableView.backgroundColor = [UIColor clearColor];
    
    prevYear = [ATHelper getYearPartHelper:appDelegate.focusedDate];
    return self;
}

//when scroll, will not come here, so have some heavy work such as calendar
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                               fromDate:timeWindowStartDate
                                                 toDate:timeWindowEndDate
                                                options:0];
    int selectedPeriodInDay = appDelegate.selectedPeriodInDays;
    
    //patch: somehow forcused date will go out of range after remove/update edge event (date at index 0 or count-1, make adjustment here
    if ([appDelegate.focusedDate compare:timeWindowStartDate]==NSOrderedAscending || [appDelegate.focusedDate compare:timeWindowEndDate]==NSOrderedDescending)
        appDelegate.focusedDate = timeWindowEndDate;
    
    if (selectedPeriodInDay <= 30)
    {
        //For day, use timeInterval is more accurate
        NSTimeInterval interval = [timeWindowEndDate timeIntervalSinceDate: timeWindowStartDate];
        currentNumberOfRow = interval/86400 +30; //better add some extra
    }
    else if (selectedPeriodInDay == 365)
    {
        currentNumberOfRow = components.month + 12 * components.year + 2;
    }
    else if (selectedPeriodInDay == 3650)
    {
        currentNumberOfRow = components.year + 2;
    }
    else if (selectedPeriodInDay == 36500)
    {
        currentNumberOfRow = components.year/10 + 2;
    }
    else
    {
        currentNumberOfRow = components.year/100 + 2;
    }
    //NSLog(@"------ CurrentNumberOfRow=%i Number of Day %i, month %i, year %i",currentNumberOfRow, components.day, components.month, components.year);
    return currentNumberOfRow + 7; //always returns 7 more so focuse to a late date works
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.parent.timeZoomLine showHideScaleText:true];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate* oldFocusedDate = appDelegate.focusedDate;
    NSDateComponents *components = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit fromDate:oldFocusedDate];
    //int year = [components year];
    int oldMonth = [components month] - 1;
    int oldDay = [components day] - 1;
    NSDateComponents *addOldDateToNewFocusedDate = [[NSDateComponents alloc] init];
    NSDateComponents *addOldMonthToNewFocusedDate = [[NSDateComponents alloc] init];
    [addOldDateToNewFocusedDate setDay:oldDay];
    [addOldMonthToNewFocusedDate setMonth:oldMonth];
    
    int currentRow = indexPath.row;
    if (prevRow == -1) //come here the first time
        prevRow = currentRow;
    int increaseDirection = 0;
    if (prevRow > currentRow ) //move left
        increaseDirection = -1;
    else if (prevRow < currentRow)
        increaseDirection = 1;
    prevRow = currentRow;
    
    focusedRow = currentRow - 4*increaseDirection ; //this is to select center row as focusedRow because timeScrollWindow has 9 dates
    
    static NSString *CellIdentifier = @"ATTimeScrollCell";
    
    __block ATTimeScrollCell *cell = (ATTimeScrollCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    int daysInPeriod = appDelegate.selectedPeriodInDays;
    if (cell == nil)
    {
        cell = [[ATTimeScrollCell alloc] initWithFrame:CGRectMake(0, 0, [ATConstants timeScrollCellWidth], [ATConstants timeScrollCellHeight])];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSDateFormatter* format = appDelegate.dateFormater;
    NSDate* displayDate;
    NSDateComponents *periodToAddForFocusedDate = [[NSDateComponents alloc] init];
    NSDateComponents *periodToAddForDisplay = [[NSDateComponents alloc] init];
    NSDateComponents *nextTimePeriodCompponent = [[NSDateComponents alloc] init];
    ATViewController* parent = appDelegate.mapViewController; //self.parent might be empty here when start
    NSDate* baseStartDate = parent.startDate; // startDate3000BC;
    if (daysInPeriod == 7)
    {
        [periodToAddForFocusedDate setDay:focusedRow]; //FocusedRow for day is differently, use 2000 days
        [periodToAddForDisplay setDay:currentRow];
        [nextTimePeriodCompponent setDay:1];
        cell.scallLabel.text = @"week";
        cell.backgroundView = nil;
    }
    else if (daysInPeriod == 30)
    {
        [periodToAddForFocusedDate setDay:focusedRow]; //FocusedRow for day is differently, use 2000 days
        [periodToAddForDisplay setDay:currentRow];
        [nextTimePeriodCompponent setDay:1];
        cell.scallLabel.text = @"month";
        
        UIImageView *av = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        av.backgroundColor = [UIColor clearColor];
        av.opaque = NO;
        av.image = [UIImage imageNamed:@"scaleDay.png"];
        cell.backgroundView = av;
    }
    else if (daysInPeriod == 365)
    {
        [periodToAddForFocusedDate setMonth:focusedRow];
        [periodToAddForDisplay setMonth:currentRow];
        [nextTimePeriodCompponent setMonth:1];
        cell.scallLabel.text = @"1 yr";
        
        UIImageView *av = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        av.backgroundColor = [UIColor clearColor];
        av.opaque = NO;
        av.image = [UIImage imageNamed:@"scaleYearMonth.png"];
        cell.backgroundView = av;
        
    }
    else if (daysInPeriod == 3650)
    {
        [periodToAddForFocusedDate setYear:focusedRow];
        [periodToAddForDisplay setYear:currentRow];
        [nextTimePeriodCompponent setYear:1];
        cell.scallLabel.text = @"10 yrs";
        UIImageView *av = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        av.backgroundColor = [UIColor clearColor];
        av.opaque = NO;
        av.image = [UIImage imageNamed:@"scaleYear1.png"];
        cell.backgroundView = av;
        
    }
    else if (daysInPeriod == 36500)
    {
        [periodToAddForFocusedDate setYear:focusedRow * 10];
        [periodToAddForDisplay setYear:currentRow * 10];
        [nextTimePeriodCompponent setYear:10];
        cell.scallLabel.text = @"100 yrs";
        UIImageView *av = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        av.backgroundColor = [UIColor clearColor];
        av.opaque = NO;
        av.image = [UIImage imageNamed:@"scaleYear10.png"];
        cell.backgroundView = av;
    }
    else if (daysInPeriod == 365000)
    {
        [periodToAddForFocusedDate setYear:focusedRow * 100];
        [periodToAddForDisplay setYear:currentRow * 100];
        [nextTimePeriodCompponent setYear:100];
        cell.scallLabel.text = @"1000qhw yrs";
        UIImageView *av = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        av.backgroundColor = [UIColor clearColor];
        av.opaque = NO;
        av.image = [UIImage imageNamed:@"scaleYear100.png"];
        cell.backgroundView = av;
    }
    cell.scallLabel.textColor = [UIColor whiteColor];
    cell.scallLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:13.0];
    
    displayDate = [ATHelper dateByAddingComponentsRegardingEra:periodToAddForDisplay toDate:baseStartDate options:0];
    
    NSDateComponents *tmpCom = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:displayDate];
    int yearForImages = tmpCom.year;
    //IMPORTANT Since startDate always started at 01/01/yyyy, When move time by year/10year/..., date part will be lost, so need to add back
    appDelegate.focusedDate = [ATHelper dateByAddingComponentsRegardingEra:periodToAddForFocusedDate toDate:baseStartDate options:0];
    if (daysInPeriod == 365)
        appDelegate.focusedDate = [calendar dateByAddingComponents:addOldDateToNewFocusedDate toDate:appDelegate.focusedDate options:0];
    else if (daysInPeriod > 365)
    {
        appDelegate.focusedDate = [calendar dateByAddingComponents:addOldDateToNewFocusedDate toDate:appDelegate.focusedDate options:0];
        appDelegate.focusedDate = [calendar dateByAddingComponents:addOldMonthToNewFocusedDate toDate:appDelegate.focusedDate options:0];
    }
    
    NSString* dateString = [NSString stringWithFormat:@" %@", [format stringFromDate:displayDate]];
    NSString* shortYear = [dateString substringWithRange:NSMakeRange(7, 4)];
    
    if ([dateString rangeOfString:@"AD"].location == NSNotFound )
    {
        cell.titleLabel.text =[dateString substringWithRange:NSMakeRange(7, 7)];
        yearForImages = -yearForImages ;
    }
    else
        cell.titleLabel.text = shortYear;
    
    NSString *dateLiterString=[dateLiterFormat stringFromDate:displayDate];
    cell.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    NSRange range = [dateLiterString rangeOfString:@" "];
    NSInteger idx = range.location + range.length;
    NSString* monthDateString = [dateLiterString substringFromIndex:idx];
    NSString* month3Letter = [monthDateString substringToIndex:3];
    
    range = [monthDateString rangeOfString:@" "];
    idx = range.location + range.length;
    NSString* dayString = [monthDateString substringFromIndex:idx];
    NSString* weekDay3Letter = [dateLiterString substringToIndex:3];
    
    if (daysInPeriod == 7)
    {
        //cell.titleLabel.text = [NSString stringWithFormat:@"%@ %@",month3Letter,shortYear];
        cell.titleLabel.text = [NSString stringWithFormat:@"%@ %@",month3Letter, dayString];
        cell.subLabel.text = [NSString stringWithFormat:@"%@",weekDay3Letter];
        NSString* str = cell.subLabel.text;
        if ([str hasPrefix:@"Sun"])
        {
            gradulColor = 0.0;
            cell.titleLabel.textColor = [UIColor blueColor];
            UIImageView *av = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
            av.backgroundColor = [UIColor clearColor];
            av.opaque = NO;
            av.image = [UIImage imageNamed:@"scaleEdge.png"];
            cell.backgroundView = av;
        }
    }
    else if (daysInPeriod == 30)
    {
        cell.titleLabel.text = [NSString stringWithFormat:@"%@",month3Letter];
        cell.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        cell.subLabel.text =dayString;
    }
    else if (daysInPeriod == 365)
    {
        cell.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        cell.subLabel.text = month3Letter;
    }
    else
    {
        cell.subLabel.text = @"";
        cell.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    }
    cell.titleLabel.textColor = [UIColor blackColor];
    cell.date = displayDate;
    
    if (daysInPeriod == 30 || daysInPeriod == 365)
    {
        NSString* labelTxt = cell.titleLabel.text;
        if (prevGroupLabelText == nil)
            prevGroupLabelText = labelTxt;
        if (![prevGroupLabelText isEqualToString:labelTxt])
        {
            if ([groupLabelBackgroundAlpha isEqualToString: GROUP_BACKGROUND_COLOR_1])
                groupLabelBackgroundAlpha = GROUP_BACKGROUND_COLOR_2;
            else
                groupLabelBackgroundAlpha = GROUP_BACKGROUND_COLOR_1;
            prevGroupLabelText = labelTxt;
        }
        cell.titleLabel.textColor = [ATHelper colorWithHexString:groupLabelBackgroundAlpha];
    }
    if (daysInPeriod == 7) //flip background color each week
    {
        NSString* compareToTxt = @"Sun";
        if (increaseDirection == -1)
            compareToTxt = @"Sat";
        if ([weekDay3Letter isEqualToString:compareToTxt])
        {
            if ([groupLabelBackgroundAlpha isEqualToString: GROUP_BACKGROUND_COLOR_1])
                groupLabelBackgroundAlpha = GROUP_BACKGROUND_COLOR_2;
            else
                groupLabelBackgroundAlpha = GROUP_BACKGROUND_COLOR_1;
        }
        cell.titleLabel.textColor = [ATHelper colorWithHexString:groupLabelBackgroundAlpha];
    }
    
    int index1 = [self getIndexOfClosestDate:displayDate :0 :FIRST_TIME_CALL];
    NSDate* nextExpectedDate= [ATHelper dateByAddingComponentsRegardingEra:nextTimePeriodCompponent toDate:displayDate options:0];
    int index2 = [self getIndexOfClosestDate:nextExpectedDate :0 :FIRST_TIME_CALL];
    
    //Start special edge logic. My recursive function does not return correct index for event start and end date
    //Following is special hack to force start/end event to be counted as one to be displayed  as Cyan color
    //NSLog(@"--Recurs dDate %@ | nDate=%@  idx1=%i  idx2=%i diff=%i", [format stringFromDate: displayDate], [format stringFromDate: nextExpectedDate], index1, index2, index1-index2);
    int displayCount = abs(index1 - index2);
    int totalCnt = [appDelegate.eventListSorted count];
    NSDate* startDate;
    NSDate* endDate;
    
    
    NSDate* displayCellStartDate;
    NSDate* displayCellEndDate;
    
    if (daysInPeriod == 365)
    {
        
        displayCellStartDate = [ATHelper getMonthStartDate:displayDate];
        displayCellEndDate = [ATHelper dateByAddingComponentsRegardingEra:nextTimePeriodCompponent toDate:displayCellStartDate options:0];
    }
    else //TODO need see if 10 year/100 year need special
    {
        displayCellStartDate = [ATHelper getYearStartDate:displayDate];
        displayCellEndDate = [ATHelper dateByAddingComponentsRegardingEra:nextTimePeriodCompponent toDate:displayCellStartDate options:0];
    }
    if (totalCnt > 0)
    {
        startDate = ((ATEventDataStruct*)appDelegate.eventListSorted[0]).eventDate;
        endDate = ((ATEventDataStruct*)appDelegate.eventListSorted[totalCnt -1]).eventDate;
        
    }
    if (daysInPeriod <=30)
    {
        if (totalCnt > 0 &&
            ([startDate compare:displayDate] == NSOrderedSame || [endDate compare:displayDate] == NSOrderedSame))
        {
            displayCount++;
        }
    }
    else if (totalCnt >0 &&
             (([startDate compare:displayDate] == NSOrderedSame || [endDate compare:displayDate] == NSOrderedSame)
              ||(([displayCellEndDate compare:endDate] == NSOrderedDescending  && [endDate compare:displayCellStartDate] == NSOrderedDescending)
                 || ([startDate compare:displayCellStartDate] == NSOrderedDescending  && [displayCellEndDate compare:startDate] == NSOrderedDescending))
              )
             )
    {
        displayCount++; //take care of the first/last event not hightlighted. this is a hack way to resolv
        // but startDate event still not highlighted, why?
    }
    //END adjust edge case
    
    if (displayCount > 0)
    {
        cell.scallLabel.text=[NSString stringWithFormat:@"%i", displayCount];
        cell.scallLabel.textColor = [UIColor blackColor];
        cell.scallLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0];
        cell.scallLabel.backgroundColor = [UIColor cyanColor];
    }
    else
    {
        cell.scallLabel.backgroundColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:0.7];
    }
    //[self changeBackgroundImage:self year:yearForImages];
    //[self displayTimeElapseinSearchBar];
    
    [self.parent changeTimeScaleState];
    
    [self.parent.timeZoomLine changeDateText];
    [self.parent.timeZoomLine changeScaleText];
    if (daysInPeriod <= 30)
    {
        if (![prevYear isEqualToString:[ATHelper getYearPartHelper:appDelegate.focusedDate]])
        {
            prevYear = [ATHelper getYearPartHelper:appDelegate.focusedDate];
            [self.parent displayZoomLine];
        }
    }
    
    return cell;
}



//zoom time, should interactive with timeScale slider in some way
- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    // recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    // recognizer.scale = 1;
    
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        pinchVelocity = 0;
        //lastScale = [recognizer scale];
        //NSLog(@"  pinch gesture Begin, lastScale=%f", lastScale);
    }
    if ([recognizer state] == UIGestureRecognizerStateBegan ||
        [recognizer state] == UIGestureRecognizerStateChanged) {
        //float newScale = [recognizer scale];
        pinchVelocity = pinchVelocity + recognizer.velocity;
        //NSLog(@"     newScale %f  velocity %f",newScale, recognizer.velocity); //velocity < 0 is pinch in
    }
    if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        [self doTimewheelZooming:pinchVelocity];
        
    }
}

- (void) doTimewheelZooming:(int)direction
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self performSettingFocusedRowForPinch:appDelegate.focusedDate];
    
    [self.parent changeTimeScaleState];
    [self.parent refreshAnnotations];
    [self.parent showTimeLinkOverlay];
    [self.parent displayZoomLine];//call this to change time line to whole mode or year mode
    [self showHideZoomAnimation:direction];
}
- (void) performSettingFocusedRowForPinch:(NSDate*) newFocusedDate
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int selectedPeriodInDay = appDelegate.selectedPeriodInDays;
    bool maxZoomOutReached = false;
    NSString* maxZoomOutTxt;
  //  /**** remove zoom level WEEK for simplicity, may be later have a option

        if (selectedPeriodInDay == 7)
        {
            if (pinchVelocity <0)
            {
                appDelegate.selectedPeriodInDays = 30 ;
            }
            else if (pinchVelocity > 0 )
            {
                appDelegate.selectedPeriodInDays = 7;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"WEEK is the max zoom-in level!" message:@"You can change to default max level MONTH in Settings -> Options." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                return;
            }
        }
 
    if (selectedPeriodInDay == 30)
    {
        if (pinchVelocity <0)
        {
            if (currentNumberOfRow >7)
                appDelegate.selectedPeriodInDays = 365 ;
            else //alert that could not zoom out since
                return;
        }
        else if (pinchVelocity > 0 )
        {
            if ([ATHelper getOptionZoomToWeek])
            {
                appDelegate.selectedPeriodInDays = 7;
            }
            else
            {

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MONTH is the max zoom-in level!" message:@"You can make WEEK to be the max zoom-in level in Settings -> Options." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                return;
            }
        }
    }
    if (selectedPeriodInDay == 365)
    {
        if (pinchVelocity <0)  // from 30 to 365
        {
            if (currentNumberOfRow / 10  > 1)
                appDelegate.selectedPeriodInDays = 365 * 10;
            else  //no enough total time to zoom out
            {
                maxZoomOutReached = true;
                maxZoomOutTxt = @"1 year";
                //return;
            }
            //focusedRow = focusedRow/12;
            //focusedRow = abs(components.year);
        }
        else if (pinchVelocity > 0 )  //from 365 to 30
        {
            appDelegate.selectedPeriodInDays = 30;
            
        }
    }
    else if (selectedPeriodInDay == 3650)
    {
        if (pinchVelocity <0)  //form 10 year to 100 year
        {
            if (currentNumberOfRow / 10 > 1)
                appDelegate.selectedPeriodInDays = 3650 * 10;
            else
            {
                maxZoomOutReached = true;
                maxZoomOutTxt = @"10 years";
                //return;
            }
        }
        else if (pinchVelocity > 0 ) //from 10 year to 1 year
        {
            appDelegate.selectedPeriodInDays = 3650/10;
        }
    }
    else if (selectedPeriodInDay == 36500)
    {
        if (pinchVelocity < 0)  //from 100y to 1000 year
        {
            if (currentNumberOfRow / 10 > 1)
                appDelegate.selectedPeriodInDays = 36500 * 10;
            else
            {
                maxZoomOutReached = true;
                maxZoomOutTxt = @"100 years";
                //return;
            }
            //focusedRow = focusedRow/10;
            //focusedRow = abs(components.year /100);
        }
        else if (pinchVelocity > 0 ) //from 100 to 10 year
        {
            appDelegate.selectedPeriodInDays = 36500/10;
            //focusedRow = focusedRow * 10;
            //focusedRow = abs(components.year);
        }
    }
    else if (selectedPeriodInDay == 365000) //1000 year
    {
        if (pinchVelocity < 0)
        {
            if (currentNumberOfRow / 10 > 1)
                appDelegate.selectedPeriodInDays = 365000;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Zooming out the timeline reached 1000-years range limit!" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return;
        }
        else if (pinchVelocity > 0 ) //from 1000 to 100
        {
            appDelegate.selectedPeriodInDays = 365000/10;
            //focusedRow = focusedRow * 10;
            //focusedRow = abs(components.year / 10);
        }
    }
    if (maxZoomOutReached)
    {
        NSDateFormatter* df = appDelegate.dateFormater;
        NSString* dt = [[df stringFromDate:appDelegate.focusedDate] substringToIndex:10];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot zoom-out anymore!" message:[NSString stringWithFormat:@"In this case, all events within %@ of %@ are colored.",maxZoomOutTxt, dt] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    [self performSettingFocusedRowForDate:newFocusedDate needAdjusted: FALSE];
}

- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)recognizer{
    //NSLog(@"----  double Tapped");
    
    //IMPORTANT: following two line is to find touch point when tap on tableView, spent long time to find this solution.
    NSIndexPath *index = [self.horizontalTableView indexPathForRowAtPoint: [recognizer locationInView:self.horizontalTableView]];
    CGRect rect;
    if (index == nil) //this is to handle when horizontal table only has fewer than 9 cell and double tap on non-cell position
        rect.origin.x=9999;
    else
        rect = [self.horizontalTableView convertRect:[self.horizontalTableView rectForRowAtIndexPath:index] toView:[self.horizontalTableView superview]];
    
    //ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int windowWidth = [ATConstants timeScrollWindowWidth];
    int leftPosition = windowWidth/3;
    int middlePosition = 2 * windowWidth / 3;
    if (rect.origin.x <= leftPosition) //touch right side,  zoom out
    {
        pinchVelocity = -999; //reuse code for pinch. as long as less than 0
        [self doTimewheelZooming:pinchVelocity];
    }
    else if (rect.origin.x > leftPosition && rect.origin.x <= middlePosition) //middle position
    {
        NSDate* today = [[NSDate alloc] init];
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.focusedDate = today;
        [self performSettingFocusedRowForDate:today needAdjusted:FALSE];
        [self.parent refreshAnnotations];
        [self.parent.timeZoomLine showHideScaleText:false]; //have to do this else scale label will show
    }
    else //touched right side, zoom in the time window
    {
        pinchVelocity = 999; //reuse code for pinch. as long as greate than 0
        [self doTimewheelZooming:pinchVelocity];
    }
    //Todo this does not help to fix doubleTap issue, not important anyway. ----[self centerTable];
}

-(void) zoomInAction:(id)sender
{
    pinchVelocity = 999; //reuse code for pinch. as long as greate than 0
    [self doTimewheelZooming:pinchVelocity];
}
-(void) zoomOutAction:(id)sender
{
    pinchVelocity = -999; //reuse code for pinch. as long as greate than 0
    [self doTimewheelZooming:pinchVelocity];
}

//have tap gesture achive two thing: prevent call tapGesture on parent mapView and process select a row action without a TableViewController
- (void)handleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer numberOfTouches] == 1)
    {
        NSIndexPath *index = [self.horizontalTableView indexPathForRowAtPoint: [gestureRecognizer locationInView:self.horizontalTableView]];
        //NSLog(@"   row clicked on is %i", index.row);
        [self didSelectRowAtIndexPath:index];
        [self changeFocusedCellColorToRed];
    }
}

- (void)handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer //do nothing, just to prevent mapview's longpress
{
}

- (void) scrollToFocusedRow
{
    //NSLog(@"======== ScrollToFocusedRow at %d", focusedRow);
    if (focusedRow == 0 || focusedRow > currentNumberOfRow + 1 || focusedRow == currentNumberOfRow) //somehow these will cause crash
        return;
    if (focusedRow > currentNumberOfRow) //sometimes focusedRow will be too big that cause crash, need more investigate why, here is defenseively program to make sure it works
        focusedRow = currentNumberOfRow -1;
    
    int scrollToRow = focusedRow;
    //TODO xxxxxx very weired, my iPod touch have to add by 1, while iPad need decrease by 1 need more test
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && focusedRow + 1 > currentNumberOfRow)
        scrollToRow = focusedRow + 1;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && focusedRow - 1 > 0)
        scrollToRow = focusedRow - 1;
    
    [self.horizontalTableView scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:scrollToRow inSection:0]
                                    atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    [self changeFocusedCellColorToRed];
}
- (void) changeFocusedCellColorToRed
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *paths = [self.horizontalTableView indexPathsForVisibleRows];
    float rowDistance = 0;
    for (NSIndexPath *path in paths) {
        ATTimeScrollCell* cell = (ATTimeScrollCell*)[self.horizontalTableView cellForRowAtIndexPath:path];
        rowDistance = abs(focusedRow - path.row);
        if (rowDistance == 0)
        {
            if (appDelegate.selectedPeriodInDays > 365)
            {
                cell.titleLabel.textColor=[UIColor colorWithRed:1.0 green:0 blue:0 alpha:1];
            }
            else
            {
                //cell.titleLabel.backgroundColor = [UIColor clearColor];
                cell.subLabel.textColor=[UIColor redColor];
            }
            
            if ([ATHelper isStringNumber:cell.scallLabel.text])
            {
                cell.scallLabel.backgroundColor = [UIColor cyanColor];
            }
            else
                cell.scallLabel.backgroundColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:0.7];
        }
        else
        {
            if (appDelegate.selectedPeriodInDays > 365)
                cell.titleLabel.textColor = [UIColor blackColor];
            
            cell.subLabel.textColor = [UIColor blackColor];
            
            float colorDivider = rowDistance + 2;
            cell.scallLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.1*colorDivider blue:0.1*colorDivider alpha:0.7];
            cell.scallLabel.textColor = [UIColor whiteColor];
            if (path.row > focusedRow && ![ATHelper isStringNumber:cell.scallLabel.text])
                cell.scallLabel.textColor = [UIColor greenColor];
            if ([ATHelper isStringNumber:cell.scallLabel.text])
            {
                cell.scallLabel.textColor = [UIColor blackColor];
                cell.scallLabel.backgroundColor = [UIColor cyanColor];
            }
        }
    }
}

- (UIColor*)stretchScleImage:(NSString*) imageName :(CGRect) labelFrame
{
    UIImage* originalImage = [UIImage imageNamed:imageName];
    CGSize imgSize = labelFrame.size;
    
    UIGraphicsBeginImageContext( labelFrame.size );
    [originalImage drawInRect:CGRectMake(0,0,imgSize.width,imgSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:newImage];
}

- (void)endDeceleratingAction
{
    //NSLog(@"end move");
    [self.parent.timeZoomLine showHideScaleText: false];
    [self.parent.timeZoomLine changeDateText];
    [self.parent.timeZoomLine changeScaleText];
    [self.parent refreshAnnotations];
    [self changeFocusedCellColorToRed ];
    
    //animate button for emphasis
    /*
    if (toastFirstTimeDelay == 5 || toastFirstTimeDelay == 15 || toastFirstTimeDelay == 35 || toastFirstTimeDelay == 60 )
    {
        
        btnZoomOut.alpha = 1.0f;
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionAutoreverse
                         animations:^
         {
             [UIView setAnimationRepeatCount:10.0f/2.0f];
             btnZoomOut.alpha = 0.0f;
         }
                         completion:^(BOOL finished)
         {
             btnZoomOut.alpha = 1.0;
         }];
        btnZoomIn.alpha = 1.0f;
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionAutoreverse
                         animations:^
         {
             [UIView setAnimationRepeatCount:8.0f/2.0f];
             btnZoomIn.alpha = 0.0f;
         }
                         completion:^(BOOL finished)
         {
             btnZoomIn.alpha = 1.0;
         }];
        
    }
    toastFirstTimeDelay ++;
     */
}

- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath  //called by tapGesture. This is not in a TableViewController, so no didSelect... delegate mechanism, have to process  by tap gesture
{
    //TODO is it neccessart to move tapped cell to middle???
    /*
     ATTimeScrollCell *cell = (ATTimeScrollCell*)[self.horizontalTableView cellForRowAtIndexPath:indexPath];
     ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
     appDelegate.focusedDate = cell.date;
     //xxxxxx see new logic for center       focusedRow = indexPath.row;
     //NSLog(@" ------ horizontal row didselected  cell date is %@", appDelegate.focusedDate);
     [self.parent.timeZoomLine showHideScaleText:false];
     //[self displayTimeElapseinSearchBar]; //from Yixing suggestion, do not confuse people
     [self.parent refreshAnnotations];
     [self changeFocusedCellColorToRed ];
     */
}
- (void) performSettingFocusedRowForDate:(NSDate*) newFocusedDate needAdjusted:(BOOL)fromFocuseEventDate
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int selectedPeriodInDay = appDelegate.selectedPeriodInDays;
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:newFocusedDate toDate:timeWindowStartDate options:0];
    
    if (selectedPeriodInDay == 30 || selectedPeriodInDay == 7)
    {
        //For day, use timeInterval is more accurate
        NSTimeInterval interval = [newFocusedDate timeIntervalSinceDate: timeWindowStartDate];
        focusedRow = interval/86400;
    }
    else if (selectedPeriodInDay == 365)
    {
        focusedRow = abs(components.year * 12) + abs(components.month);
    }
    else if (selectedPeriodInDay == 3650)
    {
        focusedRow = abs(components.year);
    }
    else if (selectedPeriodInDay == 36500)
    {
        focusedRow = abs(components.year / 10);
    }
    else if (selectedPeriodInDay == 365000) //1000 year
    {
        focusedRow = abs(components.year / 100);
    }
    
    if (fromFocuseEventDate && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        focusedRow++; //TODO: do not know why, only when focused a selected event to time wheel need to add by 1, in iPad  not iPhone case
    
    [self.horizontalTableView reloadData];
    
    //NSLog(@" ------ year=%i,mon=%i,day=%d,focusedRow=%i,currNoRow=%i",components.year, components.month, components.day,focusedRow,currentNumberOfRow);
    if (focusedRow > currentNumberOfRow) //this check is not neccessary, but leave it here
        focusedRow = currentNumberOfRow - 5;
    [self scrollToFocusedRow]; //important
    
}

-(void) displayTimeElapseinSearchBar
{
    self.parent.searchBar.text = [self getTimeElapsedFromFocusedDate];
}


- (NSString*)getTimeElapsedFromFocusedDate
{
    NSDate* today = [[NSDate alloc] init];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSTimeInterval interval = [appDelegate.focusedDate timeIntervalSinceDate: today];
    int dayInterval = interval/86400;
    /** These logic is for my previouse thining that all point be shown, and color phase depends on selectedPeriodInDays
     float segmentDistance = dayInterval/segmentInDays;
     ***/
    
    //Here, only show events withing selectedPeriodInDays, color phase will be selectedPeriodInDays/8
    int year = dayInterval/365 ;
    yearElapsedFromToday = year; //used in time scroll logic
    int month = dayInterval/30;
    int monthInYear = abs((dayInterval - year*365)/30);
    int dayInMonth = abs((dayInterval - year*365 - month*30));
    NSString* beforeAgo;
    NSString* returnStr;
    int finalDisplayNumber;
    if (year != 0)
    {
        if (year < -1 )
        {
            if (abs(year) < 5 && monthInYear != 0)
                beforeAgo = [NSString stringWithFormat: @"years %i mo ago", monthInYear];
            else
                beforeAgo = [NSString stringWithFormat: @"years ago"];
        }
        else if (year == -1)
            if (monthInYear !=0)
                beforeAgo = [NSString stringWithFormat: @"year %i mo ago", monthInYear];
            else
                beforeAgo = [NSString stringWithFormat: @"year ago"];
            else if (year == 1)
                if (monthInYear !=0)
                    beforeAgo = [NSString stringWithFormat: @"year %i mo later", monthInYear];
                else
                    beforeAgo = [NSString stringWithFormat: @"year later"];
                else
                {
                    if (abs(year) < 5 && monthInYear != 0)
                        beforeAgo = [NSString stringWithFormat: @"years %i mo later", monthInYear];
                    else
                        beforeAgo = [NSString stringWithFormat: @"years later"];
                }
        finalDisplayNumber = year;
    }
    else if (month != 0 && year == 0)
    {
        NSString* dayW = @"day";
        if (dayInMonth > 1)
            dayW = @"days";
        if (month < -1)
            beforeAgo = [NSString stringWithFormat: @"mo %i %@ ago", dayInMonth, dayW];
        else if (month == -1)
            beforeAgo = [NSString stringWithFormat: @"mo %i %@ ago", dayInMonth, dayW];
        else if (month == 1)
            beforeAgo =[NSString stringWithFormat: @"mo %i %@ later", dayInMonth, dayW];
        else
            beforeAgo = [NSString stringWithFormat: @"mo %i %@ later", dayInMonth, dayW];
        finalDisplayNumber = month;
    }
    else if (dayInterval != 0 && month == 0 && year == 0)
    {
        if (dayInterval < -1)
            beforeAgo = @"days ago";
        else if (dayInterval == -1)
            beforeAgo = @"day ago";
        else if (dayInterval == 1)
            beforeAgo =@"day later";
        else
            beforeAgo = @"days later";
        finalDisplayNumber = dayInterval;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (dayInterval == 0)
            returnStr = @"                          Today";
        else
            returnStr = [NSString stringWithFormat:@"               %i %@",abs(finalDisplayNumber), beforeAgo];
        return returnStr;
    }
    else
    {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        {
            if (dayInterval == 0)
                returnStr = @"             Today";
            else
                returnStr = [NSString stringWithFormat:@"         %i %@",abs(finalDisplayNumber), beforeAgo];
        }
        else
        {
            if (dayInterval == 0)
                returnStr = @"     Today";
            else
                returnStr = [NSString stringWithFormat:@" %i %@",abs(finalDisplayNumber), beforeAgo];
        }
        return returnStr;
    }
}

#pragma mark - Memory Management

- (NSString *) reuseIdentifier
{
    return @"HorizontalCell";
}

- (void) changeBackgroundImage:(UIView*)view year:(int)year
{
    NSString* tmpImg = nil;
    self.horizontalTableView.backgroundColor = [UIColor clearColor];
    if (year <-2500)
        tmpImg=@"3000BCSumer.png";
    else if (year < -2000)
        tmpImg = @"2500BCPyramid.png";
    else if (year < -1700)
        tmpImg = @"2000BCDing.png";
    else if (year < -1500)
        tmpImg = @"1700BCHamrabi.png";
    else if (year < -1000)
        tmpImg = @"1200BCTut.png";
    else if (year < -700)
        tmpImg = @"1000BCDavid.png";
    else if (year < -500)
        tmpImg = @"700BC.png";
    else if (year < -300)
        tmpImg = @"500BC.png";
    else if (year < -200)
        tmpImg = @"300BCAlex.png";
    else if (year < -100)
        tmpImg = @"200BCQin.png";
    else if (year < 0)
        tmpImg = @"100BCRome.png";
    else if (year < 600)
        tmpImg = @"0BC.png";
    else if (year < 650)
        tmpImg = @"600ADMahamd.png";
    else if (year < 1000)
        tmpImg = @"650ADTangTaiZhong.png";
    else if (year < 1500)
        tmpImg = @"1000ADCrusade.png";
    else if (year < 1800)
        tmpImg = @"1500DaVench.png";
    else if (year < 1914)
        tmpImg = @"1800AD.png";
    else if (year < 1945)
        tmpImg = @"1914ADWar1.png";
    else //no picture
    { //added on 2013-06-01 when first version is in wait for review
        //self.horizontalTableView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        int selectedPeriod = appDelegate.selectedPeriodInDays;
        if (selectedPeriod == 30)
            tmpImg = @"scaleBkg_25.png";
        else if (selectedPeriod == 365)
            tmpImg = @"scaleBkg_20.png";
        else if (selectedPeriod == 3650)
            tmpImg = @"scaleBkg_15.png";
        else if (selectedPeriod == 36500)
            tmpImg = @"scaleBkg_10.png";
        else if (selectedPeriod == 365000)
            tmpImg = @"scaleBkg_5.png";
        else if (selectedPeriod == 7)
            tmpImg = @"scaleBkg_60.png";
        
    }
    
    if (tmpImg != nil )
    {
        self.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:tmpImg]];
    }
    
}

-(void) setNewFocusedDateFromAnnotation:(NSDate *)newFocusedDate needAdjusted:(BOOL)needAdjusted
{
    //NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    //[dateComponents setYear:-1];
    [self performSettingFocusedRowForDate:newFocusedDate needAdjusted:needAdjusted];
}

//recursive function to get index of a event
-(int) getIndexOfClosestDate:(NSDate*)inDate :(int)startPos :(int)size
{
    //if (size == FIRST_TIME_CALL)
    //NSLog(@"===== FIRST TIME: inDate=%@, startPos=%i, size=%i",inDate, startPos,size);
    if (size > 2 || size == FIRST_TIME_CALL)
    {
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSArray* sortedEventList = appDelegate.eventListSorted;
        if (size == FIRST_TIME_CALL)
            size = [sortedEventList count];
        if (size == 0) return 0;
        int middlePos = startPos + size/2;
        //NSLog(@"         inDate=%@, startPos=%i, middle=%i, size=%i",inDate, startPos, middlePos, size);;
        ATEventDataStruct *middleEntity = sortedEventList[middlePos];
        NSDate* middleDate = middleEntity.eventDate;
        //if ([middleDate compare:inDate] == NSOrderedSame ) return middlePos;
        if ([middleDate compare:inDate] == NSOrderedAscending) // if middleDate < inDate . remember the sort is from latest to earlist
        {
            if ([middleDate compare: inDate ]  == NSOrderedSame) size = size/2 -1;
            return [self getIndexOfClosestDate:inDate :startPos :size/2 + 1];
        }
        else
        {
            int newSize = size/2;
            if (2*newSize < size)
                newSize = newSize + 1;
            return [self getIndexOfClosestDate:inDate :middlePos :newSize];
        }
    }
    else
        return startPos;
}

- (void)showHideZoomAnimation:(float)pinchDirection //minus is zoom out
{
    int leftViewFromX;
    int leftViewToX;
    int rightViewFromX;
    int rightViewToX;
    
    if (pinchDirection > 0) //zoom out
    {
        leftViewFromX = [ATConstants timeScrollWindowWidth]/2;
        leftViewToX = 0;
        rightViewFromX = [ATConstants timeScrollWindowWidth]/2;
        rightViewToX = [ATConstants timeScrollWindowWidth];
    }
    else //zomm in
    {
        leftViewToX = [ATConstants timeScrollWindowWidth]/2;
        leftViewFromX = 0;
        rightViewToX = [ATConstants timeScrollWindowWidth]/2;
        rightViewFromX = [ATConstants timeScrollWindowWidth];
    }
    int height = [ATConstants timeScrollWindowHeight];
    leftZommAnimationView.frame=CGRectMake(leftViewFromX, 0, 50, height);
    rightZoomAnimationView.frame=CGRectMake(rightViewFromX, 0, 50, height);
    leftZommAnimationView.hidden = false;
    rightZoomAnimationView.hidden = false;
    CGRect leftFrameNew = CGRectMake(leftViewToX, 0, 50, height);
    CGRect rightFrameNew = CGRectMake(rightViewToX, 0, 50, height);
    [UIView transitionWithView:leftZommAnimationView
                      duration:0.5f
                       options:UIViewAnimationCurveEaseInOut
                    animations:^(void) {
                        leftZommAnimationView.frame = leftFrameNew;
                    }
                    completion:^(BOOL finished) {
                        [leftZommAnimationView setHidden:TRUE];
                    }];
    [UIView transitionWithView:rightZoomAnimationView
                      duration:0.5f
                       options:UIViewAnimationCurveEaseInOut
                    animations:^(void) {
                        rightZoomAnimationView.frame = rightFrameNew;
                    }
                    completion:^(BOOL finished) {
                        [rightZoomAnimationView setHidden:TRUE];
                    }];
    
    //TODO may show labelScaleText in timeZoomLine
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // if decelerating, let scrollViewDidEndDecelerating: handle it
    if (decelerate == NO) {
        [self centerTable];
        [self endDeceleratingAction];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self centerTable];
    [self endDeceleratingAction];
}

- (void)centerTable {
    NSIndexPath *pathForCenterCell = [self.horizontalTableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.horizontalTableView.bounds), CGRectGetMidY(self.horizontalTableView.bounds))];
    
    [self.horizontalTableView scrollToRowAtIndexPath:pathForCenterCell atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    focusedRow = pathForCenterCell.row; //xxxxx need test
    ATTimeScrollCell *cell = (ATTimeScrollCell*)[self.horizontalTableView cellForRowAtIndexPath:pathForCenterCell];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.focusedDate = cell.date;
}
//Following it to detect scroll direction, currently I am not using it
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    lastContentOffset = scrollView.contentOffset.y;
}


- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (lastContentOffset > self.horizontalTableView.contentOffset.y)
        scrollDirection = SCROLL_DIRECTION_RIGHT;
    else if (lastContentOffset < self.horizontalTableView.contentOffset.y)
        scrollDirection = SCROLL_DIRECTION_LEFT;
    
    lastContentOffset = self.horizontalTableView.contentOffset.y;
    
    // do whatever you need to with scrollDirection here.
}

//add for iOS 7 migration
- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}
/*
 
 startIndex = getIndexOfCloesetDate(startDate, 0, eventList.size)
 endIndex = getIndexOfCloesetDate(endDate, 0, eventList.size)
 
 numberOfEvents = endIndex - startIndex
 */

@end
