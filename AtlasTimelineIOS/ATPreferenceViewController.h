//
//  ATPreferenceViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATSourceChooseViewController.h"

@interface ATPreferenceViewController : UITableViewController <SourceChooseViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

-(void) changeSelectedSource:(NSString*)selectedAtlasName;
@end
