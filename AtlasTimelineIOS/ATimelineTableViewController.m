//
//  ATimelineTableViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 12/29/12.
//  Copyright (c) 2012 hong. All rights reserved.
//


#import "ATimelineTableViewController.h"
#import "ATCell.h"
#import "SectionInfo.h"
#import "SectionHeaderView.h"
#import "ATAppDelegate.h"
#import "ATPeriod.h"
#import "ATEventAnnotation.h"
#import "ATEventDataStruct.h"
#import "ATHelper.h"
#import "ATConstants.h"
#import "ATViewController.h"


#pragma mark -


#pragma mark -
#pragma mark TableViewController


// Private TableViewController properties and methods.
@interface ATimelineTableViewController ()

@property (nonatomic, strong) NSMutableArray* sectionInfoArray;
@property (nonatomic, strong) NSIndexPath* pinchedIndexPath;
@property (nonatomic, assign) NSInteger openSectionIndex;
@property (nonatomic, assign) CGFloat initialPinchHeight;

// Use the uniformRowHeight property if the pinch gesture should change all row heights simultaneously.
@property (nonatomic, assign) NSInteger uniformRowHeight;

-(void)updateForPinchScale:(CGFloat)scale atIndexPath:(NSIndexPath*)indexPath;
- (void)setUpPeriodsArray;

@end



#define DEFAULT_ROW_HEIGHT 58
#define HEADER_HEIGHT 45

@implementation ATimelineTableViewController

NSString* mapViewSelectedYear;
NSMutableArray* filteredEventListSorted;
NSMutableArray* originalEventListSorted;

@synthesize periods=periods_, sectionInfoArray=sectionInfoArray_, atCell=newsCell_, pinchedIndexPath=pinchedIndexPath_, uniformRowHeight=rowHeight_, openSectionIndex=openSectionIndex_, initialPinchHeight=initialPinchHeight_;

#pragma mark Initialization and configuration


-(BOOL)canBecomeFirstResponder {
    
    return YES;
}


//This viewDidLoad will be called eachtime switch to it. but why not mapView?
- (void)viewDidLoad {
	
    [super viewDidLoad];
    [self.searchDisplayController.searchBar setPlaceholder:NSLocalizedString(@"search any description and address",nil)];
    [self.navigationItem setTitle:NSLocalizedString(@"List/Search", nil)];
    // Add a pinch gesture recognizer to the table view.
	UIPinchGestureRecognizer* pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
	[self.tableView addGestureRecognizer:pinchRecognizer];
    
    // Set up default values.
    self.tableView.sectionHeaderHeight = HEADER_HEIGHT;
	/*
     The section info array is thrown away in viewWillUnload, so it's OK to set the default values here. If you keep the section information etc. then set the default values in the designated initializer.
     */
    rowHeight_ = DEFAULT_ROW_HEIGHT;
    openSectionIndex_ = NSNotFound;
    
    /*
     Get the plays and quotations data from the core data set in ATAppDelegate, then pass the array on to the table view controller.
     */
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    mapViewSelectedYear = [ATHelper getYearPartHelper:appDelegate.focusedDate];
    originalEventListSorted = appDelegate.eventListSorted;
    if ([originalEventListSorted count] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No events to list!",nil)
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    filteredEventListSorted = [NSMutableArray arrayWithCapacity:[originalEventListSorted count]];
    
    if (self.tableView == self.searchDisplayController.searchResultsTableView)
	{
        [self setUpPeriodsArray: filteredEventListSorted];
    }
	else
	{
        [self setUpPeriodsArray: originalEventListSorted];
    }
}

- (void)setUpPeriodsArray:(NSMutableArray*) eventListSorted {
    
    // NSURL *url = [[NSBundle mainBundle] URLForResource:@"PlaysAndQuotations" withExtension:@"plist"];
    // NSArray *playDictionariesArray = [[NSArray alloc ] initWithContentsOfURL:url];
    NSMutableArray* innerDateList = [[NSMutableArray alloc] init];
    NSMutableArray* orderedYearList = [[NSMutableArray alloc] init];
    ATPeriod* period = [[ATPeriod alloc] init];
    ATEventDataStruct* firstEnt = eventListSorted[0];
    NSString* prevYear = [ATHelper getYearPartHelper:firstEnt.eventDate];
    //remember eventListSorted is sorted on event date
    NSString* year;
    int periodCount = 0;
    for (ATEventDataStruct* ent in eventListSorted)
    {
        year = [ATHelper getYearPartHelper:ent.eventDate];
        //NSLog(@"myear %@     prevYear= %@     %@", year, prevYear, evtDate);
        if ([year isEqualToString: prevYear])
        {
            [innerDateList addObject:ent];
        }
        else
        {
            period.periodName = [NSString stringWithFormat:@"%@ (%i)", prevYear,[innerDateList count]];
            period.sectionIndex = periodCount;
            periodCount++;
            period.events = innerDateList;
            innerDateList = [[NSMutableArray alloc] init];
            [orderedYearList addObject:period];
            period = [[ATPeriod alloc] init];
            [innerDateList addObject:ent];
            prevYear = year;
        }
    }
    //the last section will be added here
    period.periodName = [NSString stringWithFormat:@"%@ (%i)", year,[innerDateList count]];
    period.sectionIndex = periodCount;
    period.events = innerDateList;
    [orderedYearList addObject:period];
    
    self.periods = orderedYearList;
  }

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	
    /*
     Check whether the section info array has been created, and if so whether the section count still matches the current section count. In general, you need to keep the section info synchronized with the rows and section. If you support editing in the table view, you need to appropriately update the section info during editing operations.
     */
	if ((self.sectionInfoArray == nil) || ([self.sectionInfoArray count] != [self numberOfSectionsInTableView:self.tableView])) {
		
        // For each play, set up a corresponding SectionInfo object to contain the default height for each row.
		NSMutableArray *infoArray = [[NSMutableArray alloc] init];
		
		for (ATPeriod *period in self.periods) {
			
			SectionInfo *sectionInfo = [[SectionInfo alloc] init];
			sectionInfo.period = period;
			sectionInfo.open = NO;
			
            NSNumber *defaultRowHeight = [NSNumber numberWithInteger:DEFAULT_ROW_HEIGHT];
			NSInteger countOfEvents = [[sectionInfo.period events] count];
			for (NSInteger i = 0; i < countOfEvents; i++) {
				[sectionInfo insertObject:defaultRowHeight inRowHeightsAtIndex:i];
			}
			
			[infoArray addObject:sectionInfo];
		}
		
		self.sectionInfoArray = infoArray;
	}
	
}


