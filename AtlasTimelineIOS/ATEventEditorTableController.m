//
//  ATEventEditorTableController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/16/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATEventEditorTableController.h"
#import "ATEventEntity.h"
#import "ATEventDataStruct.h"
#import "ATAppDelegate.h"
#import "ATViewImagePickerController.h"
#import "BasePhotoViewController.h"
#import "ATHelper.h"
#import "ATConstants.h"
#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>

#define JPEG_QUALITY 1.0
#define THUMB_JPEG_QUALITY 0.3
#define RESIZE_WIDTH 1024
#define RESIZE_HEIGHT 768
#define THUMB_WIDTH 120
#define THUMB_HEIGHT 70

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

//iPad mini size as standard
#define EDITOR_PHOTOVIEW_WIDTH 400
#define EDITOR_PHOTOVIEW_HEIGHT 160

#define PHOTOVIEW_WIDTH 1024
#define PHOTOVIEW_HEIGHT 768

#define NOT_THUMBNAIL -1
#define ADD_PHOTO_BUTTON_TAG_777 777
#define DESC_TEXT_TAG_FROM_STORYBOARD_888 888
#define DATE_TEXT_FROM_STORYBOARD_999 999
#define ADDED_PHOTOSCROLL_TAG_900 900
#define NEWEVENT_DESC_PLACEHOLD @"Write notes here"
#define NEW_NOT_SAVED_FILE_PREFIX @"NEW"

@implementation ATEventEditorTableController

static NSArray* _photoList = nil;
static NSString* _eventId = nil;
static int _selectedPhotoIdx=0;

ATViewImagePickerController* imagePicker;

@synthesize delegate;
@synthesize description;
@synthesize address;
@synthesize dateTxt;
NSMutableArray *photoNewAddedList; //add after come back from photo picker
NSMutableArray *photoDeletedList; //add to this list if user click Remove in photoViewController
UIView* customViewForPhoto;

UILabel *lblTotalCount;
UILabel *lblNewAddedCount;
UILabel *lblShareCount;

UIAlertView *alertDelete;
UIAlertView *alertCancel;

NSMutableArray* markerPickerTitleList;
NSMutableArray* markerPickerImageNameList;
NSString* markerPickerSelectedItemName;
UIPickerView* markerPickerView;
UIToolbar* markerPickerToolbar; //treat it the same way as self.toolbar

int editorPhotoViewWidth;
int editorPhotoViewHeight;

#pragma mark UITableViewDelegate
/*
- (void)tableView: (UITableView*)tableView
  willDisplayCell: (UITableViewCell*)cell
forRowAtIndexPath: (NSIndexPath*)indexPath
{
    //cell.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];

}
 */
