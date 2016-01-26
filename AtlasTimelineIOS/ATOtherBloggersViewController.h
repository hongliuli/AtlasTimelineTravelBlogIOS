//
//  ATOtherBloggersViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/15.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATOtherBloggersViewController;
@protocol POIChooseViewControllerDelegate <NSObject>
- (void)poiGroupChooseViewController:(ATOtherBloggersViewController *)controller didSelectPoiGroup:(NSArray *)poiList;
@end


@interface ATOtherBloggersViewController : UITableViewController <UIAlertViewDelegate>
@property (nonatomic, weak) id <POIChooseViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *poiSource;
@end