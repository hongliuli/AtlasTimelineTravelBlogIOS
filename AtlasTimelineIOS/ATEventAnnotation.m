//
//  ATEventAnnotation.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/5/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATEventAnnotation.h"
#import "ATAppDelegate.h"
#import "ATHelper.h"

@implementation ATEventAnnotation

@synthesize coordinate;
@synthesize eventDate;
@synthesize description;
@synthesize address;
@synthesize eventType;

- (id)initWithLocation:(CLLocationCoordinate2D)coord {
    self = [super init];
    if (self){
        coordinate = coord;
    }
    return self;
}

// annotation view need title/subtitle to show callout
- (NSString *)subtitle
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter *dateFormater = appDelegate.dateFormater;
    NSString * dateStr = [dateFormater stringFromDate:self.eventDate];
    NSUInteger removeBC_ADPos = [dateStr rangeOfString:@" "].location;
    dateStr = [dateStr substringToIndex:removeBC_ADPos];
    NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    if ([targetName hasPrefix:@"WorldHeritage"])
        dateStr = [ATHelper getYearPartHelper:self.eventDate];
    
    dateStr = [NSString stringWithFormat:@"[%@] ",dateStr];
    return[NSString stringWithFormat:@"%@%@",dateStr , NSLocalizedString(self.address,nil)]; //add for WorldHeritage culture/natural
}

- (NSString *)title
{
    return [ATHelper clearMakerAllFromDescText: self.description];
}



// required if you set the MKPinAnnotationView's "canShowCallout" property to YES


@end