+ (NSArray*) photoList { return _photoList;}
+ (NSString*) eventId { return _eventId;}
+ (void) setEventId:(NSString *)evtId { _eventId = evtId;}
+ (int) selectedPhotoIdx { return _selectedPhotoIdx;}
+ (void) setSelectedPhotoIdx:(int)idx { _selectedPhotoIdx = idx; }

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer* tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = FALSE;
    [self.view addGestureRecognizer:tapper];
    self.dateTxt.delegate = self;
    editorPhotoViewWidth = EDITOR_PHOTOVIEW_WIDTH;
    editorPhotoViewHeight = EDITOR_PHOTOVIEW_HEIGHT;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        BOOL optionIPADFullScreenEditorFlag = [ATHelper getOptionEditorFullScreen];
        if (optionIPADFullScreenEditorFlag)
        {
            editorPhotoViewWidth = [ATConstants screenWidth];
            //editorPhotoViewHeight = [ATConstants screenHeight];
            CGRect frame = self.description.frame;
            frame.size.width = editorPhotoViewWidth;
            [self.description setFrame:frame];
            
            frame = self.address.frame;
            frame.size.width = editorPhotoViewWidth;
            [self.address setFrame:frame];
        }
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0 &&  indexPath.row == 0)
    {
       // ### IMPORTANT tick to remove cell background for the section 0's row 0
        cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return cell;
}
-(void) resetEventEditor //called by mapview whenever bring up event editor
{
    if (photoNewAddedList != nil)
        [photoNewAddedList removeAllObjects];
    if (photoDeletedList != nil)
        [photoDeletedList removeAllObjects];
    if (self.photoScrollView != nil)
    {
        [self.photoScrollView removeFromSuperview];
        self.photoScrollView = nil;
    }
    lblShareCount.text = NSLocalizedString(@"Share Event",nil);
    
    //customViewForPhoto = nil;
    
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* customView = nil;
    // create the parent view that will hold header Label
    if (section == 0)
    {
        //view for this section. Please refer to heightForHeaderInSection() function
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, editorPhotoViewWidth, editorPhotoViewHeight)];
        
        // create photo count display
        lblTotalCount = [[UILabel alloc] initWithFrame:CGRectMake(editorPhotoViewWidth - 180, editorPhotoViewHeight + 15, 20, 20)];
        lblNewAddedCount = [[UILabel alloc] initWithFrame:CGRectMake(editorPhotoViewWidth - 160, editorPhotoViewHeight + 15, 100, 20)];
        lblTotalCount.backgroundColor = [UIColor clearColor];
        lblNewAddedCount.backgroundColor = [UIColor clearColor];
        lblTotalCount.font = [UIFont fontWithName:@"Helvetica" size:13];
        lblNewAddedCount.font = [UIFont fontWithName:@"Helvetica" size:13];
        lblNewAddedCount.textColor = [UIColor redColor];
        [customView addSubview:lblTotalCount];
        [customView addSubview:lblNewAddedCount];
        
        // create the button object
        UIButton * photoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *thumb2 = [UIImage imageNamed:@"add-button-md.png"];
        [photoBtn setImage:thumb2 forState:UIControlStateNormal];
        photoBtn.frame = CGRectMake(50, editorPhotoViewHeight - 40, 48, 48);
        [photoBtn addTarget:self action:@selector(takePictureAction:) forControlEvents:UIControlEventTouchUpInside];
        photoBtn.tag = ADD_PHOTO_BUTTON_TAG_777;
        [customView addSubview:photoBtn];
        customViewForPhoto = customView;
        //tricky, see another comments with word "tricky"
        if (self.photoScrollView != nil && nil == [customViewForPhoto viewWithTag:ADDED_PHOTOSCROLL_TAG_900])
        {
            [customViewForPhoto addSubview:self.photoScrollView];
            [self.photoScrollView.horizontalTableView reloadData];
            UIView* addPhotoBtn = (UIButton*)[customViewForPhoto viewWithTag:ADD_PHOTO_BUTTON_TAG_777];
            [customViewForPhoto bringSubviewToFront:addPhotoBtn];
            [self updatePhotoCountLabel];
        }
    }
    else if (section == 2)
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 40.0)];
        
        //Label in the view
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 40)];
        label.backgroundColor = [UIColor clearColor];
        label.text = NSLocalizedString(@"Addr:",nil);
        [customView addSubview:label];
        
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shareButton.frame = CGRectMake(240, 0, 40, 30);
        [shareButton setImage:[UIImage imageNamed:@"share.png"] forState:UIControlStateNormal];
        [shareButton addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:shareButton];
        
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate.sourceName isEqual:@"myEvents"]) //can create episode on myEvents only
        {
            UIButton *episodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            episodeButton.frame = CGRectMake(170, 0, 40, 30);
            if ([self.delegate isInEpisode])
                [episodeButton setImage:[UIImage imageNamed:@"add-to-episode-folder-reverse.png"] forState:UIControlStateNormal];
            else
                [episodeButton setImage:[UIImage imageNamed:@"add-to-episode-folder.png"] forState:UIControlStateNormal];
            [episodeButton addTarget:self action:@selector(addToEpisodeAction:) forControlEvents:UIControlEventTouchUpInside];
            [customView addSubview:episodeButton];
        }
        UIButton *markerPicker = [UIButton buttonWithType:UIButtonTypeCustom];
        markerPicker.frame = CGRectMake(100, 0, 30, 30);
        [markerPicker setImage:[UIImage imageNamed:@"marker_star.png"] forState:UIControlStateNormal];
        [markerPicker setAlpha:0.8];
        [markerPicker addTarget:self action:@selector(markerPickerAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:markerPicker];
        
        lblShareCount = [[UILabel alloc] initWithFrame:CGRectMake(270, 0, 100, 40)];
        lblShareCount.font = [UIFont fontWithName:@"Helvetica" size:10];
        lblShareCount.backgroundColor = [UIColor clearColor];
        lblShareCount.text = @"";
        [customView addSubview:lblShareCount];
    }
    return customView;
}

- (void) setShareCount
{
    lblShareCount.text = [NSString stringWithFormat:NSLocalizedString(@"%d photo(s)",nil), self.photoScrollView.selectedAsShareIndexSet.count ];
}
 
