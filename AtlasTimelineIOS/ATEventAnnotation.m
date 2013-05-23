//
//  ATEventAnnotation.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/5/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATEventAnnotation.h"
#import "ATAppDelegate.h"

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
    NSString *dateStr = [NSString stringWithFormat:@"[%@] ",
                         [dateFormater stringFromDate:self.eventDate]];
    return[NSString stringWithFormat:@"%@%@", dateStr, self.address];
}

- (NSString *)title
{
    return self.description;
}



// required if you set the MKPinAnnotationView's "canShowCallout" property to YES


@end