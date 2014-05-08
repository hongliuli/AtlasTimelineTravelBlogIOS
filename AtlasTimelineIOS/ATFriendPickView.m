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

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

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
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //if user not login, then network not availbe case will be alert
        return;
    }
    pickedEmails = [[NSMutableArray alloc] init];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    /*********  here is test for test *****/
   // [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
   // [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
   // [userDefault synchronize];
    /**********************************/

    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];

    NSString* serviceUrl = [NSString stringWithFormat:@"%@/retreivefriendlist?user_id=%@&security_code=%@",[ATConstants ServerURL], userId, securityCode];
    NSString* responseStr = [ATHelper httpGetFromServer:serviceUrl];
    if (responseStr == nil)
        return;
    else
        friendList = [[responseStr componentsSeparatedByString:@"|"] mutableCopy];

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
    if ([friendStr rangeOfString:@"(wait)"].location != NSNotFound)
        cell.textLabel.textColor = [UIColor grayColor];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
    cell.textLabel.text = friendStr;

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
        label.text = [NSString stringWithFormat:@"Episode:  \"%@\"\n- Pick friends to send to their ChronicleMap\n- Add friends if not in the list to pick",appDelegate.episodeToBeShared ];
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
        [addFriendButton setTitle:@"Add Friend" forState:UIControlStateNormal];
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
    friendStr = [friendStr lowercaseString];
    if ([friendStr rangeOfString:@"(wait)"].location != NSNotFound)
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
    if (buttonIndex == 1) //send episode
    {
        //send lanquage to server so server know what language
        NSString *pickedFriendsStr = [pickedEmails componentsJoinedByString:@"|"];
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString* dbName = [appDelegate sourceName];
        if (![dbName isEqualToString:@"myEvents"])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You active content is not myEvents!" message:@"please switch to myEvents as active content!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return;
        }
        [self startUploadJson:pickedFriendsStr];
    }
}

//following function is almost identical that in ATPreferenceViewController which upload content
-(void)startUploadJson:(NSString*)startUploadJson
{
    //[spinner startAnimating];
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
    NSString* episodeName = appDelegate.episodeToBeShared;
    
    NSDictionary* episodeDictionary = [userDefault objectForKey:[ATConstants EpisodeDictionaryKeyName]];
    NSArray* episodeEventIdList = nil;
    if (episodeDictionary != nil)
        episodeEventIdList = [episodeDictionary objectForKey:episodeName];
    
    NSArray *allEvents = appDelegate.eventListSorted;
    NSMutableArray* episodeEventList = [[NSMutableArray alloc] init];
    NSString* eventId = nil;
    for (ATEventDataStruct* event in allEvents)
    {
        eventId = event.uniqueId;
        if ([episodeEventIdList containsObject:eventId])
            [episodeEventList addObject:event];
    }
    if ([episodeEventList count] == 0)
    {
        //this may happen if event still in episodeIdList, but already removed from myEvents
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"This episode is empty!" message:@"Then events in this episode is no longer in myEvents, please remove this episode." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
        
    }
    int eventCount = [episodeEventList count];
    NSMutableArray* dictArray = [[NSMutableArray alloc] initWithCapacity:eventCount];
    for (ATEventDataStruct* item in episodeEventList)
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
    NSString* postStr = [NSString stringWithFormat:@"user_id=%@&security_code=%@&friend_email_list=%@&episode_name=%@&json_content=%@", userEmail, securityCode
                         ,startUploadJson, episodeName, longStr];
//NSLog(@"============post body = %@", postStr);
    NSData *postData = [postStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSURL* serviceUrl = [NSURL URLWithString: [NSString stringWithFormat:@"%@/shareepisode",[ATConstants ServerURL]]];
    
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
    //[spinner stopAnimating];
    if (![returnStatus isEqual:@"SUCCESS"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Share Episode Failed!" message:@"Fail reason could be network issue or data issue!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Share Episode Success!"
                                                        message: [NSString stringWithFormat:@"Episode [%@], with %i events, has been uploaded to server successfully!",episodeName,eventCount]
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
}


@end
