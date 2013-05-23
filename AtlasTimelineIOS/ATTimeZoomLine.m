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

#define MOVABLE_VIEW_HEIGHT 4

@implementation ATTimeZoomLine

UIImageView* timeScaleImageView;
//UILabel* labelScaleText;
UILabel* label1;
UILabel* label2;
UILabel* label3;
UILabel* label4;
UILabel* label5;
UILabel* labelSeg1;
UILabel* labelSeg2;
UILabel* labelSeg3;
UILabel* labelSeg4;


NSCalendar *calendar;
NSDateFormatter *dateLiterFormat;

double frameWidth;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        frameWidth = frame.size.width;
        // Initialization code
        timeScaleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width/2 - 45, -10, 90, MOVABLE_VIEW_HEIGHT)];
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar700.png"]];
        timeScaleImageView.contentMode = UIViewContentModeScaleToFill; // UIViewContentModeScaleAspectFill;
        timeScaleImageView.clipsToBounds = YES;
        
        /*
        labelScaleText = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 200, MOVABLE_VIEW_HEIGHT)];
        labelScaleText.font=[UIFont fontWithName:@"Helvetica-Bold" size:13];
        labelScaleText.backgroundColor = [UIColor clearColor];
        labelScaleText.textColor = [UIColor whiteColor];
        labelScaleText.textAlignment = UITextAlignmentCenter;
        [timeScaleImageView addSubview:labelScaleText];
        labelScaleText.center = timeScaleImageView.center;
        */
        
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

        
        [self addSubview:timeScaleImageView];
        [self addSubview:label1];
        [self addSubview:label2];
        [self addSubview:label3];
        [self addSubview:label4];
        [self addSubview:label5];
        
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
        
        dateLiterFormat=[[NSDateFormatter alloc] init];
        [dateLiterFormat setDateFormat:@"EEEE MMMM dd"];
    }
    return self;
}

- (void) changeScaleText:(NSString *)text
{
   // labelScaleText.text = text;
}

//have to call this after set text otherwise sizeToFit will not work
- (void) fitSzie:(UILabel*)label
{
    UIColor* bgColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.1 alpha:0.5 ];
    label.backgroundColor = bgColor;
    label.textColor = [UIColor whiteColor];
    label.font=[UIFont fontWithName:@"Helvetica-Bold" size:13];
    label.textAlignment = UITextAlignmentCenter;
    label.layer.cornerRadius = 5;
    label.layer.borderColor = [UIColor brownColor].CGColor;
    label.layer.borderWidth = 1;
    
    [label sizeToFit];
    
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    int x = CGRectGetMaxX(rect);
    int y = CGRectGetMaxY(rect);

    CGContextRef context = UIGraphicsGetCurrentContext();
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
}

