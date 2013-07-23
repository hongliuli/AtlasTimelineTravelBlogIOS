//
//  ATPreferenceViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "ATDataController.h"
#import "ATPreferenceViewController.h"
#import "ATDownloadTableViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"
#import "ATHelpWebView.h"
#import "ATInAppPurchaseViewController.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1
#define SECTION_LOGIN_EMAIL 1
#define ROW_SYNC_TO_DROPBOX 2
#define ROW_SYNC_TO_DROPBOX_ALL 3
#define ROW_SYNC_FROM_DROPBOX 4
#define SECTION_THREE 2
#define ROW_VIDEO_TUTORIAL 0
#define ROW_PURCHASE 1
#define ROW_RESTORE_PURCHASE 2
#define IN_APP_PURCHASED @"IN_APP_PURCHASED"

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
    int uploadSuccessExcludeThumbnailCount;
    int deleteCount;
    int downloadFromDropboxStartCount;
    int downloadFromDropboxSuccessCount;
    int downloadFromDropboxFailCount;
    int downloadFromDropboxLoadMedadataFailCount;
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
    spinner = [[UIActivityIndicatorView alloc]
               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(0,0,60,60);
    spinner.center =  CGPointMake(160, 200); //set self.view center does not work
    //spinner.hidesWhenStopped = YES;
    [[self  view] addSubview:spinner];
    self.detailLabel.text = _source;
}

- (void)sourceChooseViewController: (ATSourceChooseViewController *)controller
                   didSelectSource:(NSString *)source{
    //########################################
    // If user select a large period, then map may be slow if there is too many annotations. but I could not do anything to prevent it.
    //########################################
    _source = source;
    self.detailLabel.text = _source ;
    [ATHelper setSelectedDbFileName:_source];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate emptyEventList];
    [appDelegate.mapViewController cleanSelectedAnnotationSet];
    [appDelegate.mapViewController prepareMapView];
    [self.navigationController popViewControllerAnimated:YES];
    isRemoveSourceForUploadAll = false;
}

