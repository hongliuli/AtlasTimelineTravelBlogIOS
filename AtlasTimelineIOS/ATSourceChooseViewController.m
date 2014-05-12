//
//  ATPeriodChooseViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATSourceChooseViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"
#import "SWTableViewCell.h"

#define EVENT_TYPE_HAS_PHOTO 1

#define EPISODE_SELECTED_ALERT 1

#define FOR_CHOOSE_ACTIVE 0
#define FOR_SHARE_MY_EVENTS 1

@interface ATSourceChooseViewController ()

@end

@implementation ATSourceChooseViewController
{
    NSMutableArray* _sources;
    NSUInteger _selectedIndex;
    NSMutableDictionary* _episodeDictionary;
    NSArray* _episodeNameList;
    NSString* episodeNameForAlertView;
    int swipPromptCount;
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
    
    swipPromptCount = 0;
    _sources = [[ATHelper listFileAtPath:[ATHelper applicationDocumentsDirectory]] mutableCopy];
    _sources = [[_sources sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    [_sources removeObject:@"myEvents"];
    [_sources insertObject:@"myEvents" atIndex:0];
    _selectedIndex = [_sources indexOfObject:self.source];
    
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString* dbName = [appDelegate sourceName];
    if ([dbName isEqualToString:@"myEvents"])
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        _episodeDictionary = [[userDefault objectForKey:[ATConstants EpisodeDictionaryKeyName]] mutableCopy];
        if (_episodeDictionary != nil)
        {
            _episodeNameList = [[_episodeDictionary allKeys] mutableCopy];
            _episodeNameList = [_episodeNameList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        }
    }
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
    int retCount = 0;
    if (self.requestType == FOR_CHOOSE_ACTIVE)
        retCount = [_sources count];
    else if (self.requestType == FOR_SHARE_MY_EVENTS)
    {
        if (_episodeNameList != nil)
            retCount = [_episodeNameList count];
    }
    return retCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    // Configure the cell...
    UITableViewCell *cell;
    if (self.requestType == FOR_CHOOSE_ACTIVE)
    {
        CellIdentifier = @"PeriodCell";
        cell = [tableView  dequeueReusableCellWithIdentifier:CellIdentifier];
        NSString* sourceName  = _sources[indexPath.row];
        //do not display ".sqlite" in the Source tableview
        
        if ([sourceName rangeOfString:@"*"].location != NSNotFound)
        {
            NSArray* nameList = [sourceName componentsSeparatedByString:@"*"];
            cell.textLabel.text = nameList[0];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@    %@",nameList[2], nameList[1]];
        }
        else
        {
            cell.textLabel.text = sourceName;
            cell.detailTextLabel.text = @"";
        }

        if ([@"myEvents" isEqualToString:sourceName])
        {
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19.0];
            cell.detailTextLabel.text = @" - All your life stories are here!";
        }
        else
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0];
        if (indexPath.row == _selectedIndex)
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = [UIColor blueColor];
            [self getStatsForEvent:sourceName tableCell:cell];
        }
 
        return cell;
    }
    else //this is for FOR_SHARE_MY_EPISODE
    {
        CellIdentifier = @"PeriodCell2";
        NSString* episodeName  = _episodeNameList[indexPath.row];
        /*
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.accessoryView = [[ UIImageView alloc ]
                                initWithImage:[UIImage imageNamed:@"share.png" ]];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.text = @"";
         */
        
        
        SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            NSMutableArray *rightUtilityButtons = [NSMutableArray new];
            //see action in didTriggerRightUtilityButtonWithIndex
            [rightUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor colorWithRed:0.78f green:0.38f blue:0.5f alpha:1.0]
                                                        title:@"Del"];
            [rightUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                        title:@"Edit"];
            [rightUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor colorWithRed:1.0f green:0.53f blue:0.38 alpha:1.0f]
                                                        title:@"Share"];
            
            cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:CellIdentifier
                                      containingTableView:self.tableView // For row height and selection
                                       leftUtilityButtons:nil
                                      rightUtilityButtons:rightUtilityButtons];
            cell.delegate = self;
            cell.tag = indexPath.row;
        }
        cell.textLabel.text = episodeName;
        //cell.detailTextLabel.text = @"Swipe Right";
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        return cell;
    }

}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.requestType == FOR_CHOOSE_ACTIVE)
    {
        return @" Set Active Contents";
    }
    else
    {
        return @" Swipe one to Share";
    }
}
//change section font
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(0, 0, 250, 40);
    myLabel.font = [UIFont boldSystemFontOfSize:17];
    myLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    myLabel.backgroundColor = [UIColor clearColor];
