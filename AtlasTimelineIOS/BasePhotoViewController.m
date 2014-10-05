//
//  BasePhotoViewController.m
//  PhotoScroller
//
//  Created by Stephanie Sharp on 19/06/13.
//

#import "BasePhotoViewController.h"
#import "PhotoViewController.h"
#import "ATEventEditorTableController.h"
#import "ATConstants.h"
#import "ATAppDelegate.h"

#define NOT_THUMBNAIL -1;

@implementation BasePhotoViewController

@synthesize pageViewController;

UIImageView* shareIconView;
UILabel* shareCountLabel;
UILabel* sortIdexLabel;
UITextView* photoDescView;
NSString* currentPhotoDescTxt;
NSString* currentPhotoFileName;
UITextView *photoDescInputView;
UILabel* hasPhotoDescLabel;

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
    UIImage *markerIcon = [UIImage imageNamed:@"sort-ascending-icon.png"];
    UIButton *markerButton = [UIButton buttonWithType:UIButtonTypeCustom ];
    [markerButton setBackgroundImage:markerIcon forState:UIControlStateNormal];
    [markerButton addTarget:self action:@selector(sortSelectedAction:) forControlEvents:UIControlEventTouchUpInside];
    markerButton.frame = (CGRect) { .size.width = 30, .size.height = 30,};
    UIBarButtonItem* setThumbnailButton = [[UIBarButtonItem alloc] initWithCustomView:markerButton ];
    
    UIImage *shareIcon = [UIImage imageNamed:@"share.png"];
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom ];
    [shareButton setBackgroundImage:shareIcon forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(setShareAction:) forControlEvents:UIControlEventTouchUpInside];
    shareButton.frame = (CGRect) { .size.width = 30, .size.height = 30,};
    UIBarButtonItem* setShareButton = [[UIBarButtonItem alloc] initWithCustomView:shareButton ];
   
    UIImage *editIcon = [UIImage imageNamed:@"pencil-orange-icon.png"];
    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom ];
    [editButton setBackgroundImage:editIcon forState:UIControlStateNormal];
    [editButton addTarget:self action:@selector(setEditAction:) forControlEvents:UIControlEventTouchUpInside];
    editButton.frame = (CGRect) { .size.width = 30, .size.height = 30,};
    UIBarButtonItem* setEditButton = [[UIBarButtonItem alloc] initWithCustomView:editButton ];
    UIBarButtonItem* deleteButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem: UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10;
    
    NSArray *items = [NSArray arrayWithObjects: doneButton, fixedSpace, setShareButton, nil];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.authorMode)
    {
        items = [NSArray arrayWithObjects: doneButton, fixedSpace, setThumbnailButton, fixedSpace, setShareButton, fixedSpace, setEditButton,fixedSpace, deleteButton, nil];
    }
    [self.toolbar setItems:items animated:NO];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(tapToHideShowToolbar:)];
    [self.pageViewController.view addGestureRecognizer:tap];
    [self.view bringSubviewToFront:self.toolbar];
    [self.view bringSubviewToFront:self.pageControl];
    
    hasPhotoDescLabel = [[UILabel alloc] initWithFrame:CGRectMake([ATConstants screenWidth] - 80, 50 , 35, 40)];
    [hasPhotoDescLabel setBackgroundColor:[UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.6]];
    hasPhotoDescLabel.numberOfLines = 4;
    [hasPhotoDescLabel.layer setCornerRadius:4.0f];
    [hasPhotoDescLabel.layer setMasksToBounds:YES];
    hasPhotoDescLabel.textColor = [UIColor whiteColor];
    hasPhotoDescLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    hasPhotoDescLabel.layer.borderWidth = 1;
    hasPhotoDescLabel.font = [UIFont fontWithName:@"Helvetica" size:8];
    hasPhotoDescLabel.text=@"   . . . . .\n   . . . . .\n   . . . . .\n   . . . . .";
    [self.view addSubview:hasPhotoDescLabel];
    
    shareIconView = [[UIImageView alloc] initWithFrame:CGRectMake(50, [ATConstants screenHeight] - 110 , 30, 30)];
    shareCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, [ATConstants screenHeight] - 110 , 180, 30)];
    shareIconView.image = nil;
    shareCountLabel.backgroundColor = [UIColor colorWithRed: 0.55 green: 0.55 blue: 0.55 alpha: 0.5];
    shareCountLabel.textColor = [UIColor whiteColor];
    
    
    int screenWidth = [ATConstants screenWidth];
    int textWidth = screenWidth * 0.7;
    photoDescView = [[UITextView alloc] initWithFrame:CGRectMake((screenWidth - textWidth)/2, 20 , textWidth, 110)];
    photoDescView.backgroundColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.5];
    photoDescView.textColor = [UIColor whiteColor];
    //photoDescView.textAlignment = NSTextAlignmentCenter;
    photoDescView.font = [UIFont fontWithName:@"Helvetica" size:20];
    photoDescView.editable = false;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        photoDescView.font = [UIFont fontWithName:@"Helvetica" size:13];
    
    [photoDescView.layer setCornerRadius:8.0f];
    [photoDescView.layer setMasksToBounds:YES];
    
    [self.view addSubview:shareIconView];
    [self.view addSubview:shareCountLabel];
    [self.view addSubview:photoDescView];
    shareCountLabel.hidden = true;
    
    sortIdexLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, [ATConstants screenHeight] - 140 , 120, 30)];
    sortIdexLabel.backgroundColor = [UIColor colorWithRed: 0.55 green: 0.55 blue: 0.55 alpha: 0.5];
    sortIdexLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:sortIdexLabel];
    sortIdexLabel.hidden = true;
    
    [self showHideIcons:[ATEventEditorTableController selectedPhotoIdx]];
}


# pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(PhotoViewController *)vc
{
    NSUInteger index = vc.pageIndex;
    self.pageControl.currentPage = index;
    
    [self showHideIcons:index];
    
    return [PhotoViewController photoViewControllerForPageIndex:(index - 1)];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(PhotoViewController *)vc
{
    NSUInteger index = vc.pageIndex;
    self.pageControl.currentPage =  index;
    [self showHideIcons:index];
    
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

-(void)showHideIcons:(int)index
{
    if ([self.eventEditor.photoScrollView.selectedAsShareIndexSet containsObject:[NSNumber numberWithInt:index]])
    {
        shareIconView.image = [UIImage imageNamed:@"share.png"];
        shareCountLabel.hidden = false;
        shareCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d selected for sharing",nil),self.eventEditor.photoScrollView.selectedAsShareIndexSet.count ];
    }
    else
    {
        shareIconView.image = nil;
        shareCountLabel.hidden = true;
    }
    
    if ([self.eventEditor.photoScrollView.selectedAsSortIndexList containsObject:[NSNumber numberWithInt:index]])
    {
        int sortIdx = [self.eventEditor.photoScrollView.selectedAsSortIndexList indexOfObject:[NSNumber numberWithInt:index]];
        sortIdexLabel.hidden = false;
        sortIdexLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Order: %d",nil),sortIdx + 1 ];
    }
    else
    {
        sortIdexLabel.hidden = true;
    }
    
    currentPhotoFileName =self.eventEditor.photoScrollView.photoList[index];
    NSDictionary* photoDescMap = self.eventEditor.photoScrollView.photoDescMap;
    currentPhotoDescTxt = nil;
    photoDescView.hidden = true;
    hasPhotoDescLabel.hidden = true;
    if (photoDescMap != nil)
    {
        currentPhotoDescTxt = [photoDescMap objectForKey:currentPhotoFileName];
        if (currentPhotoDescTxt != nil)
        {
            photoDescView.text = currentPhotoDescTxt;
            if ([currentPhotoDescTxt length] < 100)
                photoDescView.textAlignment = NSTextAlignmentCenter;
            else
                photoDescView.textAlignment = NSTextAlignmentLeft;
            
            if (!self.toolbar.hidden)
            {
                photoDescView.hidden = false;
                hasPhotoDescLabel.hidden = true;
            }
            else
                hasPhotoDescLabel.hidden = false;
        }
        else
        {
            hasPhotoDescLabel.hidden = true;
        }
    }
}

- (void) doneAction: (id)sender
{
    int selectedPhotoIdx = self.pageControl.currentPage;
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
    [self.eventEditor.photoScrollView.horizontalTableView scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:selectedPhotoIdx inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    [self.eventEditor updatePhotoCountLabel];
}

//TODO delete will cause issue to those marked as share, but I do not want to consider it, it weired that people will do share and delete in the same session
- (void) deleteAction: (id)sender
{
    int selectedPhotoIdx = self.pageControl.currentPage;
    if ([self.eventEditor.photoScrollView.selectedAsSortIndexList containsObject: [NSNumber numberWithInt:selectedPhotoIdx]])
        [self.eventEditor.photoScrollView.selectedAsSortIndexList removeObject:[NSNumber numberWithInt:selectedPhotoIdx]];
    if ([self.eventEditor.photoScrollView.selectedAsShareIndexSet containsObject:[NSNumber numberWithInt:selectedPhotoIdx]])
        [self.eventEditor.photoScrollView.selectedAsShareIndexSet removeObject:[NSNumber numberWithInt:selectedPhotoIdx]];
    
    NSString* deletedFileName =self.eventEditor.photoScrollView.photoList[selectedPhotoIdx];
    //NSLog(@" deleted file = %@",deletedFileName);
    [self.eventEditor deleteCallback: deletedFileName];
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}
- (void) sortSelectedAction: (id)sender
{
    int selectedPhotoIdx = self.pageControl.currentPage;
    
    NSNumber *selectedPhotoIdxObj = [NSNumber numberWithInt: selectedPhotoIdx];
    if ([self.eventEditor.photoScrollView.selectedAsSortIndexList containsObject:selectedPhotoIdxObj])
    {
        [self.eventEditor.photoScrollView.selectedAsSortIndexList removeObject: selectedPhotoIdxObj];
        sortIdexLabel.hidden = true;
    }
    else
    {
        [self.eventEditor.photoScrollView.selectedAsSortIndexList addObject:selectedPhotoIdxObj];
        int count = [self.eventEditor.photoScrollView.selectedAsSortIndexList count];
        
        sortIdexLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Order: %d",nil), count ];
        sortIdexLabel.hidden = false;
    }
    [self.eventEditor.photoScrollView.horizontalTableView reloadData]; //so order number will display on new cell
}
- (void) setShareAction: (id)sender
{
    int selectedPhotoIdx = self.pageControl.currentPage;
    
    [self.eventEditor.photoScrollView.selectedAsShareIndexSet addObject:[NSNumber numberWithInt: selectedPhotoIdx]];
    [self.eventEditor.photoScrollView.horizontalTableView reloadData]; //show share icon will display on new
    shareCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d selected for sharing",nil),self.eventEditor.photoScrollView.selectedAsShareIndexSet.count ];
    if (shareIconView.image == nil)
    {
        shareIconView.image = [UIImage imageNamed:@"share.png"];
        shareCountLabel.hidden = false;
    }
    else
    {
        shareIconView.image = nil;
        shareCountLabel.hidden = true;
        [self.eventEditor.photoScrollView.selectedAsShareIndexSet removeObject:[NSNumber numberWithInt: selectedPhotoIdx]];
    }
    [self.eventEditor setShareCount];
}

- (void) setEditAction: (id)sender
{
    // Here we need to pass a full frame
    CustomIOS7AlertView *alertView = [[CustomIOS7AlertView alloc] init];
    
    // Add some custom content to the alert view
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UILabel* photoDescLabel =[[UILabel alloc] initWithFrame:CGRectMake(10, 10, 290, 30)];
    photoDescLabel.text = NSLocalizedString(@"Enter Photo Description:",nil);
    [contentView addSubview:photoDescLabel];
    
    if (photoDescInputView == nil)
        photoDescInputView= [[UITextView alloc] initWithFrame:CGRectMake(10, 45, 270, 145)];
    if (currentPhotoDescTxt != nil && [currentPhotoDescTxt length] >0)
        photoDescInputView.text = currentPhotoDescTxt;
    else
        photoDescInputView.text = @"";
    [contentView addSubview:photoDescInputView];
    [alertView setContainerView:contentView];
    
    // Modify the parameters
    [alertView setButtonTitles:[NSMutableArray arrayWithObjects:NSLocalizedString(@"Continue",nil), NSLocalizedString(@"Delete",nil),NSLocalizedString(@"Cancel",nil), nil]];
    [alertView setDelegate:self];
    
    // You may use a Block, rather than a delegate.
    /*** I will use following delegate
     [alertView setOnButtonTouchUpInside:^(CustomIOS7AlertView *alertView, int buttonIndex) {
     NSLog(@"Block: Button at position %d is clicked on alertView %d.", buttonIndex, (int)[alertView tag]);
     [alertView close];
     }];
     */
    
    [alertView setUseMotionEffects:true];
    
    // And launch the dialog
    [alertView show];
}
- (void)customIOS7dialogButtonTouchUpInside: (CustomIOS7AlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
    if (buttonIndex == 0) //continue button cliced
    {
        NSString* currentTxtTmp = currentPhotoDescTxt;
        if (currentTxtTmp == nil)
            currentTxtTmp = @"";
        if (![photoDescInputView.text isEqualToString:currentTxtTmp])
        {
            self.eventEditor.photoDescChangedFlag = true;
            //TODO enable Save button
            if (self.eventEditor.photoScrollView.photoDescMap == nil)
                self.eventEditor.photoScrollView.photoDescMap = [[NSMutableDictionary alloc] init];
            [self.eventEditor.photoScrollView.photoDescMap setObject:photoDescInputView.text forKey:currentPhotoFileName];
            photoDescView.text = photoDescInputView.text;
            currentPhotoDescTxt = photoDescInputView.text;
            photoDescView.hidden = false;
        }
    }
    else if (buttonIndex == 1) //delete button
    {
        if (currentPhotoDescTxt != nil && [currentPhotoDescTxt length] > 0)
            self.eventEditor.photoDescChangedFlag = true;
        [self.eventEditor.photoScrollView.photoDescMap removeObjectForKey:currentPhotoFileName];
        photoDescView.hidden = true;
    }
    [alertView close];
}

- (void)tapToHideShowToolbar:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.toolbar.isHidden)
    {
        self.toolbar.hidden = false;
        NSDictionary* photoDescMap = self.eventEditor.photoScrollView.photoDescMap;
        if ([photoDescMap objectForKey:currentPhotoFileName] != nil)
            photoDescView.hidden = false;
    }
    else
    {
        self.toolbar.hidden = true;
        photoDescView.hidden = true;
    }
    
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    int screenWidth = [ATConstants screenWidth];
    int textWidth = screenWidth * 0.7;
    [photoDescView setFrame:CGRectMake((screenWidth - textWidth)/2, 20 , textWidth, 120)];
    
    [sortIdexLabel setFrame:CGRectMake(50, [ATConstants screenHeight] - 140 , 120, 30)];
    [shareCountLabel setFrame:CGRectMake(80, [ATConstants screenHeight] - 110 , 180, 30)];
    [shareIconView setFrame:CGRectMake(50, [ATConstants screenHeight] - 110 , 30, 30)];
    [hasPhotoDescLabel setFrame:CGRectMake([ATConstants screenWidth] - 80, 50 , 35, 40)];
    //NSLog(@"  rotation scree height=%d",[ATConstants screenHeight]);
}

@end
