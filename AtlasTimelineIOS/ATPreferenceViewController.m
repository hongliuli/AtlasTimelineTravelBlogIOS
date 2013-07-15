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
    int copyCount;
    int deleteCount;
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
    self.detailLabel.text = _source;
    
    //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    // {
    //     UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStyleBordered target:self action:@selector(helpClicked:)];
    //     self.navigationItem.rightBarButtonItems = @[helpButton];
    // }
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    if ([segue.identifier isEqualToString:@"PeriodPick"]) {
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
        NSLog(@"download segue clicked");
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        NSLog(@"init PreferenceViewController");
        _source = [ATHelper getSelectedDbFileName];
    }
    return self;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"upload clicked view clicked row is %i" , indexPath.row);
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    int cnt = [appDelegate.eventListSorted count];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:@"Sync %i events to %@ on server",cnt, [ATHelper getSelectedDbFileName]]
                                                   message: [NSString stringWithFormat:@"Upload will replace existing %@ events on server.",_source]
                                                  delegate: self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Upload & Replace",@"Cancel & Logout",nil];
    
    
    [alert show];
    
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        NSLog(@"user canceled upload");
        // Any action can be performed here
    }
    else if (buttonIndex == 1)
    {
        NSLog(@"user want continues to upload");
        [self startUploadJson];
    }
    else
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
        [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
    }
}

-(void)startUploadJson
{
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
    NSLog(@"============post url = %@", serviceUrl.absoluteString);
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
    if (![returnStatus isEqual:@"SUCCESS"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Failed!" message:@"Fail reason could be network issue or data issue!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Success!"
                                                        message: [NSString stringWithFormat:@"%i %@ events has been uploaded to server successfully!",eventCount,[ATHelper getSelectedDbFileName]]
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
            int numberOfNewPhotos = [dataController getNewPhotoQueueSize];
            int numberOfDeletedPhoto = [dataController getDeletedPhotoQueueSize];
            cell.textLabel.text = [NSString stringWithFormat:@"%@  New:%d  Del:%d", cell.textLabel.text,numberOfNewPhotos,numberOfDeletedPhoto ];
        }
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
            }
            [[self myRestClient] createFolder:@"/ChronicleMap"]; //createFolder success/alreadyExist delegate will do the chain action
        }
    }
}
//Because of the DBRestClient's asynch nature, I have to implement a synchronous way:
/*
 * 1. create /ChronicleMap fold. if success of fail with already-exists then create Source Folder (such as myEvents)
 * 2. if detected create Source success or already exist, then call createPhotoEventDir(), which will pop one photo entry
 * 3. in createPhotoEventDir() do:
 *      . popup one photo entry, save to a global var currentPhotoEventPath
 *      . create event dir. In createFolder delegate, if success or already exist, call restClient uploadFile(currentPhotoEnventPath)
 * 4. in uploadFile success delegate:
 *      . delete from sqlite queue
 *      . call createPhotoEventDir() which loops back to popup next photo from newAddedPhotoQueue table
 *
 * For delete should be simpler: delete next only
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
    if ([self dropboxFolderAlreadyExist:error])
    {
        NSLog(@"   ------ Folder Fail Error %@",error);
        if ( [@"/ChronicleMap" isEqualToString:(NSString*)[error.userInfo objectForKey:@"path"]]) //TODO
        {
            NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName] ];
            [[self myRestClient ] createFolder:destDir]; //delegate come back with following if
        }
        else if ([[NSString stringWithFormat:@"/ChronicleMap/%@", [ATHelper getSelectedDbFileName] ] isEqualToString:(NSString*)[error.userInfo objectForKey:@"path"]])
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
    
    NSString* file = [[self getDataController] popDeletedPhototQueue];
    if (file != nil )
    {
        NSArray* tmpArray = [file componentsSeparatedByString:@"/"];
        currentEventId = tmpArray[0];
        currentPhotoName = tmpArray[1];
        //part of chain action: createFolder delegate will do uploadFile to dropbox when success or fail with 403 (folder already exist
        [[self myRestClient] deletePath:[ NSString stringWithFormat:@"%@/%@/%@", destDir, tmpArray[0], tmpArray[1] ]];
    }
    else if (copyCount > 0 || deleteCount > 0)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Copy to Dropbox completed!"
                                                       message: [NSString stringWithFormat:@"Add:%d/Delete:%d files in Dropbox succesfully.",copyCount,deleteCount]
                                                      delegate: self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil,nil];
        
        
        [alert show];
    }
}

//delegate called by upload to dropbox
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    [[self getDataController] emptyNewPhotoQueue:[NSString stringWithFormat:@"%@/%@" ,currentEventId, currentPhotoName]];
    copyCount++;
    [self startProcessNewPhotoQueueChainAction]; //start upload next file until 
    NSLog(@"====File uploaded successfully to path: %@", metadata.path);
}
- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    deleteCount++;
    [[self getDataController] emptyDeletedPhotoQueue:[NSString stringWithFormat:@"%@/%@", currentEventId, currentPhotoName]];
    [self processEmptyDeletedPhotoQueue];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Could not copy file to Dropbox"
                                                   message: @"May be the network is not available"
                                                  delegate: self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil,nil];
    
    
    [alert show];
}

- (BOOL) dropboxFolderAlreadyExist:(NSError*)error
{
    if (error.code == 403 && [(NSString*)[error.userInfo objectForKey:@"error"] rangeOfString:@"already exists" options:NSCaseInsensitiveSearch].location != NSNotFound)
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