//called by mapView after know eventId
- (void) createPhotoScrollView:(NSString *)photoDirName
{
    self.photoScrollView = [[ATPhotoScrollView alloc] initWithFrame:CGRectMake(0,5,editorPhotoViewWidth,editorPhotoViewHeight)];
    self.photoScrollView.tag = ADDED_PHOTOSCROLL_TAG_900;
    self.photoScrollView.eventEditor = self;
    if (self.photoScrollView.photoList == nil && photoDirName != nil) //photoDirName==nil if first drop pin in map
    {

        self.photoScrollView.photoList = [[NSMutableArray alloc] init];
        //read photo list and save tophotoScrollView
        NSError *error = nil;
        
        NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:photoDirName];
            
        NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
        if (tmpFileList != nil && [tmpFileList count] > 0)
        {
            self.photoScrollView.photoList = [NSMutableArray arrayWithArray:tmpFileList];
            //remove thumbnail file title
            [self.photoScrollView.photoList removeObject:@"thumbnail"];
            _photoList = self.photoScrollView.photoList;
        }
    }
    //tricky: in iPod, here will be called before viewForSectionHeader, so customViewForPhoto is nil
    if (customViewForPhoto != nil && nil == [customViewForPhoto viewWithTag:ADDED_PHOTOSCROLL_TAG_900]) 
    {
        [customViewForPhoto addSubview:self.photoScrollView];
        [self.photoScrollView.horizontalTableView reloadData];
        UIView* addPhotoBtn = (UIButton*)[customViewForPhoto viewWithTag:ADD_PHOTO_BUTTON_TAG_777];
        [customViewForPhoto bringSubviewToFront:addPhotoBtn];
        [self updatePhotoCountLabel];
    } //else it will process in viewForSectionHeader
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];

    CGFloat height = cell.contentView.frame.size.height;
    //in full screen editor, show large description
    if (indexPath.section == 1 &&  indexPath.row == 0)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            BOOL optionIPADFullScreenEditorFlag = [ATHelper getOptionEditorFullScreen];
            if (optionIPADFullScreenEditorFlag)
            {
                height = 200;
                CGRect frame = cell.contentView.frame;
                frame.size.height = 200;
                [cell.contentView setFrame:frame];
                CGRect frame2 = self.description.frame;
                frame2.size.height = 200;
                [self.description setFrame:frame2];
            }
        }

    }
    return height;
    // return the height of the particular row in the table view
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (section == 0)
        return editorPhotoViewHeight + 15; //IMPORTANT, this will decide where is clickable for my photoScrollView and Add Photo button. 15 is the gap between Date and photo scroll
    else if (section == 1)
        return 0;
    else
        return [super tableView:tableView heightForHeaderInSection:section];
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    if (section == 0)
        return 0; //IMPORTANT, this will decide where is clickable for my photoScrollView
    else
        return [super tableView:tableView heightForFooterInSection:section];
}
//called by photoScrollView's didSelect...
-(void)showPhotoView:(int)photoFileName image:image
{
    //use Modal with Done button is good both iPad/iPhone
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard* storyboard = appDelegate.storyBoard;
    BasePhotoViewController* ctr = [storyboard instantiateViewControllerWithIdentifier:@"photo_view"];
    ctr.eventEditor = self;
    //[self presentModalViewController:ctr animated:YES]; //ATPhotoScrollViewController::viewDidLoad will be called
    [self presentViewController:ctr animated:YES completion:nil];
    ctr.pageControl.numberOfPages = [self.photoScrollView.photoList count];
    ctr.pageControl.currentPage = self.photoScrollView.selectedPhotoIndex; //This is very strange, I have to go to storyboard and set PageControll's number Of Page to a big number such as 999, instead of default 3, otherwise my intiall page will always stay at 3.
    ctr.photoList = self.photoScrollView.photoList;
    //[self presentViewController:ctr animated:false completion:nil];


   // [ctr imageView].contentMode = UIViewContentModeScaleAspectFit;
   // [ctr imageView].clipsToBounds = YES;
   // [[ctr imageView] setImage:image];
   // [ctr showCount];
}