//called by download window after downloaded a source
-(void) changeSelectedSource:(NSString*)selectedAtlasName
{
    _source = selectedAtlasName;
    self.detailLabel.text = selectedAtlasName;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"choose_offline_content"]) {
        ATSourceChooseViewController *sourceChooseViewController = segue.destinationViewController;
        sourceChooseViewController.delegate = self;
        sourceChooseViewController.source = _source;
    }
    if ([segue.identifier isEqualToString:@"download"]) {
        Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
        if (!successFlag)
        {
            //Need alert again?  checkUserEmailAndSecurityCode already alerted
            return;
        }
        ATDownloadTableViewController *downloadTableViewController = segue.destinationViewController;
        downloadTableViewController.parent = self;
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _source = [ATHelper getSelectedDbFileName];
    }
    return self;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    int cnt = [appDelegate.eventListSorted count];
    
    uploadAlertView = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:@"Sync %i events to %@ on server",cnt, [ATHelper getSelectedDbFileName]]
                                                   message: [NSString stringWithFormat:@"WARNING: Upload will replace existing %@ event data on server.",_source]
                                                  delegate: self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Upload & Replace",@"Cancel & Logout",nil];
    
    
    [uploadAlertView show];
    
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == uploadAlertView)
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user canceled upload");
            // Any action can be performed here
        }
        else if (buttonIndex == 1)
        {
            confirmUploadContentAlertView  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Confirm to replace %@ content on server!",[ATHelper getSelectedDbFileName]]
                message:@"Enter agree to continue:" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [confirmUploadContentAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            UITextField * aa = [confirmUploadContentAlertView textFieldAtIndex:0];
            aa.placeholder = @"agree";
            [confirmUploadContentAlertView show];
        }
        else
        {
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
            [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
        }
    }
    if (alertView == confirmUploadContentAlertView)
    {
        UITextField *agree = [alertView textFieldAtIndex:0];
        if ([agree.text caseInsensitiveCompare:@"agree"] == NSOrderedSame)
        {
            [self startUploadJson];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You Canceled uploading the content to server" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    if (alertView == uploadAllToDropboxAlert)
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user canceled copy all to dropbox");
            // Any action can be performed here
        }
        else if (buttonIndex == 1)
        {
            confirmUploadAllPhotoAlertView  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Confirm to replace all %@ photos on Dropbox!",[ATHelper getSelectedDbFileName]]
                message:@"Enter agree to continue:" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [confirmUploadAllPhotoAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            UITextField * aa = [confirmUploadAllPhotoAlertView textFieldAtIndex:0];
            aa.placeholder = @"agree";
            [confirmUploadAllPhotoAlertView show];
        }
    }
    if (alertView == confirmUploadAllPhotoAlertView)
    {
        UITextField *agree = [alertView textFieldAtIndex:0];
        if ([agree.text caseInsensitiveCompare:@"agree"] == NSOrderedSame)
        {
            [spinner startAnimating];
            isRemoveSourceForUploadAll = true; //so if /ChronicleMap/myEvent not on dropbox yet, delete fail will know the case
            [[self myRestClient] deletePath:[NSString stringWithFormat:@"/ChronicleMap/%@", [ATHelper getSelectedDbFileName]]];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You Canceled uploading all photos to Dropbox" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    if (alertView == downloadAllFromDropboxAlert)
    {
        if (buttonIndex == 0)
        {
            return; //user canceled download all
        }
        //if local path does not exist, loadFile will not write
        NSString* localFullPath = [ATHelper getPhotoDocummentoryPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:localFullPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:localFullPath withIntermediateDirectories:YES attributes:nil error:nil];
        downloadFromDropboxStartCount = 0;
        downloadFromDropboxSuccessCount = 0;
        downloadFromDropboxFailCount = 0;
        downloadFromDropboxLoadMedadataFailCount = 0;
        onlyShowOnceForIssueWithDropbox = true;
        showDownloadAllLoadMetadataErrorAlert = true;
        if ([eventListToCopyPhotoFromDropbox count] > 0)
            [spinner startAnimating];
        for(NSString* eventId in eventListToCopyPhotoFromDropbox)
        {
            //local path has to exist for loadFile to save. But local path may not exist after re-install app so need do it here
            if (![[NSFileManager defaultManager] fileExistsAtPath:[localFullPath stringByAppendingPathComponent:eventId]])
                [[NSFileManager defaultManager] createDirectoryAtPath:[localFullPath stringByAppendingPathComponent:eventId] withIntermediateDirectories:YES attributes:nil error:nil];
            [[self myRestClient] loadMetadata:[NSString stringWithFormat:@"/ChronicleMap/%@/%@", [ATHelper getSelectedDbFileName], eventId]]; //then see loadedMetadata delegate where we start download file
        }
    }
}

-(void)startUploadJson
{
    [spinner startAnimating];
    // [self dismissViewControllerAnimated:true completion:nil]; does not dismiss preference itself here
    
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //Need alert again?  checkUserEmailAndSecurityCode already alerted
        return;
    }
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    if (userEmail == nil || securityCode == nil)
    {
        //should never come here
        return;
    }
    
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDateFormatter* formater = appDelegate.dateFormater;
    NSArray *myAtlasList = appDelegate.eventListSorted;
    int eventCount = [myAtlasList count];
    NSMutableArray* dictArray = [[NSMutableArray alloc] initWithCapacity:eventCount];
    for (ATEventDataStruct* item in myAtlasList)
    {
        NSNumber* eventType = [NSNumber numberWithInt: item.eventType]; //not initialized in code, need fix
        if (eventType == nil)
            eventType = [NSNumber numberWithInt:EVENT_TYPE_NO_PHOTO];
        
        NSMutableDictionary* itemDict = [[NSMutableDictionary alloc] init];
        [itemDict setObject:item.uniqueId forKey:@"uniqueId"];
        [itemDict setObject:item.eventDesc forKey:@"eventDesc"];
        [itemDict setObject:[formater stringFromDate:item.eventDate] forKey:@"eventDate"]; //NSDate is not serializable
        [itemDict setObject:eventType forKey:@"eventType"];
        [itemDict setObject:item.address forKey:@"address"];
        [itemDict setObject:[NSNumber numberWithDouble:item.lat] forKey:@"lat"];
        [itemDict setObject:[NSNumber numberWithDouble:item.lng] forKey:@"lng"];
        
        [dictArray addObject:itemDict];
    }
    NSArray *info = [NSArray arrayWithArray:dictArray];
    NSError* error;
    NSData* eventData = [NSJSONSerialization dataWithJSONObject:info options:0 error:&error];
    
    //"application/x-www-form-urlencoded" is used, need encode % and & sign (spend long time to figure out)
    NSMutableString *longStr = [[NSMutableString alloc] initWithData:eventData encoding:NSUTF8StringEncoding];
    [longStr replaceOccurrencesOfString:@"%" withString:@"%25" options:0 range:NSMakeRange(0, [longStr length])];
    [longStr replaceOccurrencesOfString:@"&" withString:@"%26" options:0 range:NSMakeRange(0, [longStr length])];
    
    //NSString* eventStr= @"百科 abc 2012/02/34";//test post chinese
    NSString* postStr = [NSString stringWithFormat:@"user_id=%@&security_code=%@&atlas_name=%@&json_contents=%@", userEmail, securityCode
                         ,[ATHelper getSelectedDbFileName], longStr];
    //NSLog(@"============post body = %@", postStr);
    NSData *postData = [postStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSURL* serviceUrl = [NSURL URLWithString: [ATConstants ServerURL]];
    //NSLog(@"============post url = %@", serviceUrl.absoluteString);
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:serviceUrl];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //Get Responce hear----------------------
    NSURLResponse *response;
    
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString* returnStatus = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    //NSLog(@"upload response  urlData = %@", returnStatus);
    //Event Editor should exclude & char which will cause partial upload until &
    [spinner stopAnimating];
    if (![returnStatus isEqual:@"SUCCESS"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Failed!" message:@"Fail reason could be network issue or data issue!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Success!"
                                                        message: [NSString stringWithFormat:@"%i %@ events have been uploaded to server successfully!",eventCount,[ATHelper getSelectedDbFileName]]
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SECTION_LOGIN_EMAIL)
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
        if (userEmail != nil)
            return userEmail;
    }
    
    return @"";
}
#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //for static tableView's cellFor.. works, have to use super tableView here, do not know why
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    int section = indexPath.section;
    int row = indexPath.row;
    if (section == SECTION_THREE)
    {
        if (row == ROW_PURCHASE || row == ROW_RESTORE_PURCHASE)
        {
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            if ([userDefault objectForKey:IN_APP_PURCHASED] != nil)
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.textColor = [UIColor lightGrayColor];
            }
        }
    }
    else if (section == SECTION_LOGIN_EMAIL)
    {
        if (row == ROW_SYNC_TO_DROPBOX )
        {
            ATDataController* dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
            int numberOfNewPhotos = [dataController getNewPhotoQueueSizeExcludeThumbNail];
            int numberOfDeletedPhoto = [dataController getDeletedPhotoQueueSize];
            cell.textLabel.text = [NSString stringWithFormat:@"Photo to Dropbox - New:%d  Del:%d",numberOfNewPhotos,numberOfDeletedPhoto ];
            PhotoToDropboxCell = cell;
        }
        if (row == ROW_SYNC_FROM_DROPBOX)
            photoFromDropboxCell = cell;
    }
    return cell;
}

