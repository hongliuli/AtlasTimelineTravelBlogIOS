//
//  ATDownloadTableViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 2/17/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@class ATPreferenceViewController;

@interface ATDownloadTableViewController : UITableViewController<SWTableViewCellDelegate>

@property (nonatomic, strong) ATPreferenceViewController* parent;

@end