-(void)takePictureAction:(id)sender
{
    self.hasPhotoFlag = EVENT_TYPE_NO_PHOTO;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard* storyboard = appDelegate.storyBoard;
    imagePicker = [storyboard instantiateViewControllerWithIdentifier:@"image_picker"];
    imagePicker.delegate = self;
    //Use Modal with Done button is good for both iPad/iPhone
    //[self presentModalViewController:imagePicker animated:YES];
    [self presentViewController:imagePicker animated:YES completion:nil];
}
- (IBAction)shareButtonAction:(id)sender {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    BOOL isAtLeast6 = [version compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending;
    if (isAtLeast6)
    {
        //how to send html email, or how to send different items depends on selected service Facebook/twitter/email etc
        //this one is the best: http://www.albertopasca.it/whiletrue/2012/10/objective-c-custom-uiactivityviewcontroller-icons-text/
        // In above, ignore UIActivities, we do not need, just need Provider to reutn items based on type of service. Following is
        //   another exact sample to have customized provide for items:
        //http://stackoverflow.com/questions/12639982/uiactivityviewcontroller-customize-text-based-on-selected-activity
        //But how to give email subject? this does not help: http://stackoverflow.com/questions/12769499/override-uiactivityviewcontroller-default-behaviour
        
        //Aggregated Questions http://stackoverflow.com/questions/tagged/uiactivityviewcontroller

        //I need have provider to send HTMl for email and text for tweeter
        
        if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook] && ![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Account"
                                                                message:@"Facebook and Twitter have not setup! Please go to the device settings and add account to Facebook or Twitter. Or you can continues to send by email."
                                                               delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alertView show];
        }
        
        APActivityProvider *ActivityProvider = [[APActivityProvider alloc] init];
        ActivityProvider.eventEditor = self;
        NSMutableArray *activityItems = [[NSMutableArray alloc] init];
    
        if (self.photoScrollView.photoList != nil && [self.photoScrollView.photoList count] > 0)
        {
            for (int selectedIndex = 0; selectedIndex < [self.photoScrollView.photoList count] ; selectedIndex++)
            {
                if ([self.photoScrollView.selectedAsShareIndexSet containsObject:[NSNumber numberWithInt:selectedIndex ]])
                {
                    NSString* photoForShareName = self.photoScrollView.photoList[selectedIndex];
                    NSString* photoFullPath = [[[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:self.eventId] stringByAppendingPathComponent:photoForShareName];
                    if ([photoForShareName hasPrefix:NEW_NOT_SAVED_FILE_PREFIX]) //in case selected a unsaved image for share
                        photoFullPath = [[ATHelper getNewUnsavedEventPhotoPath] stringByAppendingPathComponent:photoForShareName];
                    UIImage* img = [UIImage imageWithContentsOfFile:photoFullPath];
                    [activityItems addObject:img];
                }
            }
        } 
        [activityItems addObject:ActivityProvider];
        
        UIActivityViewController *activityController =
        [[UIActivityViewController alloc]
         initWithActivityItems:activityItems
         applicationActivities:nil];
        activityController.excludedActivityTypes = [NSArray arrayWithObjects: UIActivityTypePrint,UIActivityTypeAssignToContact,UIActivityTypeCopyToPasteboard, UIActivityTypeMessage, nil];
        //Finally can set subject in email with following line (01/05/2014)
        NSString* emailSubject = [ATHelper clearMakerAllFromDescText: self.description.text];
        if ([emailSubject length] > 50)
            emailSubject = [NSString stringWithFormat:@"%@...",[emailSubject substringToIndex:50]];
        [activityController setValue:emailSubject forKey:@"subject"];
    
        [self presentViewController:activityController
                       animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Available for iOS6 or above"
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}
- (void)markerPickerAction:(id)sender {

    
    markerPickerTitleList = [[NSMutableArray alloc] init];
    markerPickerImageNameList = [[NSMutableArray alloc] init];
    [markerPickerTitleList addObject:@"Default"];
    [markerPickerTitleList addObject:@"Star"];
    [markerPickerTitleList addObject:@"Eat/Food"];
    [markerPickerTitleList addObject:@"Hotel/Bed"];
    [markerPickerTitleList addObject:@"Transportation"];
    [markerPickerTitleList addObject:@"Air Port"];
    [markerPickerTitleList addObject:@"Scenary/View"];
    [markerPickerTitleList addObject:@"Historical"];
    [markerPickerTitleList addObject:@"Art/Museum"];
    [markerPickerTitleList addObject:@"Party"];
    [markerPickerTitleList addObject:@"Uncertain"];
    [markerPickerTitleList addObject:@"Information"];
    [markerPickerTitleList addObject:@"Hiking"];
    [markerPickerTitleList addObject:@"Wildlife"];
    [markerPickerTitleList addObject:@"School"];
    [markerPickerTitleList addObject:@"Hospital"];
    
    [markerPickerImageNameList addObject:@"marker_selected.png"];
    [markerPickerImageNameList addObject:@"marker_star.png"];
    [markerPickerImageNameList addObject:@"marker_food.png"];
    [markerPickerImageNameList addObject:@"marker_bed.png"];
    [markerPickerImageNameList addObject:@"marker_bus.png"];
    [markerPickerImageNameList addObject:@"marker_airport.png"];
    [markerPickerImageNameList addObject:@"marker_view.png"];
    [markerPickerImageNameList addObject:@"marker_historical.png"];
    [markerPickerImageNameList addObject:@"marker_art.png"];
    [markerPickerImageNameList addObject:@"marker_party.png"];
    [markerPickerImageNameList addObject:@"marker_question.png"];
    [markerPickerImageNameList addObject:@"marker_info.png"];
    [markerPickerImageNameList addObject:@"marker_hiking.png"];
    [markerPickerImageNameList addObject:@"marker_wildlife.png"];
    [markerPickerImageNameList addObject:@"marker_school.png"];
    [markerPickerImageNameList addObject:@"marker_hospital.png"];
    
    markerPickerSelectedItemName = [ATHelper getMarkerNameFromDescText:self.description.text];
    markerPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 215, 360, 440)];
    markerPickerView.delegate = self;
    markerPickerView.showsSelectionIndicator = YES;
    
    if (markerPickerSelectedItemName != nil)
    {
        NSString* markerImageName = [NSString stringWithFormat:@"marker_%@.png", markerPickerSelectedItemName];
        int index = [markerPickerImageNameList indexOfObject:markerImageName];
        if (index != NSNotFound)
        {
            [markerPickerView selectRow:index inComponent:0 animated:NO];
        }
    }
    
    markerPickerToolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 380, 320, 44)];
    markerPickerView.backgroundColor = [UIColor colorWithRed: 0.95 green: 0.95 blue: 0.95 alpha: 1.0];
    [markerPickerToolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Done",nil) style: UIBarButtonItemStyleDone target: self action: @selector(markerPicked:)];
    doneButton.width = 50;
    doneButton.tintColor = [UIColor blueColor];
    markerPickerToolbar.items = [NSArray arrayWithObject: doneButton];
 
    [self.view addSubview:markerPickerView];
    [self.view addSubview: markerPickerToolbar];
    self.saveButton.enabled = false;
    
}
-(void)textFieldDidBeginEditing:(UITextField*)textField
{
 }
