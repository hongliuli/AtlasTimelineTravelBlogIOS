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
#import "ATPhotoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

//iPad mini size as standard
#define EDITOR_PHOTOVIEW_WIDTH 190
#define EDITOR_PHOTOVIEW_HEIGHT 160

#define PHOTOVIEW_WIDTH 1024
#define PHOTOVIEW_HEIGHT 768

@implementation ATEventEditorTableController

ATViewImagePickerController* imagePicker;

@synthesize delegate;
@synthesize description;
@synthesize address;
@synthesize dateTxt;

#pragma mark UITableViewDelegate
/*
- (void)tableView: (UITableView*)tableView
  willDisplayCell: (UITableViewCell*)cell
forRowAtIndexPath: (NSIndexPath*)indexPath
{
    //cell.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];

}
 */


- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer* tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = FALSE;
    [self.view addGestureRecognizer:tapper];
    self.dateTxt.delegate = self;
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
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* customView = nil;
    // create the parent view that will hold header Label
    if (section == 0)
    {
        //view for this section
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 60.0)];
        
        //Label in the view
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, 60, 40)];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"Date:";
        [customView addSubview:label];
        
        // create the button object
        UIButton * photoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        photoBtn.frame = CGRectMake(10, 20, 100, 30);
        [photoBtn.layer setCornerRadius:7.0f];
        photoBtn.backgroundColor = [UIColor lightGrayColor];
        photoBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
        //headerBtn.opaque = NO;
        [photoBtn setTitle:@"Add Photo" forState:UIControlStateNormal];
        [photoBtn addTarget:self action:@selector(takePicutureAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:photoBtn];
        
        //get photo into button image if this event has one is done before come here in ATViewController
        if (self.photoButton == nil) //viewForHeader.. may called again if scroll eventEditor, if do not check here, small photo will gone if scroll, especially in iPhone version
        {
            self.photoButton = [[UIButton alloc] initWithFrame:CGRectMake(120,5,EDITOR_PHOTOVIEW_WIDTH,EDITOR_PHOTOVIEW_WIDTH)];
            
            [self.photoButton addTarget:self action:@selector(showPhotoView:) forControlEvents:UIControlEventTouchUpInside];
        }
        [customView addSubview:self.photoButton];

 
    }
    else if (section == 2)
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 40.0)];
        
        //Label in the view
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 40)];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"Address:";
        [customView addSubview:label];
        
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shareButton.frame = CGRectMake(200, 0, 100, 30);
        [shareButton setImage:[UIImage imageNamed:@"share-icons.png"] forState:UIControlStateNormal];
        [shareButton addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:shareButton];
    }
    return customView;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (section == 0)
        return 94;
    else
        return [super tableView:tableView heightForHeaderInSection:section];
}
-(void)showPhotoView:(id)sender
{
    //use Modal with Done button is good both iPad/iPhone
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard* storyboard = appDelegate.storyBoard;
    ATPhotoViewController* ctr = [storyboard instantiateViewControllerWithIdentifier:@"photo_view"];
    [self presentModalViewController:ctr animated:YES];
    [[ctr imageView] setImage:self.photoButton.imageView.image];
    [ctr imageView].contentMode = UIViewContentModeScaleAspectFit;
    [ctr imageView].clipsToBounds = YES;
}

