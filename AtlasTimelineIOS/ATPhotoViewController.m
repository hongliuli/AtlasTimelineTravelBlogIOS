//
//  ATViewImagePickerController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 3/31/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ATPhotoViewController.h"
#import "ATHelper.h"
#import "ATConstants.h"

#define NOT_THUMBNAIL -1;
@interface ATPhotoViewController ()

@end

@implementation ATPhotoViewController

UILabel * lblCount = nil;

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
    UISwipeGestureRecognizer* recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [[self view] addGestureRecognizer:recognizer];
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setDirection:( UISwipeGestureRecognizerDirectionLeft)];
    [[self view] addGestureRecognizer:recognizer];
    
    lblCount = [[UILabel alloc] initWithFrame:CGRectMake([ATConstants screenWidth]/2 - 20, 50, 80, 30)];
    lblCount.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4 ];
    lblCount.textColor = [UIColor whiteColor];
    lblCount.textAlignment = UITextAlignmentCenter;
    lblCount.font = [UIFont fontWithName:@"Helvetica-Bold" size:22.0];
    lblCount.layer.cornerRadius = 5;
    [self.view addSubview:lblCount];
    
    [super viewDidLoad];
}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    //NSLog(@"Swipe received.");
    int totalPhotoCount = [self.eventEditor.photoScrollView.photoList count];
    if(recognizer.direction == UISwipeGestureRecognizerDirectionRight)
    {
        if (self.currentIndex == 0 )
        {
            //shake current image
        }
        else
        {
            self.currentIndex --;
            NSString* photoName = self.eventEditor.photoScrollView.photoList[self.currentIndex];
            NSString* eventId = self.eventEditor.eventId;
            [self.imageView setImage:[ATHelper readPhotoFromFile:photoName eventId:eventId]];
           /***
            UIImageView* newView = [[UIImageView alloc] initWithImage:[ATHelper readPhotoFromFile:photoName eventId:eventId]];
            UIImageView* existingImageView = self.imageView;
            newView.contentMode = UIViewContentModeScaleAspectFit;
            newView.clipsToBounds = YES;
            
            [UIView transitionFromView:self.imageView
                                toView:self.imageView
                              duration:1.0f
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            completion:nil];
           // [existingImageView setImage:newView.image];
           // self.imageView = existingImageView; //so guesture actions etc still work
            */
        }
    }
    else if(recognizer.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        if (self.currentIndex == totalPhotoCount -1)
        {
            //share current image
        }
        else
        {
            self.currentIndex ++;
            NSString* photoName = self.eventEditor.photoScrollView.photoList[self.currentIndex];
            NSString* eventId = self.eventEditor.eventId;
            [self.imageView setImage:[ATHelper readPhotoFromFile:photoName eventId:eventId]];
        }
    }
    [self showCount];
    [self.view bringSubviewToFront:lblCount];
    
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
    
    [self setImageView:nil];
    [super viewDidUnload];
}
- (void) showCount
{
    lblCount.text = [NSString stringWithFormat:@"%d / %d",self.currentIndex + 1, [self.eventEditor.photoScrollView.photoList count] ];
    [self.view bringSubviewToFront:lblCount];
    int deltaHeight;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        deltaHeight = 110;
    }
    else{
        deltaHeight =100;
    }
    CGRect frame = CGRectMake([ATConstants screenWidth]/2 - 30, 20, 80, 30);
    [lblCount setFrame:frame];
    
}
@end
