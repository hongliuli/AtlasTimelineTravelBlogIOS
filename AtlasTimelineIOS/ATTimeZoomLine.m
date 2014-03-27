//
//  ATTimeZoomLine.m
//  AtlasTimelineIOS
//
//  Created by Hong on 2/12/13.
//  Copyright (c) 2013 hong. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "ATTimeZoomLine.h"
#import "ATAppDelegate.h"
#import "ATHelper.h"
#import "ATConstants.h"
#import "ATEventDataStruct.h"
#import "ATTimeScrollWindowNew.h"
#import "Toast+UIView.h"

#define MOVABLE_VIEW_HEIGHT 2
#define LABEL_SCALE_TEXT_CONTAINER_Y -38
#define ZOOM_LEVEL_TXT_Y -1
#define ZOOM_LEVEL_BLOCK_HEIGHT 30
#define SCREEN_WIDTH ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

@implementation ATTimeZoomLine

UIView* timeScaleLineView;
UILabel* timeScaleLeftBlock;
UILabel* timeScaleRightBlock;
UILabel* timeScaleZoomLeveText;

//UILabel* labelScaleText;
UILabel* label1;
UILabel* label2;
UILabel* label3;
UILabel* label4;
UILabel* label5;
/*
UILabel* labelSeg1;
UILabel* labelSeg2;
UILabel* labelSeg3;
UILabel* labelSeg4;
 */

static int toastFirstTimeDelay = 0;

UIView* labelScaleTextContainer;
UILabel* labelScaleText;
UILabel* labelScaleTextSecondLine;
UILabel* labelMagnifier;
UILabel* labelDateMonthText;

NSCalendar *calendar;
NSDateFormatter *dateLiterFormat;

NSDate* mStartDateFromParent;
NSDate* mEndDateFromParent;

double frameWidth;
CGContextRef context;

