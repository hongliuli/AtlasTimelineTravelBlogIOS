//
//  ATTimeScrollWindow.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/30/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATTimeScrollWindow.h"
#import "ATAppDelegate.h"
#import "ATViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"

@implementation ATTimeScrollWindow
{
    float lastScale;
    NSMutableArray* dateStrList;
    NSMutableArray* dateStrYearList;
    NSMutableArray* yearLabelList;
    NSMutableArray* dateLabelList;
    NSTimer* panTimer;
    int tmpSlowPanDateLabelDraw; //do not calculate every move when in slow pan
    int panTimerCount;
    int panTimerLoopCount; //stop scrolling after this number of loop. Each loop will increase the timer interval to slowdown
    int panTimerLoopLimit; //the large velocity, the large loop limit
    int moveAnimationFactor;
    float pinchVelocity; //minus is pinch in
    float panTimerDirection; // get value from panTranslationX, but kept for faster pan. <<0 is move left, >>0 is move right. then use magnitude or slidemutl to decide how fast move
    int panTranslationX; //0 not pan (set in pan end state). < 0 slow pan left, >0 slow pan right. this is make slow pan move smothly
    int timeScrollNumOfDateLabels;
    NSCalendar* calendar;
    int yearElapsedFromToday; //used to stop scrolling if date is 1000 years later, or if date is less than 9000 BC
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self addGestureRecognizer:pinch];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        // stop timer.
        UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongGesture:)];
        lpgr.minimumPressDuration = 0.2;  //user must press for 0.5 seconds
        [self addGestureRecognizer:lpgr];

        self.pinchFlag = 1;
        dateStrList = [[NSMutableArray alloc] init];
        dateStrYearList = [[NSMutableArray alloc] init];
        yearLabelList = [[NSMutableArray alloc] init];
        dateLabelList = [[NSMutableArray alloc] init];
        timeScrollNumOfDateLabels = [ATConstants timeScrollNumOfDateLabels];
        for(int i=0; i<timeScrollNumOfDateLabels; i++)
        {
            UILabel* yearLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,0)];
            UILabel* dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,0)];
            [yearLabel setBackgroundColor:[UIColor clearColor]];
            [dateLabel setBackgroundColor:[UIColor clearColor]];
            [yearLabelList addObject:yearLabel];
            [dateLabelList addObject:dateLabel];
            [self addSubview:yearLabel];
            [self addSubview:dateLabel];
        }

        yearElapsedFromToday = 0;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    // Draw the base.
    CGContextSetLineWidth(context, 2.0);
    CGContextMoveToPoint(context, self.startX,self.endY); //start at this point
    CGContextAddLineToPoint(context, self.endX, self.endY); //draw to this point
    
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    float periodInDays = appDelegate.selectedPeriodInDays;
    
    
    int numberSmallBar = 10;
    if (periodInDays > 30 && periodInDays <=365)
        numberSmallBar = 20;
    if (periodInDays > 365 && periodInDays <=3650)
        numberSmallBar = 40;
    if (periodInDays >3650 && periodInDays <= 36500)
        numberSmallBar = 60;
    if (periodInDays > 36500)
        numberSmallBar = 100;
    int stepLength = [ATConstants timeScrollWindowWidth]/numberSmallBar;
    CGContextSetLineWidth(context, 1.0);
    moveAnimationFactor = moveAnimationFactor % 2;
    //#######Draw small bars
    for (int i = -5; i<numberSmallBar + 5; i++)
    {
        if (panTranslationX == 0)
        {
            CGContextMoveToPoint(context, i*stepLength - self.pinchFlag*stepLength*moveAnimationFactor/2,self.endY); //start at this point
            CGContextAddLineToPoint(context, i*stepLength - self.pinchFlag*stepLength*moveAnimationFactor/2, self.endY*0.7); //draw to this point
        }
        else
        {
            CGContextMoveToPoint(context, i*stepLength + panTranslationX,self.endY); //start at this point
            CGContextAddLineToPoint(context, i*stepLength + panTranslationX, self.endY*0.7); //draw to this point
        }
        
    }
    moveAnimationFactor++;
    
    // and now draw the Path!
    CGContextStrokePath(context);
    
    int bigFontSize = [ATConstants timeScrollBigDateFont];

    UIFont* reggularYearFont = [UIFont fontWithName:@"Helvetica-Bold" size:bigFontSize];
    UIFont* fontForDatePart = [UIFont fontWithName:@"Helvetica" size:13];
    UIColor* colorForDatePart;
    UIFont* fontForYear;
    UIColor* colorForYear;
    [self dateStrMake: 1];
    float frameWidth = [ATConstants timeScrollWindowWidth];
    //Following is draw Year/Date lables. I used NSAttributedString which make the job much easier, but it only works in iOS6, so I changed to instance UILabel for each of them
    UILabel * currentLable;//=[[NSAttributedString alloc] initWithString:@"" attributes: attributes];
    //######### draw date lables
    for (int i = 0; i<timeScrollNumOfDateLabels; i++)
    {

        //UIColor* color = [UIColor colorWithRed:0x99/255.0 green:0x33/255 blue:0x33/255.0 alpha:0.1];//(1 - abs(4 - i))/4];
        UIColor* color = [UIColor colorWithRed:1.0 green:0x88/255 blue:0x88/255.0 alpha:fabsf(1.0 - fabs(4 - i)/4)+ 0.2];
        UIColor* greenColor = [UIColor colorWithRed:0x88/255 green:1.0 blue:0x88/255.0 alpha:fabsf(1.0 - fabs(4 - i)/4)+ 0.2];
        if (i == 4)
        {
            fontForYear = [UIFont fontWithName:@"Helvetica-Bold" size:bigFontSize];
            colorForYear = [self darkerColorForColor:color];
        }
        else
        {
            fontForYear = reggularYearFont;
            colorForYear = color;
        }
        if (i > 4)
            colorForDatePart = [self darkerColorForColor:greenColor];
        else
            colorForDatePart = color;

        //instance and draw year part at upper
        currentLable = yearLabelList[i];
        [currentLable setFrame: CGRectMake((i+1)*frameWidth/timeScrollNumOfDateLabels - 61, 2,0,0)];
        currentLable.text = dateStrYearList[i];
        [currentLable sizeToFit];
        [currentLable setFont:fontForYear];
        [currentLable setTextColor:colorForYear];

        //instance and draw date part at lower
        currentLable = dateLabelList[i];
        [currentLable setFrame:CGRectMake((i+1)*frameWidth/timeScrollNumOfDateLabels - 63, 15,0,0)];
        currentLable.text = dateStrList[i];
        [currentLable sizeToFit];
        [currentLable setFont:fontForDatePart];
        [currentLable setTextColor:colorForDatePart];


    }
    int outX = 13;
    int innerX=7;
    int outY=16;
    int innerY=10;
    int shiftX = 0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        outX = 8;
        innerX = 4;
        outY = 10;
        innerY = 6;
        shiftX = -11;
    }
    
    //draw a small triangle indicator
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint   (ctx, CGRectGetMaxX(rect)/2 - outX + shiftX, CGRectGetMaxY(rect));  // top left
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)/2 + shiftX, CGRectGetMaxY(rect) - outY);  // bottom left
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)/2 + outX + shiftX, CGRectGetMaxY(rect));  // mid right
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)/2 - outX + shiftX, CGRectGetMaxY(rect));  // bottom left
    CGContextClosePath(ctx);
    CGContextSetRGBFillColor(ctx, 1, 0.1, 0.1, 1);
    CGContextFillPath(ctx);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint   (ctx, CGRectGetMaxX(rect)/2 - innerX + shiftX, CGRectGetMaxY(rect));  // top left
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)/2 + shiftX, CGRectGetMaxY(rect) -innerY);  // bottom left
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)/2 + innerX + shiftX, CGRectGetMaxY(rect));  // mid right
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)/2 - innerX + shiftX, CGRectGetMaxY(rect));  // bottom left
    CGContextClosePath(ctx);
    CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
    
    CGContextFillPath(ctx);
}
- (UIColor *)darkerColorForColor:(UIColor *)c
{
    float r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2, 0.0)
                               green:MAX(g - 0.2, 0.0)
                                blue:MAX(b - 0.2, 0.0)
                               alpha:a];
    return nil;
}

