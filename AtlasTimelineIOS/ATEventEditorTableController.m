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
#import <iAd/iAd.h>

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
#define NEWEVENT_DESC_PLACEHOLD NSLocalizedString(@"Write notes here",nil)
#define NEW_NOT_SAVED_FILE_PREFIX @"NEW"

#define AUTHOR_MODE_KEY @"AUTHOR_MODE_KEY"

#define SECTION_1_ADVERTISE_HEIGHT 40
#define SECTION_2_HEIGHT 40

#define PHOTO_META_FILE_NAME @"MetaFileForOrderAndDesc"
#define PHOTO_META_SORT_LIST_KEY @"sort_key"
#define PHOTO_META_DESC_MAP_KEY @"desc_key"

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

int editorPhotoViewWidth;
int editorPhotoViewHeight;


NSMutableDictionary *photoFilesMetaMap;

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
    self.description.editable = false;
    self.description.dataDetectorTypes = UIDataDetectorTypeLink;
    //CGRect frame = self.description.frame;
    CGRect frame = CGRectMake(0, 0, 0, 0);
    frame.size.width = EDITOR_PHOTOVIEW_WIDTH - 20;
    frame.size.height = [self getEventEditorDescriptionHeight ];
    [self.description setFrame:frame];
    self.description.font =[UIFont fontWithName:@"Helvetica" size:15];
    BOOL optionIPADFullScreenEditorFlag = [ATHelper getOptionEditorFullScreen];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && optionIPADFullScreenEditorFlag)
        || (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone))
    {
        editorPhotoViewWidth = [ATConstants screenWidth];
        //editorPhotoViewHeight = [ATConstants screenHeight];
        CGRect frame = self.description.frame;
        frame.size.width = editorPhotoViewWidth;
            
        [self.description setFrame:frame];
        self.description.font =[UIFont fontWithName:@"Helvetica" size:19];
        
        frame = self.address.frame;
        frame.size.width = editorPhotoViewWidth;
        [self.address setFrame:frame];
    }
    self.address.backgroundColor = [UIColor clearColor]; // [UIColor colorWithRed:1 green:1 blue:1 alpha:0.4];
    self.description.backgroundColor = [UIColor whiteColor];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* currentAuthorMode = [userDefault valueForKey:AUTHOR_MODE_KEY];
    
    if (currentAuthorMode == nil || [currentAuthorMode isEqualToString:@"VIEW_MODE"])
    {
        self.authorModeFlag = false;
    }
    else
    {
        self.authorModeFlag = true;
    }
    
    // I did not use iOS7's self.canDisplayBannerAds to automatically display adds, not sure why
    //if (ipad)
    [self initiAdBanner];
    [self initgAdBanner];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0 &&  indexPath.row == 0)
    {
       // ### IMPORTANT trick to remove cell background for the section 0's row 0
        cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    cell.contentView.backgroundColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor whiteColor];
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
        
       // create the button object
        self.photoAddBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *thumb2 = [UIImage imageNamed:@"add-button-md.png"];
        [self.photoAddBtn setImage:thumb2 forState:UIControlStateNormal];
        self.photoAddBtn.frame = CGRectMake(50, editorPhotoViewHeight - 40, 48, 48);
        [self.photoAddBtn addTarget:self action:@selector(takePictureAction:) forControlEvents:UIControlEventTouchUpInside];
        self.photoAddBtn.tag = ADD_PHOTO_BUTTON_TAG_777;
        customView.backgroundColor = [UIColor clearColor];
        [customView addSubview:self.photoAddBtn];
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
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0, 300.0, SECTION_2_HEIGHT)];
        
        //Label in the view
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 200, SECTION_2_HEIGHT)];
        label.backgroundColor = [UIColor clearColor];
        label.text = NSLocalizedString(@"Tags, Address:",nil);
        [customView addSubview:label];
        
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shareButton.frame = CGRectMake(280, 0, 30, 30);
        [shareButton setImage:[UIImage imageNamed:@"share.png"] forState:UIControlStateNormal];
        [shareButton addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:shareButton];
        UIButton *sizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sizeButton.frame = CGRectMake(210, 0, 30, 30);
        BOOL fullFlag = [ATHelper getOptionEditorFullScreen];
        if (fullFlag)
            [sizeButton setImage:[UIImage imageNamed:@"window_minimize.png"] forState:UIControlStateNormal];
        else
            [sizeButton setImage:[UIImage imageNamed:@"window_maximize.png"] forState:UIControlStateNormal];
        
        [sizeButton addTarget:self action:@selector(sizeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            [customView addSubview:sizeButton];
        
        self.photoSaveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.photoSaveBtn setTitle:@"Save Photo" forState:UIControlStateNormal];
        [self.photoSaveBtn setBackgroundColor:[UIColor blueColor]];
        [self.photoSaveBtn addTarget:self action:@selector(saveAction:) forControlEvents:UIControlEventTouchUpInside];
        self.photoSaveBtn.frame = CGRectMake(10, 0, 190, 30);
        customView.backgroundColor = [UIColor clearColor];
        [customView addSubview:self.photoSaveBtn];
        
        if (self.authorModeFlag) {
            self.photoAddBtn.hidden = false;
            self.photoSaveBtn.hidden = false;
        }
        else
        {
            self.photoAddBtn.hidden = true;
            self.photoSaveBtn.hidden = true;
        }
    }
    else if (section ==  1 && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) //advertize
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0, 300.0, SECTION_1_ADVERTISE_HEIGHT)];
        [customView addSubview:self.gAdBannerView];
        [customView addSubview:self.iAdBannerView];
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
    if (photoDirName == nil)
        self.isFirstTimeAddPhoto = true;
    if (self.photoScrollView.photoList == nil && photoDirName != nil) //photoDirName==nil if first drop pin in map
    {

        self.photoScrollView.photoList = [[NSMutableArray alloc] init];
        //read photo list and save tophotoScrollView
        NSError *error = nil;
        NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:photoDirName];
        
        NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
        if(error != nil) {
            NSLog(@"Error in reading files: %@", [error localizedDescription]);
            self.isFirstTimeAddPhoto = true;
            return;
        }
        if ([tmpFileList count] == 0)
            self.isFirstTimeAddPhoto = true;
        else
            self.isFirstTimeAddPhoto = false;
        
        self.photoScrollView.photoList = [NSMutableArray arrayWithArray:tmpFileList];
        //Sort photo list. The sort will be saved to dropbox as a file together with photo description
        NSString *photoMetaFilePath = [[[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:self.eventId] stringByAppendingPathComponent:PHOTO_META_FILE_NAME];
        
        //photoFileMetaMap will be nil if no file ???
        photoFilesMetaMap = [NSDictionary dictionaryWithContentsOfFile:photoMetaFilePath];
        if (photoFilesMetaMap != nil)
        {
            self.photoScrollView.photoSortedNameList = (NSMutableArray*)[photoFilesMetaMap objectForKey:PHOTO_META_SORT_LIST_KEY];
            self.photoScrollView.photoDescMap = [photoFilesMetaMap objectForKey:PHOTO_META_DESC_MAP_KEY];
        }
        //Although photoSortedNameList should have all filenames in order, to be safe, still read filename from directory then sort accordingly
        if (self.photoScrollView.photoSortedNameList != nil)
        {
            NSMutableArray* newList = [[NSMutableArray alloc] initWithCapacity:[self.photoScrollView.photoList count]];
            int tmpCnt = [self.photoScrollView.photoSortedNameList count];
            for (int i = 0; i < tmpCnt; i++)
            {
                NSString* fileName = self.photoScrollView.photoSortedNameList[i];
                if ([self.photoScrollView.photoList containsObject:fileName])
                    [newList addObject: fileName];
            }
            for (int i = 0; i < tmpCnt; i++)
            {
                NSString* fileName = self.photoScrollView.photoSortedNameList[i];
                [self.photoScrollView.photoList removeObject:fileName];
            }
            [newList addObjectsFromArray:self.photoScrollView.photoList];
            self.photoScrollView.photoList = newList;
        }
        //remove thumbnail file title
        [self.photoScrollView.photoList removeObject:@"thumbnail"];
        [self.photoScrollView.photoList removeObject:PHOTO_META_FILE_NAME];
        _photoList = self.photoScrollView.photoList;
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
        height = [self getEventEditorDescriptionHeight]; //value for non-full screen iPad
        
        CGRect frame = cell.contentView.frame;
        frame.size.height = height;
        [cell.contentView setFrame:frame];
        
        CGRect frame2 = self.description.frame;
        frame2.size.height = height;
        [self.description setFrame:frame2];

    }
    return height;
    // return the height of the particular row in the table view
}