NSDate* prevYearDate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        frameWidth = frame.size.width;
        // Initialization code
        timeScaleLineView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width/2 - 45, -10, 90, MOVABLE_VIEW_HEIGHT)];
        timeScaleZoomLeveText = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2 - 45, ZOOM_LEVEL_TXT_Y, 90, 15)];
        timeScaleZoomLeveText.textColor = [UIColor darkGrayColor];
        timeScaleZoomLeveText.font = [UIFont fontWithName:@"Helvetica-bold" size:12];
        timeScaleZoomLeveText.textAlignment = NSTextAlignmentCenter;
        
        CGRect frameLeft = CGRectMake(0, -10, 10, ZOOM_LEVEL_BLOCK_HEIGHT);
        timeScaleLeftBlock = [[UILabel alloc] initWithFrame:frameLeft];
        [timeScaleLeftBlock setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.15]];

        CGRect frameRight = CGRectMake([ATConstants timeScrollWindowWidth] - 200, -10, 300, ZOOM_LEVEL_BLOCK_HEIGHT);
        timeScaleRightBlock = [[UILabel alloc] initWithFrame:frameRight];
        [timeScaleRightBlock setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.15]];
        
        /*
        self.zoomLabel.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0.8 alpha:1 ];
        self.zoomLabel.font=[UIFont fontWithName:@"Helvetica" size:13];
        self.zoomLabel.layer.borderColor=[UIColor orangeColor].CGColor;
        self.zoomLabel.layer.borderWidth=1;
        self.zoomLabel.textAlignment = UITextAlignmentCenter;
        //self.zoomLabel.backgroundColor =
        self.zoomLabel.layer.cornerRadius = 5;
        */

        label1 = [[UILabel alloc] initWithFrame:CGRectMake(-10, -15, 70, 15)];
        
        label2 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/4 - 25, -15, 70, 15)];
        
        label3 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2 - 25, -15, 70, 15)];
        
        label4 = [[UILabel alloc] initWithFrame:CGRectMake(3*frame.size.width/4 - 25, -15, 70, 15)];
        
        label5 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 25, -15, 70, 15)];

        int segLabelShift = 70;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            segLabelShift = 40;

        
        [self addSubview:timeScaleLineView];
        [self addSubview:timeScaleZoomLeveText];

        [self addSubview:label1];
        [self addSubview:label2];
        [self addSubview:label3];
        [self addSubview:label4];
        [self addSubview:label5];
        [self addSubview:timeScaleLeftBlock];
        [self addSubview:timeScaleRightBlock];
        
        /*
        labelSeg1 = [[UILabel alloc] initWithFrame:CGRectMake(segLabelShift, -5, 70, 15)];
        labelSeg1.backgroundColor = [UIColor clearColor];
        labelSeg1.textColor = [UIColor blueColor];
        labelSeg1.font=[UIFont fontWithName:@"Helvetica" size:11];
        [self addSubview:labelSeg1];
        labelSeg2 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/4 + segLabelShift, -5, 70, 15)];
        labelSeg2.backgroundColor = [UIColor clearColor];
        labelSeg2.textColor = [UIColor blueColor];
        labelSeg2.font=[UIFont fontWithName:@"Helvetica" size:11];
        [self addSubview:labelSeg2];
        labelSeg3 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2 + segLabelShift, -5, 70, 15)];
        labelSeg3.backgroundColor = [UIColor clearColor];
        labelSeg3.textColor = [UIColor blueColor];
        labelSeg3.font=[UIFont fontWithName:@"Helvetica" size:11];
        [self addSubview:labelSeg3];
        labelSeg4 = [[UILabel alloc] initWithFrame:CGRectMake(3*frame.size.width/4 + segLabelShift, -5, 70, 15)];
        labelSeg4.backgroundColor = [UIColor clearColor];
        labelSeg4.textColor = [UIColor blueColor];
        labelSeg4.font=[UIFont fontWithName:@"Helvetica" size:11];
        [self addSubview:labelSeg4];
        */
        dateLiterFormat=[[NSDateFormatter alloc] init];
        [dateLiterFormat setDateFormat:@"EEEE MMMM dd"];
        
        //add the at front
        
        labelScaleTextContainer = [[UIView alloc] initWithFrame:CGRectMake(-30,LABEL_SCALE_TEXT_CONTAINER_Y, 80, 45)];
        labelScaleTextContainer.backgroundColor = [UIColor  colorWithRed:0.8 green:0.8 blue:1.0 alpha:0.5 ];
        labelScaleTextContainer.layer.borderColor=[UIColor grayColor].CGColor;
        labelScaleTextContainer.layer.borderWidth=1;
        labelScaleTextContainer.layer.cornerRadius = 15;
        
        labelScaleText = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 80, 20)];

        labelScaleText.textColor = [UIColor blueColor];
        labelScaleText.font=[UIFont fontWithName:@"Helvetica-bold" size:20];
        labelScaleText.textAlignment = NSTextAlignmentCenter;
        
        labelScaleTextSecondLine = [[UILabel alloc] initWithFrame:CGRectMake(0,25, 80, 20)];
        labelScaleTextSecondLine.backgroundColor = [UIColor clearColor];
        labelScaleTextSecondLine.textColor = [UIColor blueColor];
        labelScaleTextSecondLine.font=[UIFont fontWithName:@"Helvetica" size:16];
        labelScaleTextSecondLine.textAlignment = NSTextAlignmentCenter;
        
        
        [labelScaleTextContainer addSubview:labelScaleText];
        [labelScaleTextContainer addSubview:labelScaleTextSecondLine];
        [self addSubview:labelScaleTextContainer];
        
        CGPoint center = timeScaleLineView.center;
        center.y = 100;
        labelScaleTextContainer.hidden=true;
        labelScaleTextContainer.center = center;
        
        //UIWindow* theWindow = [[UIApplication sharedApplication] keyWindow];
        //UIViewController* rvc = theWindow.rootViewController;
        

        //Following xCenter numbers is based on test, if some number even make program crash when change orenation
        int deviceDeltaLandscape = 0;
        int deviceDeltaPortrait = 0;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            deviceDeltaLandscape = 50;
            deviceDeltaPortrait = -100;
        }
        int xCenter = SCREEN_WIDTH/2 -45;//self.mapViewController.timeScrollWindow.center.x;
        xCenter = [ATConstants screenWidth]/2 -45 + deviceDeltaLandscape;
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
            xCenter = SCREEN_WIDTH/2 - 17 - deviceDeltaPortrait;
        //for Retina landscape iPhone5, need special adjust
        
        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];

        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)
            && UIInterfaceOrientationIsLandscape(interfaceOrientation)
            && screenRect.size.height == 568) //to see if it is iPhone5 width
            xCenter = xCenter -43;
        labelMagnifier = [[UILabel alloc] initWithFrame:CGRectMake(xCenter,200, 80, 80)];
        labelMagnifier.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:1.0 alpha:0.5 ];
        labelMagnifier.font=[UIFont fontWithName:@"Helvetica-bold" size:24];
        labelMagnifier.layer.borderColor=[UIColor grayColor].CGColor;
        labelMagnifier.layer.borderWidth=1;
        labelMagnifier.layer.shadowColor = [UIColor blackColor].CGColor;
        labelMagnifier.layer.shadowOffset = CGSizeMake(100,100);
        labelMagnifier.layer.shadowOpacity = 1;
        labelMagnifier.layer.shadowRadius = 40.0;
        labelMagnifier.layer.cornerRadius = 40;
        labelMagnifier.textAlignment = NSTextAlignmentCenter;
        //Puposely comment out    [self addSubview:labelDateText];
        [self addSubview:labelMagnifier];
        
        labelDateMonthText = [[UILabel alloc] initWithFrame:CGRectMake(xCenter,240, 40, 40)];
        labelDateMonthText.backgroundColor = [UIColor clearColor];
        labelDateMonthText.font=[UIFont fontWithName:@"Helvetica" size:14];
        labelDateMonthText.textColor = [UIColor blackColor];
        labelDateMonthText.layer.borderColor=[UIColor clearColor].CGColor;
        labelDateMonthText.layer.borderWidth=0;
        labelDateMonthText.textAlignment = NSTextAlignmentCenter;
        //Puposely comment out    [self addSubview:labelDateText];
        [self addSubview:labelDateMonthText];
        

        labelMagnifier.center = CGPointMake(xCenter, 0);// timeScaleImageView.center;
        labelDateMonthText.center = CGPointMake(xCenter, 20);// timeScaleImageView.center;

        
    }
    return self;
}

