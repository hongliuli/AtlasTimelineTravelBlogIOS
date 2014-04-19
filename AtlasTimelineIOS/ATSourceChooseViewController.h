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
    - (void)sourceChooseViewController:(ATSourceChooseViewController *)controller didSelectEpisode:(NSString *)episodeName;
@end


@interface ATSourceChooseViewController : UITableViewController <UIAlertViewDelegate>
    @property (nonatomic, weak) id <SourceChooseViewControllerDelegate> delegate;
    @property (nonatomic, strong) NSString *source;
@end
