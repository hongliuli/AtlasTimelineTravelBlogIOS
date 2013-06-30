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
    UIBarButtonItem* deleteAction = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
    UIBarButtonItem* setThumbnailAction = [[UIBarButtonItem alloc] initWithTitle:@"Use it on map" style:UIBarButtonItemStyleBordered target:self action:@selector(setDefaultAction:)];
    
    NSArray *items = [NSArray arrayWithObjects: deleteAction, setThumbnailAction, doneButton,nil];
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
    //add to deletedList xxxxx
    NSString* deletedFileName =self.eventEditor.photoScrollView.photoList[selectedPhotoIdx];
    NSLog(@" deleted file = %@",deletedFileName);
    [self.eventEditor deleteCallback: deletedFileName];
    [self dismissModalViewControllerAnimated:true]; //use Modal with Done button is good both iPad/iPhone
}
- (void) setDefaultAction: (id)sender
{
    self.eventEditor.photoScrollView.selectedAsThumbnailIndex = self.eventEditor.photoScrollView.selectedPhotoIndex;
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