//called in ATViewController
- (void) changeScaleText
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([ATHelper getOptionDateMagnifierModeScroll])
    {
        labelScaleTextContainer.hidden = false;
        labelMagnifier.hidden = true;
        labelDateMonthText.hidden = true;
    }
    else
    {
        labelScaleTextContainer.hidden = true;
        labelMagnifier.hidden = false;
        labelDateMonthText.hidden = false;
    }
    NSString* yrTxt = [ATHelper getYearPartHelper:appDelegate.focusedDate];
    NSString* monthDateText  = @"";
    if (appDelegate.selectedPeriodInDays   < 3650)
        monthDateText = [ATHelper getMonthSlashDateInNumber:appDelegate.focusedDate];

    labelScaleText.text = yrTxt;
    labelScaleTextSecondLine.text = monthDateText;
}
- (void) changeDateText
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([ATHelper getOptionDateMagnifierModeScroll])
    {
        labelScaleTextContainer.hidden = true;
        labelMagnifier.hidden = false;
        labelDateMonthText.hidden = false;
    }
    else
    {
        labelScaleTextContainer.hidden = false;
        labelMagnifier.hidden = true;
        labelDateMonthText.hidden = true;
    }
    NSString* yearText = [ATHelper getYearPartHelper:appDelegate.focusedDate];
    NSString* monthDateText  = @"";
    if (appDelegate.selectedPeriodInDays < 3650)
        monthDateText = [ATHelper getMonthSlashDateInNumber:appDelegate.focusedDate];
    if ([yearText rangeOfString:@"BC"].location == NSNotFound)
    {
        labelMagnifier.text=[yearText substringToIndex:4];
        labelMagnifier.textColor = [UIColor blackColor];
    }
    else
    {
        labelMagnifier.text=[yearText substringToIndex:4];
        labelMagnifier.textColor = [UIColor redColor];
    }
    labelDateMonthText.text = monthDateText;
}

