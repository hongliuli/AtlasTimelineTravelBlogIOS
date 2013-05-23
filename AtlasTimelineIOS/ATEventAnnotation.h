//
//  ATEventAnnotation.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/5/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface ATEventAnnotation : NSObject <MKAnnotation> {
    CLLocationCoordinate2D coordinate;
    UIImage *image;
}
@property (nonatomic, retain) UIImage *image;
@property CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) NSDate *eventDate;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *uniqueId; //for link back to db entity
@property int eventType;

- (id) initWithLocation:(CLLocationCoordinate2D) coord;

@end



