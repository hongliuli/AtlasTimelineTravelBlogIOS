//
//  ATTutorialView.m
//  AtlasTimelineIOS
//
//  Created by Hong on 4/23/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATTutorialView.h"
#import "ATConstants.h"

@implementation ATTutorialView

int initialX;
int initialY = 100;
int itemWidth = 500;
int itemHeight = 80;


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

UILabel* timeWindowLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        // add subview etc here
    }
    return self;
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
    
    
    [self addLongPressSection];
    
    [self addSwipeTimeWindowSection];
    
    [self addTimeZoomLevelSection1];
    [self addTimeZoomLevelSection2];
    [self addDoubleTapCenterSection:x_start + [ATConstants timeScrollWindowWidth]/3]; //this first so red shade go under pinch
    [self addTimeZoomLevelSection:x_start - 50 :@"TimewheelZoomOut.png" :@"Tap to zoom out Time Wheel"];
    [self addTimeZoomLevelSection:x_start + [ATConstants timeScrollWindowWidth]/3-85 :@"gesture-pinch.png" :@"Pinch is another way of zooming Time Wheel"];
    [self addTimeZoomLevelSection:x_start + 2*[ATConstants timeScrollWindowWidth]/3   + 50:@"TimewheelZoomIn.png" :@"Tap to zoom in Time Wheel"];
}

- (void) addLongPressSection
{
    CGRect frm = CGRectMake(initialX, initialY, itemWidth * iphoneSizeSpecialFactor, itemHeight);
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
    lblLongPress.text = @"Long-press on a map location to record an event.";
    lblLongPress.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lblLongPress.backgroundColor = [UIColor clearColor];
    lblLongPress.textColor = [UIColor whiteColor];
    lblLongPress.lineBreakMode = NSLineBreakByWordWrapping;
    lblLongPress.numberOfLines=2;
    [self addSubview:lblLongPress];
}

- (void) addSwipeTimeWindowSection
{
    int startY = initialY + itemHeight +50*iPhoneSizeYFactor;
    CGRect frm = CGRectMake(initialX, startY, itemWidth * iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:frm];
    lbl.text = @"Browse the time wheel: ";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [self addSubview:lbl];
    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(frm.origin.x + 270*iPhoneSizeXFactor, frm.origin.y, imageSize, imageSize) ];
    [imgView setImage:[UIImage imageNamed:@"gesture-swipe.png"]]; //swipe image
    [self addSubview:imgView];
    
    UILabel* lblLongPress = [[UILabel alloc] initWithFrame:CGRectMake(frm.origin.x + 350*iPhoneSizeXFactor, frm.origin.y, 320*iPhoneSizeXFactor, 90*iPhoneSizeYFactor)];
    lblLongPress.text = @"Swipe on time wheel to change visible period in which events are visible by color ";
    lblLongPress.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lblLongPress.backgroundColor = [UIColor clearColor];
    lblLongPress.textColor = [UIColor whiteColor];
    lblLongPress.lineBreakMode = NSLineBreakByWordWrapping;
    lblLongPress.numberOfLines=2;
    [self addSubview:lblLongPress];
    
    int startY2 = startY + itemHeight;
    CGRect frameLbl2 = CGRectMake(initialX , startY2 - 30*iPhoneSizeYFactor, 400*iPhoneSizeXFactor, itemHeight);
    UILabel* lbl2 = [[UILabel alloc] initWithFrame:frameLbl2];
    lbl2.text = @"The event is colored if its date is visible in the time wheel, the darker the color is the closer is to the selected date in the center: ";
    lbl2.lineBreakMode = NSLineBreakByWordWrapping;
    lbl2.numberOfLines=3;
    lbl2.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl2.backgroundColor = [UIColor clearColor];
    lbl2.textColor = [UIColor lightGrayColor];
    [self addSubview:lbl2];
    
    CGRect frameColorImage = CGRectMake(initialX + 400*iPhoneSizeXFactor, startY2, imageAnn, imageAnn);
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