//move time in window
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        moveAnimationFactor = 0;
        panTimerDirection = 0;
        tmpSlowPanDateLabelDraw = 0;
        if (panTimer != nil)
            [panTimer invalidate];
        panTimerCount = 0;
        panTimerLoopCount = 0;
        //NSLog(@"--------  pan gesture Begin %f   %f", recognizer.view.center.x, recognizer.view.center.y);
    }
    CGPoint translation = [recognizer translationInView:self];

    panTranslationX = translation.x;
    [self setNeedsDisplay]; //when slow pan, before pan end, only move small bars, no date change
    /*
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y)
     */;
    //[recognizer setTranslation:CGPointMake(0, 0) inView:self];

    //NSLog(@"  pan gesture %f  %f",translation.x, translation.y);
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self redrawTimeScrollWindow:0]; //for slowpan, only advance one date unit per pan action
        panTimerDirection = panTranslationX;
        panTranslationX = 0;
        //NSLog(@"  -- pan gesture end %f   %f", recognizer.view.center.x, recognizer.view.center.y);
        CGPoint velocity = [recognizer velocityInView:self];
        
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));

        //NSLog(@"magnitude: %f, slideMult: %f, panTimerDirection=%f", magnitude, slideMult, panTimerDirection);
        
        if (magnitude >2700 && magnitude < 3700)
        {
            panTimerLoopLimit = 2;
            panTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(panTimer:) userInfo:nil repeats:YES];
        }
        else if (magnitude >=3700 && magnitude < 4500)
        {
            panTimerLoopLimit =4;
            panTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(panTimer:) userInfo:nil repeats:YES];
        }
        else if (magnitude >=4500 )
        {
            panTimerLoopLimit = 6;
            panTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(panTimer:) userInfo:nil repeats:YES];
        }
        else
            [self.parent refreshAnnotations]; //refresh map for slow pan action
    }
}
-(void) panTimer: (NSTimer*) theTimer
{
    panTimerCount++;
    //NSLog(@"handle Pan Timer %i",panTimerCount);
    [self redrawTimeScrollWindow:0];
    if (panTimerCount >10)
    {
        panTimerCount = 0;
        [theTimer invalidate];
        panTimerLoopCount ++;
        if (panTimerLoopCount >= panTimerLoopLimit)
        {
            [self refreshMapview];
            return;
        }
        else //restart timer with slower speed (larger interval)
        {
            float oldInterval = panTimer.timeInterval;
            panTimer = nil;
            panTimer = [NSTimer scheduledTimerWithTimeInterval:oldInterval*1.4 target:self selector:@selector(panTimer:) userInfo:nil repeats:YES];
        }
    }
}


