//
//  ATEventListViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 6/1/14.
//  Copyright (c) 2014 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATViewController.h"

@interface ATEventListWindowView: UIView <UITableViewDelegate, UITableViewDataSource,UIScrollViewDelegate>
@property (nonatomic, retain) UITableView *tableView;
- (void) refresh:(NSMutableArray*)eventList :(BOOL)eventListViewInMapModeFlag;
@end
