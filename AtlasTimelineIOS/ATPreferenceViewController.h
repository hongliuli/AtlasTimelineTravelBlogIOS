//
//  ATPreferenceViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface ATPreferenceViewController : UITableViewController <DBRestClientDelegate>
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) ATViewController* mapViewParent;
@property (nonatomic, strong) DBRestClient *_restClient;

@end