- (void)viewDidUnload {
    
    [super viewDidUnload];
    
    // To reduce memory pressure, reset the section info array if the view is unloaded.
	self.sectionInfoArray = nil;
}


#pragma mark Table view data source and delegate

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 1;
    else
        return [self.periods count];
}


-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.sectionInfoArray count] == 0) //take care of if no events and user still type into searchbar
        return nil;
	SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:section];
	NSInteger numEventsInSection = [[sectionInfo.period events] count];

	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [filteredEventListSorted count];
    }
    else
        return sectionInfo.open ? numEventsInSection : 0;
}


-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    static NSString *EventCellIdentifier = @"EventCellIdentifier";
    static NSString *searchCellIdentifier = @"searchCellIdentifier";
    ATCell* cell = nil;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        cell = (ATCell*)[tableView dequeueReusableCellWithIdentifier:searchCellIdentifier];
        
        if (cell == nil) {
            cell = [[ATCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:searchCellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        ATEventDataStruct* ent = [filteredEventListSorted objectAtIndex:indexPath.row];
        cell.entity = ent;
        cell.textLabel.text = [NSString stringWithFormat:@"[%@] - %@",[appDelegate.dateFormater stringFromDate: ent.eventDate], ent.eventDesc];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
    }
    else
    {
        cell = (ATCell*)[tableView dequeueReusableCellWithIdentifier:EventCellIdentifier];
    
        if (cell == nil) { 
            //Never comes here. I think it is because the cell in on storyboard (id is EventCellIdentifier in storyboard
        }
    
        ATPeriod *period = (ATPeriod *)[[self.sectionInfoArray objectAtIndex:indexPath.section] period];
        cell.entity = [period.events objectAtIndex:indexPath.row];
        cell.dateLabel.text = [appDelegate.dateFormater stringFromDate: cell.entity.eventDate];
        cell.descLabel.text=cell.entity.eventDesc;
        cell.addressLabel.text=cell.entity.address;
    }

    return cell;
}


-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    
    /*
     Create the section header views lazily.
     */
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{ //for search tableview, only one section
        return [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, HEADER_HEIGHT)];
    }
	SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:section];
    if (!sectionInfo.headerView) {
        //NSLog(@" section = %i", section );
		NSString *periodName = sectionInfo.period.periodName;
        sectionInfo.headerView = [[SectionHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, HEADER_HEIGHT) title:periodName section:section delegate:self];
        if ([periodName rangeOfString:[NSString stringWithFormat:@"%@ (",mapViewSelectedYear]].location != NSNotFound) //take care of 2013 and 2013 BC is same
        {
            [sectionInfo.headerView setHeaderCorlor:0.5];
            //TODO I want to scroll to section at focusedDate, but it does not work 
            //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
            //[self.tableView scrollToRowAtIndexPath:indexPath  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        
    }
    
    return sectionInfo.headerView;
}


-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return DEFAULT_ROW_HEIGHT;
}


-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    //NSLog(@" in didSelectedRow %i", indexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark Section header delegate

