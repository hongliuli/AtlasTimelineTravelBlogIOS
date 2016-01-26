//
//  ATPreferenceViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATDataController.h"
#import "ATPreferenceViewController.h"
#import "ATDownloadTableViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"
#import "ATHelpWebView.h"
#import "ATInAppPurchaseViewController.h"
#import "ATOptionsTableViewController.h"
#import "SWRevealViewController.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

#define SECTION_LOGIN_EMAIL 0
#define SECTION_CONTENT_MANAGE 1
#define SECTION_MISC 2

#define ROW_INBOX 0
#define ROW_CONTENT_MG_MY_EPISODE 1

#define ROW_OPTIONS 0
#define ROW_VIDEO_TUTORIAL 1

#define FOR_SHARE_MY_EVENTS 1

#define DOWNLOAD_REPLACE_MY_SOURCE_TO_MYEVENTS_ALERT 100
#define DOWNLOAD_MYEVENTS_CONFIRM 101

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

    int downloadAlreadyExistCount;
    int totalPhotoCountInDevice;
    BOOL isEventDir;
    BOOL isRemoveSourceForUploadAll;
    BOOL showDownloadAllLoadMetadataErrorAlert;

    UIActivityIndicatorView* spinner;
    
    UIAlertView* uploadAlertView;
    UIAlertView* confirmUploadAllPhotoAlertView;
    UIAlertView* confirmUploadContentAlertView;
    
    UIButton* logoutButton;
    UILabel* loginEmailLabel;
    
    BOOL hasNewIncomingShareFlag;
    NSString* currentEventMetapath;
    UIProgressView* progressDownloadOveralView;
    UIProgressView* progressDownloadDetailView;
    int progressDownloadTotalNumberOfEvents;
    int progressDownloadTotalNumberOfPhotosInOneEvent;
    int progressDownloadEventCount;
    int progressDownloadPhotoCount;
    
    UIProgressView* progressUploadView;
    int progressUploadTotalCount;
    int progressUploadPhotoCount;
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
    hasNewIncomingShareFlag = false;
    spinner = [[UIActivityIndicatorView alloc]
               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(0,0,60,60);
    spinner.center =  CGPointMake(160, 200); //set self.view center does not work
    //spinner.hidesWhenStopped = YES;
    [[self  view] addSubview:spinner];
    self.detailLabel.text = _source;
    
    SWRevealViewController* revealController = [self revealViewController];
    UIBarButtonItem *timelineBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"arrow-right.png"] style:UIBarButtonItemStylePlain target:revealController action:@selector(rightRevealToggle:)];
    self.navigationItem.leftBarButtonItem = timelineBarButtonItem;
    
    [self refreshDisplayStatusAndData];
    
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwiper];
    
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
}


- (void)swipeRight {
    SWRevealViewController *revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
}

- (void)refreshDisplayStatusAndData
{
    //Check if there are new incoming. This logic is duplicated from ATDownloadViewController
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    if (userId == nil)
        return;
    NSString* serviceUrl = [NSString stringWithFormat:@"%@/retreivelistofcontents?user_id=%@&security_code=%@",[ATConstants ServerURL], userId, securityCode];
    NSString* responseStr = [ATHelper httpGetFromServer:serviceUrl :false];
    NSArray* libraryList = nil;
    if (responseStr == nil)
        return;
    else
        libraryList = [responseStr componentsSeparatedByString:@"|"];
    for (int i=0; i< [libraryList count]; i++)
    {
        NSString* item = libraryList[i];
        if (item != nil && [item hasPrefix:@"1*"])
        {
            hasNewIncomingShareFlag = true;
            break;
        }
    }
}


//This is delegate, will be called from ATDownloadTableView didSelect..
- (void)downloadTableViewController: (ATDownloadTableViewController *)controller
                    didSelectSource:(NSString *)source{
    //########################################
    // If user select a large period, then map may be slow if there is too many annotations. but I could not do anything to prevent it.
    //########################################
    _source = source;
    self.detailLabel.text = _source ;
    [ATHelper setSelectedDbFileName:_source];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate emptyEventList];
    //////////////[appDelegate.mapViewController cleanAnnotationToShowImageSet];
    [appDelegate.mapViewController prepareMapView];
    [appDelegate.mapViewController refreshEventListView:false];
    [self.navigationController popViewControllerAnimated:YES];
    isRemoveSourceForUploadAll = false;
    [self.tableView reloadData]; //reload so active source name will be display when back to preference view
    
    SWRevealViewController* revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
}

