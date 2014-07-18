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
        UITextField *agree = [alertView textFieldAtIndex:0];
        if ([agree.text caseInsensitiveCompare:@"agree"] == NSOrderedSame)
        {
            [spinner startAnimating];
            isRemoveSourceForUploadAll = true; //so if /ChronicleReader/myEvent not on dropbox yet, delete fail will know the case
            [[self myRestClient] deletePath:[NSString stringWithFormat:@"/ChronicleReader/%@", [ATHelper getSelectedDbFileName]]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"The upload started and [New] number is decreasing.\n If number reach 0 then full back up is done.\n If number stop at non-zero, then tap [Photo Backup] row to continue.",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You Canceled uploading all photos to Dropbox",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
    }
    if (alertView == downloadAllFromDropboxAlert)
    {
        if (buttonIndex == 0)
        {
            return; //user canceled download all
        }
        onlyShowOnceForIssueWithDropbox = true;
        showDownloadAllLoadMetadataErrorAlert = true;
        totalDownloadFromDropboxSuccessCount = 0;
        [self startDownload];
    }
}

-(void) startDownload
{
    //if local path does not exist, loadFile will not write
    NSString* localFullPath = [ATHelper getPhotoDocummentoryPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:localFullPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:localFullPath withIntermediateDirectories:YES attributes:nil error:nil];
    downloadFromDropboxStartCount = 0;
    downloadFromDropboxSuccessCount = 0;
    downloadFromDropboxFailCount = 0;
    downloadFromDropboxLoadMedadataFailCount = 0;
    downloadAlreadyExistCount = 0;

    if ([eventListToCopyPhotoFromDropbox count] > 0)
        [spinner startAnimating];
    for(NSString* eventId in eventListToCopyPhotoFromDropbox)
    {
        //local path has to exist for loadFile to save. But local path may not exist after re-install app so need do it here
        if (![[NSFileManager defaultManager] fileExistsAtPath:[localFullPath stringByAppendingPathComponent:eventId]])
            [[NSFileManager defaultManager] createDirectoryAtPath:[localFullPath stringByAppendingPathComponent:eventId] withIntermediateDirectories:YES attributes:nil error:nil];
        [[self myRestClient] loadMetadata:[NSString stringWithFormat:@"/ChronicleReader/%@/%@", [ATHelper getSelectedDbFileName], eventId]]; //then see loadedMetadata delegate where we start download file
    }
    //NSLog(@"---------- spinner stop %d", downloadAlreadyExistCount);
    [spinner stopAnimating];
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
    int section = indexPath.section;

    if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
        [self handleSynchPhotoSection:tableView :indexPath];
}


-(void) handleLoginEmailSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    //also see prepareForSeque() where pass values
    [self performSegueWithIdentifier:@"options" sender:nil];
}



-(void) handleSynchPhotoSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    int row = indexPath.row;
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
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo Backup - New:%d  Del:%d",nil),dbNewPhotoCount,dbDeletedPhotoCount ];
        if (dbNewPhotoCount + dbDeletedPhotoCount > 0)
        {
            [spinner startAnimating]; //stop when chain complete or any error
        }
        if (dbNewPhotoCount > 0) //will process both queue
            [[self myRestClient] createFolder:@"/ChronicleReader"]; //createFolder success/alreadyExist delegate will start the chain action, which will include delete Queue
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
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"No photos to export to your Dropbox!",nil)
                                                           message: @""
                                                          delegate: self
                                                 cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                 otherButtonTitles:nil,nil];
            
            
            [alert show];
        }
        else
        {
            uploadAllToDropboxAlert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Replace photos on Dropbox for %@",nil), [ATHelper getSelectedDbFileName]]
                                                                message: [NSString stringWithFormat:NSLocalizedString(@"WARNING: All photoes on your dropbox:/ChoronicleMap/%@ will be deleted and replaced by %d photos from this device!",nil),_source, totalPhotoCountInDevice]
                                                               delegate: self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                      otherButtonTitles:NSLocalizedString(@"Yes, Continue",nil),nil];
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
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Content %@ is empty or do not have photos to download.",nil), [ATHelper getSelectedDbFileName]]
                                                           message: NSLocalizedString(@"This content may not have photos.",nil)
                                                          delegate: self
                                                 cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                 otherButtonTitles:nil,nil];
            
            
            [alert show];
        }
        else
        {
            downloadAllFromDropboxAlert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Import photos from Dropbox:/ChronicleReader/%@",nil), [ATHelper getSelectedDbFileName]]
                            message: [NSString stringWithFormat:NSLocalizedString(@"Download missing %@ photos from Dropbox. This operation can be repeated until all photos are downloaded.",nil),[ATHelper getSelectedDbFileName]]
                            delegate: self
                            cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                            otherButtonTitles:NSLocalizedString(@"Yes, Continue",nil),nil];
            [downloadAllFromDropboxAlert show];
        }
    }
}

