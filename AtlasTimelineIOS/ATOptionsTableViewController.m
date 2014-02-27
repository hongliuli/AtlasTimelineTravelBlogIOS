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
#define ROW_IPAD_EDIT_FULLSCREEN 1
#define ROW_DATE_FIELD_KEYBOARD 2
//#define ROW_ENABLE_TIME_LINK 4

@interface ATOptionsTableViewController ()

@end

@implementation ATOptionsTableViewController

UISwitch *switchViewTimeLink;
UISwitch *switchViewEditorFullScreen;
UISwitch *switchViewKeyboardForDate;
UISwitch *switchViewMagnifierMove;

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
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* customView = nil;
    if (section == 0)
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 60.0)];
    
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
        shareButton.frame = CGRectMake(-15, -15, 200, 60);
        [shareButton setTitle:@"Reset to Default" forState:UIControlStateNormal];
        shareButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
        [shareButton addTarget:self action:@selector(setDefaultAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:shareButton];
    }
    return customView;

}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch( [indexPath row] ) {
        case ROW_ENABLE_MOVE_DATE: {
            UITableViewCell* aCell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCellMoveDate"];
            if( aCell == nil ) {
                aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCellMoveDate"];
                aCell.textLabel.text = @"Date Magnifer Scroll";
                aCell.selectionStyle = UITableViewCellSelectionStyleNone;
                switchViewMagnifierMove = [[UISwitch alloc] initWithFrame:CGRectZero];
                aCell.accessoryView = switchViewMagnifierMove;
                if ([ATHelper getOptionDateMagnifierModeScroll])
                    [switchViewMagnifierMove setOn:YES animated:NO];
                else
                    [switchViewMagnifierMove setOn:NO animated:NO];
                [switchViewMagnifierMove addTarget:self action:@selector(dateMagnifierModeChanged:) forControlEvents:UIControlEventValueChanged];
            }
            return aCell;
        }
        case ROW_IPAD_EDIT_FULLSCREEN: { //will not show this row in iPhone
            UITableViewCell* aCell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCellEditFullScreen"];
            if( aCell == nil ) {
                aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCellEditFullScreen"];
                aCell.textLabel.text = @"Full Screen Event Editor"; //Note: iPad only show this row
                aCell.selectionStyle = UITableViewCellSelectionStyleNone;
                switchViewEditorFullScreen = [[UISwitch alloc] initWithFrame:CGRectZero];
                aCell.accessoryView = switchViewEditorFullScreen;
                if ([ATHelper getOptionEditorFullScreen])
                    [switchViewEditorFullScreen setOn:YES animated:NO];
                else
                    [switchViewEditorFullScreen setOn:NO animated:NO];
                [switchViewEditorFullScreen addTarget:self action:@selector(editorFullScreenChanged:) forControlEvents:UIControlEventValueChanged];
            }
            return aCell;
        }
        case ROW_DATE_FIELD_KEYBOARD: {
            UITableViewCell* aCell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCellDateField"];
            if( aCell == nil ) {
                aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCellDateField"];
                aCell.textLabel.text = @"Use keyboard to enter date";
                aCell.selectionStyle = UITableViewCellSelectionStyleNone;
                switchViewKeyboardForDate = [[UISwitch alloc] initWithFrame:CGRectZero];
                aCell.accessoryView = switchViewKeyboardForDate;
                if ([ATHelper getOptionDateFieldKeyboardEnable])
                    [switchViewKeyboardForDate setOn:YES animated:NO];
                else
                    [switchViewKeyboardForDate setOn:NO animated:NO];
                [switchViewKeyboardForDate addTarget:self action:@selector(dateFieldKeyboardEnableChanged:) forControlEvents:UIControlEventValueChanged];
            }
            return aCell;
        }
        /****** comment out option or enable/disable time link
        case ROW_ENABLE_TIME_LINK: {
            UITableViewCell* aCell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCellTimeLink"];
            if( aCell == nil ) {
                aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCellTimeLink"];
                aCell.textLabel.text = @"Show timelink when focuse event";
                aCell.selectionStyle = UITableViewCellSelectionStyleNone;
                switchViewTimeLink = [[UISwitch alloc] initWithFrame:CGRectZero];
                aCell.accessoryView = switchViewTimeLink;
                if ([ATHelper getOptionDisplayTimeLink])
                    [switchViewTimeLink setOn:YES animated:NO];
                else
                    [switchViewTimeLink setOn:NO animated:NO];
                [switchViewTimeLink addTarget:self action:@selector(timeLinkEnableChanged:) forControlEvents:UIControlEventValueChanged];
            }
            return aCell;
        }
        *******/
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && indexPath.row == ROW_IPAD_EDIT_FULLSCREEN)
        return 0;
    else
        return 40;
}

- (void) setDefaultAction: (id)sender {
    UIButton* button = (UIButton*)sender;
    UIColor* originalColor = button.titleLabel.backgroundColor;

    [ATHelper setOptionDateFieldKeyboardEnable:false];
    [switchViewKeyboardForDate setOn:NO animated:NO];
    [ATHelper setOptionDateMagnifierModeScroll:true];
    [switchViewMagnifierMove setOn:YES animated:NO];
    //[ATHelper setOptionDisplayTimeLink:true];
    //[switchViewTimeLink setOn:YES animated:NO];
    [ATHelper setOptionEditorFullScreen:false];
    [switchViewEditorFullScreen setOn:NO animated:NO];
    
    [UIView transitionWithView:button.titleLabel duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        button.titleLabel.backgroundColor = [UIColor blueColor];
    } completion:^(BOOL finished){button.titleLabel.backgroundColor = originalColor;}];

    
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

- (void) editorFullScreenChanged:(id)sender {
    UISwitch* switchControl = sender;
    if (switchControl.on)
        [ATHelper setOptionEditorFullScreen:true];
    else
        [ATHelper setOptionEditorFullScreen:false];
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
