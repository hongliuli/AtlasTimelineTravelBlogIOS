//
//  ATPeriodChooseViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATSourceChooseViewController;
@protocol SourceChooseViewControllerDelegate <NSObject>
    - (void)sourceChooseViewController:(ATSourceChooseViewController *)controller didSelectSource:(NSString *)source;
@end


@interface ATSourceChooseViewController : UITableViewController
    @property (nonatomic, weak) id <SourceChooseViewControllerDelegate> delegate;
    @property (nonatomic, strong) NSString *source;
@end
