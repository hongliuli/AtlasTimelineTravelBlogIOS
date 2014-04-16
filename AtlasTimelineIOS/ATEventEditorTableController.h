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
#import "ATPhotoScrollView.h"

@protocol EventEditorDelegate ;

@class ATViewController;
@class ATEventEntity;
@class ATEventDataStruct;

@interface ATEventEditorTableController : UITableViewController <UITextFieldDelegate, ATImagePickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    ATEventAnnotation * annotation;
}
@property int hasPhotoFlag;
@property int eventType;
@property ATPhotoScrollView* photoScrollView;
@property (strong, nonatomic) UIImageView* selectedPhoto; //set by ATPhotoScrollView didRowSelected
@property CLLocationCoordinate2D coordinate;
@property (strong, nonatomic) NSString* eventId;

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
- (void)createPhotoScrollView:(NSString*) photoDirName;
- (void)showPhotoView:(int)photoFileName image:(UIImage*)image;
- (void)deleteCallback:(NSString*) photoFileName;
- (void)resetEventEditor;
- (void)setShareCount;

//these can easily be assigne to BasePhotoViewController, but ImageScrollView also need, so make them static
+ (NSArray*) photoList;
+ (NSString*) eventId;
+ (void)setEventId:(NSString*)eventId;
+ (int) selectedPhotoIdx;
+ (void) setSelectedPhotoIdx:(int)idx;

@end

// I can save/delete Core Data here, but I will let these to be done in mapview by delegate since we have pass info back to update annotation view when save/delete
//ATViewController is designed to conform to this protocal, so it need implement
@protocol EventEditorDelegate <NSObject>
@required
- (void)deleteEvent; //ATViewController will delete the selectedAnnotation, so no need to pass parameter
- (void)updateEvent:(ATEventDataStruct*)newData newAddedList:(NSArray *)newAddedList deletedList:(NSArray*)deletedList thumbnailFileName:(NSString*)thumbNailFileName;
- (void)cancelEvent;
- (void)addToEpisode;
- (BOOL)isInEpisode;

@end

@interface APActivityProvider : UIActivityItemProvider <UIActivityItemSource>
@property ATEventEditorTableController* eventEditor;
@end