- (ATDataController*)getDataController
{
    if (privateDataController == nil)
        privateDataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    return privateDataController;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int section = indexPath.section;
    int row = indexPath.row;
    if (section == SECTION_THREE)
    {
        if (row == ROW_VIDEO_TUTORIAL)
        {
            NSURL *url = [NSURL URLWithString:@"http://www.chroniclemap.com/onlinehelp"];
            if (![[UIApplication sharedApplication] openURL:url])
                NSLog(@"%@%@",@"Failed to open url:",[url description]);
        }
        if (row == ROW_PURCHASE)
        {
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            if ([userDefault objectForKey:IN_APP_PURCHASED] == nil)
            {
                purchase = [[ATInAppPurchaseViewController alloc] init];
                [purchase processInAppPurchase];
            }
        }
        if (row == ROW_RESTORE_PURCHASE)
        {
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            if ([userDefault objectForKey:IN_APP_PURCHASED] == nil)
            {
                purchase = [[ATInAppPurchaseViewController alloc] init];
                [purchase restorePreviousPurchases];
            }
            
        }
    }
    if (section == SECTION_LOGIN_EMAIL)
    {
        if (row == ROW_SYNC_TO_DROPBOX)
        {
            if (![[DBSession sharedSession] isLinked]) {
                [[DBSession sharedSession] linkFromController:self];
                return;
            }
            int dbNewPhotoCount = [[self getDataController] getNewPhotoQueueSizeExcludeThumbNail];
            int dbDeletedPhotoCount = [[self getDataController] getDeletedPhotoQueueSize];
            //set cell count again (already done in celFor...) here, is to refresh count after user clicked this row and already synched
            UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
            cell.textLabel.text = [NSString stringWithFormat:@"Photo to Dropbox - New:%d  Del:%d",dbNewPhotoCount,dbDeletedPhotoCount ];
            if (dbNewPhotoCount + dbDeletedPhotoCount > 0)
            {
                [spinner startAnimating]; //stop when chain complete or any error
            }
            if (dbNewPhotoCount > 0) //will process both queue
                [[self myRestClient] createFolder:@"/ChronicleMap"]; //createFolder success/alreadyExist delegate will start the chain action, which will include delete Queue
            else if (dbDeletedPhotoCount > 0) //bypass process createFolder, only delete file for more efficient
                [self processEmptyDeletedPhotoQueue];
        }
        else if (row == ROW_SYNC_TO_DROPBOX_ALL)
        {
            if (![[DBSession sharedSession] isLinked]) {
                [[DBSession sharedSession] linkFromController:self];
                return;
            }
            totalPhotoCountInDevice = 0;
            //get total number of photos on device
            ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSArray* eventList = appDelegate.eventListSorted;
            NSError *error;
            for (ATEventDataStruct* evt in eventList)
            {
                if (evt.eventType == EVENT_TYPE_HAS_PHOTO)
                {
                    NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:evt.uniqueId];
                    NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
                    if (tmpFileList != nil && [tmpFileList count] > 0)
                    {
                        for (NSString* file in tmpFileList)
                        {
                            if (![file isEqualToString:@"thumbnail"])
                                totalPhotoCountInDevice++;
                        }
                    }
                    
                }
            }
            if (totalPhotoCountInDevice == 0)
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"No photos to upload to your Dropbox!"
                                                               message: @""
                                                              delegate: self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil,nil];
                
                
                [alert show];
            }
            else
            {
                uploadAllToDropboxAlert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:@"Replace photos on Dropbox for %@", [ATHelper getSelectedDbFileName]]
                            message: [NSString stringWithFormat:@"WARNING: All photoes on your dropbox:/ChoronicleMap/%@ will be replaced with %d photos on this device!",_source, totalPhotoCountInDevice]
                            delegate: self
                            cancelButtonTitle:@"Cancel"
                            otherButtonTitles:@"Yes, Continue",nil];
                [uploadAllToDropboxAlert show];
            }
        }
        else if (row == ROW_SYNC_FROM_DROPBOX)
        {
            if (![[DBSession sharedSession] isLinked]) {
                [[DBSession sharedSession] linkFromController:self];
                return;
            }
            int totalEventWithPhoto = 0;
            eventListToCopyPhotoFromDropbox = [[NSMutableArray alloc] initWithCapacity:10];
            //get total number of photos on device
            ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSArray* eventList = appDelegate.eventListSorted;

            for (ATEventDataStruct* evt in eventList)
            {
                if (evt.eventType == EVENT_TYPE_HAS_PHOTO)
                {
                    totalEventWithPhoto++;
                    [eventListToCopyPhotoFromDropbox addObject:evt.uniqueId];
                    
                }
            }
            if (totalEventWithPhoto == 0)
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:@"Content %@ is empty or do not have photos to download.", [ATHelper getSelectedDbFileName]]
                            message: @"This content may not have photos."
                            delegate: self
                        cancelButtonTitle:@"OK"
                        otherButtonTitles:nil,nil];
                
                
                [alert show];
            }
            else
            {
                downloadAllFromDropboxAlert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:@"Download photos from Dropbox:/ChronicleMap/%@", [ATHelper getSelectedDbFileName]]
                        message: @"Find all photos in the above Dropbox folder and save to the corresponding events in your device. This operation is safe, it will not remove existing photos in your device."
                        delegate: self
                        cancelButtonTitle:@"Cancel"
                        otherButtonTitles:@"Yes, Continue",nil];
                [downloadAllFromDropboxAlert show];
            }
        }
    }
}
//Because of the DBRestClient's asynch nature, I have to implement a synchronous way:
/*
 * 1. create /ChronicleMap fold. if success or fail with already-exists then create Source Folder (such as myEvents)
 * 2. if detected create Source success or already exist, then call startProcessNewPhotoQueueChainAction(), which will pop one photo entry
 * 3. in startProcessNewPhotoQueueChainAction() do:
 *      . popup one photo entry, save to a global var currentPhotoEventPath
 *      . create event dir. In createFolder delegate, if success or already exist, call restClient uploadFile(currentPhotoEnventPath)
 * 4. in uploadFile success delegate:
 *      . delete from sqlite queue
 *      . call startProcessNewPhotoQueueChainAction() which loops back to popup next photo from newAddedPhotoQueue table
 *
 * For delete should be simpler
 */

