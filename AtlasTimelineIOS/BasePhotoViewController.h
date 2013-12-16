//
//  BasePhotoViewController.h
//  PhotoScroller
//
//  Created by Stephanie Sharp on 19/06/13.
//

#import <UIKit/UIKit.h>
@class ATEventEditorTableController;

@interface BasePhotoViewController : UIViewController <UIPageViewControllerDataSource>

@property (nonatomic, strong) UIPageViewController * pageViewController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) NSMutableArray* photoList;

@property (weak, nonatomic) ATEventEditorTableController* eventEditor;
@property int initialPhotoIdx;

@end
