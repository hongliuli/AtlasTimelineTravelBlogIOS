//
//  ATViewImagePickerController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 3/31/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATViewImagePickerController.h"

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
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Camera"
                                     style:UIBarButtonItemStyleBordered
                                     target:self
                                     action:@selector(useCamera:)];
    UIBarButtonItem *cameraRollButton = [[UIBarButtonItem alloc]
                                         initWithTitle:@"Camera Roll"
                                         style:UIBarButtonItemStyleBordered
                                         target:self
                                         action:@selector(useCameraRoll:)];
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    NSArray *items = [NSArray arrayWithObjects: cameraButton,
                      cameraRollButton, space, doneButton,nil];
    [self.toolbar setItems:items animated:NO];
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@" ---- receive Memonry Warning in camera thing");
    // Dispose of any resources that can be recreated.
}

- (IBAction) useCamera: (id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType =
        UIImagePickerControllerSourceTypeCamera;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:
                                  (NSString *) kUTTypeImage,
                                  nil];
        imagePicker.allowsEditing = NO;
        [self presentModalViewController:imagePicker
                                animated:YES];
        newMedia = YES;
    }
}

- (IBAction) useCameraRoll: (id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        //*** for iPhone, use following, iPad will not work with Modal wndow. See Apple document
        UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
        mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
     
        mediaUI.mediaTypes = [NSArray arrayWithObjects:(NSString *) kUTTypeImage,nil];
     
        // Hides the controls for moving & scaling pictures, or for
        // trimming movies. To instead show the controls, use YES.
        mediaUI.allowsEditing = NO;
        mediaUI.delegate = self;
     
        [self presentModalViewController: mediaUI animated: YES];
    }
    else //for iPad have to use popover for cameraroll
    {
        if ([popoverController isPopoverVisible]) {
            [popoverController dismissPopoverAnimated:YES];
        } else {
            if ([UIImagePickerController isSourceTypeAvailable:
             UIImagePickerControllerSourceTypeSavedPhotosAlbum]) //UIImagePickerControllerSourceTypeSavedPhotosAlbum  UIImagePickerControllerSourceTypePhotoLibrary
            {
                UIImagePickerController *imagePicker =
                [[UIImagePickerController alloc] init];
                imagePicker.delegate = self;
                imagePicker.sourceType =
                UIImagePickerControllerSourceTypePhotoLibrary;
                imagePicker.mediaTypes = [NSArray arrayWithObjects:
                                      (NSString *) kUTTypeImage,
                                      nil];
                imagePicker.allowsEditing = NO;
                popoverController = [[UIPopoverController alloc]
                                      initWithContentViewController:imagePicker];
                popoverController.delegate = self;
            
                //[popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
                CGRect imageFrame = CGRectMake(10, 10, 800, 600); //Size does not matter, this is fix for iOS7, iOS 7. Somehow the above presentPopoverFromBarButtonItem does not work anymore in iOS
                [popoverController presentPopoverFromRect:imageFrame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

                newMedia = NO;
            }
        }
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [popoverController dismissPopoverAnimated:true];
    
    NSString *mediaType = [info
                           objectForKey:UIImagePickerControllerMediaType];
    if (newMedia) //#### I added this check, otherwise cameraroll will not work. code from http://www.techotopia.com/index.php/An_Example_iOS_4_iPad_Camera_and_UIImagePickerController_Application_%28Xcode_4%29
        [self dismissModalViewControllerAnimated:YES];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info
                          objectForKey:UIImagePickerControllerOriginalImage];
        self.imageView.image = image;

        //save to file will be in EventEditor with doneSelectPicture() callback
        
        //if (newMedia)
       //     UIImageWriteToSavedPhotosAlbum(image, self,  @selector(image:finishedSavingWithError:contextInfo:),nil);
        
    }
    else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie])
    {
        // Code here to support video if enabled
    }
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

- (void) doneAction: (id)sender
{
    [self.delegate doneSelectPicture:self.imageView.image]; 
    [self dismissModalViewControllerAnimated:true]; //TODO for iPad case. iPhone should use navigators
}


- (void)viewDidUnload {
    [self setImageView:nil];
    [self setToolbar:nil];
    
    self.imageView = nil;
    self.toolbar = nil;
    
    [super viewDidUnload];
}
@end
