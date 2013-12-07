//
//  PagedScrollViewController.m
//  ScrollViews
//
//  Created by Matt Galloway on 01/03/2012.
//  Copyright (c) 2012 Swipe Stack Ltd. All rights reserved.
//

#import "ATPhotoScrollViewControler.h"
#import "ATEventEditorTableController.h"
#import "ATHelper.h"
#import "ATConstants.h"

#define NOT_THUMBNAIL -1;

@interface ATPhotoScrollViewControler ()
@property (nonatomic, strong) NSArray *pageImages;
@property (nonatomic, strong) NSMutableArray *pageViews;

- (void)loadVisiblePages;
- (void)loadPage:(NSInteger)page;
- (void)purgePage:(NSInteger)page;
@end

@implementation ATPhotoScrollViewControler

@synthesize scrollView = _scrollView;
@synthesize pageControl = _pageControl;

@synthesize pageImages = _pageImages;
@synthesize pageViews = _pageViews;

#pragma mark -

//call trail when tap on eventEditor's small photo scroll view:
//   AATPhotoScrollVew::handleTapGesture -> didSelect.. ->EventEditor::showPhotoView().presentModalView...
//   -> then come there
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
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
    
    //swipe gesture
    /*
     UISwipeGestureRecognizer* recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
     [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
     [[self view] addGestureRecognizer:recognizer];
     recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
     [recognizer setDirection:( UISwipeGestureRecognizerDirectionLeft)];
     [[self view] addGestureRecognizer:recognizer];
     */
    self.scrollView.delegate = self; //ScrollView demo code do not have this and works, but I have to add this
    
    //following is from  sample code
    self.title = @"Paged";
    
    //NSInteger pageCount = self.pageImages.count;
    NSInteger pageCount = [self.eventEditor.photoScrollView.photoList count];
    
    // Set up the page control
    self.pageControl.currentPage = 0;//self.currentIndex; //currentIndex is set in EventEdito::ShowPhotoView()
    self.pageControl.numberOfPages = pageCount;
    
    // Set up the array to hold the views for each page
    self.pageViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < pageCount; ++i) {
        [self.pageViews addObject:[NSNull null]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Set up the content size of the scroll view
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * [self.eventEditor.photoScrollView.photoList count], pagesScrollViewSize.height);
    [self.scrollView setContentOffset:CGPointMake(pagesScrollViewSize.width*self.currentIndex, 0)];
    
    // Load the initial set of pages that are on screen
    [self loadVisiblePages];
}
#pragma mark -

- (void)loadVisiblePages {
    // First, determine which page is currently visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    // Update the page control
    self.pageControl.currentPage = page;
    
    // Work out which pages we want to load
    NSInteger firstPage = page - 1;
    NSInteger lastPage = page + 1;

    self.currentIndex = page;

    // Purge anything before the first page
    for (NSInteger i=0; i<firstPage; i++) {
        [self purgePage:i];
    }
    for (NSInteger i=firstPage; i<=lastPage; i++) {
        [self loadPage:i];
    }
    for (NSInteger i=lastPage+1; i<[self.eventEditor.photoScrollView.photoList count]; i++) {
        [self purgePage:i];
    }
}

- (void)loadPage:(NSInteger)page {
    if (page < 0 || page >= self.pageControl.numberOfPages) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    // Load an individual page, first seeing if we've already loaded it

    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView == [NSNull null]) {
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        NSString* photoName = self.eventEditor.photoScrollView.photoList[page];
        NSString* eventId = self.eventEditor.eventId;

        UIImageView *newPageView = [[UIImageView alloc] initWithImage:[ATHelper readPhotoFromFile:photoName eventId:eventId]];
        newPageView.contentMode = UIViewContentModeScaleAspectFit;
        newPageView.frame = frame;
        [self.scrollView addSubview:newPageView];
        [self.pageViews replaceObjectAtIndex:page withObject:newPageView];
    }
}

- (void)purgePage:(NSInteger)page {
    if (page < 0 || page >= [self.eventEditor.photoScrollView.photoList count]) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    // Remove a page from the scroll view and reset the container array
    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView != [NSNull null]) {
        [pageView removeFromSuperview];
        [self.pageViews replaceObjectAtIndex:page withObject:[NSNull null]];
    }
}


- (void) doneAction: (id)sender
{
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}

- (void) deleteAction: (id)sender
{
    
    int selectedPhotoIdx = self.currentIndex;
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
    self.eventEditor.photoScrollView.selectedAsThumbnailIndex = self.currentIndex;
    [self.eventEditor.photoScrollView.horizontalTableView reloadData]; //so map marker icon will display on new cell
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}
- (void) setShareAction: (id)sender
{
    self.eventEditor.photoScrollView.selectedAsShareIndex = self.currentIndex;
    [self.eventEditor.photoScrollView.horizontalTableView reloadData]; //show share icon will display on new selected cell
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}

- (void)viewDidUnload {
    [self setToolbar:nil];
    [super viewDidUnload];
    
    self.scrollView = nil;
    self.pageControl = nil;
    self.pageImages = nil;
    self.pageViews = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Load the pages which are now on screen
    [self loadVisiblePages];
}

- (void) showCount
{
    
}

@end