- (void)sourceChooseViewController: (ATSourceChooseViewController *)controller
                  didSelectEpisode:(NSString *)episodeName{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    //////////////[appDelegate.mapViewController loadEpisode:episodeName];
    //  ???????   TODO does not work , why   ??????????
    [appDelegate.mapViewController cancelPreference];
    [self.navigationController removeFromParentViewController];
    [self dismissViewControllerAnimated:NO completion:nil]; //for iPhone case
    
    SWRevealViewController* revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
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

//prepareForSegue() is useful for pass values to called storyboard objects
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"share_my_episode"]) {
        ATSourceChooseViewController *sourceChooseViewController = segue.destinationViewController;
        sourceChooseViewController.delegate = self;
        sourceChooseViewController.source = _source;
        sourceChooseViewController.requestType = FOR_SHARE_MY_EVENTS;
    }
    if ([segue.identifier isEqualToString:@"options_id"]) {
        ATOptionsTableViewController *optionPage = segue.destinationViewController;
        optionPage.parent = self;
    }
    if ([segue.identifier isEqualToString:@"download"]) {
        ATDownloadTableViewController *downloadTableViewController = segue.destinationViewController;
        downloadTableViewController.delegate = self;
        downloadTableViewController.parent = self;
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _source = [ATHelper getSelectedDbFileName];
    }
    return self;
}

