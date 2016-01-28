//
//  ATOtherBloggersViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 5/17/15.
//  Copyright (c) 2015 hong. All rights reserved.
//

#import "ATOtherBloggersViewController.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "SWRevealViewController.h"
#import "ATConstants.h"

@interface ATOtherBloggersViewController ()

@end

@implementation ATOtherBloggersViewController

NSMutableArray* poiGroupList;
NSString* selectedPoiGroupName;
NSInteger selectedPoiGroupIdxForDeselect;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.delegate = appDelegate.mapViewController;

    [self fetchBloggerAppList];
}


- (void) fetchBloggerAppList
{
    NSString* serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com/resources/blogger_app_list_zh.html"];

    NSString* responseStr  = [ATHelper httpGetFromServer:serviceUrl :false];
    poiGroupList = [[NSMutableArray alloc] init];
    //blogger_app_list.html has format of :
    /*
     blogger name|blogger app store url:subtitleDescription
     etc
     */
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    selectedPoiGroupName = [userDefaults objectForKey:@"SELECTED_POI_GROUP_NAME"];
    if (responseStr == nil)
    {
        responseStr = [userDefaults objectForKey:@"GROUP_POI_SAVED"];
    }
    else
    {
        [userDefaults setObject:responseStr forKey:@"GROUP_POI_SAVED"];
    }
    
    if (responseStr != nil && [responseStr length] > 100)
    {
        NSArray* glist = [responseStr componentsSeparatedByString:@"\n"];
        poiGroupList = [[NSMutableArray alloc] init];
        NSString* targetName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        for (NSString* poiRowText in glist)
        {
            NSString* poiGroupName = [self getPoiTitle:poiRowText];
            if (![poiGroupName isEqualToString:targetName])
                [poiGroupList addObject:poiRowText];
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network is unavailable!",nil)
                                                        message:NSLocalizedString(@"",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [poiGroupList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    // Configure the cell...
    UITableViewCell *cell;
    
    NSString* poiRowText = poiGroupList[indexPath.row];
    CellIdentifier = @"PeriodCell";
    cell = [tableView  dequeueReusableCellWithIdentifier:CellIdentifier];

    cell.textLabel.text = [self getPoiTitle:poiRowText];
    cell.detailTextLabel.text = [self getPoiSubTitle:poiRowText];
    //For world heritage, detail subtitle will show //apple-app-store-rul ...
    if ([cell.detailTextLabel.text hasPrefix:@"//"])
        cell.detailTextLabel.text = @"Start App here ...";
    
    if ([selectedPoiGroupName isEqualToString:[self getPoiTitle:poiRowText]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedPoiGroupIdxForDeselect = indexPath.row;
    }
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* poiRowText = poiGroupList[indexPath.row];
    if ([poiRowText length] <= 4)
        return;
    
    NSString* poiGroupName = [self getPoiTitle:poiRowText];
    if (poiRowText == nil || [poiRowText isEqualToString:@""])
        return;
    
    selectedPoiGroupName = poiGroupName;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (selectedPoiGroupIdxForDeselect != NSNotFound) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath
                                                                  indexPathForRow:selectedPoiGroupIdxForDeselect inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        selectedPoiGroupIdxForDeselect = indexPath.row;
    }
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:poiGroupName forKey:@"SELECTED_POI_GROUP_NAME"];
    [userDefaults synchronize];


    NSString* poiAppUrl = [self getPoiFileName:poiRowText];
    poiAppUrl = [poiAppUrl stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSLog(@"##### store url:%@", poiAppUrl);
    if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:poiAppUrl]]) //World Heritage app store url
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"即将推出!",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"好的",nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    SWRevealViewController* revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
}

////On server, poi_list_xx.html has format: poiDisplayText|poiFileName:.......
-(NSString*)getPoiTitle:(NSString*)poiRow
{
    NSArray* poiRowText = [poiRow componentsSeparatedByString:@":"];
    NSString* poiHeaderText = poiRowText[0];
    NSArray* textArr = [poiHeaderText componentsSeparatedByString:@"|"];
    return textArr[0];
}
-(NSString*) getPoiFileName:(NSString*)poiRow
{
    NSArray* poiRowText = [poiRow componentsSeparatedByString:@":"];
    return [@"https:" stringByAppendingString: poiRowText[1]];
}
-(NSString*) getPoiFileName2:(NSString*)poiRow //for example, World Heritage is in URL format
{
    NSArray* textArr = [poiRow componentsSeparatedByString:@"|"];
    return textArr[1];
}
-(NSString*) getPoiSubTitle:(NSString*)poiRow
{
    NSArray* poiRowText = [poiRow componentsSeparatedByString:@":"];
    if ([poiRowText count] > 1)
        return poiRowText[[poiRowText count ] - 1];
    else
        return @"";
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"reaching accessoryButtonTappedForRowWithIndexPath: section %ld   row %ld", indexPath.section, indexPath.row);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