- (void) logoutButtonAction: (id)sender {
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
    [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
    [logoutButton setTitle:@"" forState: UIControlStateNormal];
    [loginEmailLabel setText:NSLocalizedString(@"Not login",nil)];
}

//Because of the DBRestClient's asynch nature, I have to implement a synchronous way:
/*
 * 1. create /ChronicleReader fold. if success or fail with already-exists then create Source Folder (such as myEvents)
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
    if ( [@"/ChronicleReader" isEqualToString:[folder path]])
    {
        NSString *destDir = [ NSString stringWithFormat:@"/ChronicleReader/%@",  [ATHelper getSelectedDbFileName] ];
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
        if ( [@"/ChronicleReader" isEqualToString:(NSString*)[error.userInfo objectForKey:@"path"]]) //TODO
        {
            NSString *destDir = [ NSString stringWithFormat:@"/ChronicleReader/%@",  [ATHelper getSelectedDbFileName]];
            [[self myRestClient ] createFolder:destDir]; //delegate come back with following if
        }
        else if ([[NSString stringWithFormat:@"/ChronicleReader/%@", [ATHelper getSelectedDbFileName]] isEqualToString:(NSString*)[error.userInfo objectForKey:@"path"]])
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
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Could not copy to Dropbox",nil)
                            message: NSLocalizedString(@"May be the network is not available",nil)
                            delegate: self
                            cancelButtonTitle:NSLocalizedString(@"OK",nil)
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
    NSString *destDir = [ NSString stringWithFormat:@"/ChronicleReader/%@",  [ATHelper getSelectedDbFileName]];

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
    NSString *destDir = [ NSString stringWithFormat:@"/ChronicleReader/%@",  [ATHelper getSelectedDbFileName]];
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
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Copy to Dropbox completed!",nil)
                    message: [NSString stringWithFormat:NSLocalizedString(@"Add:%d/Delete:%d files in Dropbox succesfully.",nil),uploadSuccessExcludeThumbnailCount,deleteCount]
                    delegate: self
                    cancelButtonTitle:NSLocalizedString(@"OK",nil)
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
        PhotoToDropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo Backup - New:%d  Del:%d",nil),dbNewPhotoCount, dbDeletedPhotoCount];
    }
    [self startProcessNewPhotoQueueChainAction]; //start upload next file until
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [spinner stopAnimating];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Could not copy file to Dropbox",nil)
                message: NSLocalizedString(@"May be the network is not available",nil)
                delegate: self
                cancelButtonTitle:NSLocalizedString(@"OK",nil)
                otherButtonTitles:nil,nil];
    
    
    [alert show];
}
- (BOOL) prepareUploadAllToDropbox //call this after remove ChronicleReader/myEvent on dropbox successfully
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
        NSString *destDir = [ NSString stringWithFormat:@"/ChronicleReader/%@",  [ATHelper getSelectedDbFileName] ];
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
        PhotoToDropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo Backup - New:%d  Del:%d",nil),dbNewPhotoCount, dbDeletedPhotoCount];
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
            NSString *destDir = [ NSString stringWithFormat:@"/ChronicleReader/%@",  [ATHelper getSelectedDbFileName] ];
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
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Could not access Dropbox",nil)
                message: NSLocalizedString(@"May be the network is not available",nil)
                delegate: self
                cancelButtonTitle:NSLocalizedString(@"OK",nil)
                otherButtonTitles:nil,nil];
        
        
        [alert show];
    }
}

//following loadedMetadata delegate is for copy from dropbox to device. When it come here after loadMetaData() called with eventId
//so here is a directory for the eventId
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    if (metadata.isDirectory) {
        //NSLog(@"Folder '%@' contains:", metadata.path);
        for (DBMetadata *file in metadata.contents) {
            //NSLog(@"\t%@", file.filename);
            NSString* localPhotoPath = [[[ATHelper getRootDocumentoryPath] stringByAppendingPathComponent:currentEventId] stringByAppendingPathComponent:currentPhotoName];
            NSString* partialPath = [metadata.path substringFromIndex:17]; //metadata.path is "/ChronicleReader/myEvents/eventid"
            localPhotoPath = [[localPhotoPath stringByAppendingPathComponent:partialPath] stringByAppendingPathComponent:file.filename];

            if (![[NSFileManager defaultManager] fileExistsAtPath:localPhotoPath]){
                //NSLog(@"------ Local file not exist %@",localPhotoPath);
                [[self myRestClient] loadFile:[NSString stringWithFormat:@"%@/%@", metadata.path, file.filename ] intoPath:localPhotoPath];
            }
            else
            {
                downloadAlreadyExistCount ++;
            }

            if (![file.filename isEqualToString:@"thumbnail"])
            {
                downloadFromDropboxStartCount++;
            }
        }
        //following is to prompt user that device already has all photos in dropbox
        if ( [photoFromDropboxCell.textLabel.text isEqualToString:RESTORE_PHOTO_TITLE])
                photoFromDropboxCell.textLabel.text = NSLocalizedString(@"All photos are already downloaded",nil);
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
                //come here if directory in Dropbox cannot be found while we think it should. It may happen if /ChronicleReader/xxsourcexx is not in dropbox, Or it may also happen if we manually remove some directory from dropbox for this content
                downloadFromDropboxLoadMedadataFailCount ++;
                [self promptCopyFromDropboxStatus];
            }
            return;
        }

        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Could not import from Dropbox",nil)
               message: NSLocalizedString(@"May be the network is not available",nil)
               delegate: self
               cancelButtonTitle:NSLocalizedString(@"OK",nil)
               otherButtonTitles:nil,nil];
    
    
        [alert show];
    }
}
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    if (![localPath hasSuffix:@"thumbnail" ])
    {
        downloadFromDropboxSuccessCount++;
        photoFromDropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloading .. %d success, %d warnings",nil), totalDownloadFromDropboxSuccessCount + downloadFromDropboxSuccessCount, downloadFromDropboxFailCount];
    }
	[self promptCopyFromDropboxStatus];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    downloadFromDropboxFailCount++;
    photoFromDropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloading ... %d success, %d warnings",nil), totalDownloadFromDropboxSuccessCount, downloadFromDropboxFailCount];
    [self promptCopyFromDropboxStatus];
}

- (void)promptCopyFromDropboxStatus
{
    //NSLog(@" ----- download success=%d, failed=%d, total=%d",downloadFromDropboxSuccessCount,downloadFromDropboxFailCount,downloadFromDropboxStartCount);
    if (   downloadFromDropboxSuccessCount + downloadFromDropboxFailCount + downloadAlreadyExistCount == downloadFromDropboxStartCount
        && downloadFromDropboxStartCount > 0)
    {
        totalDownloadFromDropboxSuccessCount = totalDownloadFromDropboxSuccessCount + downloadFromDropboxSuccessCount;
        if (downloadFromDropboxFailCount > 0)
        {
            [self startDownload];
            return;
        }
        [spinner stopAnimating];
        NSString* message;
        if (downloadFromDropboxFailCount == 0)
            message = [NSString stringWithFormat: NSLocalizedString(@"%d photos have been downloaded to your device from Dropbox!",nil), totalDownloadFromDropboxSuccessCount ];
        else if (downloadFromDropboxSuccessCount == 0)
            message = [NSString stringWithFormat:NSLocalizedString(@"Import failed, please check if network is available, or if your Dropbox has photos in /ChronicleReader/%@ directory.",nil), [ATHelper getSelectedDbFileName]];
        else
            message = [NSString stringWithFormat:NSLocalizedString(@"Import photos from Dropbox: %d success, %d fail. Please make sure you have a good wifi connection and try again.",nil), totalDownloadFromDropboxSuccessCount,downloadFromDropboxFailCount];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import photos from Dropbox finished",nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
    }
    else if (downloadFromDropboxLoadMedadataFailCount > 0 && downloadFromDropboxSuccessCount + downloadFromDropboxFailCount == 0 && onlyShowOnceForIssueWithDropbox)
    { //this condition is used when loadMetadataWithError called the function
        onlyShowOnceForIssueWithDropbox = false;
        NSString* message = [NSString stringWithFormat:NSLocalizedString(@"This may happen if the app was uninstalled before export all photos to dropbox /ChronicleReader/%@ folder!",nil), [ATHelper getSelectedDbFileName]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox may not have some photos you are looking for.",nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
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
