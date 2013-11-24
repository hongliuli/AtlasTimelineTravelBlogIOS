//
//  ATViewImagePickerController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 3/31/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATViewImagePickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import "ELCAssetTablePicker.h"
#import "ATCameraAction.h"


@interface ATViewImagePickerController ()

@end

@implementation ATViewImagePickerController

BOOL newMedia;
UIPopoverController *popoverController;

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

	// Do any additional setup after loading the view.
    /*
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Camera"
                                     style:UIBarButtonItemStyleBordered
                                     target:self
                                     action:@selector(useCamera:)];
     */
    UIBarButtonItem *cameraRollButton = [[UIBarButtonItem alloc]
                                         initWithTitle:@"Camera Roll"
                                         style:UIBarButtonItemStyleBordered
                                         target:self
                                         action:@selector(useCameraRoll:)];
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    NSArray *items = [NSArray arrayWithObjects: //cameraButton, //issue with camera when integrate ECLImagePicker, disable it because camera is not important in our app
                      cameraRollButton, space, doneButton,nil];
    [self.toolbar setItems:items animated:NO];
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@" ---- receive Memonry Warning in camera thing start");
    [super didReceiveMemoryWarning];
    NSLog(@" ---- receive Memonry Warning in camera thing end");
    // Dispose of any resources that can be recreated.
}

- (IBAction) useCamera: (id)sender  //not used because some issue when integrate ELCImagePickerController
{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
        ATCameraAction* action = [[ATCameraAction alloc] init];
        action.parentCtlr = self;
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = action;
        imagePicker.sourceType =
        UIImagePickerControllerSourceTypeCamera;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:
                                  (NSString *) kUTTypeImage,
                                  nil];
        imagePicker.allowsEditing = NO;
        [self presentViewController:imagePicker animated:YES completion:nil];
        newMedia = YES;
    }
}

- (IBAction) useCameraRoll: (id)sender
{
	ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] init];
    elcPicker.maximumImagesCount = 9;
	elcPicker.imagePickerDelegate = self;
    
    [self presentViewController:elcPicker animated:YES completion:nil];
}


-(void)image:(UIImage *)image
finishedSavingWithError:(NSError *)error
 contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Save failed"
                              message: @"Failed to save image"\
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

//called when photo picked
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    NSLog(@"----- didFinish ");
    [self dismissViewControllerAnimated:YES completion:nil];
	
    for (UIView *v in [_scrollView subviews]) {
        [v removeFromSuperview];
    }
    
	CGRect workingFrame = _scrollView.frame;
	workingFrame.origin.x = 0;
    workingFrame.origin.y=0; //copy from ELImmage demo without this, but I have to add this, do not know why
    //NSLog(@"--- workingFrame  %f   %f   %f   %f", workingFrame.origin.x, workingFrame.origin.y, workingFrame.size.width, workingFrame.size.height);
    
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:[info count]];
	
	for (NSDictionary *dict in info) {
        
        UIImage *image = [dict objectForKey:UIImagePickerControllerOriginalImage];
        [images addObject:image];
        
		UIImageView *imageview = [[UIImageView alloc] initWithImage:image];
		[imageview setContentMode:UIViewContentModeScaleAspectFit ];//     UIViewContentModeScaleAspectFit];
		imageview.frame = workingFrame;
		
		[_scrollView addSubview:imageview];
		
		workingFrame.origin.x = workingFrame.origin.x + workingFrame.size.width;
	}
    
    self.chosenImages = images;
	
	[_scrollView setPagingEnabled:YES];
	[_scrollView setContentSize:CGSizeMake(workingFrame.origin.x, workingFrame.size.height)];

}
//called after cancel
- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) doneAction: (id)sender //called after click my Done button, not ELCImagePicker's done
{
    [self.delegate doneSelectPictures:self.chosenImages];
    [self dismissModalViewControllerAnimated:true]; //TODO for iPad case. iPhone should use navigators
}


- (void)viewDidUnload {
    
    [self setScrollView:nil];
    [super viewDidUnload];
}
@end
