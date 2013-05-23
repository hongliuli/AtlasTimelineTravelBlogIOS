//
//  ATimelineTableViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 12/29/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "SectionHeaderView.h"

@class ATCell;

@interface ATimelineTableViewController : UITableViewController < SectionHeaderViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSArray* periods; //old plays
@property (nonatomic, weak) IBOutlet ATCell *atCell; //old quoteCell

@end

