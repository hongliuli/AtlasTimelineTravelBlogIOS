//
//  ATPhotoScrollViewControlerViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 12/3/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATEventEditorTableController;

@interface ATPhotoScrollViewControler : UIViewController<UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) NSMutableArray* photoList;

@property (weak, nonatomic) ATEventEditorTableController* eventEditor;
@property int currentIndex;

- (void) showCount;

@end
