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

#define SECTION_OTHER_BLOGGERS 0
#define SECTION_SUGGESTED 1
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

    BOOL isEventDir;


    NSArray* appList;

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

    self.detailLabel.text = _source;
    
    SWRevealViewController* revealController = [self revealViewController];
    UIBarButtonItem *timelineBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"arrow-right.png"] style:UIBarButtonItemStylePlain target:revealController action:@selector(rightRevealToggle:)];
    self.navigationItem.leftBarButtonItem = timelineBarButtonItem;
    
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwiper];
    
    appList = [self fetchAppList];
}

- (NSMutableArray*) fetchAppList
{
    NSString* serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com/resources/newappshortlist_for_blogger_app_zh.html"];
    
    NSString* responseStr  = [ATHelper httpGetFromServer:serviceUrl :false];
    NSMutableArray* appListLocal = [[NSMutableArray alloc] init];
    //blogger_app_list.html has format of :
    /*
     blogger name|blogger app store url:subtitleDescription
     etc
     */
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if (responseStr == nil)
    {
        responseStr = [userDefaults objectForKey:@"APP_LIST_SAVED"];
    }
    else
    {
        [userDefaults setObject:responseStr forKey:@"APP_LIST_SAVED"];
    }
    
    if (responseStr != nil && [responseStr length] > 100)
    {
        NSArray* glist = [responseStr componentsSeparatedByString:@"\n"];
        for (NSString* poiRowText in glist)
        {
            if (poiRowText != nil && [poiRowText length] > 0)
            {
                NSArray* tmp = [poiRowText componentsSeparatedByString:@"|"];
                if ([tmp count] >= 3) //extra defensive protection so user client will not blow if my server data has wrong
                    [appListLocal addObject:poiRowText];
            }
        }
    }
    return appListLocal;
}

- (void)swipeRight {
    SWRevealViewController *revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
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


#pragma mark - Table view delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2; //SECTION_MISC will be not used with 2 sections
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //TODO these part should be dynamically from server side
    NSInteger retCount = 0;
    if (section == SECTION_OTHER_BLOGGERS)
        retCount = 1; //其它旅行名家博客
    else if (section == SECTION_SUGGESTED)
        retCount = [appList count]; //攻略锦囊，霞客行，谷歌，脸书，Flickr，
    else  //SECTION_SUPPORT...
        retCount = 2; //世界遗产，第二次世界大战纪实
    
    return retCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    UITableViewCell *cell = nil;
    if (section == SECTION_SUGGESTED)
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
    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell.imageView setImage:nil];
    long row = indexPath.row;
    if (section == SECTION_SUGGESTED)
    {
        if ([appList count] <= indexPath.row)
            return nil; //defensive protection in case no app store in local and network not available
        NSString* rowText = appList[indexPath.row];
        NSArray* tmp = [rowText componentsSeparatedByString:@"|"];

        cell.textLabel.text = tmp[0];
        cell.detailTextLabel.text = tmp[2];
    }
    else if (section == SECTION_OTHER_BLOGGERS)
    {
        if (row == 0)
        {
            cell.textLabel.text = @"其它旅行名家博客";
            [cell.imageView setImage:[UIImage imageNamed:@"star-red-orig-purple.png"]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    else if (section == SECTION_MISC)
        
    {  //世界遗产，第二次世界大战纪实
        if (row == 0)
        {
            cell.textLabel.text = NSLocalizedString(@"世界文化，自然遗产APP",nil);
            cell.detailTextLabel.text = NSLocalizedString(@"在地图上发现世界遗产",nil);
        }
        if (row == 1)
        {
            cell.textLabel.text = NSLocalizedString(@"第二次世界大战纪实APP",nil);
            cell.detailTextLabel.text = NSLocalizedString(@"在有时间轴的地图上研究二战历史",nil);
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
    if (section == SECTION_SUGGESTED)
    {
        label.text = @"旅行规划／像集管理好帮手";
    }
    if (section == SECTION_OTHER_BLOGGERS)
    {
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"推荐";
    }
    if (section == SECTION_MISC)
    {
        label.text = NSLocalizedString(@"其它",nil);
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
    if (section == SECTION_SUGGESTED)
        [self handleSugestedSection:tableView :indexPath ];
    if (section == SECTION_OTHER_BLOGGERS)
        [self handleLoginEmailSection:tableView :indexPath ];
    if (section == SECTION_MISC)
        [self handleMiscSection:tableView :indexPath ];
}
-(void) handleMiscSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    NSString* appUrl;
    if (indexPath.row == 0)
    {
        appUrl = @"https://itunes.apple.com/us/app/world-heritage-sites-on-chronicle/id1043944432?ls=1&mt=8";
    }
    if (indexPath.row == 1)
    {
        appUrl = @"https://itunes.apple.com/us/app/second-world-war-on-chroniclemap/id893801070?ls=1&mt=8";
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appUrl]];
}
-(void) handleSugestedSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    NSString* rowText = appList[indexPath.row];
    NSArray* tmp = [rowText componentsSeparatedByString:@"|"];
    NSString* appUrl = tmp[1];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appUrl]];
}
-(void) handleLoginEmailSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    //also see prepareForSeque() where pass values
    if (indexPath.row == 0)
        [self performSegueWithIdentifier:@"choose_poi" sender:nil];
}


-(void) helpClicked:(id)sender //Only iPad come here. on iPhone will be frome inside settings and use push segue
{
    ATHelpWebView *helpView = [[ATHelpWebView alloc] init];//[storyboard instantiateViewControllerWithIdentifier:@"help_webview_id"];
    
    [self.navigationController pushViewController:helpView animated:true];
}


@end