- (void)startExport
{
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //Need alert again?  checkUserEmailAndSecurityCode already alerted
        return;
    }
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString* sourceName = appDelegate.sourceName;
    if (![@"myEvents" isEqualToString:sourceName])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"myEvents need to be shown on map",nil) message:NSLocalizedString(@"Please pick myEvents to show on map and try again",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSUInteger cnt = [appDelegate.eventListSorted count];
    
    uploadAlertView = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Sync %i events to %@ on server",nil),cnt, [ATHelper getSelectedDbFileName]]
                                                message: [NSString stringWithFormat:NSLocalizedString(@"WARNING: Export will replace existing %@ event data on server.",nil),_source]
                                               delegate: self
                                      cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                      otherButtonTitles:NSLocalizedString(@"Export & Replace",nil),nil];
    
    
    [uploadAlertView show];
    
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == DOWNLOAD_REPLACE_MY_SOURCE_TO_MYEVENTS_ALERT )
    {
        if (buttonIndex == 0)
            return; //user clicked cancel button
        UIAlertView* alert  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Confirm to replace %@ contents in your device!",nil),[ATHelper getSelectedDbFileName]]
                                                         message:NSLocalizedString(@"Enter agree to continue:",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        UITextField * aa = [alert textFieldAtIndex:0];
        aa.placeholder = @"agree";
        alert.tag = DOWNLOAD_MYEVENTS_CONFIRM;
        [alert show];
    }
    if (alertView.tag == DOWNLOAD_MYEVENTS_CONFIRM)
    {
        UITextField *agree = [alertView textFieldAtIndex:0];
        if ([agree.text caseInsensitiveCompare:@"agree"] == NSOrderedSame)
        {
            [ATHelper startReplaceDb:@"myEvents" :downloadedMyEventsJsonArray :spinner];
            [self changeSelectedSource: @"myEvents"];
            downloadedMyEventsJsonArray = nil;
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You canceled replacing offline content!",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
    }
    if (alertView == uploadAlertView)
    {
        if (buttonIndex == 0)
        {
            //NSLog(@"user canceled upload");
            // Any action can be perfhttp://www.wenxuecity.com/news/2014/05/10/3255854.htmlormed here
        }
        else if (buttonIndex == 1)
        {
            confirmUploadContentAlertView  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Confirm to replace %@ contents on server!",nil),[ATHelper getSelectedDbFileName]]
                                                                        message:NSLocalizedString(@"Enter agree to continue:",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [confirmUploadContentAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            UITextField * aa = [confirmUploadContentAlertView textFieldAtIndex:0];
            aa.placeholder = @"agree";
            [confirmUploadContentAlertView show];
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You canceled uploading the content to server",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
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
    
    
    NSDateFormatter* usDateFormater = [appDelegate.dateFormater copy];
    //always use USLocale to save date in JSON, so always use it to read. this resolve a big issue when user upload with one local and download with another local setting.
    // See ATHelper startDownload
    [usDateFormater setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    
    NSArray *myAtlasList = appDelegate.eventListSorted;
    NSInteger eventCount = [myAtlasList count];
    NSMutableArray* dictArray = [[NSMutableArray alloc] initWithCapacity:eventCount];
    for (ATEventDataStruct* item in myAtlasList)
    {
        NSNumber* eventType = [NSNumber numberWithInt: item.eventType]; //not initialized in code, need fix
        if (eventType == nil)
            eventType = [NSNumber numberWithInt:EVENT_TYPE_NO_PHOTO];
        
        NSMutableDictionary* itemDict = [[NSMutableDictionary alloc] init];
        [itemDict setObject:item.uniqueId forKey:@"uniqueId"];
        [itemDict setObject:item.eventDesc forKey:@"eventDesc"];
        [itemDict setObject:[usDateFormater stringFromDate:item.eventDate] forKey:@"eventDate"]; //NSDate is not serializable
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
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export Failed!",nil) message:NSLocalizedString(@"Fail reason could be network issue or data issue!",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export Success!",nil)
                                                        message: [NSString stringWithFormat:NSLocalizedString(@"%i %@ events have been uploaded to server successfully!",nil),eventCount,[ATHelper getSelectedDbFileName]]
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
}


#pragma mark - Table view delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    int retCount = 0;
    if (section == SECTION_LOGIN_EMAIL)
        retCount = 1;
    else if (section == SECTION_CONTENT_MANAGE)
        retCount = 2;
    else  //SECTION_SUPPORT...
        retCount = 2;
    
    return retCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    UITableViewCell *cell = nil;
    if (section == SECTION_CONTENT_MANAGE)
    {
        NSString* cellIdentifier = @"cell_type_mg";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if( cell == nil )
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
    }
    else
    {
        NSString* cellIdentifier = @"cell_type_other";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if( cell == nil )
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell.imageView setImage:nil];
    long row = indexPath.row;
    if (section == SECTION_CONTENT_MANAGE)
    {
        if (row == ROW_CONTENT_MG_MY_EPISODE)
        {
            cell.textLabel.text = NSLocalizedString(@"Share my Episodes to Friends",nil);
            cell.detailTextLabel.text = NSLocalizedString(@"Send episodes / Invite Friends",nil);
        }
        if (row == ROW_INBOX)
        {
            cell.textLabel.text = NSLocalizedString(@"Collection Box",nil);
            cell.detailTextLabel.text = NSLocalizedString(@"Pick an item to show; recover myEvents..",nil);
            if (hasNewIncomingShareFlag)
            {
                UIImage *img = [UIImage imageNamed:@"new-message-red-dot"];
                UIImageView *icon = [[UIImageView alloc] initWithImage:img];
                [icon setFrame:CGRectMake(0, 0, 18, 18)];
                cell.textLabel.text = [NSString stringWithFormat:@"    %@", cell.textLabel.text ];
                [cell.textLabel addSubview:icon];
            }
        }
    }
    else if (section == SECTION_LOGIN_EMAIL)
    {
        if (row == 0)
        {
            cell.textLabel.text = @"其它旅行玩家博客";
            [cell.imageView setImage:[UIImage imageNamed:@"star-red-orig-purple.png"]];
        }
    }
    else if (section == SECTION_MISC)
        
    {
        switch (row) {
            case ROW_OPTIONS:
                cell.textLabel.text = NSLocalizedString(@"Options",nil);
                [cell.imageView setImage:nil];
                break;
            case ROW_VIDEO_TUTORIAL:
                cell.textLabel.text = NSLocalizedString(@"Video Tutorial and FAQ",nil);
                break;
            default:
                break;
        }
        
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
    label.textColor = [UIColor lightGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    // create the parent view that will hold header Label
    if (section == SECTION_CONTENT_MANAGE)
    {
        /**** TODO **** add refersh button for later implement auto synch. Also see unused smartDownloadMyEvents() function
         //Show full sync button only when:
         //  1. not logged in yet
         //  2. current active contents is myEvents
         UIButton* refreshBtn =[UIButton buttonWithType:UIButtonTypeCustom];
         [refreshBtn setImage:[UIImage imageNamed:@"Refresh-icon.png"] forState:UIControlStateNormal];
         [refreshBtn addTarget:self action:@selector(fullSyncMyEvents:) forControlEvents:UIControlEventTouchUpInside];
         refreshBtn.frame = CGRectMake(10, -10, 40, 40);
         //TODO if not login, and first time, and ....... see document
         [customView addSubview:refreshBtn];
         ******/
        NSUInteger loc = [_source rangeOfString:@"*"].location;
        NSString* namePart = _source;
        if (loc != NSNotFound)
            namePart =  [_source substringToIndex:loc];
        label.text = [NSString stringWithFormat:NSLocalizedString(@"On Map: %@",nil), namePart];
    }
    if (section == SECTION_LOGIN_EMAIL)
    {
        label.textAlignment = NSTextAlignmentLeft;
        NSString* loginEmail = nil;
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
        if (userEmail != nil)
            loginEmail = userEmail;
        else
            loginEmail = @"";
        
        label.text = loginEmail;
        
        if (userEmail != nil)
        {
            logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
            logoutButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
            logoutButton.frame = CGRectMake(210, -10, 60, 50);
            [logoutButton setTitle:NSLocalizedString(@"Logout",nil) forState:UIControlStateNormal];
            [logoutButton.titleLabel setTextColor:[UIColor blueColor]];
            [logoutButton addTarget:self action:@selector(logoutButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [customView addSubview:logoutButton];
        }
        else
        {
            logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
            logoutButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
            logoutButton.frame = CGRectMake(210, -10, 60, 50);
            [logoutButton setTitle:NSLocalizedString(@"Login",nil) forState:UIControlStateNormal];
            [logoutButton.titleLabel setTextColor:[UIColor blueColor]];
            [logoutButton addTarget:self action:@selector(loginButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [customView addSubview:logoutButton];
        }
    }
    if (section == SECTION_MISC)
    {
        label.text = NSLocalizedString(@"Misc",nil);
    }
    [customView addSubview:label];
    return customView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44; //44 is default value in object-c tablecell view
}
- (ATDataController*)getDataController
{
    if (privateDataController == nil)
        privateDataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    return privateDataController;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    if (section == SECTION_CONTENT_MANAGE)
        [self handleContentManageSection:tableView :indexPath ];
    if (section == SECTION_LOGIN_EMAIL)
        [self handleLoginEmailSection:tableView :indexPath ];
    if (section == SECTION_MISC)
        [self handleMiscSection:tableView :indexPath ];
}
-(void) handleMiscSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    long row = indexPath.row;
    if (row == ROW_OPTIONS)
    {
        [self performSegueWithIdentifier:@"options" sender:nil];
    }
    if (row == ROW_VIDEO_TUTORIAL)
    {
        NSURL *url = [NSURL URLWithString:@"http://www.chroniclemap.com/onlinehelp"];
        if (![[UIApplication sharedApplication] openURL:url])
            NSLog(@"%@%@",@"Failed to open url:",[url description]);
    }
}
-(void) handleContentManageSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    //also see prepareForSegue() where pass values
    if (indexPath.row == ROW_CONTENT_MG_MY_EPISODE)
    {
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([@"myEvents" isEqualToString:appDelegate.sourceName])
            [self performSegueWithIdentifier:@"share_my_episode" sender:nil];
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Please pick myEvents to show on map!",nil)
                                                           message: NSLocalizedString(@"You can share your episode only when myEvents is on map",nil)
                                                          delegate: self
                                                 cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                 otherButtonTitles:nil,nil];
            
            
            [alert show];
        }
    }
    else if (indexPath.row == ROW_INBOX)
        [self performSegueWithIdentifier:@"download" sender:nil];
    
}
-(void) handleLoginEmailSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    //also see prepareForSeque() where pass values
    if (indexPath.row == 0)
        [self performSegueWithIdentifier:@"choose_poi" sender:nil];
}

//Unused, just created for later implement auto synch mysevnts
-(void) smartDownloadMyEvents
{
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //Need alert again?  checkUserEmailAndSecurityCode already alerted
        return;
    }
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    long localListCnt = [appDelegate.eventListSorted count];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    //continues to get from server
    NSString* userId = userEmail;
    
    NSString* atlasName = @"myEvents";
    
    //TODO need pass LUT (last upload time) to server
    NSURL* serviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/downloadjsoncontents?user_id=%@&security_code=%@&atlas_name=%@",[ATConstants ServerURL], userId, securityCode, atlasName]];
    
    NSData* downloadedData = [NSData dataWithContentsOfURL:serviceUrl];
    if (downloadedData == nil)
        return;
    NSString* displayLocalCnt = @"";
    if ([[ATHelper getSelectedDbFileName] isEqualToString :atlasName])
        displayLocalCnt = [NSString stringWithFormat:@"%ld", localListCnt];
    
    NSError* error;
    downloadedMyEventsJsonArray = [NSJSONSerialization JSONObjectWithData:downloadedData options:kNilOptions error:&error];
    
    [ATHelper startReplaceDb:@"myEvents" :downloadedMyEventsJsonArray :nil];
}

//this function is almost identical in ATDownloadTableViewController's startDownload functions
// (Dec, 2015: download MyEvents will be in smartDownloadMyEvents()
-(void) startDownloadMyEventsJson
{
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //Need alert again?  checkUserEmailAndSecurityCode already alerted
        return;
    }
    [spinner startAnimating];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    long localListCnt = [appDelegate.eventListSorted count];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    //continues to get from server
    NSString* userId = userEmail;
    
    NSString* atlasName = @"myEvents";
    NSURL* serviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/downloadjsoncontents?user_id=%@&security_code=%@&atlas_name=%@",[ATConstants ServerURL], userId, securityCode, atlasName]];
    
    NSData* downloadedData = [NSData dataWithContentsOfURL:serviceUrl];
    if (downloadedData == nil)
        return;
    NSString* displayLocalCnt = @"";
    if ([[ATHelper getSelectedDbFileName] isEqualToString :atlasName])
        displayLocalCnt = [NSString stringWithFormat:@"%ld", localListCnt];
    
    NSError* error;
    downloadedMyEventsJsonArray = [NSJSONSerialization JSONObjectWithData:downloadedData options:kNilOptions error:&error];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Downloaded %@ has %i events",nil),atlasName,[downloadedMyEventsJsonArray count]]
                                                   message: [NSString stringWithFormat:NSLocalizedString(@"WARNING: Local %@'s %@ events will be replaced!",nil),@"myEvents",displayLocalCnt]
                                                  delegate: self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                         otherButtonTitles:NSLocalizedString(@"Replace",nil),nil];
    alert.tag = DOWNLOAD_REPLACE_MY_SOURCE_TO_MYEVENTS_ALERT;
    [spinner stopAnimating];
    [alert show];
}

- (void) logoutButtonAction: (id)sender {
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
    [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
    [logoutButton setTitle:@"" forState: UIControlStateNormal];
    [loginEmailLabel setText:NSLocalizedString(@"Not login",nil)];
}
- (void) loginButtonAction: (id)sender {
    [ATHelper checkUserEmailAndSecurityCode:self];
    [logoutButton setTitle:@"" forState: UIControlStateNormal];
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

-(void) helpClicked:(id)sender //Only iPad come here. on iPhone will be frome inside settings and use push segue
{
    ATHelpWebView *helpView = [[ATHelpWebView alloc] init];//[storyboard instantiateViewControllerWithIdentifier:@"help_webview_id"];
    
    [self.navigationController pushViewController:helpView animated:true];
}


@end
