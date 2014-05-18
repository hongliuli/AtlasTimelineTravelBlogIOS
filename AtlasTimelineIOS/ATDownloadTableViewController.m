//
//  ATDownloadTableViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 2/17/13.
//  Copyright (c) 2013 hong. All rights reserved.
//
#define DOWNLOAD_START_ALERT 1
#define DOWNLOAD_REPLACE_MY_SOURCE_ALERT 2
#define DOWNLOAD_AGAIN_ALERT 3
#define DOWNLOAD_CONFIRM 4
#define DELETE_INCOMING_ON_SERVER_CONFIRM 5

#import "ATDownloadTableViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"

@interface ATDownloadTableViewController ()

@end

@implementation ATDownloadTableViewController

NSMutableArray* filteredList;
NSMutableArray* localList;
NSString* selectedAtlasName;
NSArray* downloadedJson;
UIActivityIndicatorView* spinner;
int swipPromptCount;

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
    swipPromptCount = 0;
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    /*********  here is test for test *****/
   // [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
   // [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
   // [userDefault synchronize];
    /**********************************/

    localList = [[NSMutableArray alloc] initWithArray:[ATHelper listFileAtPath:[ATHelper applicationDocumentsDirectory]]];

    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    
    NSString* serviceUrl = [NSString stringWithFormat:@"%@/retreivelistofcontents?user_id=%@&security_code=%@",[ATConstants ServerURL], userId, securityCode];
    NSString* responseStr = [ATHelper httpGetFromServer:serviceUrl];
    NSArray* libraryList = nil;
    if (responseStr == nil)
        return;
    else
         libraryList = [responseStr componentsSeparatedByString:@"|"];
    filteredList = [[NSMutableArray alloc] init];
    //should use predicate to filter nil
    for (int i=0; i< [libraryList count]; i++)
    {
        NSString* item = libraryList[i];
        if (item != nil && [item length]>0)
            [filteredList addObject:libraryList[i]];
    }
    [filteredList removeObject:@"myEvents"]; //myEvents backup/restore is done in Settings->Backup/Restore myEvents data section
    
    filteredList = [[filteredList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];

    spinner = [[UIActivityIndicatorView alloc]
               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(160, 200);
    spinner.hidesWhenStopped = YES;
    [[self  view] addSubview:spinner];
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   // Return the number of rows in the section.
    return [filteredList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"downloadcellswap";
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        NSMutableArray *rightUtilityButtons = [NSMutableArray new];
        //see action in didTriggerRightUtilityButtonWithIndex
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:0.78f green:0.38f blue:0.5f alpha:1.0]
                                                    title:NSLocalizedString(@"Delete",nil)];
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                    title:NSLocalizedString(@"Download",nil)];
        cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier
                                  containingTableView:self.tableView // For row height and selection
                                   leftUtilityButtons:nil
                                  rightUtilityButtons:rightUtilityButtons];
        cell.delegate = self;
        cell.tag = indexPath.row;
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    }

    
    // Configure the cell...
    NSString* tmpAtlasName = filteredList[indexPath.row];
    BOOL unreadEpisode = false;
    if ([tmpAtlasName hasPrefix:@"1*"]) //1* means unreaded episode. see java serverside code
    {
        unreadEpisode = true;//so bold it as new message
        tmpAtlasName = [tmpAtlasName substringFromIndex:2]; //remove 1* when display in text, and this text will be used when download from server
    }
    
    
    if ([tmpAtlasName rangeOfString:@"*"].location != NSNotFound)
    {
        NSArray* nameList = [tmpAtlasName componentsSeparatedByString:@"*"];
        cell.textLabel.text = nameList[0];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@    %@",nameList[2], nameList[1]];
    }
    else
    {
        cell.textLabel.text = tmpAtlasName;
        cell.detailTextLabel.text = @"";
    }
    if ([localList containsObject:filteredList[indexPath.row]]){
        if ([filteredList[indexPath.row] isEqual:[ATConstants defaultSourceName]])
        {
            cell.textLabel.textColor = [UIColor blueColor];
        }
        else
        {
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        }
    }
    else{
        if (unreadEpisode)
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17.0];
        else
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

        if (swipPromptCount >= 1)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please swipe right",nil) message:[NSString stringWithFormat:@""] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
            swipPromptCount = 0;
        }
        else
        {
            swipPromptCount++;
        }
}

