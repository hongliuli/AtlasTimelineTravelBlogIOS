//
//  ATViewImagePickerController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 3/31/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATPhotoViewController.h"
#define NOT_THUMBNAIL -1;
@interface ATPhotoViewController ()

@end

@implementation ATPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{

    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    UIBarButtonItem* setThumbnailButton = [[UIBarButtonItem alloc] initWithTitle:@"Set on Map" style:UIBarButtonItemStyleBordered target:self action:@selector(setDefaultAction:)];
    UIBarButtonItem* setShareButton = [[UIBarButtonItem alloc] initWithTitle:@"Set to share" style:UIBarButtonItemStyleBordered target:self action:@selector(setShareAction:)];
    UIBarButtonItem* deleteButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem: UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
    NSArray *items = [NSArray arrayWithObjects: doneButton, setThumbnailButton, setShareButton,deleteButton, nil];
    [self.toolbar setItems:items animated:NO];
    [super viewDidLoad];
}

- (void) doneAction: (id)sender
{
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}

- (void) deleteAction: (id)sender
{
    int selectedPhotoIdx = self.eventEditor.photoScrollView.selectedPhotoIndex;
    if (self.eventEditor.photoScrollView.selectedAsThumbnailIndex == selectedPhotoIdx)
        self.eventEditor.photoScrollView.selectedAsThumbnailIndex = NOT_THUMBNAIL;
    if (self.eventEditor.photoScrollView.selectedAsShareIndex == selectedPhotoIdx)
        self.eventEditor.photoScrollView.selectedAsShareIndex = 0;

    NSString* deletedFileName =self.eventEditor.photoScrollView.photoList[selectedPhotoIdx];
    NSLog(@" deleted file = %@",deletedFileName);
    [self.eventEditor deleteCallback: deletedFileName];
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}
- (void) setDefaultAction: (id)sender
{
    self.eventEditor.photoScrollView.selectedAsThumbnailIndex = self.eventEditor.photoScrollView.selectedPhotoIndex;
    [self.eventEditor.photoScrollView.horizontalTableView reloadData]; //so map marker icon will display on new cell
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}
- (void) setShareAction: (id)sender
{
    self.eventEditor.photoScrollView.selectedAsShareIndex = self.eventEditor.photoScrollView.selectedPhotoIndex;
    [self.eventEditor.photoScrollView.horizontalTableView reloadData]; //show share icon will display on new selected cell
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@" ---- receive Memonry Warning in photoview thing");
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload {
    [self setImageView:nil];
    [self setToolbar:nil];
    
    self.imageView = nil;
    self.toolbar = nil;
    
    [super viewDidUnload];
}
@end