//zoom time, should interactive with timeScale slider in some way
- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {

   // recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
   // recognizer.scale = 1;
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        pinchVelocity = 0;
        //lastScale = [recognizer scale];
        NSLog(@"  pinch gesture Begin, lastScale=%f", lastScale);
    }
    if ([recognizer state] == UIGestureRecognizerStateBegan ||
        [recognizer state] == UIGestureRecognizerStateChanged) {
        //float newScale = [recognizer scale];
        pinchVelocity = pinchVelocity + recognizer.velocity;
        //NSLog(@"     newScale %f  velocity %f",newScale, recognizer.velocity); //velocity < 0 is pinch in
    }
    if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        int periodInDays = appDelegate.selectedPeriodInDays;
        NSLog(@"------ Pinch end velocity=%f, periodInDay=%i", pinchVelocity, periodInDays);
        int paretnSliderValue = 0;
        switch(periodInDays)
        {
            case 7:
                if (pinchVelocity <0)
                    appDelegate.selectedPeriodInDays = 30;
                paretnSliderValue = 1;
                break;
            case 30:
                if (pinchVelocity < 0)
                {
                    appDelegate.selectedPeriodInDays = 365;
                    paretnSliderValue = 2;
                }
                else if (pinchVelocity > 0)
                {
                    appDelegate.selectedPeriodInDays = 7;
                    paretnSliderValue = 0;
                }
                break;
            case 365:
                if (pinchVelocity < 0)
                {
                    appDelegate.selectedPeriodInDays = 3650;
                    paretnSliderValue = 3;
                }
                else if (pinchVelocity > 0)
                {
                    appDelegate.selectedPeriodInDays = 30;
                    paretnSliderValue = 1;
                }
                break;
            case 3650:
                if (pinchVelocity < 0)
                {
                    appDelegate.selectedPeriodInDays = 36500;
                    paretnSliderValue = 4;
                }
                else if (pinchVelocity > 0)
                {
                    appDelegate.selectedPeriodInDays = 365;
                    paretnSliderValue = 2;
                }
                break;
            case 36500:
                if (pinchVelocity < 0)
                {
                    appDelegate.selectedPeriodInDays = 365000;
                    paretnSliderValue = 5;
                }
                else if (pinchVelocity > 0)
                {
                    appDelegate.selectedPeriodInDays = 3650;
                    paretnSliderValue = 3;
                }
                break;
            case 365000:
                if (pinchVelocity > 0)
                {
                    appDelegate.selectedPeriodInDays = 36500;
                    paretnSliderValue = 4;
                }
                break;
        }
        self.pinchFlag = 0;
        [self redrawTimeScrollWindow:1];
