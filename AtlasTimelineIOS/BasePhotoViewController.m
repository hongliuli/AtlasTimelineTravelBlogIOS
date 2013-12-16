//
//  BasePhotoViewController.m
//  PhotoScroller
//
//  Created by Stephanie Sharp on 19/06/13.
//

#import "BasePhotoViewController.h"
#import "PhotoViewController.h"
#import "ATEventEditorTableController.h"

#define NOT_THUMBNAIL -1;

@implementation BasePhotoViewController

@synthesize pageViewController;

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        PhotoViewController *pageZero = [PhotoViewController photoViewControllerForPageIndex:[ATEventEditorTableController selectedPhotoIdx]];

        //pageZero.eventEditor = self.eventEditor;
        if (pageZero != nil)
        {
            self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:1
                                                                      navigationOrientation:0
                                                                                    options:nil];
            self.pageViewController.dataSource = self;
            
            [self.pageViewController setViewControllers:@[pageZero]
                                              direction:UIPageViewControllerNavigationDirectionForward
                                               animated:NO
                                             completion:NULL];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    //prepare button
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    UIImage *markerIcon = [UIImage imageNamed:@"marker-selected.png"];
    UIButton *markerButton = [UIButton buttonWithType:UIButtonTypeCustom ];
    [markerButton setBackgroundImage:markerIcon forState:UIControlStateNormal];
    [markerButton addTarget:self action:@selector(setDefaultAction:) forControlEvents:UIControlEventTouchUpInside];
    markerButton.frame = (CGRect) { .size.width = 30, .size.height = 30,};
    UIBarButtonItem* setThumbnailButton = [[UIBarButtonItem alloc] initWithCustomView:markerButton ];
    
    UIImage *shareIcon = [UIImage imageNamed:@"share.png"];
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom ];
    [shareButton setBackgroundImage:shareIcon forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(setShareAction:) forControlEvents:UIControlEventTouchUpInside];
    shareButton.frame = (CGRect) { .size.width = 30, .size.height = 30,};
    UIBarButtonItem* setShareButton = [[UIBarButtonItem alloc] initWithCustomView:shareButton ];
    
    UIBarButtonItem* deleteButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem: UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10;
    
    NSArray *items = [NSArray arrayWithObjects: doneButton, fixedSpace, setThumbnailButton, fixedSpace, setShareButton, fixedSpace, deleteButton, nil];
    [self.toolbar setItems:items animated:NO];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(tapToHideShowToolbar:)];
    [self.pageViewController.view addGestureRecognizer:tap];
    [self.view bringSubviewToFront:self.toolbar];
    [self.view bringSubviewToFront:self.pageControl];
}

- (void) viewDidAppear:(BOOL)animated
{
    // Set up the page control
    NSInteger tmpIdx = self.initialPhotoIdx;
    //TODO ##### following initial page setting is so weired, it max set to 3 event tmpIdx is 4,5,6, ...
    //     #####  Do not know why???????????????????? xxxxxxxxxx
    [self.pageControl setCurrentPage:tmpIdx];
    //NSLog(@"----- self.initialPhotoind=%d, pageCountro.currentPage=%d",tmpIdx,self.pageControl.currentPage);
    self.pageControl.numberOfPages = [[ATEventEditorTableController photoList] count];
}

# pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(PhotoViewController *)vc
{
    NSUInteger index = vc.pageIndex;
    self.pageControl.currentPage = index;
    return [PhotoViewController photoViewControllerForPageIndex:(index - 1)];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(PhotoViewController *)vc
{
    NSUInteger index = vc.pageIndex;
    self.pageControl.currentPage =  index;
    return[PhotoViewController photoViewControllerForPageIndex:(index + 1)];
}
//Following delegate for show page numbers. But the position is too low and no way to customize, so I have to use PageControl
/*
- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [[ATEventEditorTableController photoList] count];
}
- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return [ATEventEditorTableController selectedPhotoIdx];
}
 */
- (void) doneAction: (id)sender
{
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}

- (void) deleteAction: (id)sender
{
    int selectedPhotoIdx = self.initialPhotoIdx;
    if (self.eventEditor.photoScrollView.selectedAsThumbnailIndex == selectedPhotoIdx)
        self.eventEditor.photoScrollView.selectedAsThumbnailIndex = NOT_THUMBNAIL;
    if (self.eventEditor.photoScrollView.selectedAsShareIndex == selectedPhotoIdx)
        self.eventEditor.photoScrollView.selectedAsShareIndex = 0;
    
    NSString* deletedFileName =self.eventEditor.photoScrollView.photoList[selectedPhotoIdx];
    //NSLog(@" deleted file = %@",deletedFileName);
    [self.eventEditor deleteCallback: deletedFileName];
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}
- (void) setDefaultAction: (id)sender
{
    self.eventEditor.photoScrollView.selectedAsThumbnailIndex = self.initialPhotoIdx;
    [self.eventEditor.photoScrollView.horizontalTableView reloadData]; //so map marker icon will display on new cell
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}
- (void) setShareAction: (id)sender
{
    self.eventEditor.photoScrollView.selectedAsShareIndex = self.initialPhotoIdx;
    [self.eventEditor.photoScrollView.horizontalTableView reloadData]; //show share icon will display on new selected cell
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}

- (void)tapToHideShowToolbar:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.toolbar.isHidden)
        self.toolbar.hidden = false;
    else
        self.toolbar.hidden = true;
}

@end