//this is createFolder delegate, important of my chain action
- (void)restClient:(DBRestClient*)client createdFolder:(DBMetadata*)folder{
    //NSLog(@"+++++ Folder success Meta Data Path %@; filename %@; hasDirectory %d;",[folder path], [folder filename], [folder isDirectory]);
    if ( [@"/ChronicleMap" isEqualToString:[folder path]]) 
    {
        NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName] ];
        [[self myRestClient ] createFolder:destDir]; //chain action 1: create "source" directory if not so
    }
    else if ([[folder filename] isEqualToString:[ATHelper getSelectedDbFileName]])
    {
        [self startProcessNewPhotoQueueChainAction ];
    }
    else //Part of chain: come here if created eventId directory
    {
        NSString *localPhotoPath = [ATHelper getPhotoDocummentoryPath];
        localPhotoPath = [[localPhotoPath stringByAppendingPathComponent:currentEventId] stringByAppendingPathComponent:currentPhotoName];
        //Following gives me rediculourse errors where Dropbox did not document
        // 1. get 1003 error with no description, the find fromPath must also include filename part
        // 2. then get 403 Forbidden error, then realize I have to ask dropbox to enable production mode
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPhotoPath])
        {
            [[self myRestClient] uploadFile: currentPhotoName toPath:[folder path] withParentRev:nil fromPath:localPhotoPath];
        }
    }
}