//[2014-01-21] change following code from textFieldDidBegingEditing to shouldBeginEditing, and return false to disable keybord (should configurable to enable keyboarder for BC input
//       This change resolved a big headache in iPad: click desc/address to bring keypad, then date field, will leave keypad always displayed.
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField.tag == DATE_TEXT_FROM_STORYBOARD_999) { //999 is for date textField in storyboard
        NSString* bcDate = self.dateTxt.text;
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSDateFormatter *dateFormater = appDelegate.dateFormater;
        NSDate* tmpDate = [dateFormater dateFromString:bcDate];
        //if date is already a a BC date, datePicker will crash, so do not show date picker if is a BC date
        if (bcDate != nil && [ATHelper isBCDate:tmpDate])
            return true;

        if (self.datePicker == nil) //will be nill if clicked Done button
        {
            self.datePicker = [[UIDatePicker alloc] init];
            
            
            //[UIView appearanceWhenContainedIn:[UITableView class], [UIDatePicker class], nil].backgroundColor = [UIColor colorWithWhite:1 alpha:1];
            
            self.datePicker.backgroundColor = [UIColor colorWithRed: 0.95 green: 0.95 blue: 0.95 alpha: 1.0];
            
            
            [self.datePicker setFrame:CGRectMake(0,240,320,180)];
            
            [self.datePicker addTarget:self action:@selector(changeDateInLabel:) forControlEvents:UIControlEventValueChanged];
            self.datePicker.datePickerMode = UIDatePickerModeDate;
            
            [self.view addSubview:self.datePicker];
            
            self.toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 380, 320, 44)];
            //[self.toolbar setBackgroundColor:[UIColor clearColor]];
            [self.toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
            
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle: @"Done" style: UIBarButtonItemStyleDone target: self action: @selector(datePicked:)];
            doneButton.width = 50;
            doneButton.tintColor = [UIColor blueColor];
            self.toolbar.items = [NSArray arrayWithObject: doneButton];
            
            
            [self.view addSubview: self.toolbar];
            
        }
        
        if ([self.dateTxt.text isEqualToString: @""] || self.dateTxt.text == nil)
        {
            self.datePicker.date = [[NSDate alloc] init];
            self.dateTxt.text = [NSString stringWithFormat:@"%@",
                                 [dateFormater stringFromDate:self.datePicker.date]];
        }
        else
        {
            //if date is already a a BC date, datePicker will crash here, so have the first line check above, so do not show date picker if is a BC date
            NSDate* dt = [dateFormater dateFromString:self.dateTxt.text];
            if (dt != nil)
                self.datePicker.date = dt;
            else
                self.datePicker.date = [[NSDate alloc] init];
        }
        self.cancelButton.enabled = false;
        self.saveButton.enabled = false;
        self.deleteButton.enabled = false;
        self.address.hidden=true;
        self.address.backgroundColor = [UIColor darkGrayColor];//do not know why this does not work, however it does not mappter
    }
    if ([ATHelper getOptionDateFieldKeyboardEnable])
        return YES;
    else
        return NO;  // Hide both keyboard and blinking cursor.
}
- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    if (textView.tag == DESC_TEXT_TAG_FROM_STORYBOARD_888) //this is description text, emilate placehold situation
    {
        if ([self.description.text hasPrefix: NEWEVENT_DESC_PLACEHOLD])
        {
            self.description.textColor = [UIColor blackColor];
            self.description.text= [self.description.text stringByReplacingOccurrencesOfString:NEWEVENT_DESC_PLACEHOLD withString:@""];
        }
    }
    return YES;
}
- (IBAction)saveAction:(id)sender {
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter *dateFormater = appDelegate.dateFormater;
    ATEventDataStruct *ent = [[ATEventDataStruct alloc] init];
    ent.eventDesc = self.description.text;
    ent.address = self.address.text;
    ent.uniqueId = nil;
    NSDate* dt = [dateFormater dateFromString:self.dateTxt.text ];
    if (dt == nil)  //this could happen if edit a BC date where DatePicker is not allowed popup
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wrong Date Format",nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"The correct date format is MM/dd/yyyy Era (such as %@)",nil),appDelegate.localizedAD]
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //A bug fix, "\n" is treated as empty, thus the event became untapable. (a long time bug, just found 03/22/14)
    NSString* descTxt = self.description.text;
    descTxt = [descTxt stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    descTxt = [descTxt stringByReplacingOccurrencesOfString:@" " withString:@""];
    descTxt = [ATHelper clearMakerAllFromDescText:descTxt];
    if (descTxt == nil || descTxt.length == 0)
    {  //#### have to have this check, otherwise the eventEditor will not popup
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Description field may not be empty. (keep tag <<...>> if there is one)",nil)
                message:NSLocalizedString(@"Please enter description.",nil)
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
        [alert show];
        return;
    }
    ent.eventDate = dt;

    ent.eventType = self.eventType;
    //see doneSelectPicture() which will set if there is a picture
    if ([self.photoScrollView.photoList count] > 0 || [photoNewAddedList count] > 0) //1 means has photo so mapView will show thumbnail
        ent.eventType = 1;
    else
        ent.eventType = 0;
    
    //else
        //imageToBeWritten = nil; //if no photo taken this time, no need write to file again
    
    //have to ask ATViewController to write photo files, because for new event, we do not have id for photo directory names yet
    //photoViewController will write which to delete and wihich to set as thumbnail etc
    NSString* thumbNailFileName = nil;
    int thumbNailIndex = self.photoScrollView.selectedAsThumbnailIndex;
    if (thumbNailIndex >= 0 && thumbNailIndex < [self.photoScrollView.photoList count])
        thumbNailFileName = self.photoScrollView.photoList[thumbNailIndex];
        
    [self.delegate updateEvent:ent newAddedList:photoNewAddedList deletedList:photoDeletedList thumbnailFileName:thumbNailFileName];
    [self dismissViewControllerAnimated:NO completion:nil]; //for iPhone case
}

- (IBAction)deleteAction:(id)sender {
    int cnt = [self.photoScrollView.photoList count] ;
    NSString* promptStr = NSLocalizedString(@"This event will be deleted!",nil);
    if (cnt > 0)
    {
        promptStr = [NSString stringWithFormat:NSLocalizedString(@"%d photo(s) in the event will be deleted as well",nil),cnt];
    }
    alertDelete = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Confirm to delete the event",nil)
                                            message: promptStr
                                           delegate: self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"Delete",nil];
    [alertDelete show];

    [self dismissViewControllerAnimated:NO completion:nil]; //for iPhone case
}
- (IBAction)addToEpisodeAction:(id)sender {
    if (self.eventId == nil)
        return;
    [self.delegate addToEpisode];
    [self dismissViewControllerAnimated:NO completion:nil]; //for iPhone case
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == alertDelete)
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user canceled upload");
            // Any action can be performed here
        }
        else if (buttonIndex == 1)
        {
            //will delete selected event from annotation/db
            [self.delegate deleteEvent];
        }
    }
    if (alertView == alertCancel)
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user canceled upload");
            // Any action can be performed here
        }
        else if (buttonIndex == 1)
        {
            //will delete selected event from annotation/db
            [self.delegate cancelEvent];
        }
    }
}