//this will be called when add/modify ends event, so it is actually called inside setTimeScrollConfiguration()
- (void)changeScaleLabelsDateFormat:(NSDate*)startDay :(NSDate*)endDay
{
    NSTimeInterval interval = [endDay timeIntervalSinceDate: startDay];
    int dayInterval = interval/86400;
    double timeSpanInDay = dayInterval;
    float tmp = 0.0;
    int timeSegment = 0;
    NSString* timeSegmentUnit = nil;
    if (timeSpanInDay < 121)
    {
        tmp = timeSpanInDay/4;
        timeSegment = timeSpanInDay/4;
        timeSegmentUnit = @"days";
    }
    else if (timeSpanInDay < 365*4)
    {
        tmp = timeSpanInDay/120;
        timeSegment = timeSpanInDay/120; //divide 30 and 4
        timeSegmentUnit=@"months";
    }
    else
    {
        tmp = (timeSpanInDay/365)/4;
        timeSegment = (timeSpanInDay/365)/4;
        timeSegmentUnit=@"years";
    }
    NSString* plusSign=@"";
    if (tmp - timeSegment >0.3)
        plusSign=@"+";
    labelSeg1.text = [NSString stringWithFormat:@"%i%@ %@",timeSegment,plusSign,timeSegmentUnit];
    labelSeg2.text = [NSString stringWithFormat:@"%i%@ %@",timeSegment,plusSign,timeSegmentUnit];
    labelSeg3.text = [NSString stringWithFormat:@"%i%@ %@",timeSegment,plusSign,timeSegmentUnit];
    labelSeg4.text = [NSString stringWithFormat:@"%i%@ %@",timeSegment,plusSign,timeSegmentUnit];
    
    if (calendar == nil)
        calendar = [NSCalendar currentCalendar];
    
    NSString* yearPart;
    if (timeSpanInDay <= 30)
    {
        label1.hidden = true;
        label2.hidden = true;
        label3.hidden = true;
        label4.hidden = true;
        label5.hidden = true;
        return;
    }
    else
    {
        label1.hidden = false;
        label2.hidden = false;
        label3.hidden = false;
        label4.hidden = false;
        label5.hidden = false;
    }
    NSDate* tmpDate = startDay;

    NSDateComponents *dateComponent = [[NSDateComponents alloc] init];
    if (timeSpanInDay > 30 && timeSpanInDay <=365) //show Label as 01/02/2013
    {
        label1.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInLetter:tmpDate]];
                       
        dateComponent.day = timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label2.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInLetter:tmpDate]];
        
        dateComponent.day = timeSpanInDay/2;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label3.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInLetter:tmpDate]];
        
        dateComponent.day = 3*timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label4.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInLetter:tmpDate]];
        dateComponent.day = timeSpanInDay;
        
        tmpDate = endDay;
        label5.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInLetter:tmpDate]];;
        [self fitSzie:label1];
        [self fitSzie:label2];
        [self fitSzie:label3];
        [self fitSzie:label4];
        [self fitSzie:label5];
        
    }
    else if (timeSpanInDay > 365 && timeSpanInDay < 5 * 365) //show label as Mar 2013
    {
        
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label1.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        
        dateComponent.day = timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label2.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        
        dateComponent.day = timeSpanInDay/2;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label3.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        
        dateComponent.day = 3*timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label4.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        
        tmpDate = endDay;
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label5.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        [self fitSzie:label1];
        [self fitSzie:label2];
        [self fitSzie:label3];
        [self fitSzie:label4];
        [self fitSzie:label5];
    }
    else //> 5 year, always show label as year such as 2003 AD
    {
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
        [self fitSzie:label1];
        [self fitSzie:label2];
        [self fitSzie:label3];
        [self fitSzie:label4];
        [self fitSzie:label5];
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
        dateComponent.day = -5;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.day = 5;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
    }
    else if (periodIndays == 365)
    {
        dateComponent.month = -5;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.month = 5;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
    }
    else if (periodIndays == 3650)
    {
        dateComponent.year = -5;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 5;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
    }
    else if (periodIndays == 36500)
    {
        dateComponent.year = -50;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 50;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
    }
    else if (periodIndays == 365000)
    {
        dateComponent.year = -500;
        scaleStartDay = [ATHelper dateByAddingComponentsRegardingEra:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 500;
        scaleEndDay = [ATHelper dateByAddingComponentsRegardingEra:dateComponent toDate:focusedDate options:0];
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
    if (scaleLengthInPix <40)
    {
        self.scaleLenForDisplay = 40;
        scaleStartAdj = -5; //need compute?
    }
    timeScaleImageView.frame = CGRectMake(scaleStartInPix + scaleStartAdj, 10, self.scaleLenForDisplay, MOVABLE_VIEW_HEIGHT);
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
    //labelScaleText.center = timeScaleImageView.center;
    //[labelScaleText setFrame:CGRectMake(
                                   // floorf((timeScaleImageView.frame.size.width - labelScaleText.frame.size.width) / 2.0), 0,
                                   // labelScaleText.frame.size.width, labelScaleText.frame.size.height)];
    
}


@end
