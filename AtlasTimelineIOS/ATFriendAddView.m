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
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied"
                                                                message:@""
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"The access has previously been denied"
                                                        message:@"Please change privacy setting in settings app"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
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
        addFriendButton.frame = CGRectMake(30, 0, 200, 50);
        [addFriendButton setTitle:@"Send Request to Friend" forState:UIControlStateNormal];
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
    NSLog(@" call request friend");
    NSString* friendString = self.searchBar.text;

    //client side make sure user is a friend or not
    //         if a user is in wait state, ask user if to resend
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* friendList = appDelegate.friendList;
    
    if ([friendList containsObject:friendString])
    {
        NSLog(@"alert user is already friend");
        return;
    }
    else if ([friendList containsObject:[NSString stringWithFormat:@"%@(wait)",friendString]])
    {
        NSLog(@"alert user has not accepted previous request, do you want send a email again?");
    }
    
    //Server comback with addedToQueue
    NSString* serverResponse = @"added";
    if ([@"added" isEqualToString:serverResponse])
    {
        [appDelegate.friendList addObject:[NSString stringWithFormat:@"%@(wait)",friendString]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"An invitation email has been sent to your friend"
                                                        message:@"After he/she clicks accept link in the email, you can start to send her episode"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else //alreadyFriend, allready in Queue etc should not happen in server, if happen, treat same
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat: @"failed to add %@", friendString]
                                                        message:@"server may have issue"
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