- (IBAction)cancelAction:(id)sender {
    int cnt = [photoNewAddedList count] ;
    if (cnt > 0)
    {
        alertCancel = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"%d new photo(s) are not saved",nil),cnt]
                                                message: [NSString stringWithFormat:NSLocalizedString(@"Cancel will lose your new photos.",nil)]
                                               delegate: self
                                      cancelButtonTitle:NSLocalizedString(@"Do not cancel",nil)
                                      otherButtonTitles:NSLocalizedString(@"Quit w/o save",nil),nil];
        
        
        [alertCancel show];
    }
    else
        [self.delegate cancelEvent];

    [self dismissViewControllerAnimated:NO completion:nil]; //for iPhone case
}

- (void)changeDateInLabel:(id)sender{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter *dateFormater = appDelegate.dateFormater;
    dateTxt.text = [NSString stringWithFormat:@"%@",
            [dateFormater stringFromDate:self.datePicker.date]];
}

- (void)datePicked:(id)sender{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter *dateFormater = appDelegate.dateFormater;
    NSDate* dt = [dateFormater dateFromString:self.dateTxt.text];
    if (dt != nil)
    {
        [self.datePicker removeFromSuperview];
        [self.toolbar removeFromSuperview];
        self.datePicker = nil;
        self.toolbar = nil;
        
        self.cancelButton.enabled = true;
        self.saveButton.enabled = true;
        self.deleteButton.enabled = true;
        self.address.hidden=false;
        self.address.backgroundColor = [UIColor whiteColor];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wrong Date Format",nil)
                message:[NSString stringWithFormat:NSLocalizedString(@"The correct date format is MM/dd/yyyy Era (such as %@)",nil),appDelegate.localizedAD]
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
        [alert show];
    }
}

