//
//  ATEventEditorTableController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/16/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATEventAnnotation.h"
#import "ATViewImagePickerController.h"

@protocol EventEditorDelegate ;

@class ATViewController;
@class ATEventEntity;
@class ATEventDataStruct;

@interface ATEventEditorTableController : UITableViewController <UITextFieldDelegate, ATImagePickerDelegate>
{
    ATEventAnnotation * annotation;
    //id<EventEditorDelegate> delegate;
}
@property int hasPhotoFlag;
@property int eventType;
@property UIButton* photoButton;
@property CLLocationCoordinate2D coordinate;

@property (weak, nonatomic) IBOutlet UITextView *description;
@property (weak, nonatomic) IBOutlet UITextView *address;
@property (weak, nonatomic) IBOutlet UITextField *dateTxt;




@property(strong, nonatomic) UIDatePicker *datePicker;
@property(strong, nonatomic) UIToolbar *toolbar;

@property (weak) id<EventEditorDelegate> delegate;

//following button outlet is for disable/enable programly
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;


- (IBAction)saveAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)cancelAction:(id)sender;


- (void)changeDateInLabel:(id)sender;
- (void)datePicked:(id)sender;

@end

// I can save/delete Core Data here, but I will let these to be done in mapview by delegate since we have pass info back to update annotation view when save/delete
@protocol EventEditorDelegate <NSObject>
@required
- (void)deleteEvent; //ATViewController will delete the selectedAnnotation, so no need to pass parameter
- (void)updateEvent:(ATEventDataStruct*)newData image:(UIImage*)imageData;
- (void)cancelEvent;

@end

@interface APActivityProvider : UIActivityItemProvider <UIActivityItemSource>
@property ATEventEditorTableController* eventEditor;
@end