//called by outside when scrollWindow start/stop, or when change time zoom
- (void)showHideScaleText:(BOOL)showFlag
{
    //labelScaleText.hidden = !showFlag;
    //labelScaleTextSecondLine.hidden = !showFlag;
    labelMagnifier.hidden = !showFlag;
    labelDateMonthText.hidden = !showFlag;
    
}

//have to call this after set text otherwise sizeToFit will not work
- (void) decorateLabel:(UILabel*)label
{
    UIColor* bgColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.8 alpha:0.5 ];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.selectedPeriodInDays == 30)
        bgColor = [UIColor blueColor];
    else if (appDelegate.selectedPeriodInDays == 7)
        bgColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.8 alpha:1 ];
    label.backgroundColor = bgColor;
    label.textColor = [UIColor whiteColor];
    label.font=[UIFont fontWithName:@"Helvetica-Bold" size:13];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 5;
    label.layer.borderColor = [UIColor brownColor].CGColor;
    label.layer.borderWidth = 1;
    
    [label sizeToFit];
    
}

- (void) decorateLabelYear:(UILabel*)label
{
    UIColor* bgColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.8 alpha:0.5 ];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.selectedPeriodInDays == 30)
        bgColor = [UIColor blueColor];
    else if (appDelegate.selectedPeriodInDays == 7)
        bgColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.8 alpha:1 ];
    label.backgroundColor = bgColor;
    label.textColor = [UIColor whiteColor];
    label.font=[UIFont fontWithName:@"Helvetica-Bold" size:15];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 5;
    label.layer.borderColor = [UIColor brownColor].CGColor;
    label.layer.borderWidth = 1;
    
   // [label sizeToFit];
    
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    int x = CGRectGetMaxX(rect);
    int y = CGRectGetMaxY(rect);

    context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);

    CGContextSetLineWidth(context, 1.0);
    // Draw the base. 
    CGContextMoveToPoint(context, 0,y);
    CGContextAddLineToPoint(context, x, y);
    
    //Draw 1st line at left-most
    CGContextMoveToPoint(context, 0,0);
    CGContextAddLineToPoint(context, 0, y);
    //draw 2nd
    CGContextMoveToPoint(context, x/4,0);
    CGContextAddLineToPoint(context, x/4, y);
    //draw 3rd (middle)
    CGContextMoveToPoint(context, x/2,0);
    CGContextAddLineToPoint(context, x/2, y);
    //draw 4nd
    CGContextMoveToPoint(context, 3*x/4,0);
    CGContextAddLineToPoint(context, 3*x/4, y);
    //Draw last line at right most
    CGContextMoveToPoint(context, x,0);
    CGContextAddLineToPoint(context, x, y); 
    
    CGContextStrokePath(context);
    [self drawEventDotsBySpan];
    

}