- (void)markerPicked:(id)sender{
    [markerPickerView removeFromSuperview];
    [markerPickerToolbar removeFromSuperview];
    
    self.saveButton.enabled = true;
    
    if (markerPickerSelectedItemName == nil)
        return; //do nothing if previously has no marker and user did not picker any marker
    
    NSString* toBeReplacedMarkerName = [ATHelper getMarkerNameFromDescText: self.description.text];
    if (toBeReplacedMarkerName != nil)
    {
        self.description.text = [ATHelper clearMakerFromDescText: self.description.text :toBeReplacedMarkerName];
    }
    if (![markerPickerSelectedItemName isEqualToString:@"selected"])
        self.description.text = [NSString stringWithFormat:@"%@\n<<%@>>",self.description.text,markerPickerSelectedItemName];

}


//callback from imagePicker Controller
- (void)doneSelectPictures:(NSMutableArray*)images
{
    for (int i = 0; i<[images count]; i++)
    {
        [self doneSelectedPicture:images[i] :i ];
    }
}

- (void)doneSelectedPicture:(UIImage*)newPhoto :(int)idx
{
    if (newPhoto == nil)
        return;
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_hh_mm_ss"];
    //save to a temparay file
    NSString* timeStampPhotoName = [formatter stringFromDate:[NSDate date]];
    timeStampPhotoName = [NSString stringWithFormat:@"%@_%d", timeStampPhotoName,idx];

    NSString* tmpFileNameForNewPhoto = [NSString stringWithFormat:@"%@%@", NEW_NOT_SAVED_FILE_PREFIX,timeStampPhotoName];
    if (self.photoScrollView.photoList == nil)
        self.photoScrollView.photoList = [NSMutableArray arrayWithObjects:tmpFileNameForNewPhoto, nil];
    else
        [self.photoScrollView.photoList addObject:tmpFileNameForNewPhoto];//Note tmpFile.. is add, later in cellForTableview will check if file lenght is 8 then get file from temp directory
    if (photoNewAddedList == nil)
        photoNewAddedList = [NSMutableArray arrayWithObjects:timeStampPhotoName, nil];
    else
        [photoNewAddedList addObject:timeStampPhotoName]; //so later mapView will move above new added file to real location
    //Save new photo to a temp location, so when user really tap save event, mapview will copy these temp photos to perment place
    self.hasPhotoFlag = EVENT_TYPE_HAS_PHOTO; //saveAction will write this to eventType. save image file will be in ATViewController's updateEvent because only there we can get uniqueId as filename
    //Write file to temp location before user tap event save button
    int imageWidth = RESIZE_WIDTH;
    int imageHeight = RESIZE_HEIGHT;
    
    if (newPhoto.size.height > newPhoto.size.width)
    {
        imageWidth = RESIZE_HEIGHT;
        imageHeight = RESIZE_WIDTH;
    }
    UIImage *newImage = newPhoto;
    NSData* imageData = nil;
    if (newPhoto.size.height > imageHeight || newPhoto.size.width > imageWidth)
    {
        newImage = [ATHelper imageResizeWithImage:newPhoto scaledToSize:CGSizeMake(imageWidth, imageHeight)];
    }
    //NSLog(@"widh=%f, height=%f",newPhoto.size.width, newPhoto.size.height);
    imageData = UIImageJPEGRepresentation(newImage, JPEG_QUALITY); //quality should be configurable?
    NSString *fullPathToNewTmpPhotoFile = [[ATHelper getNewUnsavedEventPhotoPath] stringByAppendingPathComponent:tmpFileNameForNewPhoto];
    NSError *error;
    [imageData writeToFile:fullPathToNewTmpPhotoFile options:nil error:&error];
   // NSLog(@"%@",[error localizedDescription]);
   // NSLog(@"write to file success or not: %d", writeFlag);

    [self updatePhotoCountLabel];
    
    [self.photoScrollView.horizontalTableView reloadData];
    
    NSIndexPath* ipath = [NSIndexPath indexPathForRow: [self.photoScrollView.photoList count]-1 inSection: 0];
    [self.photoScrollView.horizontalTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionTop animated: YES];

}

