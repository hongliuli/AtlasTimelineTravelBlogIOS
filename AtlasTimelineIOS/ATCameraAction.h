//
//  ATCameraAction.h
//  AtlasTimelineIOS
//
//  Created by Hong on 11/23/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ATViewImagePickerController.h"

@interface ATCameraAction : NSObject<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic)ATViewImagePickerController* parentCtlr;
@end