;
    //myLabel.textAlignment = NSTextAlignmentCenter;
    myLabel.textColor = [UIColor grayColor];
    
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 50)];
    [headerView setBackgroundColor:[UIColor colorWithRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0]];
    [headerView addSubview:myLabel];
    
    if (self.requestType == FOR_SHARE_MY_EVENTS)
    {
        UIButton *inviteFriendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        inviteFriendButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
        inviteFriendButton.frame = CGRectMake(180, 0, 120, 40);
        [inviteFriendButton setTitle:@"Invite Friend" forState:UIControlStateNormal];
        [inviteFriendButton.titleLabel setTextColor:[UIColor blueColor]];
        [inviteFriendButton addTarget:self action:@selector(inviteFriendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:inviteFriendButton];
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.requestType == FOR_CHOOSE_ACTIVE)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (_selectedIndex != NSNotFound) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath
                                                                      indexPathForRow:_selectedIndex inSection:0]];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        _selectedIndex = indexPath.row;
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSString *source = _sources[indexPath.row];
        [self.delegate sourceChooseViewController:self didSelectSource:source];
    }
    
    else //EPIDSODE_LIST_SECTION:  //then load episode for modify
    {
        if (swipPromptCount >= 2)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please swipe right" message:[NSString stringWithFormat:@""] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            swipPromptCount = 0;
        }
        else
        {
            swipPromptCount++;
        }
    }
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"reaching accessoryButtonTappedForRowWithIndexPath: section %d   row %d", indexPath.section, indexPath.row);
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    int row = cell.tag;
    switch (index) {
        case 0:
        {
            NSLog(@"Del row %d",row);
            
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            
            if (_episodeDictionary != nil)
                [_episodeDictionary removeObjectForKey:_episodeNameList[row]];

            _episodeNameList = [[_episodeDictionary allKeys] mutableCopy];
            
            [userDefault setObject:_episodeDictionary forKey:[ATConstants EpisodeDictionaryKeyName]];
            
            [UIView animateWithDuration:0.5 animations:^{
                [self.tableView reloadData];
            }];
            break;
        }
        case 1:
        {
            if (![@"myEvents" isEqualToString:appDelegate.sourceName])
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot edit episode" message:@"Edit Episode is available when active content is myEvents" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                return;
            }
            NSLog(@"Edit row %d",row);
            episodeNameForAlertView = _episodeNameList[row];
            [self.delegate sourceChooseViewController:self didSelectEpisode:episodeNameForAlertView];
            [self dismissViewControllerAnimated:NO completion:nil];
            break;
        }
        case 2:
        {
            //NSLog(@"Share row %d",row);
            appDelegate.episodeToBeShared = _episodeNameList[row];
            [self performSegueWithIdentifier:@"pick_friend" sender:nil];
            break;
        }
        default:
            break;
    }
}

- (void) inviteFriendButtonAction: (id)sender {
    //UIButton* button = (UIButton*)sender;
    NSLog(@" call addFriend");
    [self performSegueWithIdentifier:@"invite_friend" sender:nil];
    
}
-(void) getStatsForEvent:(NSString*)sourceName tableCell:(UITableViewCell*)cell
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray* eventList = appDelegate.eventListSorted;
    NSError *error;
    int totalPhotoCount = 0;
    double totalPhotoSize = 0;
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
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[fullPathToFile stringByAppendingPathComponent:file] error: &error];
                    NSNumber* fileSize = [dict valueForKey:@"NSFileSize"];
                    totalPhotoSize = totalPhotoSize + [fileSize doubleValue];
                    if (![file isEqualToString:@"thumbnail"])
                        totalPhotoCount++;
                }
            }
            
        }
    }
    float totalSizeInM = totalPhotoSize / 1048576;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:1];
    [formatter setRoundingMode: NSNumberFormatterRoundDown];
    NSString *numberString = [formatter stringFromNumber:[NSNumber numberWithFloat:totalSizeInM]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d events, %d photos, %@MB ",[eventList count], totalPhotoCount, numberString ];
    if ([@"myEvents" isEqualToString:sourceName])
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - Your life stories",cell.detailTextLabel.text];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/



@end