// Folder is the metadata for the newly created folder
- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error{
    //if error is folder alrady exist, then continues our chain action
    [spinner stopAnimating];
    if ([self dropboxFolderAlreadyExist:error])
    {
        if ( [@"/ChronicleMap" isEqualToString:(NSString*)[error.userInfo objectForKey:@"path"]]) //TODO
        {
            NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName]];
            [[self myRestClient ] createFolder:destDir]; //delegate come back with following if
        }
        else if ([[NSString stringWithFormat:@"/ChronicleMap/%@", [ATHelper getSelectedDbFileName]] isEqualToString:(NSString*)[error.userInfo objectForKey:@"path"]])
        {
            [self startProcessNewPhotoQueueChainAction ]; //start upload the 1st file
        }
        else //Part of chain: come here if created eventId directory
        {
            NSString *localPhotoPath = [ATHelper getPhotoDocummentoryPath];
            localPhotoPath = [[localPhotoPath stringByAppendingPathComponent:currentEventId] stringByAppendingPathComponent:currentPhotoName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:localPhotoPath])
            {
                [[self myRestClient] uploadFile:currentPhotoName toPath:(NSString*)[error.userInfo objectForKey:@"path"] withParentRev:nil fromPath:localPhotoPath];
            }
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Could not copy to Dropbox"
                                                       message: @"May be the network is not available"
                                                      delegate: self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil,nil];
        
        
        [alert show];
    }
}


