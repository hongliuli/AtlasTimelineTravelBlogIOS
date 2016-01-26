//
//  ATPreferenceViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATSourceChooseViewController.h"
#import "ATDownloadTableViewController.h"
#import "ATViewController.h"

@interface ATPreferenceViewController : UITableViewController <SourceChooseViewControllerDelegate,DownloadTableViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) ATViewController* mapViewParent;

- (void) changeSelectedSource:(NSString*)selectedAtlasName;
- (void) refreshDisplayStatusAndData;


@end