//this will be called when add/modify ends event, so it is actually called inside setTimeScrollConfiguration()
- (void)changeScaleLabelsDateFormat:(NSDate*)startDay :(NSDate*)endDay
{
    NSTimeInterval interval = [endDay timeIntervalSinceDate: startDay];
    int dayInterval = interval/86400;
    double timeSpanInDay = dayInterval;

    if (calendar == nil)
        calendar = [NSCalendar currentCalendar];
    
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.selectedPeriodInDays <= 30 || timeSpanInDay <= 356)
    {
        startDay = [ATHelper getYearStartDate:appDelegate.focusedDate];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setYear:1];
        endDay = [gregorian dateByAddingComponents:dateComponents toDate:startDay  options:0];

        label1.text = [NSString stringWithFormat:@"Jan %@", [ATHelper getYearPartHelper:appDelegate.focusedDate] ];
        label2.text = @"  Mar  ";
        label3.text = @"  Jun  ";
        label4.text = @"  Sep  ";
        label5.text = @"  Dec  ";
        
        
        
        CGRect label1Frame = label1.frame;
        CGRect label2Frame = label2.frame;
        CGRect label3Frame = label3.frame;
        CGRect label4Frame = label4.frame;
        CGRect label5Frame = label5.frame;
        
        
        CGRect startFrame = label1.frame;
        startFrame.size.height=0;
        startFrame.size.width=0;
        if ([prevYearDate compare:appDelegate.focusedDate] == NSOrderedDescending) {
            NSLog(@"date1 is later than date2");
            startFrame.origin.x = 1800;
        }
        else
            startFrame.origin.x = 0;
        
        prevYearDate = appDelegate.focusedDate;
        
        [label1 setFrame:startFrame];
        [label2 setFrame:startFrame];
        [label3 setFrame:startFrame];
        [label4 setFrame:startFrame];
        [label5 setFrame:startFrame];
        
        
        [UIView transitionWithView:label1
                          duration:0.9f
                           options: UIViewAnimationCurveEaseIn
                        animations:^(void) {
                            label1.frame = label1Frame;
                        }
                        completion:^(BOOL finished) {
                            // Do nothing
                            [label1 setHidden:false];
                        }];
        [UIView transitionWithView:label2
                          duration:0.9f
                           options: UIViewAnimationCurveEaseIn
                        animations:^(void) {
                            label2.frame = label2Frame;
                        }
                        completion:^(BOOL finished) {
                            // Do nothing
                            [label2 setHidden:false];
                        }];
        [UIView transitionWithView:label3
                          duration:0.9f
                           options: UIViewAnimationCurveEaseIn
                        animations:^(void) {
                            label3.frame = label3Frame;
                        }
                        completion:^(BOOL finished) {
                            // Do nothing
                            [label3 setHidden:false];
                        }];
        [UIView transitionWithView:label4
                          duration:0.9f
                           options: UIViewAnimationCurveEaseIn
                        animations:^(void) {
                            label4.frame = label4Frame;
                        }
                        completion:^(BOOL finished) {
                            // Do nothing
                            [label4 setHidden:false];
                        }];

        [UIView transitionWithView:label5
                          duration:0.9f
                           options: UIViewAnimationCurveEaseIn
                        animations:^(void) {
                            label5.frame = label5Frame;
                        }
                        completion:^(BOOL finished) {
                            // Do nothing
                            [label5 setHidden:false];
                        }];
        
        
        [self decorateLabelYear:label1];
        [self decorateLabel:label2];
        [self decorateLabel:label3];
        [self decorateLabel:label4];
        [self decorateLabel:label5];
    }
    else //always show label as year such as 2003 AD
    {
        NSDate* tmpDate = startDay;

        NSDateComponents *dateComponent = [[NSDateComponents alloc] init];

        label1.text = [NSString stringWithFormat:@" %@ ", [ATHelper getYearPartHelper:tmpDate] ];
        dateComponent.day = timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label2.text = [NSString stringWithFormat:@" %@ ", [ATHelper getYearPartHelper:tmpDate] ];
        dateComponent.day = timeSpanInDay/2;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label3.text = [NSString stringWithFormat:@" %@ ", [ATHelper getYearPartHelper:tmpDate] ];
        dateComponent.day = 3*timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label4.text = [NSString stringWithFormat:@" %@ ", [ATHelper getYearPartHelper:tmpDate] ];
        tmpDate = endDay;
        label5.text = [ATHelper getYearPartHelper:tmpDate];
        [self decorateLabel:label1];
        [self decorateLabel:label2];
        [self decorateLabel:label3];
        [self decorateLabel:label4];
        [self decorateLabel:label5];
        
    }
}

- (NSString*)getThreeLetterMonth:(NSDate*)tmpDate
{
    NSString* tmpDateStr = [dateLiterFormat stringFromDate:tmpDate];
    NSRange range = [tmpDateStr rangeOfString:@" "];
    NSInteger idx = range.location + range.length;
    NSString* monthDateString = [tmpDateStr substringFromIndex:idx];
    return [monthDateString substringToIndex:3];
}