//        [self.parent.scaleSlider setValue:paretnSliderValue];
        [self.parent setSelectedPeriodLabel];
        [self.parent refreshAnnotations];
        //[self.parent.scaleSlider setNeedsDisplay];//TODO still does not work
    }

    
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer{
    NSLog(@"---- Tapped");
    if (panTimer != nil)
    {
        [panTimer invalidate];
        [self refreshMapview];
    }
}
- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)recognizer{
    NSLog(@"----  double Tapped");
    if (panTimer != nil)
    {
        [panTimer invalidate];
    }
    NSDate* today = [[NSDate alloc] init];
    NSLog(@"  today is %@", today);
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.focusedDate = today;
    [self redrawTimeScrollWindow:1]; //pass 1 as zoomingFlag here because we already has focused date
    [self refreshMapview];
}

- (IBAction)handleLongGesture:(UITapGestureRecognizer *)recognizer{
    if (recognizer.state != UIGestureRecognizerStateBegan)   // UIGestureRecognizerStateEnded)
        return;
    NSLog(@"---- Long pressed");
    if (panTimer != nil)
    {
        [panTimer invalidate];
        [self refreshMapview];
    }
}

- (void) redrawTimeScrollWindow:(int)zoomingAction
{
    [self dateStrMake:zoomingAction];
    [self displayTimeElapseinSearchBar];
    [self setNeedsDisplay];
    self.pinchFlag = 1; //alwys reset to 1, only pinch gesture will set it to zero
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

- (void) dateStrMake:(int)zoomingAction
{
    int periodType; //0-day, 1 month, 2 year, 3 10y , 4 100y

    if (calendar == nil)
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    //Have to put periodToxxx datecomponent locally, otherwise date add is weired
    NSDateComponents *periodToAdd = [[NSDateComponents alloc] init];
    NSDateComponents *periodToMinus = [[NSDateComponents alloc] init];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int specialFactor = 1;
    NSDate* focusedDate = appDelegate.focusedDate;
    NSDateFormatter *dateFormater = appDelegate.dateFormater;
    int periodInDays = appDelegate.selectedPeriodInDays;
    switch(periodInDays){
        case 7:
            [periodToAdd setDay:1];
            [periodToMinus setDay:-1];
            periodType = 0;
            break;
        case 30:
            [periodToAdd setDay:1];
            [periodToMinus setDay:-1];
            specialFactor = 3; //inorder to fit whole month into the scrollwindow
            periodType = 0;
            break;
        case 365:
            [periodToAdd setMonth:1];
            [periodToMinus setMonth:-1];
            periodType = 1;
            break;
        case 3650:
            [periodToAdd setYear:1];
            [periodToMinus setYear:-1];
            periodType = 2;
            break;
        case 36500:
            [periodToAdd setYear:10];
            [periodToMinus setYear:-10];
            periodType = 3;
            break;
        case 365000:
            [periodToAdd setYear:100];
            [periodToMinus setYear:-100];
            periodType = 4;
            break;
    }
    if (zoomingAction != 1) //do not do following for timeline zooming. because zooming do not need change focusedDate
    {
        if (panTranslationX != 0)  //for slowpan
        {
            tmpSlowPanDateLabelDraw++;
            {
                if (panTranslationX < 0 )
                {
                    if (yearElapsedFromToday > 1000)
                        return; //do not shift date if date is already very large
                    appDelegate.focusedDate = [self dateByAddingComponentsRegardingEra:periodToAdd toDate:appDelegate.focusedDate options:0];
                }
                else if (panTranslationX >0)
                {
                    if (yearElapsedFromToday < -5520) //hard coded for 3510 BC. eventEditor does not accept date before 3510 BC
                        return;
                    appDelegate.focusedDate = [self dateByAddingComponentsRegardingEra:periodToMinus toDate:appDelegate.focusedDate options:0];
                }
            }
        }
        else //faster pan by timer
        {
            if (panTimerDirection < 0 )
            {
                if (yearElapsedFromToday > 1000)
                {
                    //NSLog((@"   very large date "));
                    if (panTimer != nil)
                        [panTimer invalidate];
                    return; //do not shift date if date is already very large
                }
                appDelegate.focusedDate = [self dateByAddingComponentsRegardingEra:periodToAdd toDate:appDelegate.focusedDate options:0];
            }
            else if (panTimerDirection >0)
            {
                if (yearElapsedFromToday < -5520)
                {
                    if (panTimer != nil)
                        [panTimer invalidate];
                    return; //do not shift date if date is already is smaller than 9000 BC
                }
                appDelegate.focusedDate = [self dateByAddingComponentsRegardingEra:periodToMinus toDate:appDelegate.focusedDate options:0];
            }
        }
    }
    [dateStrList removeAllObjects];
    [dateStrYearList removeAllObjects];
    //Start generate date labels to be displayed


    //Following has my way of AD/BC calculation. For adding over year, have to use minus
    for (int i = 0; i<timeScrollNumOfDateLabels; i++)
    {
        NSString* periodLable;
        switch(periodType)
        {
            case 0:
                [periodToAdd setDay:(i-4)*specialFactor];
                [periodToMinus setDay:(i-4)*specialFactor]; //use for BC/AD case
                if (i-4 < 0)
                    periodLable = [NSString stringWithFormat:@"-%i d",abs(specialFactor*(i-4))];
                else
                    periodLable = [NSString stringWithFormat:@"+%i d",specialFactor*(i-4)];
                break;
            case 1:
                [periodToAdd setMonth:(i -4)];
                [periodToMinus setDay:(i-4)];
                if (i-4 < 0)
                    periodLable = [NSString stringWithFormat:@"-%i m",abs(i-4)];
                else
                    periodLable = [NSString stringWithFormat:@"+%i m",i-4];
                break;
            case 2:
                [periodToAdd setYear:i -4];
                [periodToMinus setYear:-i +4];
                if (i-4 < 0)
                    periodLable = [NSString stringWithFormat:@"-%i yr",abs(i-4)];
                else
                    periodLable = [NSString stringWithFormat:@"+%i yr",i-4];
                break;
            case 3:
                [periodToAdd setYear:10*(i -4)];
                [periodToMinus setYear:10*(-i +4)];
                if (i-4 < 0)
                    periodLable = [NSString stringWithFormat:@"-%i yr",abs(10*(i-4))];
                else
                    periodLable = [NSString stringWithFormat:@"+%i yr",10*(i-4)];
                break;
            case 4:
                [periodToAdd setYear:100*(i -4)];
                [periodToMinus setYear:100*(-i +4)];
                if (i-4 < 0)
                    periodLable = [NSString stringWithFormat:@"-%i yr",abs(100*(i-4))];
                else
                    periodLable = [NSString stringWithFormat:@"+%i yr",100*(i-4)];
                break;
        }
        NSDate* newDate = nil;
        newDate = [self dateByAddingComponentsRegardingEra:periodToAdd toDate:focusedDate options:0];
        
       // NSLog(@"    ---- focusedDate=%@   newDate=%@",[dateFormater stringFromDate:focusedDate],[dateFormater stringFromDate:newDate]);
        NSString* yearPart;
        yearPart = [ATHelper getYearPartSmart :newDate];
        NSString* dateString = [NSString stringWithFormat:@" %@", [dateFormater stringFromDate:newDate]];
        if (i !=4)
            dateString = periodLable;
        else
            dateString =[dateString substringWithRange:NSMakeRange(0, 6)];

        [dateStrList addObject:dateString];
        [dateStrYearList addObject:yearPart];
    }
  }
- (void) refreshMapview
{
    [self.parent refreshAnnotations];
}

//This function is from Googling, it is a magic function to scroll NSDate across BC/AD, saved me a very difficult issue, so now I can show BC/AD
- (NSDate *)dateByAddingComponentsRegardingEra:(NSDateComponents *)comps toDate:(NSDate *)date options:(NSUInteger)opts
{ 
    NSDateComponents *toDateComps = [calendar components:NSEraCalendarUnit fromDate:date];
    NSDateComponents *compsCopy = [comps copy];
    if ([toDateComps era] == 0) //B.C. era
    {
        if ([comps year] != NSUndefinedDateComponent) [compsCopy setYear:-[comps year]];
    }
    
    return [calendar dateByAddingComponents:compsCopy toDate:date options:opts];
}

@end
