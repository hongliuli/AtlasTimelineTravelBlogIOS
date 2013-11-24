//
//  ATCameraAction.m
//  AtlasTimelineIOS
//
//  Created by Hong on 11/23/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATCameraAction.h"


@implementation ATCameraAction

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"------ATCameraAction didFinish delegate");
    //[popoverController dismissPopoverAnimated:true];
    Boolean newMedia = YES;
    NSString *mediaType = [info
                           objectForKey:UIImagePickerControllerMediaType];

    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info
                          objectForKey:UIImagePickerControllerOriginalImage];
        //self.parentCtlr.imageView.image = image;
        
        //save to file will be in EventEditor with doneSelectPictures() callback
        
        //if (newMedia)
        //     UIImageWriteToSavedPhotosAlbum(image, self,  @selector(image:finishedSavingWithError:contextInfo:),nil);
        
    }
    else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie])
    {
        // Code here to support video if enabled
    }
}

@end