//swapable delegate
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    int row = cell.tag;
    selectedAtlasName = filteredList[row];
    switch (index) {
        case 0:
        {
            if ([selectedAtlasName hasPrefix:@"1*"])
                selectedAtlasName = [selectedAtlasName substringFromIndex:2];
            NSString* tmpAtlasName = selectedAtlasName;
            if ([tmpAtlasName rangeOfString:@"*"].location != NSNotFound)
            {
                NSArray* nameList = [tmpAtlasName componentsSeparatedByString:@"*"];
                tmpAtlasName = nameList[0];

            }
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Delete [%@] From Server",nil),tmpAtlasName]
                                                           message: NSLocalizedString(@"If you have downloaded it before, the offline one will stay until you remove the app. Are you sure to delete it from server?",nil)
                                                          delegate: self
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                 otherButtonTitles:NSLocalizedString(@"Continue",nil),nil];
            alert.tag = DELETE_INCOMING_ON_SERVER_CONFIRM;
            [alert show];

            break;
        }
        case 1:
        {
            if ([selectedAtlasName hasPrefix:@"1*"])
                selectedAtlasName = [selectedAtlasName substringFromIndex:2];
            if ([cell.textLabel.textColor isEqual:[UIColor lightGrayColor]])
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"%@ was downloaded before",nil),selectedAtlasName]
                                                               message: NSLocalizedString(@"Are you sure to replace your offline copy?",nil)
                                                              delegate: self
                                                     cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                     otherButtonTitles:NSLocalizedString(@"Continue",nil),nil];
                alert.tag = DOWNLOAD_AGAIN_ALERT;
                [alert show];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Import %@",nil),selectedAtlasName]
                                                               message: NSLocalizedString(@"Import may take a few minutes, continue?.",nil)
                                                              delegate: self
                                                     cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                     otherButtonTitles:NSLocalizedString(@"Continue",nil),nil];
                alert.tag = DOWNLOAD_START_ALERT;
                [alert show];
                
            }

            break;
        }
        default:
            break;
    }
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == DOWNLOAD_CONFIRM)
    {
        UITextField *agree = [alertView textFieldAtIndex:0];
        if ([agree.text caseInsensitiveCompare:NSLocalizedString(@"agree",nil)] == NSOrderedSame)
        {
            [ATHelper startReplaceDb:selectedAtlasName :downloadedJson :spinner];
            [_parent changeSelectedSource: selectedAtlasName];
            downloadedJson = nil;
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You Canceled replacing offline content!",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
    }
    else if (alertView.tag == DELETE_INCOMING_ON_SERVER_CONFIRM)
    {
        if (buttonIndex == 0)
            return;
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
        NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
        if (userId == nil)
            return;
        NSString* serviceUrl = [NSString stringWithFormat:@"%@/deleteincomingepisode?user_id=%@&security_code=%@&episode_name=%@",[ATConstants ServerURL], userId, securityCode,selectedAtlasName];
        NSString* responseStr = [ATHelper httpGetFromServer:serviceUrl];
        if ([@"SUCCESS" isEqualToString:responseStr])
        {
            [filteredList removeObject:selectedAtlasName];
            [self.tableView reloadData];
        }
    }
    else
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user canceled upload");
            // Any action can be performed here
        }
        else
        {
            if (alertView.tag == DOWNLOAD_START_ALERT || alertView.tag == DOWNLOAD_AGAIN_ALERT)
                [self startDownload];
            if (alertView.tag == DOWNLOAD_REPLACE_MY_SOURCE_ALERT )
            {
                UIAlertView* alert  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Confirm to replace %@ contents in your device!",nil),[ATHelper getSelectedDbFileName]]
                    message:NSLocalizedString(@"Enter agree to continue:",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                UITextField * aa = [alert textFieldAtIndex:0];
                aa.placeholder = NSLocalizedString(@"agree",nil);
                alert.tag = DOWNLOAD_CONFIRM;
                [alert show];
            }
        }
    }
}

//NOTE at serverside, if do not find user own this, it means user first time selected a public_share file, server will first copy it to user's row, then download, so user can modify its own copy
-(void) startDownload
{
    [spinner startAnimating];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int localListCnt = [appDelegate.eventListSorted count];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    //continues to get from server
    NSString* userId = userEmail;

    NSString* atlasName = [selectedAtlasName stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString* urlString = [NSString stringWithFormat:@"%@/downloadjsoncontents?user_id=%@&security_code=%@&atlas_name=%@",[ATConstants ServerURL], userId, securityCode, atlasName];
    //NSLog(@"-- bf encoding%@",urlString);
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//so atlasName is other language will work
    //NSLog(@"-- after encoding%@",urlString);
    NSURL* serviceUrl = [NSURL URLWithString:urlString];

    NSData* downloadedData = [NSData dataWithContentsOfURL:serviceUrl];
    NSString* displayLocalCnt = @"";
    if ([[ATHelper getSelectedDbFileName] isEqualToString :selectedAtlasName])
        displayLocalCnt = [NSString stringWithFormat:@"%i", localListCnt];
        
    NSError* error;
    downloadedJson = [NSJSONSerialization JSONObjectWithData:downloadedData options:kNilOptions error:&error];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Downloaded %@ has %i events",nil),selectedAtlasName,[downloadedJson count]]
                                message: [NSString stringWithFormat:NSLocalizedString(@"WARNING: Local %@'s %@ events will be replaced!",nil),selectedAtlasName,displayLocalCnt]
                                delegate: self
                                cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                otherButtonTitles:NSLocalizedString(@"Replace",nil),nil];
    alert.tag = DOWNLOAD_REPLACE_MY_SOURCE_ALERT;
    [spinner stopAnimating];
    [alert show];
}


@end
