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

#define EVENT_TYPE_HAS_PHOTO 1

#define OFFLINE_CONTENT_SECTION 0
#define EPISODE_LIST_SECTION 1
#define EPISODE_SELECTED_ALERT 1

@interface ATSourceChooseViewController ()

@end

@implementation ATSourceChooseViewController
{
    NSArray* _sources;
    NSUInteger _selectedIndex;
    NSMutableDictionary* _episodeDictionary;
    NSArray* _episodeNameList;
    NSString* episodeNameForAlertView;
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
    
    _sources = [ATHelper listFileAtPath:[ATHelper applicationDocumentsDirectory]];
    _selectedIndex = [_sources indexOfObject:self.source];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    _episodeDictionary = [userDefault objectForKey:[ATConstants EpisodeDictionaryKeyName]];
    if (_episodeDictionary != nil)
    {
        _episodeNameList = [[_episodeDictionary allKeys] mutableCopy];
        _episodeNameList = [_episodeNameList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    //NSLog(@"   number of episode %d", [_episodeNameList count]);

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    int retCount = 0;
    if (section == OFFLINE_CONTENT_SECTION)
        retCount = [_sources count];
    else if (section == EPISODE_LIST_SECTION)
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
    if (indexPath.section == OFFLINE_CONTENT_SECTION)
    {
        CellIdentifier = @"PeriodCell";
        cell = [tableView  dequeueReusableCellWithIdentifier:CellIdentifier];
        NSString* source  = _sources[indexPath.row];
        //do not display ".sqlite" in the Source tableview
        cell.textLabel.text = source;
        
        if (indexPath.row == _selectedIndex)
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = [UIColor blueColor];
            [self getStatsForEvent:source tableCell:cell];
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.text = @"";
        }
    }
    else //this is for EPISODE_LIST_SECTION
    {
        CellIdentifier = @"PeriodCell2";
        cell = [tableView  dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        NSString* episodeName  = _episodeNameList[indexPath.row];
        cell.textLabel.text = episodeName;
        /*
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.accessoryView = [[ UIImageView alloc ]
                                initWithImage:[UIImage imageNamed:@"share.png" ]];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.text = @"";
         */
    }
    
    return cell;

}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == OFFLINE_CONTENT_SECTION)
    {
        return @" Offline Contents";
    }
    else
    {
        return @" Share Episodes (Swipe to delete)";
    }
}
//change section font
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(0, 0, 400, 40);
    myLabel.font = [UIFont boldSystemFontOfSize:17];
    myLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    myLabel.backgroundColor = [UIColor colorWithRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
;
    //myLabel.textAlignment = NSTextAlignmentCenter;
    myLabel.textColor = [UIColor grayColor];
    
    
    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:myLabel];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == OFFLINE_CONTENT_SECTION)
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
        if ([@"myEvents" isEqual:self.source])
        {
            episodeNameForAlertView = _episodeNameList[indexPath.row];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Episode: %@",episodeNameForAlertView]
                                                            message:@"Edit episode or Send it to your followers' ChronicleMap app"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Edit", @"Share it to my followers", nil];
            alert.tag = EPISODE_SELECTED_ALERT;
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load episode to edit" message:[NSString stringWithFormat:@"Please select myEvents first."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
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
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == EPISODE_LIST_SECTION)
    {
        if (editingStyle == UITableViewCellEditingStyleDelete)
        {
            NSLog(@"delete row %d",indexPath.row);
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            
            if (_episodeDictionary != nil)
                [_episodeDictionary removeObjectForKey:_episodeNameList[indexPath.row]];
            
            _episodeNameList = [[_episodeDictionary allKeys] mutableCopy];
            
            [userDefault setObject:_episodeDictionary forKey:[ATConstants EpisodeDictionaryKeyName]];
            
            [UIView animateWithDuration:0.5 animations:^{
                [self.tableView reloadData];
            }];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == EPISODE_LIST_SECTION)
        return YES;
    else
        return NO;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == EPISODE_SELECTED_ALERT)
    {
        if (buttonIndex == 1) //EDIT episode
        {
         [self.delegate sourceChooseViewController:self didSelectEpisode:episodeNameForAlertView];
            /*
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Episode is loaded" message:[NSString stringWithFormat:@"Episode %@ has been loaded to the map, you can modify and save it.", episodeNameForAlertView] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
         [alert show];
             */
        }
        else if (buttonIndex == 2) //share
        {
            //call server
        }
    }

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