- (void) startProcessNewPhotoQueueChainAction
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
    //When this is called, destDir is already successfully created on dropbox before
    NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName]];

    NSString* file = [[self getDataController] popNewPhotoQueue];
    if (file != nil )
    {
        NSArray* tmpArray = [file componentsSeparatedByString:@"/"];
        currentEventId = tmpArray[0];
        currentPhotoName = tmpArray[1];
        //part of chain action: createFolder delegate will do uploadFile to dropbox when success or fail with 403 (folder already exist
        [[self myRestClient] createFolder:[ NSString stringWithFormat:@"%@/%@", destDir, tmpArray[0] ]];
    }
    else
    {
        [self processEmptyDeletedPhotoQueue]; //start process deletedPhotoQueue chain action after finish process newPhotoQueue
    }
}
//will be a implicit loop by delete success delegate
- (void) processEmptyDeletedPhotoQueue
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
    //When this is called, destDir is already successfully created on dropbox before
    NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName]];
    isEventDir = false;
    NSString* file = [[self getDataController] popDeletedPhototQueue];
    if (file == nil)
    {
        file = [[self getDataController] popDeletedEventPhototQueue];
        isEventDir = true;
    }
    
    if (file != nil )
    {
        if (!isEventDir)
        {
            NSArray* tmpArray = [file componentsSeparatedByString:@"/"];
            currentEventId = tmpArray[0];
            currentPhotoName = tmpArray[1];
            //part of chain action: createFolder delegate will do uploadFile to dropbox when success or fail with 403 (folder already exist
            [[self myRestClient] deletePath:[ NSString stringWithFormat:@"%@/%@/%@", destDir, tmpArray[0], tmpArray[1] ]];
        }
        else
        {
            currentEventId = file;
            [[self myRestClient] deletePath:[ NSString stringWithFormat:@"%@/%@", destDir, file ]];
        }
    }
    else if (uploadSuccessExcludeThumbnailCount > 0 || deleteCount > 0)
    {
        [spinner stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Copy to Dropbox completed!"
                                                       message: [NSString stringWithFormat:@"Add:%d/Delete:%d files in Dropbox succesfully.",uploadSuccessExcludeThumbnailCount,deleteCount]
                                                      delegate: self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil,nil];
        
        
        [alert show];
        uploadSuccessExcludeThumbnailCount = 0;
        deleteCount = 0;
    }
}