- (void) addTimeZoomLevelSection1
{
    CGRect lblFrame = CGRectMake(initialX, initialY + 3 * itemHeight + 50*iPhoneSizeYFactor, itemWidth*iphoneSizeSpecialFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, initialY + 3 * itemHeight, itemWidth * iphoneSizeSpecialFactor, itemHeight)];

    lbl.text = @"Zoom the time wheel:";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontBig];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [lbl setFrame:lblFrame];
    [self addSubview:lbl];

}
- (void) addTimeZoomLevelSection2 //level wordings
{
    CGRect lblFrame = CGRectMake(initialX+270*iPhoneSizeXFactor, initialY + 3 * itemHeight + 52*iPhoneSizeYFactor, itemWidth, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(1000*iPhoneSizeXFactor, initialY + 3 * itemHeight + 2, 0, 0)];

    lbl.text = @"1) Change the time wheel spin scale to day / month / year / 10 yrs / 100 yrs ";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall-2];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    [lbl setFrame:lblFrame];
    [self addSubview:lbl];
    
    lblFrame = CGRectMake(initialX+270*iPhoneSizeXFactor, initialY + 3 * itemHeight + 52*iPhoneSizeYFactor + 20, itemWidth, itemHeight);
    UILabel* lbl2 = [[UILabel alloc] initWithFrame:CGRectMake(1000*iPhoneSizeXFactor, initialY + 3 * itemHeight + 2, 0, 0)];
    
    lbl2.text = @"2) Thus the wheel's span is changed to week / month / 1yr / 10yrs / 100yrs/ 1000yrs accordingly";
    lbl2.font = [UIFont fontWithName:@"Arial" size:fontSmall-2];
    lbl2.backgroundColor = [UIColor clearColor];
    lbl2.textColor = [UIColor whiteColor];
    [lbl2 setFrame:lblFrame];
    [self addSubview:lbl2];

}

- (void) addTimeZoomLevelSection:(int)xStart :(NSString*)gestureImageName :(NSString*)text
{
    int scrollWindowWidth = [ATConstants timeScrollWindowWidth];
    int scrollWindowHeight = [ATConstants timeScrollWindowHeight];
    
    int lineX = xStart + scrollWindowWidth/3 - 150*iPhoneSizeXFactor;
    int lineY = initialY + 5 * itemHeight + 30*iPhoneSizeYFactor;
    
    //Upper Label description
    CGRect lblFrame = CGRectMake(lineX - 50*iPhoneSizeXFactor, lineY - 60*iPhoneSizeYFactor, 135*iPhoneSizeXFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:lblFrame];
    lbl.text = text;
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=2;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    if ([lbl.text rangeOfString:@"Pinch"].location != NSNotFound)
        lbl.textColor = [UIColor grayColor];
    [self addSubview:lbl];
    
    //draw line
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    //Draw lines around time window

    CGContextMoveToPoint(context, lineX, lineY);
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
    int lineY = initialY + 5 * itemHeight + 70*iPhoneSizeYFactor;
    
    //Upper Label description
    CGRect lblFrame = CGRectMake(lineX - 50*iPhoneSizeXFactor, lineY - 60*iPhoneSizeYFactor, 140*iPhoneSizeXFactor, itemHeight);
    UILabel* lbl = [[UILabel alloc] initWithFrame:lblFrame];
    lbl.text = @"Double-tap at center to center on today";
    lbl.font = [UIFont fontWithName:@"Arial" size:fontSmall - 2];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines=2;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor redColor];
    [self addSubview:lbl];
    
    //Time Window Label description
    CGRect timeWindowFrame = CGRectMake(initialX, y_start - 60, itemWidth + 100, itemHeight);
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
    
    CGContextMoveToPoint(context, lineX, lineY);
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
