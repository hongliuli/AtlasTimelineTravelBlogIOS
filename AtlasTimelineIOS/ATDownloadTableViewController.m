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
    
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    /*********  here is test for test *****/
   // [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
   // [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
   // [userDefault synchronize];
    /**********************************/

    localList = [[NSMutableArray alloc] initWithArray:[ATHelper listFileAtPath:[ATHelper applicationDocumentsDirectory]]];

    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    
    NSURL* serviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/retreivelistofcontents?user_id=%@&security_code=%@",[ATConstants ServerURL], userId, securityCode]];
    NSMutableURLRequest * serviceRequest = [NSMutableURLRequest requestWithURL:serviceUrl];
    NSLog(@"%@",serviceUrl);
    //Get Responce hear----------------------
    NSURLResponse *response;
    NSError *error;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:serviceRequest returningResponse:&response error:&error];
    if (urlData == nil)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connect Server Fail!" message:@"Metwork may not be available, Please try later!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSString* responseStr = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
    if ([responseStr hasPrefix:@"<html>"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Need Retry!" message:@"Metwork problem, Please try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSArray* libraryList = [responseStr componentsSeparatedByString:@"|"];
    filteredList = [[NSMutableArray alloc] init];
    //should use predicate to filter nil
    for (int i=0; i< [libraryList count]; i++)
    {
        NSString* item = libraryList[i];
        if (item != nil && [item length]>0)
            [filteredList addObject:libraryList[i]];
    }
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
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [filteredList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"downloadcell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    cell.textLabel.text = filteredList[indexPath.row];
    if ([localList containsObject:filteredList[indexPath.row]]){
        if ([filteredList[indexPath.row] isEqual:[ATConstants defaultSourceName]])
            cell.textLabel.textColor = [UIColor blueColor];
        else
        {
            cell.textLabel.textColor = [UIColor lightGrayColor];
            //cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else{
        cell.textLabel.textColor = [UIColor blackColor];
        //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath
                                                              indexPathForRow:indexPath.row inSection:0]];
    if ([cell.textLabel.textColor isEqual:[UIColor lightGrayColor]])
    {
        selectedAtlasName = cell.textLabel.text;
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:@"%@ was downloaded before",selectedAtlasName]
                                                       message: @"Are you sure to replace your offline copy?"
                                                      delegate: self
                                             cancelButtonTitle:@"Cancel"
                                             otherButtonTitles:@"Continue",nil];
        alert.tag = DOWNLOAD_AGAIN_ALERT;
        [alert show];
    }
    else
    {
        
        
        NSLog(@"  selected to download %@", cell.textLabel.text);
        selectedAtlasName = cell.textLabel.text;
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:@"Download %@",selectedAtlasName]
                                                       message: @"Download may take a few minutes, continue?."
                                                      delegate: self
                                             cancelButtonTitle:@"Cancel"
                                             otherButtonTitles:@"Continue",nil];
        alert.tag = DOWNLOAD_START_ALERT;
        [alert show];
        
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
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
            [self startReplaceDb];
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
    NSURL* serviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/downloadjsoncontents?user_id=%@&security_code=%@&atlas_name=%@",[ATConstants ServerURL], userId, securityCode, atlasName]];
    
    NSLog(@"download url is %@",[serviceUrl absoluteString]);
    NSData* downloadedData = [NSData dataWithContentsOfURL:serviceUrl];
    NSString* displayLocalCnt = @"";
    if ([[ATHelper getSelectedDbFileName] isEqualToString :selectedAtlasName])
        displayLocalCnt = [NSString stringWithFormat:@"%i", localListCnt];
        
    NSError* error;
    downloadedJson = [NSJSONSerialization JSONObjectWithData:downloadedData options:kNilOptions error:&error];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:@"Downloaded %@ has %i events",selectedAtlasName,[downloadedJson count]]
                                message: [NSString stringWithFormat:@"Local %@'s %@ events will be replaced!",selectedAtlasName,displayLocalCnt]
                                delegate: self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Replace",nil];
    alert.tag = DOWNLOAD_REPLACE_MY_SOURCE_ALERT;
    [spinner stopAnimating];
    [alert show];
}

-(void)startReplaceDb
{
    NSLog(@"Start replace db called");
    [spinner startAnimating];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int cnt = [downloadedJson count];
    NSMutableArray* newEventList = [[NSMutableArray alloc] initWithCapacity:cnt];
    for (NSDictionary* dict in downloadedJson)
    {
        ATEventDataStruct* evt = [[ATEventDataStruct alloc] init];
        evt.uniqueId = [dict objectForKey:@"uniqueId"];
        evt.eventDesc = [dict objectForKey:@"eventDesc"];
        evt.eventDate = [appDelegate.dateFormater dateFromString:[dict objectForKey:@"eventDate"]];
        evt.address = [dict objectForKey:@"address"];
        evt.lat = [[dict objectForKey:@"lat"] doubleValue];
        evt.lng = [[dict objectForKey:@"lng"] doubleValue];
        evt.eventType = [[dict objectForKey:@"eventType"] intValue];
        [newEventList addObject:evt];
        // NSLog(@"%@    desc %@", [dict objectForKey:@"eventDate"],[dict objectForKey:@"eventDesc"]);
    }
    
    [ATHelper setSelectedDbFileName:selectedAtlasName];
    [_parent changeSelectedSource: selectedAtlasName];
    ATDataController* dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    [appDelegate.eventListSorted removeAllObjects];
    appDelegate.eventListSorted = newEventList;
    [dataController deleteAllEvent]; //only meaniful for myTrips database
    
    for (ATEventDataStruct* evt in newEventList)
    {
        [dataController addEventEntityAddress:evt.address description:evt.eventDesc date:evt.eventDate lat:evt.lat lng:evt.lng type:evt.eventType uniqueId:evt.uniqueId];
    }
    [appDelegate emptyEventList];
    [appDelegate.mapViewController cleanSelectedAnnotationSet];
    [appDelegate.mapViewController prepareMapView];
    downloadedJson = nil;
    [spinner stopAnimating];
}

@end