//delegate called by upload to dropbox
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    [[self getDataController] emptyNewPhotoQueue:[NSString stringWithFormat:@"%@/%@" ,currentEventId, currentPhotoName]];
    int dbNewPhotoCount = [[self getDataController] getNewPhotoQueueSizeExcludeThumbNail];
    int dbDeletedPhotoCount = [[self getDataController] getDeletedPhotoQueueSize];
    if (![currentPhotoName isEqualToString:@"thumbnail"])
    {
        uploadSuccessExcludeThumbnailCount++;
        PhotoToDropboxCell.textLabel.text = [NSString stringWithFormat:@"Photo to Dropbox - New:%d  Del:%d",dbNewPhotoCount, dbDeletedPhotoCount];
    }
    [self startProcessNewPhotoQueueChainAction]; //start upload next file until
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [spinner stopAnimating];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Could not copy file to Dropbox"
                                                   message: @"May be the network is not available"
                                                  delegate: self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil,nil];
    
    
    [alert show];
}
- (BOOL) prepareUploadAllToDropbox //call this after remove ChronicleMap/myEvent on dropbox successfully
{
    BOOL hasFileToUpload = false;
    //empty queues
    NSString* file = [[self getDataController] popNewPhotoQueue];
    while (file != nil)
    {
        [[self getDataController] emptyNewPhotoQueue:file];
        file = [[self getDataController] popNewPhotoQueue];
    }
    file = [[self getDataController] popDeletedEventPhototQueue];
    while (file != nil)
    {
        [[self getDataController] emptyDeletedEventPhotoQueue:file];
        file = [[self getDataController] popDeletedEventPhototQueue];
    }
    file = [[self getDataController] popDeletedPhototQueue];
    while (file != nil)
    {
        [[self getDataController] emptyDeletedPhotoQueue:file];
        file = [[self getDataController] popDeletedPhototQueue];
    }
    
    //fill up newPhotoQueues
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray* eventList = appDelegate.eventListSorted;
    NSError *error;
    for (ATEventDataStruct* evt in eventList)
    {
        if (evt.eventType == EVENT_TYPE_HAS_PHOTO)
        {
            NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:evt.uniqueId];
            NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
            if (tmpFileList != nil && [tmpFileList count] > 0)
            {
                for (NSString* file in tmpFileList)
                {
                    [[self getDataController] insertNewPhotoQueue:[evt.uniqueId stringByAppendingPathComponent:file]];
                    hasFileToUpload = true;
                }
            }
            
        }
    }
    return hasFileToUpload;
}
- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    if (isRemoveSourceForUploadAll)
    {
        if (![self prepareUploadAllToDropbox])
            return; //return if no file to upload
        NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName] ];
        [[self myRestClient ] createFolder:destDir]; //this will start chain action for copy all in the queue to dropbox
        isRemoveSourceForUploadAll = false;
        return;
    }
    
    [[self getDataController] emptyDeletedPhotoQueue:[NSString stringWithFormat:@"%@/%@", currentEventId, currentPhotoName]];
    int dbNewPhotoCount = [[self getDataController] getNewPhotoQueueSizeExcludeThumbNail];
    int dbDeletedPhotoCount = [[self getDataController] getDeletedPhotoQueueSize];
    if (![currentPhotoName isEqualToString:@"thumbnail"])
    {
        [spinner stopAnimating]; //TODO? seems weired here. but need it when only have item in deleteQueue
        deleteCount++;
        PhotoToDropboxCell.textLabel.text = [NSString stringWithFormat:@"Photo to Dropbox - New:%d  Del:%d",dbNewPhotoCount, dbDeletedPhotoCount];
    }
    [self processEmptyDeletedPhotoQueue];
}
- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    if ([self dropboxDeleteFileNotExist:error]) //if not in dropbox, continues the chain. Dropbox can cleaned anyway if user select
    {
        if (isRemoveSourceForUploadAll)
        {
            if (![self prepareUploadAllToDropbox])
                return; //return if no file to upload
            NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName] ];
            [[self myRestClient ] createFolder:destDir]; //this will start chain action for copy all to dropbox
            isRemoveSourceForUploadAll = false;
            return;
        }
        if (!isEventDir)
            [[self getDataController] emptyDeletedPhotoQueue:[NSString stringWithFormat:@"%@/%@", currentEventId, currentPhotoName]];
        else
            [[self getDataController] emptyDeletedEventPhotoQueue:currentEventId];
        [self processEmptyDeletedPhotoQueue];
    }
    else
    {
        [spinner stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Could not access Dropbox"
                                                       message: @"May be the network is not available"
                                                      delegate: self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil,nil];
        
        
        [alert show];
    }
}

//following loadedMetadata delegate is for copy from dropbox to device
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    if (metadata.isDirectory) {
        //NSLog(@"Folder '%@' contains:", metadata.path);
        for (DBMetadata *file in metadata.contents) {
            //NSLog(@"\t%@", file.filename);
            NSString* localPhotoPath = [[[ATHelper getRootDocumentoryPath] stringByAppendingPathComponent:currentEventId] stringByAppendingPathComponent:currentPhotoName];
            NSString* partialPath = [metadata.path substringFromIndex:14]; //metadata.path is "/ChronicleMap/myEvents/eventid"
            localPhotoPath = [[localPhotoPath stringByAppendingPathComponent:partialPath] stringByAppendingPathComponent:file.filename];
            [[self myRestClient] loadFile:[NSString stringWithFormat:@"%@/%@", metadata.path, file.filename ] intoPath:localPhotoPath];
            if (![file.filename isEqualToString:@"thumbnail"])
                downloadFromDropboxStartCount++;
        }
    }
}
- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    if (showDownloadAllLoadMetadataErrorAlert)
    {
        [spinner stopAnimating];
        showDownloadAllLoadMetadataErrorAlert = false;
        NSString* path = (NSString*)[error.userInfo objectForKey:@"path"] ;
        NSString* eventId = nil;
        if (path != nil)
            eventId = [[path componentsSeparatedByString:@"/"] lastObject];
        if (error.code == 404 && [(NSString*)[error.userInfo objectForKey:@"error"] rangeOfString:@"not found" options:NSCaseInsensitiveSearch].location != NSNotFound )
        {  //If come here because of newAdded photo not uploaded yet, then do nothting except .... following ...
            if (![[self getDataController] isItInNewPhotoQueue:eventId])
            {
                //come here if directory in Dropbox cannot be found while we think it should. It may happen if /ChronicleMap/xxsourcexx is not in dropbox, Or it may also happen if we manually remove some directory from dropbox for this content
                downloadFromDropboxLoadMedadataFailCount ++;
                [self promptCopyFromDropboxStatus];
            }
            return;
        }

        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Could not Download from Dropbox"
                                                   message: @"May be the network is not available"
                                                  delegate: self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil,nil];
    
    
        [alert show];
    }
}
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    if (![localPath hasSuffix:@"thumbnail" ])
    {
        downloadFromDropboxSuccessCount++;
        photoFromDropboxCell.textLabel.text = [NSString stringWithFormat:@"Downloading .. %d success, %d failed", downloadFromDropboxSuccessCount, downloadFromDropboxFailCount];
    }
	[self promptCopyFromDropboxStatus];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    downloadFromDropboxFailCount++;
    photoFromDropboxCell.textLabel.text = [NSString stringWithFormat:@"Downloading .. %d success, %d failed", downloadFromDropboxSuccessCount, downloadFromDropboxFailCount];
    [self promptCopyFromDropboxStatus];
}