-(void)takePicutureAction:(id)sender
{
    NSLog(@"   ----- take picture action");
    self.hasPhotoFlag = EVENT_TYPE_NO_PHOTO;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard* storyboard = appDelegate.storyBoard;
    imagePicker = [storyboard instantiateViewControllerWithIdentifier:@"image_picker"];
    imagePicker.delegate = self;
    //Use Modal with Done button is good for both iPad/iPhone
    [self presentModalViewController:imagePicker animated:YES];
}
- (IBAction)shareButtonAction:(id)sender {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    BOOL isAtLeast6 = [version compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending;
    if (isAtLeast6)
    {
        //how to send html email
        
        //customize UIActivityItemProvider
        //http://stackoverflow.com/questions/12639982/uiactivityviewcontroller-customize-text-based-on-selected-activity
        
        //  http://stackoverflow.com/questions/12769499/override-uiactivityviewcontroller-default-behaviour
        //http://www.albertopasca.it/whiletrue/2012/10/objective-c-custom-uiactivityviewcontroller-icons-text/
        
        if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook] && ![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Account"
                                                                message:@"Facebook and Twitter have not setup! Please go to the device settings and add account to Facebook or Twitter. Or you can continues to send by email."
                                                               delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alertView show];
        }
        NSArray *activityItems;
        NSString *googleMap = [NSString stringWithFormat:@"\n\n Google map location: https://maps.google.com/maps?q=%f,%f&spn=65.61535,79.013672",self.coordinate.latitude, self.coordinate.longitude ];
        NSString* appStoreUrl= @"\n\n By ChronicleMap.com at https://itunes.apple.com/us/app/chroniclemap-events-itinerary/id649653093?ls=1&mt=8";
        
        UIImageView *eventImage = [self.photoButton imageView];
        if (self.eventType == EVENT_TYPE_HAS_PHOTO &&  eventImage.image != nil) {
            activityItems = @[eventImage.image, self.description.text, googleMap, appStoreUrl];
        } else {
            activityItems = @[self.description.text, googleMap, appStoreUrl];
        }
    
        UIActivityViewController *activityController =
        [[UIActivityViewController alloc]
         initWithActivityItems:activityItems
         applicationActivities:nil];
        activityController.excludedActivityTypes = [NSArray arrayWithObjects: UIActivityTypePostToWeibo, UIActivityTypePrint,UIActivityTypeAssignToContact,UIActivityTypeCopyToPasteboard, UIActivityTypeMessage,UIActivityTypeSaveToCameraRoll, nil];
    
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
    if (textField.tag == 999) { //999 is for date textField in storyboard
        NSString* bcDate = self.dateTxt.text;
        //if date is already a a BC date, datePicker will crash, so do not show date picker if is a BC date
        if (bcDate != nil && [bcDate rangeOfString:@"BC"].location!=NSNotFound)
            return;
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSDateFormatter *dateFormater = appDelegate.dateFormater; 
        if (self.datePicker == nil) //will be nill if clicked Done button
        {
            //Test on iPad to see if need to diable keypad in iPad when click on date field
            //[textField resignFirstResponder]; //comment this out, I decide to let keypad show together with date picker slot machine, otherwise a big issue in iPad: click desc/address to bring keypad, then date field, will leave keypad always displayed. But need test on iPhone. we can
            self.datePicker = [[UIDatePicker alloc] init];

            [self.datePicker setFrame:CGRectMake(0,165,320,180)];
                
            [self.datePicker addTarget:self action:@selector(changeDateInLabel:) forControlEvents:UIControlEventValueChanged];
            self.datePicker.datePickerMode = UIDatePickerModeDate;
        
            [self.view addSubview:self.datePicker];
            
            self.toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 290, 320, 44)];
            self.toolbar.barStyle = UIBarStyleBlackOpaque;
        
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle: @"Done" style: UIBarButtonItemStyleBordered target: self action: @selector(datePicked:)];
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
            NSLog(@"dateTxt is %@", dateTxt.text);
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wrong Date Format"
                message:@"The correct date format is MM/dd/yyyy AD or BC"
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
        [alert show];
        return;
    }
    if (self.description.text == nil || self.description.text.length == 0)
    {  //#### have to have this check, otherwise the eventEditor will not popup
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Description field may not be empty"
                message:@"Please enter description."
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
        [alert show];
        return;
    }
    ent.eventDate = dt;
    UIImage *imageToBeWritten = [[self.photoButton imageView] image];
    ent.eventType = self.eventType;
    //see doneSelectPicture() which will set if there is a picture
    if (self.hasPhotoFlag == 1) //alwasys initialized to 0 in ATViewController. 1 means taken photo this time, has to write to file 
        ent.eventType = self.hasPhotoFlag;
    else
        imageToBeWritten = nil; //if no photo taken this time, no need write to file again
        
    [self.delegate updateEvent:ent image:imageToBeWritten];
    [self dismissModalViewControllerAnimated:true]; //for iPhone case
}

- (IBAction)deleteAction:(id)sender {
    //will delete selected event from annotation/db
    [self.delegate deleteEvent];
    [self dismissModalViewControllerAnimated:true]; //for iPhone case
}

- (IBAction)cancelAction:(id)sender {

    [self.delegate cancelEvent];
    [self dismissModalViewControllerAnimated:true]; //for iPhone case
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wrong Date Format"
                message:@"The correct date format is MM/dd/yyyy AD or BC"
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
        [alert show];
    }
}

//callback from imagePicker Controller
- (void)doneSelectPicture:(UIImage*)newPhoto
{
    if (newPhoto == nil)
        return;

    [self.photoButton setImage:newPhoto forState:UIControlStateNormal];
    [self.photoButton imageView].contentMode = UIViewContentModeScaleAspectFit;
    [self.photoButton imageView].clipsToBounds = YES;
    self.hasPhotoFlag = EVENT_TYPE_HAS_PHOTO; //saveAction will write this to eventType. save image file will be in ATViewController's updateEvent because only there we can get uniqueId as filename
}

//especially add this for iPhone to dismiss keyboard when touch any where eolse
- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}

- (void)viewDidUnload {
    [self setDateTxt:nil];
    [super viewDidUnload];
}
@end
