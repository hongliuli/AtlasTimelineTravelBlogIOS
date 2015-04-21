//
//  ATPreferenceViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATDataController.h"
#import "ATPreferenceViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"
#import "ATHelpWebView.h"
#import "ATInAppPurchaseViewController.h"
#import "ATOptionsTableViewController.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

#define SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX 0

#define ROW_SYNC_TO_DROPBOX 0
#define ROW_SYNC_TO_DROPBOX_ALL 1
#define ROW_SYNC_FROM_DROPBOX 2
#define RESTORE_PHOTO_TITLE NSLocalizedString(@"Restore Photos",nil)

#define PHOTO_META_FILE_NAME @"MetaFileForOrderAndDesc"


@interface ATPreferenceViewController ()

@end

@implementation ATPreferenceViewController
{
    NSString* _source;
    ATInAppPurchaseViewController* purchase; //have to be "global", otherwise error
    NSString* deleteEventIdPhotoName;
    ATDataController* privateDataController;
    NSString* currentEventId;
    NSString* currentPhotoName;
    NSArray* downloadedMyEventsJsonArray;
    int uploadSuccessExcludeThumbnailCount;
    int deleteCount;
    int downloadFromDropboxStartCount;
    int downloadFromDropboxSuccessCount;
    int totalDownloadFromDropboxSuccessCount;
    int downloadFromDropboxFailCount;
    int downloadFromDropboxLoadMedadataFailCount;
    int downloadAlreadyExistCount;
    BOOL onlyShowOnceForIssueWithDropbox;
    int totalPhotoCountInDevice;
    BOOL isEventDir;
    BOOL isRemoveSourceForUploadAll;
    BOOL showDownloadAllLoadMetadataErrorAlert;
    NSMutableArray* eventListToCopyPhotoFromDropbox;
    UIActivityIndicatorView* spinner;
    
    UIAlertView* uploadAlertView;
    UIAlertView* uploadAllToDropboxAlert;
    UIAlertView* downloadAllFromDropboxAlert;
    UIAlertView* confirmUploadAllPhotoAlertView;
    UIAlertView* confirmUploadContentAlertView;
    
    UITableViewCell* PhotoToDropboxCell;
    UITableViewCell* photoFromDropboxCell;
    
    UIButton* logoutButton;
    UILabel* loginEmailLabel;
    
    BOOL hasNewIncomingShareFlag;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _source = [ATHelper getSelectedDbFileName];
    spinner = [[UIActivityIndicatorView alloc]
               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(0,0,60,60);
    spinner.center =  CGPointMake(160, 200); //set self.view center does not work
    //spinner.hidesWhenStopped = YES;
    [[self  view] addSubview:spinner];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == uploadAllToDropboxAlert)
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user canceled copy all to dropbox");
            // Any action can be performed here
        }
        else if (buttonIndex == 1)
        {
            confirmUploadAllPhotoAlertView  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Confirm to replace all %@ photos on Dropbox!",nil),[ATHelper getSelectedDbFileName]]
                message:NSLocalizedString(@"Enter agree to continue:",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [confirmUploadAllPhotoAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            UITextField * aa = [confirmUploadAllPhotoAlertView textFieldAtIndex:0];
            aa.placeholder = @"agree";
            [confirmUploadAllPhotoAlertView show];
        }
    }
    if (alertView == confirmUploadAllPhotoAlertView)
    {
  
    }
    if (alertView == downloadAllFromDropboxAlert)
    {

    }
}

#pragma mark - Table view delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    int retCount = 0;
    if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
        retCount = 3;
    else  //SECTION_SUPPORT...
        retCount = 3;

    return retCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int section = indexPath.section;
    UITableViewCell *cell = nil;
    int row = indexPath.row;
    
    NSString* cellIdentifier = @"cell_type_other";
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
    {
        switch (row) {
            case ROW_SYNC_TO_DROPBOX:
                cell.textLabel.text = NSLocalizedString(@"Backup Photos (Incremental)",nil);
                break;
            case ROW_SYNC_TO_DROPBOX_ALL:
                cell.textLabel.text = NSLocalizedString(@"Backup Photos (Full)",nil);
                break;
            case ROW_SYNC_FROM_DROPBOX:
                cell.textLabel.text = RESTORE_PHOTO_TITLE;
                break;
            default:
                break;
        }
        if (row == ROW_SYNC_TO_DROPBOX )
        {
            ATDataController* dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
            int numberOfNewPhotos = [dataController getNewPhotoQueueSizeExcludeThumbNail];
            int numberOfDeletedPhoto = [dataController getDeletedPhotoQueueSize];
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo Backup - New:%d  Del:%d",nil),numberOfNewPhotos,numberOfDeletedPhoto ];
            PhotoToDropboxCell = cell;
        }
        if (row == ROW_SYNC_FROM_DROPBOX)
            photoFromDropboxCell = cell;
    }
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-italic" size:16];//no effect to chinese
    return cell;
}

//change section font

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //UITableView section is aleays in cap, I need to do something speicial here
    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0, 10, tableView.bounds.size.width, 70)];
    [customView setBackgroundColor:[UIColor colorWithRed: 0.85 green: 0.85 blue: 0.85 alpha: 0.0]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.bounds.size.width, 30)];
    label.font = [UIFont fontWithName:@"Helvetica" size:18.0];
    label.textColor = [UIColor colorWithRed: 0.55 green: 0.55 blue: 0.95 alpha: 1.0];
    // create the parent view that will hold header Label

    if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
    {
        label.text = NSLocalizedString(@"Backup/Restore Photos to Dropbox",nil);
    }

    [customView addSubview:label];
    return customView;
}
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SECTION_SYNC_MYEVENTS_TO_SERVER)
        return @"Backup/Restore myEvents data";
    if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
        return @"Backup/Restore Photos to Dropbox";
    if (section == SECTION_MISC)
        return @"Misc";

    
    return @"";
}
*/
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (ATDataController*)getDataController
{
    if (privateDataController == nil)
        privateDataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    return privateDataController;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}


-(void) handleLoginEmailSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    //also see prepareForSeque() where pass values
    [self performSegueWithIdentifier:@"options" sender:nil];
}


- (void) logoutButtonAction: (id)sender {
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
    [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
    [logoutButton setTitle:@"" forState: UIControlStateNormal];
    [loginEmailLabel setText:NSLocalizedString(@"Not login",nil)];
}


-(void) helpClicked:(id)sender //Only iPad come here. on iPhone will be frome inside settings and use push segue
{
    ATHelpWebView *helpView = [[ATHelpWebView alloc] init];//[storyboard instantiateViewControllerWithIdentifier:@"help_webview_id"];
    
    [self.navigationController pushViewController:helpView animated:true];
}


@end
