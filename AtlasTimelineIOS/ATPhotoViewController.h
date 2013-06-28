//
//  ATViewImagePickerController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 3/31/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ATEventEditorTableController.h"

@interface ATPhotoViewController : UIViewController<UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) ATEventEditorTableController* eventEditor;

@end

