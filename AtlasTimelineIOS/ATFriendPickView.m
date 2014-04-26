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

#import "ATFriendPickView.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"

@interface ATFriendPickView ()

@end

@implementation ATFriendPickView

NSMutableArray* friendList;
NSString* selectedAtlasName;
NSArray* downloadedJson;
NSMutableArray* pickedEmails;
UIButton *sendButton;

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
    pickedEmails = [[NSMutableArray alloc] init];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    /*********  here is test for test *****/
   // [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
   // [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
   // [userDefault synchronize];
    /**********************************/

    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    /*
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
    friendList = [[responseStr componentsSeparatedByString:@"|"] mutableCopy];
     */
    friendList = [NSMutableArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", nil];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.friendList = friendList; //pass to friendAddView
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [friendList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"friendcell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if( cell == nil )
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friendcell"];
    NSString* friendStr = friendList[indexPath.row];
    //Friend String should be "aa@bb.com" or "aa@bb.com (wait)"
    if ([@"(Wait)" rangeOfString:friendStr].location != NSNotFound)
        cell.textLabel.textColor = [UIColor grayColor];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
    cell.textLabel.text = friendStr;
    
    cell.textLabel.textColor = [UIColor blackColor];
        //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* customView = nil;
    // create the parent view that will hold header Label
    if (section == 0)
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 380, 90)];
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(5,0,340,60)];
        label.font = [UIFont fontWithName:@"Helvetica" size:14];
        [label setNumberOfLines:0];
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        label.text = [NSString stringWithFormat:@"To share ""%@"":\n    Pick friends -> Tap [Send]\n(Tap [New Friend] if not in the list)",appDelegate.episodeToBeShared ];
        [customView addSubview:label];
        
        sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        sendButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
        sendButton.frame = CGRectMake(30, 50, 60, 50);
        [sendButton setTitle:@"Send" forState:UIControlStateNormal];
        [sendButton.titleLabel setTextColor:[UIColor blueColor]];
        [sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [sendButton setEnabled:false];
        [customView addSubview:sendButton];
        
        UIButton *addFriendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        addFriendButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
        addFriendButton.frame = CGRectMake(130, 50, 90, 50);
        [addFriendButton setTitle:@"New Friend" forState:UIControlStateNormal];
        [addFriendButton.titleLabel setTextColor:[UIColor blueColor]];
        [addFriendButton addTarget:self action:@selector(addFriendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:addFriendButton];
    }
    return customView;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (section == 0)
        return 90;
    else
        return [super tableView:tableView heightForHeaderInSection:section];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath
                                                              indexPathForRow:indexPath.row inSection:0]];
    NSString* friendStr = cell.textLabel.text;
    if ([@"(Wait)" rangeOfString:friendStr].location != NSNotFound)
        return;
    // http://stackoverflow.com/questions/4616345/select-multiple-rows-in-uitableview
    if([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark){
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        [pickedEmails removeObject:friendStr];
        
    }else{
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [pickedEmails addObject:friendStr];
    }
    if ([pickedEmails count] > 0)
        [sendButton setEnabled:true];
    else
        [sendButton setEnabled:false];
}
- (void) addFriendButtonAction: (id)sender {
    //UIButton* button = (UIButton*)sender;
    NSLog(@" call addFriend");
    [self performSegueWithIdentifier:@"add_friend" sender:nil];
    
}
- (void) sendButtonAction: (id)sender {
    //UIButton* button = (UIButton*)sender;
    NSString *pickedFriendsStr = [pickedEmails componentsJoinedByString:@"\n"];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Send Episode %@ to following friend(s)",appDelegate.episodeToBeShared]
                                                    message:[NSString stringWithFormat:@"%@",pickedFriendsStr]
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Send it", nil];
    [alert show];
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) //EDIT episode
    {
        NSLog(@"call server url");
    }
}
//TODO  send episode button action etc

@end
