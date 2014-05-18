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

#import <AddressBookUI/AddressBookUI.h>
#import "ATFriendAddView.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"

@interface ATFriendAddView ()

@end

@implementation ATFriendAddView

NSMutableArray* filteredContactList;
NSMutableArray* contactList;
NSString* selectedAtlasName;
NSArray* downloadedJson;
UIActivityIndicatorView* spinner;
ABAddressBookRef addressBook;
BOOL isFiltered;
BOOL showSendRequestFlag;

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
    //self.searchDisplayController.searchBar.delegate = self;
    isFiltered = false;
    showSendRequestFlag = false;
    if (contactList == nil)
        contactList = [[NSMutableArray alloc] init];
    else
        [contactList removeAllObjects];
    CFErrorRef *error = NULL;
    addressBook = ABAddressBookCreateWithOptions(NULL, error);
    
    [self.searchBar setKeyboardType:UIKeyboardTypeEmailAddress];

    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [self getEmails];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied",nil)
                                                                message:@""
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                      otherButtonTitles:nil];
                [alert show];
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        [self getEmails];
    }
    else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"The access to Address Book has previously been denied",nil)
                                                        message:NSLocalizedString(@"Please grant access in iOS Settings->Privacy->Contacts->Chronicle Map\n(This is optional. Address Book is used for you to find friend easily)",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    spinner = [[UIActivityIndicatorView alloc]
               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(160, 200);
    spinner.hidesWhenStopped = YES;
    [[self  view] addSubview:spinner];
   
}

-(void) getEmails
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
    
    for(int i = 0; i < numberOfPeople; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
        //For Email ids
        ABMutableMultiValueRef eMail  = ABRecordCopyValue(person, kABPersonEmailProperty);
        if(ABMultiValueGetCount(eMail) > 0)
        {
            //NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            //NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
            NSString* email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(eMail, 0) ;
            email = [email lowercaseString];
            if (!([appDelegate.friendList containsObject:email] || [appDelegate.friendList containsObject:[NSString stringWithFormat:@"%@ (wait)",email]]))
                [contactList addObject:email];
        }
        
    }
    NSMutableArray *unique = [NSMutableArray array];
    
    for (NSString* obj in contactList) {
        if (![unique containsObject:obj]) {
            [unique addObject:obj];
        }
    }
    
    contactList = [[unique sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    filteredContactList = [NSMutableArray arrayWithCapacity:[contactList count]];
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
    if (isFiltered)
        return [filteredContactList count];
    else
        return  0;//[contactList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"contactcell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    if (isFiltered)
        cell.textLabel.text = filteredContactList[indexPath.row];
    else
        cell.textLabel.text = @"";//contactList[indexPath.row];
    
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
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200, 50)];
        UIButton *addFriendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        addFriendButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
        addFriendButton.frame = CGRectMake(0, 0, 200, 50);
        [addFriendButton setTitle:NSLocalizedString(@"Send Invitation",nil) forState:UIControlStateNormal];
        [addFriendButton.titleLabel setTextColor:[UIColor blueColor]];
        [addFriendButton addTarget:self action:@selector(requestFriendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:addFriendButton];
    }
    return customView;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (!showSendRequestFlag)
        return 0;
    if (section == 0)
        return 40;
    else
        return [super tableView:tableView heightForHeaderInSection:section];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath
                                                              indexPathForRow:indexPath.row inSection:0]];
    showSendRequestFlag = true;
    self.searchBar.text = cell.textLabel.text;
    [self.tableView reloadData]; //so to show button
}



#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    if(searchText.length == 0)
    {
        isFiltered = FALSE;
    }
    else
    {
        isFiltered = true;
        [filteredContactList removeAllObjects]; // First clear the filtered array.
       	for (NSString *emailStr in contactList)
        {
            //TODO need search for address field too
            if ([emailStr rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [filteredContactList addObject:emailStr];
            }
            
        }
    }
    showSendRequestFlag = false;
    NSRange range = [searchText rangeOfString:@"@"];
    if (range.location != NSNotFound) {
        NSString* str2 = [searchText substringFromIndex:range.location];
        range = [str2 rangeOfString:@"."];
        if (range.location != NSNotFound)
            showSendRequestFlag = true; //show submit button if email address is validated
    }
    
    [self.tableView reloadData];
}

- (void) requestFriendButtonAction: (id)sender {
    //UIButton* button = (UIButton*)sender;
    NSString* friendString = self.searchBar.text;
    friendString = [friendString lowercaseString];
    //client side make sure user is a friend or not
    //         if a user is in wait state, ask user if to resend
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* friendList = appDelegate.friendList;
    if (friendList == nil || [friendList count] == 0)
    {
        Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
        if (!successFlag)
        {
            //Need alert again?  checkUserEmailAndSecurityCode already alerted
            return;
        }
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];        
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
    
    if ([friendList containsObject:friendString])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ is already your friend",nil), friendString]
                            message:@""
                            delegate:nil
                            cancelButtonTitle:NSLocalizedString(@"OK",nil)
                            otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if ([friendList containsObject:[NSString stringWithFormat:@"%@(wait)",friendString]])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ has not accepted your request yet",nil), friendString]
                                                        message:NSLocalizedString(@"You have invited him/her before, do you want to send another invitation email?",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"No",nil)
                                              otherButtonTitles:NSLocalizedString(@"Yes",nil), nil];
        [alert show];
        return;
    }
    
    [self sendFriendRequestToServer:friendString];
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) //send episode
    {
        NSString* friendString = self.searchBar.text;
        friendString = [friendString lowercaseString];
        [self sendFriendRequestToServer:friendString];
    }
}
-(void) sendFriendRequestToServer:(NSString*) friendString
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    if (userId == nil)
        return;
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString* serviceUrl = [NSString stringWithFormat:@"%@/sendfriendrequest?user_id=%@&security_code=%@&friend_email=%@&language=%@",[ATConstants ServerURL],userId , securityCode, friendString, language];
    NSString* responseStr = [ATHelper httpGetFromServer:serviceUrl];
    
    if ([@"SUCCESS" isEqualToString:responseStr])
    {
        [appDelegate.friendList addObject:[NSString stringWithFormat:@"%@(wait)",friendString]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"An invitation email has been sent to your friend",nil)
                                                        message:NSLocalizedString(@"After he/she clicks accept link in the email, you can start to send her episode",nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [appDelegate.friendList addObject:[NSString stringWithFormat:@"%@(wait)", friendString]];
        self.searchBar.text = @"";
        self.searchBar.placeholder = NSLocalizedString(@"Enter email",nil);
    }
    else //alreadyFriend, allready in Queue etc should not happen in server, if happen, treat same
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat: NSLocalizedString(@"failed to add %@",nil), friendString]
                                                        message:NSLocalizedString(@"server may have issue, or already be friend",nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }

}

/*

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}
*/
@end