- (int) getEventEditorDescriptionHeight
{
    int height = 0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        height = 130; //value for non-full screen iPad
        BOOL optionIPADFullScreenEditorFlag = [ATHelper getOptionEditorFullScreen];
        if (optionIPADFullScreenEditorFlag)
        {
            height = 300; //value for full screen iPad
        }
    }
    else
    {
        height = 200;
    }
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (section == 0)
        return editorPhotoViewHeight + 15; //IMPORTANT, this will decide where is clickable for my photoScrollView and Add Photo button. 15 is the gap between Date and photo scroll
    else if (section == 1)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            return SECTION_1_ADVERTISE_HEIGHT;
        else
            return 0;
    }
    else if (section == 2)
        return SECTION_2_HEIGHT;
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
- (IBAction)sizeButtonAction:(id)sender {
    //xxxx
    BOOL fullFlag = [ATHelper getOptionEditorFullScreen];
    [ATHelper setOptionEditorFullScreen:!fullFlag];
    [self.delegate cancelEvent];
    [self dismissViewControllerAnimated:NO completion:nil]; //for iPhone case
    [self.delegate restartEditor];
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

-(void)textFieldDidBeginEditing:(UITextField*)textField
{
 }
//[2014-01-21] change following code from textFieldDidBegingEditing to shouldBeginEditing, and return false to disable keybord (should configurable to enable keyboarder for BC input
//       This change resolved a big headache in iPad: click desc/address to bring keypad, then date field, will leave keypad always displayed.
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    //if (textField.tag == DATE_TEXT_FROM_STORYBOARD_999) { //999 is for date textField in storyboard
        return false; //disable datetext editing, make it readonly
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

    ATEventDataStruct *ent = [[ATEventDataStruct alloc] init];
    ent.eventDesc = self.description.text;
    ent.address = self.address.text;
    ent.uniqueId = nil;
    
    //A bug fix, "\n" is treated as empty, thus the event became untapable. (a long time bug, just found 03/22/14)
    NSString* descTxt = self.description.text;
    descTxt = [descTxt stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    descTxt = [descTxt stringByReplacingOccurrencesOfString:@" " withString:@""];
    descTxt = [ATHelper clearMakerAllFromDescText:descTxt];

    ent.eventType = self.eventType;
    //see doneSelectPicture() which will set if there is a picture
    if ([self.photoScrollView.photoList count] > 0 || [photoNewAddedList count] > 0) //1 means has photo so mapView will show thumbnail
        ent.eventType = 1;
    else
        ent.eventType = 0;
    
    
    NSMutableArray* finalFullSortedList = nil;
    NSMutableDictionary* finalPhotoDescMap = nil;
    NSArray* sortedPhotoList = self.photoScrollView.selectedAsSortIndexList;
    if (sortedPhotoList != nil && [sortedPhotoList count] > 0)
    {
        NSMutableArray* newList = [[NSMutableArray alloc] init];
        for (NSNumber* orderIdx in sortedPhotoList)
        {
            NSString* fileName = self.photoScrollView.photoList[[orderIdx intValue]];
            [newList addObject:fileName];
        }
        for (NSString* tmp in newList)
        {
            [self.photoScrollView.photoList removeObject:tmp];
        }
        [newList addObjectsFromArray:self.photoScrollView.photoList];
        self.photoScrollView.photoList = newList;
        finalFullSortedList = self.photoScrollView.photoList;
    }
    
    //TODO check if have description
    NSDictionary* changedDescMap = self.photoScrollView.photoDescMap;
    NSMutableDictionary* originalMetaFileMap = [photoFilesMetaMap objectForKey:PHOTO_META_DESC_MAP_KEY];
    if (changedDescMap != nil && [changedDescMap count] > 0)
    { //check if photo desc changed then ....
        if (originalMetaFileMap == nil)
            originalMetaFileMap = [[NSMutableDictionary alloc] init];
        for (NSString* key in changedDescMap) {
            NSString* value = [changedDescMap objectForKey:key];
            [originalMetaFileMap setObject:value forKey:key];
        }
        finalPhotoDescMap = originalMetaFileMap;
    }
    NSMutableDictionary* finalPhotoMetaDataMap = nil;
    if (finalPhotoDescMap != nil || finalFullSortedList != nil)
    {
        finalPhotoMetaDataMap = [[NSMutableDictionary alloc] init];
        [finalPhotoMetaDataMap setObject:self.photoScrollView.photoList forKey:PHOTO_META_SORT_LIST_KEY];
        if (finalPhotoDescMap == nil)
            [finalPhotoMetaDataMap setObject:originalMetaFileMap forKey:PHOTO_META_DESC_MAP_KEY];
        else
            [finalPhotoMetaDataMap setObject:finalPhotoMetaDataMap forKey:PHOTO_META_DESC_MAP_KEY];
        
        //Add meta file to newAdded list so it will be synch to drop box
        if (![photoNewAddedList containsObject:PHOTO_META_FILE_NAME])
            [photoNewAddedList addObject:PHOTO_META_FILE_NAME];
    }
    
    [self.delegate updateEvent:ent newAddedList:photoNewAddedList deletedList:photoDeletedList photoMetaData:finalPhotoMetaDataMap];
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

//iad/gAd
-(void)initiAdBanner
{
    if (!self.iAdBannerView)
    {
        //NSLog(@"----- iAdView height=%f ", self.view.frame.size.height);
        CGRect rect = CGRectMake(0, [ATConstants screenHeight] - 50, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
        self.iAdBannerView = [[ADBannerView alloc]initWithFrame:rect];
        self.iAdBannerView.delegate = self;
        self.iAdBannerView.hidden = TRUE;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            rect = CGRectMake(0, -20, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
            [self.iAdBannerView setFrame:rect];
        }
        else
            [self.view addSubview:self.iAdBannerView];
    }
}

-(void)initgAdBanner
{
    if (!self.gAdBannerView)
    {
        //NSLog(@"----- gAdView height=%f ", self.view.frame.size.height);
        CGRect rect = CGRectMake(0, [ATConstants screenHeight] - 50, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
        self.gAdBannerView = [[GADBannerView alloc] initWithFrame:rect];
        self.gAdBannerView.adUnitID = @"ca-app-pub-5383516122867647/8499480217";
        self.gAdBannerView.rootViewController = self;
        self.gAdBannerView.delegate = self;
        self.gAdBannerView.hidden = TRUE;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            rect = CGRectMake(0, -20, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
            [self.gAdBannerView setFrame:rect];
        }
        else
            [self.view addSubview:self.gAdBannerView];
    }
}
-(void)hideBanner:(UIView*)banner
{
    if (banner && ![banner isHidden])
    {
        [UIView beginAnimations:@"hideBanner" context:nil];
        banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height - 60);
        [UIView commitAnimations];
        banner.hidden = TRUE;
    }
}
-(void)showBanner:(UIView*)banner
{
    if (banner && [banner isHidden])
    {
        [UIView beginAnimations:@"showBanner" context:nil];
        banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height + 60);
        [UIView commitAnimations];
        banner.hidden = FALSE;
    }
}
////////// iAd delegate
// Called before the add is shown, time to move the view
- (void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    //NSLog(@"----- Editor iAd load");
    [self hideBanner:self.gAdBannerView];
    [self showBanner:self.iAdBannerView];
}

// Called when an error occured
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    //NSLog(@"###### Editor iAd error: %@", error);
    [self hideBanner:self.iAdBannerView];
    [self.gAdBannerView loadRequest:[GADRequest request]];
}

//////////gAd delegate
// Called before ad is shown, good time to show the add
- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    //NSLog(@"------ Editor Admob load");
    [self hideBanner:self.iAdBannerView];
    [self showBanner:self.gAdBannerView];
}

// An error occured
- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    //NSLog(@"########  Editor Admob error: %@", error);
    [self hideBanner:self.gAdBannerView];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    /*
    //ATConstants screenHeight already considered screen orentation
    CGRect frame = self.iAdBannerView.frame;
    frame.origin.y = [ATConstants screenHeight] - 50;
    self.iAdBannerView.frame = frame;
    
    frame = self.gAdBannerView.frame;
    frame.origin.y = [ATConstants screenHeight] - 50;
    self.gAdBannerView.frame = frame;
     */
}

- (void)viewDidUnload {
    [self setDateTxt:nil];
    [super viewDidUnload];
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