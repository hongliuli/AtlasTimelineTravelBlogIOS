//
//  ATOptionsTableViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/21/14.
//  Copyright (c) 2014 hong. All rights reserved.
//

#import "ATOptionsTableViewController.h"
#import "ATHelper.h"

#define ROW_ENABLE_MOVE_DATE 0
#define ROW_ENABLE_TIME_LINK 1
#define ROW_DATE_FIELD_KEYBOARD 2


@interface ATOptionsTableViewController ()

@end

@implementation ATOptionsTableViewController

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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch( [indexPath row] ) {
        case ROW_ENABLE_MOVE_DATE: {
            UITableViewCell* aCell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCellMoveDate"];
            if( aCell == nil ) {
                aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCellMoveDate"];
                aCell.textLabel.text = @"Date Magnifer Scroll";
                aCell.selectionStyle = UITableViewCellSelectionStyleNone;
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                aCell.accessoryView = switchView;
                if ([ATHelper getOptionDateMagnifierModeScroll])
                    [switchView setOn:YES animated:NO];
                else
                    [switchView setOn:NO animated:NO];
                [switchView addTarget:self action:@selector(dateMagnifierModeChanged:) forControlEvents:UIControlEventValueChanged];
            }
            return aCell;
        }
        case ROW_DATE_FIELD_KEYBOARD: {
            UITableViewCell* aCell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCellDateField"];
            if( aCell == nil ) {
                aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCellDateField"];
                aCell.textLabel.text = @"Use keyboard to enter date";
                aCell.selectionStyle = UITableViewCellSelectionStyleNone;
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                aCell.accessoryView = switchView;
                if ([ATHelper getOptionDateFieldKeyboardEnable])
                    [switchView setOn:YES animated:NO];
                else
                    [switchView setOn:NO animated:NO];
                [switchView addTarget:self action:@selector(dateFieldKeyboardEnableChanged:) forControlEvents:UIControlEventValueChanged];
            }
            return aCell;
        }
        case ROW_ENABLE_TIME_LINK: {
            UITableViewCell* aCell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCellTimeLink"];
            if( aCell == nil ) {
                aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCellTimeLink"];
                aCell.textLabel.text = @"Show timelink when focuse event";
                aCell.selectionStyle = UITableViewCellSelectionStyleNone;
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                aCell.accessoryView = switchView;
                if ([ATHelper getOptionDisplayTimeLink])
                    [switchView setOn:YES animated:NO];
                else
                    [switchView setOn:NO animated:NO];
                [switchView addTarget:self action:@selector(timeLinkEnableChanged:) forControlEvents:UIControlEventValueChanged];
            }
            return aCell;
        }
    }
    return nil;
}

- (void) dateFieldKeyboardEnableChanged:(id)sender {
    UISwitch* switchControl = sender;
    if (switchControl.on)
        [ATHelper setOptionDateFieldKeyboardEnable:true];
    else
        [ATHelper setOptionDateFieldKeyboardEnable:false];
}

- (void) timeLinkEnableChanged:(id)sender {
    UISwitch* switchControl = sender;
    if (switchControl.on)
        [ATHelper setOptionDisplayTimeLink:true];
    else
        [ATHelper setOptionDisplayTimeLink:false];
}

- (void) dateMagnifierModeChanged:(id)sender {
    UISwitch* switchControl = sender;
    if (switchControl.on)
        [ATHelper setOptionDateMagnifierModeScroll:true];
    else
        [ATHelper setOptionDateMagnifierModeScroll:false];
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
