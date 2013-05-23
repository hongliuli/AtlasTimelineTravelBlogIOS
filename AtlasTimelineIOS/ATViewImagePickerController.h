//
//  ATViewImagePickerController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 3/31/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@protocol ATImagePickerDelegate;

@interface ATViewImagePickerController : UIViewController<UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UIPopoverControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak) id<ATImagePickerDelegate> delegate;

@end


//ATEventEditor will assigin itself to above "delegate" var, implement doneSelectPicture
@protocol ATImagePickerDelegate <NSObject>
@required
- (void)doneSelectPicture:(UIImage*)newPhoto;
@end