//especially add this for iPhone to dismiss keyboard when touch any where eolse
- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}
- (void)deleteCallback:(NSString*)photoFileName
{
    if (photoDeletedList == nil)
        photoDeletedList = [NSMutableArray arrayWithObjects:photoFileName, nil];
    else
        [photoDeletedList addObject:photoFileName];
    //For new added photo, the name in photoNewAddedList is still in final format, so need to do something special
    if ([photoFileName hasPrefix:NEW_NOT_SAVED_FILE_PREFIX])
    {
        NSString* finalFileName = [photoFileName substringFromIndex:[NEW_NOT_SAVED_FILE_PREFIX length]];
        [photoNewAddedList removeObject:finalFileName];
        [photoDeletedList removeObject:photoFileName]; //do not add new-created file to delete list
    }
    [self.photoScrollView.photoList removeObject:photoFileName];
    [self.photoScrollView.horizontalTableView reloadData];
    [self updatePhotoCountLabel];
}

- (void)updatePhotoCountLabel
{
    //Change total/new added photos count
    lblTotalCount.text = [NSString stringWithFormat:@"%d", [self.photoScrollView.photoList count] ];
    lblNewAddedCount.text = [NSString stringWithFormat:NSLocalizedString(@"[+%d/-%d unsaved!]",nil), [photoNewAddedList count], [photoDeletedList count] ];//color is red so use separate lbl
    if ([photoNewAddedList count] == 0 && [photoDeletedList count] == 0)
        lblNewAddedCount.hidden = true;
    else
        lblNewAddedCount.hidden = false;
}

- (void)viewDidUnload {
    [self setDateTxt:nil];
    [super viewDidUnload];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    // Handle the selection
    NSString* pngName = markerPickerImageNameList[row];
    markerPickerSelectedItemName = [pngName substringToIndex:[pngName rangeOfString:@"."].location];
    markerPickerSelectedItemName = [markerPickerSelectedItemName substringFromIndex:[markerPickerSelectedItemName rangeOfString:@"_"].location +1];
}

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return markerPickerImageNameList.count;
}


- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row
          forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UIImage *img = [UIImage imageNamed:[markerPickerImageNameList objectAtIndex:row]];
    UIImageView *icon = [[UIImageView alloc] initWithImage:img];
    [icon setFrame:CGRectMake(0, 0, 32, 32)];
    
    UILabel *firstLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 150, 32)];
    firstLabel.text = [markerPickerTitleList objectAtIndex:row];
    firstLabel.textAlignment = NSTextAlignmentLeft;
    firstLabel.backgroundColor = [UIColor clearColor];
    
    UIView *tmpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 32)];
    [tmpView insertSubview:icon atIndex:0];
    [tmpView insertSubview:firstLabel atIndex:0];
    [tmpView setUserInteractionEnabled:NO];
    [tmpView setTag:row];
    return tmpView;
}

@end




//-------------------------------------------------   APActivityProvider Interface ------------
@implementation APActivityProvider
- (id) activityViewController:(UIActivityViewController *)activityViewController
          itemForActivityType:(NSString *)activityType
{
    NSString* eventDescText = [ATHelper clearMakerAllFromDescText:self.eventEditor.description.text];
    NSString* dateStr = self.eventEditor.dateTxt.text;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter *dateFormater = appDelegate.dateFormater;
    NSDate* date = [dateFormater dateFromString:self.eventEditor.dateTxt.text];
    if (![ATHelper isBCDate:date])
        dateStr = [dateStr substringWithRange:NSMakeRange(0, 10)];
        
    NSString *googleMap = [NSString stringWithFormat:@"https://maps.google.com/maps?q=%f,%f&spn=65.61535,79.013672",self.eventEditor.coordinate.latitude, self.eventEditor.coordinate.longitude ];
    NSString* appStoreUrl= @"https://itunes.apple.com/us/app/chroniclemap-events-itinerary/id649653093?ls=1&mt=8";

    if ( [activityType isEqualToString:UIActivityTypeMail] )
    {
        
        return [NSString stringWithFormat:@"<html><body>[%@] %@<br><a href='%@'>Map Location</a>&nbsp;&nbsp;&nbsp;<br><br>Organized with <a href='%@'>ChronicleMap</a>.",dateStr, eventDescText,googleMap,appStoreUrl];;
    }
    else
    {
        return [NSString stringWithFormat:NSLocalizedString(@"[%@] %@\n\n Map Location:%@      (Organized with ChronicleMap.com)",nil),dateStr, eventDescText, googleMap];
    }
}
- (id) activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController { return @""; }

@end