//will be called when scroll time window, zoom time window and add/modify ends events
- (void)changeTimeScaleState:(NSDate*)startDate :(NSDate*)endDate :(int)periodIndays :(NSDate*)focusedDate
{
    mStartDateFromParent = startDate;
    mEndDateFromParent = endDate;
    
    if (calendar == nil)
        calendar = [NSCalendar currentCalendar];
    
    //TODO should we validate that startDay < focused date < endDay ???? for defensive
    
    NSDateComponents *dateComponent = [[NSDateComponents alloc] init];
    
    NSDate* scaleStartDay;
    NSDate* scaleEndDay;
    
    if (focusedDate == nil)
        focusedDate = [[NSDate alloc] init];
    if (periodIndays <= 30)
    {
        dateComponent.day = -1;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.day = 1;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        timeScaleZoomLeveText.text = @"1mo";
        if (periodIndays <= 7)
            timeScaleZoomLeveText.text = @"1wk";
    }
    else if (periodIndays == 365)
    {
        dateComponent.month = -5;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.month = 5;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        timeScaleZoomLeveText.text = @"1yr";
    }
    else if (periodIndays == 3650)
    {
        dateComponent.year = -5;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 5;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        timeScaleZoomLeveText.text = @"10yr";
    }
    else if (periodIndays == 36500)
    {
        dateComponent.year = -50;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 50;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        timeScaleZoomLeveText.text = @"100yr";
    }
    else if (periodIndays == 365000)
    {
        dateComponent.year = -500;
        scaleStartDay = [ATHelper dateByAddingComponentsRegardingEra:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 500;
        scaleEndDay = [ATHelper dateByAddingComponentsRegardingEra:dateComponent toDate:focusedDate options:0];
        timeScaleZoomLeveText.text = @"1000yr";
    }
    if ([startDate compare:scaleStartDay] == NSOrderedDescending)
        scaleStartDay = startDate;
    if ([endDate compare:scaleEndDay] == NSOrderedAscending)
        scaleEndDay = endDate;
    
   // ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
   // NSDateFormatter *dateFormater = appDelegate.dateFormater;
    //NSLog(@"------ focusedDate is %@  formated is %@", focusedDate, [dateFormater stringFromDate:focusedDate]);
    //Following check will fail when accross BC/AD, and not neccessary
    /*
    if ([scaleStartDay compare:scaleEndDay] == NSOrderedDescending)
    {
        NSLog(@"  ####### server error, scaleStartDay should before scaleEndDay");
       // return;
    }
    */

    NSTimeInterval interval = [endDate timeIntervalSinceDate: startDate];
    int dayInterval = interval/86400;
    double timeSpanInDay = dayInterval;
    double pixPerDay = frameWidth / timeSpanInDay;
    
    interval = [scaleStartDay timeIntervalSinceDate: startDate];
    dayInterval = interval/86400;
    
    double scaleStartInPix = pixPerDay*dayInterval;
    
    interval = [scaleEndDay timeIntervalSinceDate: scaleStartDay];
    dayInterval = interval/86400;
    double scaleLengthInPix = pixPerDay * dayInterval;
    
    if (scaleStartInPix + scaleLengthInPix >frameWidth)
    {
        //NSLog(@" ###### Server error inner scale bar out of range");
        return;
    }
    self.scaleLenForDisplay = scaleLengthInPix;
    double scaleStartAdj = 0;
    if (scaleLengthInPix <5)
    {
        if (periodIndays <= 30)
            self.scaleLenForDisplay = 5;
        else
            self.scaleLenForDisplay = 10;
        scaleStartAdj = 0; //need compute?
    }
    //add in 2/21/2014 for zoom to <=30
    if (periodIndays <= 7)
    {
        self.scaleLenForDisplay = 30;
        scaleStartAdj = -10;
    }
    else if (periodIndays == 30)
    {
        self.scaleLenForDisplay = 80;
        scaleStartAdj = -30;
    }
    
    timeScaleLineView.frame = CGRectMake(scaleStartInPix + scaleStartAdj, 10, self.scaleLenForDisplay, MOVABLE_VIEW_HEIGHT);
    [timeScaleLineView setBackgroundColor:[UIColor darkGrayColor]];
    /*
    if (self.scaleLenForDisplay < 150)
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar100.png"]];
    else if (self.scaleLenForDisplay < 250 )
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar200.png"]];
    else if (self.scaleLenForDisplay < 350 )
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar300.png"]];
    else if (self.scaleLenForDisplay < 500 )
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar400.png"]];
    else //if over 500
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar700.png"]];
    */
    
    int x = self.frame.size.width;
    CGRect frameLeft = CGRectMake(0, -10, scaleStartInPix + scaleStartAdj, 20);
    CGRect frameRight = CGRectMake(scaleStartInPix + scaleStartAdj + self.scaleLenForDisplay, -10, x - (scaleStartInPix + scaleStartAdj + self.scaleLenForDisplay), 20);
    
    [timeScaleLeftBlock setFrame:frameLeft];
    [timeScaleRightBlock setFrame:frameRight];
    /*
    CGPoint center = timeScaleLineView.center;
    center.y = -25;//this value decided y value when scroll time window
    labelScaleText.center = center;
    labelScaleTextSecondLine.center = center;
    */
    CGPoint center2 = timeScaleLineView.center;
    center2.y = ZOOM_LEVEL_TXT_Y;//this value decided y value when scroll time window
    timeScaleZoomLeveText.center = center2;
    
    CGPoint center3 = timeScaleLineView.center;
    center3.y = LABEL_SCALE_TEXT_CONTAINER_Y;//this value decided y value when scroll time window
    labelScaleTextContainer.center = center3;

    //[labelScaleText setFrame:CGRectMake(
                                  //  floorf((timeScaleImageView.frame.size.width - labelScaleText.frame.size.width) / 2.0), 0,
                                  //  labelScaleText.frame.size.width, labelScaleText.frame.size.height)];
    
}

- (void)drawEventDotsBySpan
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    float DOT_SIZE = 5.0;
    float DOT_Y_POS = 3.0;
    float DOT_Y_POS_GREEN = -25.0;
    if (appDelegate.selectedPeriodInDays <= 30)
    {
        DOT_SIZE = 8.0;
        DOT_Y_POS_GREEN = -30.0;
        DOT_Y_POS = 0.0;
    }

    Boolean eventVisibleOnMapFlag = false; //draw bar if there are event visible in map screen
    int size = [appDelegate.eventListSorted count] ;
    if (appDelegate.eventListSorted == nil || size < 1)
        return;

    //TODO mStartDate/mEndDate should not be null
    
    NSTimeInterval interval = [mEndDateFromParent timeIntervalSinceDate: mStartDateFromParent];
    int dayInterval = interval/86400;
    double timeSpanInDay = dayInterval;
    double pixPerDay = frameWidth / timeSpanInDay;
    
    //Get current map range
    MKCoordinateRegion region =  self.mapViewController.mapView.region;
    CLLocationCoordinate2D northWestCorner, southEastCorner;
    CLLocationCoordinate2D center   = region.center;
    northWestCorner.latitude  = center.latitude  - (region.span.latitudeDelta  / 2.0);
    northWestCorner.longitude = center.longitude - (region.span.longitudeDelta / 2.0);
    southEastCorner.latitude  = center.latitude  + (region.span.latitudeDelta  / 2.0);
    southEastCorner.longitude = center.longitude + (region.span.longitudeDelta / 2.0);
    
    NSDate* dt1 = ((ATEventDataStruct*)appDelegate.eventListSorted[0]).eventDate;

    //for (ATEventDataStruct* evt in appDelegate.eventListSorted)
    float previouseVisibleEventDrawXPos = 0;
    float previouseRegularDotXPos = 0;


    for (int i = 0; i< size; i++ )
    {
        //NSLog(@"#### i=%d",i);
        ATEventDataStruct* evt = appDelegate.eventListSorted[i];
        NSTimeInterval interval;
        int dayInterval;
        double x;
        
        NSDate* dt = evt.eventDate;
        if ([self checkIfEventOnScreen:evt :northWestCorner :southEastCorner])
        {
            eventVisibleOnMapFlag = true;
        }
        if (i == 0 || i == size - 1) //TODO do not know why i==0 x=930 will not draw dots
        {
            interval = [dt  timeIntervalSinceDate: mStartDateFromParent];
            dayInterval = interval/86400;
            x = pixPerDay * dayInterval;
            if (x >= self.frame.size.width)
                x = x -5;
            if (eventVisibleOnMapFlag)
            {
                CGContextSetRGBFillColor(context, 0,0.5,0.2, 1);
                CGContextFillRect(context, CGRectMake(x, DOT_Y_POS_GREEN, DOT_SIZE, 8*DOT_SIZE));
                previouseVisibleEventDrawXPos = x;
            }
            else
            {
                if (appDelegate.selectedPeriodInDays <=30)
                    CGContextSetRGBFillColor(context, 0.8, 0.3, 0.3, 1);
                else
                    CGContextSetRGBFillColor(context, 1.0, 0.4, 0.4, 1);
                CGContextFillEllipseInRect(context, CGRectMake(x, DOT_Y_POS, DOT_SIZE, DOT_SIZE));
            }
            //dt1 = dt;
            eventVisibleOnMapFlag = false;
            //NSLog(@" o or 1 -- draw dots for dt %@  dt1=%@ and x=%f i=%d", dt, dt1, x, i);
        }
        else
        {   
            interval = [dt  timeIntervalSinceDate: mStartDateFromParent];
            dayInterval = interval/86400;
            x = pixPerDay * dayInterval;
            
            if (eventVisibleOnMapFlag)
            {
                CGContextSetRGBFillColor(context, 0,0.5,0.2, 1);
                CGContextFillRect(context, CGRectMake(x, DOT_Y_POS_GREEN, DOT_SIZE, 8*DOT_SIZE));
                previouseVisibleEventDrawXPos = x;
                if (toastFirstTimeDelay > 10 && toastFirstTimeDelay < 1000 )
                {
                    toastFirstTimeDelay = 10001; //My Trick so only display once
                    float xPos = x - 170;
                    if (xPos < 80)
                        xPos = 100;
                    [self makeToast:@"Tip: Green dots indicate events currently displayed on screen." duration:10.0 position:[NSValue valueWithCGPoint:CGPointMake(xPos, -25)]];
                    self.hidden = false;
                    self.mapViewController.timeScrollWindow.hidden  = false;
                }
            }
            else
            {
                if (abs(x - previouseVisibleEventDrawXPos) >= DOT_SIZE) //make sure barDots will be draw always and not covered by later regular dot
                {
                    if (abs(x - previouseRegularDotXPos) >= DOT_SIZE) //do not draw if too crowd
                    {
                        if (appDelegate.selectedPeriodInDays <=30)
                            CGContextSetRGBFillColor(context, 0.8, 0.3, 0.3, 1);
                        else
                            CGContextSetRGBFillColor(context, 1.0, 0.4, 0.4, 1);
                        
                        CGContextFillEllipseInRect(context, CGRectMake(x, DOT_Y_POS, DOT_SIZE, DOT_SIZE));
                        previouseRegularDotXPos = x;
                    }
                }
            }
            dt1 = dt;
            eventVisibleOnMapFlag = false;
        }
    } //end for loop
    toastFirstTimeDelay++;
}

-(Boolean)checkIfEventOnScreen:(ATEventDataStruct*) event :(CLLocationCoordinate2D)northWestCorner :(CLLocationCoordinate2D)southEastCorner
{
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(event.lat, event.lng);
    CLLocationCoordinate2D location = coord;
    
    return(
        location.latitude  >= northWestCorner.latitude &&
        location.latitude  <= southEastCorner.latitude &&
        
        location.longitude >= northWestCorner.longitude &&
        location.longitude <= southEastCorner.longitude
           );
}


@end
