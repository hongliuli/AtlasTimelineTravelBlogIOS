//
//  ATEventListViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 6/1/14.
//  Copyright (c) 2014 hong. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ATEventListWindowView.h"
#import "ATViewController.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"
#import "ATHelper.h"
#import "ATConstants.h"
#import "ATEventListViewCell.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

@implementation ATEventListWindowView

NSArray* internalEventList;

- (id)initWithFrame:(CGRect)frame
{
    if (self == [super initWithFrame:frame])
    {
        internalEventList = [[NSArray alloc] init];
        self.tableView = [[UITableView alloc] initWithFrame:frame];
        
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        
        [self addSubview:self.tableView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        tap.numberOfTapsRequired =1;
        [self.tableView addGestureRecognizer:tap]; //IMPORTANT: I used [self addGest..] which cause sometime tap on a row does not react. After chage to self.tableView addGest.., it works much better

    }
    return self;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [internalEventList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@" ===== cellForRow %d  internalList count %d ",indexPath.row, [internalEventList count]);
    ATEventListViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    ATEventDataStruct* evt = internalEventList[indexPath.row];
    //ATEventListViewCell *cell = nil;
    if (cell == nil)
    {
        cell = [[ATEventListViewCell alloc] initWithFrame:CGRectMake(0, 0, [ATConstants eventListViewCellWidth], [ATConstants eventListViewCellHeight])];
        cell.eventDescView.font = [UIFont fontWithName:@"Arial" size:13];

        cell.selectionStyle = UITableViewCellStyleDefault;
        [cell.layer setCornerRadius:7.0f];
        [cell.layer setMasksToBounds:YES];
        [cell.layer setBorderWidth:1.0f];
        //[cell.layer setBorderColor:(__bridge CGColorRef)([UIColor lightGrayColor])];
    }

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    NSString* dateStr = [dateFormatter stringFromDate:evt.eventDate];
    //dateStr = [dateStr substringToIndex:10];
    cell.eventDescView.text = [NSString stringWithFormat:@"%@:\n%@",dateStr, evt.eventDesc ];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    ATEventDataStruct* focusedEvent = appDelegate.focusedEvent;
    if (focusedEvent != nil && [focusedEvent.uniqueId isEqual:evt.uniqueId])
    {
        [cell.checkIcon setHidden:false];
    }
    else
    {
        [cell.checkIcon setHidden:true];
    }
    
    if (evt.eventType == EVENT_TYPE_HAS_PHOTO )
    {
        CGRect imageFrame = CGRectMake(0, 0, [ATConstants eventListViewPhotoWidht] - 2,[ATConstants eventListViewPhotoHeight] - 5);
        cell.photoImage.image = [ATHelper readPhotoThumbFromFile:evt.uniqueId];
        
        UIBezierPath * imgRect = [UIBezierPath bezierPathWithRect:imageFrame];
        cell.eventDescView.textContainer.exclusionPaths = @[imgRect];
    }
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120;
}
//have tap gesture achive two thing: prevent call tapGesture on parent mapView and process select a row action without a TableViewController
- (void)handleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    //NSLog(@" ----- tap");
    if ([gestureRecognizer numberOfTouches] == 1)
    {
        NSIndexPath *index = [self.tableView indexPathForRowAtPoint: [gestureRecognizer locationInView:self.tableView]];
        //NSLog(@"   row clicked on is %i", index.row);
        [self didSelectRowAtIndexPath:index];
    }
}
- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath  //called by tapGesture. This is not in a TableViewController, so no didSelect... delegate mechanism, have to process  by tap gesture
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    ATEventDataStruct* evt = internalEventList[indexPath.row];
    appDelegate.focusedDate = evt.eventDate;
    appDelegate.focusedEvent = evt;  //appDelegate.focusedEvent is added when implement here
    ATViewController* mapView = appDelegate.mapViewController;
    [mapView setNewFocusedDateAndUpdateMapWithNewCenter : evt :-1]; //do not change map zoom level
    [mapView showTimeLinkOverlay];
    [self.tableView reloadData]; //so show checkIcon for selected row
}
- (void) refresh:(NSMutableArray*)eventList //called by mapview::refreshEventListView()
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    internalEventList = eventList;
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded]; //must have for following work
    if (appDelegate.focusedEvent == nil)
        return;
    int selectedEventIdx = 0;
    for (int i=0; i< [eventList count]; i++)
    {
        ATEventDataStruct* evt = eventList[i];
        if ([evt.uniqueId isEqual:appDelegate.focusedEvent.uniqueId])
        {
            selectedEventIdx = i;
            break;
        }
    }
    if (selectedEventIdx < [internalEventList count])
        [self.tableView scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:selectedEventIdx inSection:0]
                                    atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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