-(void)sectionHeaderView:(SectionHeaderView*)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {
	
	SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:sectionOpened];
	
	sectionInfo.open = YES;
    
    /*
     Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
     */
    NSInteger countOfRowsToInsert = [sectionInfo.period.events count];
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < countOfRowsToInsert; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionOpened]];
    }
    
    /*
     Create an array containing the index paths of the rows to delete: These correspond to the rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
    
    NSInteger previousOpenSectionIndex = self.openSectionIndex;
    if (previousOpenSectionIndex != NSNotFound) {
		
		SectionInfo *previousOpenSection = [self.sectionInfoArray objectAtIndex:previousOpenSectionIndex];
        previousOpenSection.open = NO;
        [previousOpenSection.headerView toggleOpenWithUserAction:NO];
        NSInteger countOfRowsToDelete = [previousOpenSection.period.events count];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
        }
    }
    
    // Style the animation so that there's a smooth flow in either direction.
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
        insertAnimation = UITableViewRowAnimationTop;
        deleteAnimation = UITableViewRowAnimationBottom;
    }
    else {
        insertAnimation = UITableViewRowAnimationBottom;
        deleteAnimation = UITableViewRowAnimationTop;
    }
    
    // Apply the updates.
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [self.tableView endUpdates];
    self.openSectionIndex = sectionOpened;
    
}


-(void)sectionHeaderView:(SectionHeaderView*)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {
    
    /*
     Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
     */
	SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:sectionClosed];
	
    sectionInfo.open = NO;
    NSInteger countOfRowsToDelete = [self.tableView numberOfRowsInSection:sectionClosed];
    
    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
        }
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
    }
    self.openSectionIndex = NSNotFound;
}


#pragma mark Handling pinches


-(void)handlePinch:(UIPinchGestureRecognizer*)pinchRecognizer {
    
    /*
     There are different actions to take for the different states of the gesture recognizer.
     * In the Began state, use the pinch location to find the index path of the row with which the pinch is associated, and keep a reference to that in pinchedIndexPath. Then get the current height of that row, and store as the initial pinch height. Finally, update the scale for the pinched row.
     * In the Changed state, update the scale for the pinched row (identified by pinchedIndexPath).
     * In the Ended or Canceled state, set the pinchedIndexPath property to nil.
     */
    
    if (pinchRecognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint pinchLocation = [pinchRecognizer locationInView:self.tableView];
        NSIndexPath *newPinchedIndexPath = [self.tableView indexPathForRowAtPoint:pinchLocation];
		self.pinchedIndexPath = newPinchedIndexPath;
        
		SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:newPinchedIndexPath.section];
        self.initialPinchHeight = [[sectionInfo objectInRowHeightsAtIndex:newPinchedIndexPath.row] floatValue];
        // Alternatively, set initialPinchHeight = uniformRowHeight.
        
        [self updateForPinchScale:pinchRecognizer.scale atIndexPath:newPinchedIndexPath];
    }
    else {
        if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
            [self updateForPinchScale:pinchRecognizer.scale atIndexPath:self.pinchedIndexPath];
        }
        else if ((pinchRecognizer.state == UIGestureRecognizerStateCancelled) || (pinchRecognizer.state == UIGestureRecognizerStateEnded)) {
            self.pinchedIndexPath = nil;
        }
    }
}


-(void)updateForPinchScale:(CGFloat)scale atIndexPath:(NSIndexPath*)indexPath {
    
    if (indexPath && (indexPath.section != NSNotFound) && (indexPath.row != NSNotFound)) {
        
		CGFloat newHeight = round(MAX(self.initialPinchHeight * scale, DEFAULT_ROW_HEIGHT));
        
		SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:indexPath.section];
        [sectionInfo replaceObjectInRowHeightsAtIndex:indexPath.row withObject:[NSNumber numberWithFloat:newHeight]];
        // Alternatively, set uniformRowHeight = newHeight.
        
        /*
         Switch off animations during the row height resize, otherwise there is a lag before the user's action is seen.
         */
        BOOL animationsEnabled = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        [UIView setAnimationsEnabled:animationsEnabled];
    }
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"detail view clicked row is %i" , indexPath.row);
    ATEventDataStruct* ent = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        ATCell *cell = (ATCell*)[tableView cellForRowAtIndexPath:indexPath];
        ent = cell.entity;
    }
    else{
        ATCell *cell = (ATCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        ent = cell.entity;
    }

    [[self getMapViewCountroller] setNewFocusedDateAndUpdateMapWithNewCenter:ent :[ATConstants defaultZoomLevel]];
    //a tech skill: to return back to a navigator, do not use segue
    [self.navigationController popViewControllerAnimated:YES];
    
}

-(ATViewController*) getMapViewCountroller
{
    UINavigationController* navController = [self navigationController];
    return (ATViewController*)[navController.viewControllers objectAtIndex:0];
}

#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[filteredEventListSorted removeAllObjects]; // First clear the filtered array.
	
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
	for (ATEventDataStruct *ent in originalEventListSorted)
	{
        //TODO need search for address field too
        if ([ent.eventDesc rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound
        || [ent.address rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound )
        //if (result == NSOrderedSame)
        {
            [filteredEventListSorted addObject:ent];
        }

	}
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

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

@end