- (void)promptCopyFromDropboxStatus
{
    //NSLog(@"  download success=%d, failed=%d, total=%d",downloadFromDropboxSuccessCount,downloadFromDropboxFailCount,downloadFromDropboxStartCount);
    if (downloadFromDropboxSuccessCount + downloadFromDropboxFailCount == downloadFromDropboxStartCount && downloadFromDropboxStartCount > 0)
    {
        [spinner stopAnimating];
        NSString* message;
        if (downloadFromDropboxFailCount == 0)
            message = [NSString stringWithFormat: @"%d photos have been downloaded to your device from Dropbox!", downloadFromDropboxSuccessCount ];
        else if (downloadFromDropboxSuccessCount == 0)
            message = [NSString stringWithFormat:@"Download failed, please check if network is available, or if your Dropbox has photos in /ChronicleMap/%@ directory.", [ATHelper getSelectedDbFileName]];
        else
            message = [NSString stringWithFormat:@"Download photos from Dropbox: %d success, %d fail. Please make sure you have a good wifi connection and try downloading all again.", downloadFromDropboxSuccessCount,downloadFromDropboxFailCount];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download photos from Dropbox finished" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else if (downloadFromDropboxLoadMedadataFailCount > 0 && downloadFromDropboxSuccessCount + downloadFromDropboxFailCount == 0 && onlyShowOnceForIssueWithDropbox)
    { //this condition is used when loadMetadataWithError called the function
        onlyShowOnceForIssueWithDropbox = false;
        NSString* message = [NSString stringWithFormat:@"On your Dropbox, please check if photos are properly copied to /ChronicleMap/%@ folder!", [ATHelper getSelectedDbFileName]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Some issue access Dropbox ChronicleMap folder." message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (BOOL) dropboxFolderAlreadyExist:(NSError*)error
{
    if (error.code == 403 && [(NSString*)[error.userInfo objectForKey:@"error"] rangeOfString:@"already exists" options:NSCaseInsensitiveSearch].location != NSNotFound)
        return true;
    else
        return false;
}
- (BOOL) dropboxDeleteFileNotExist:(NSError*)error
{
    if (error.code == 404 && [(NSString*)[error.userInfo objectForKey:@"error"] rangeOfString:@"not found" options:NSCaseInsensitiveSearch].location != NSNotFound)
        return true;
    else
        return false;
}

-(void) helpClicked:(id)sender //Only iPad come here. on iPhone will be frome inside settings and use push segue
{
    ATHelpWebView *helpView = [[ATHelpWebView alloc] init];//[storyboard instantiateViewControllerWithIdentifier:@"help_webview_id"];
    
    [self.navigationController pushViewController:helpView animated:true];
}

- (DBRestClient *)myRestClient {
    if (!self._restClient) {
        self._restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self._restClient.delegate = self;
    }
    return self._restClient;
}
@end
