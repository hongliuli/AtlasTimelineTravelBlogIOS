//
//  ATViewImagePickerController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 3/31/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ELCImagePickerController.h"

@protocol ATImagePickerDelegate;

@interface ATViewImagePickerController : UIViewController<ELCImagePickerControllerDelegate,UIScrollViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, copy) NSArray *chosenImages;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

//@property (weak) id<ELCImagePickerControllerDelegate> delegate;
@property (weak) id<ATImagePickerDelegate> delegate;
@end


//ATEventEditor will assigin itself to above "delegate" var, implement doneSelectPictures
@protocol ATImagePickerDelegate <NSObject>
@required
- (void)doneSelectPictures:(NSArray*)images;
@end