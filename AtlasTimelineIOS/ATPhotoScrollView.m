//
//  ATTimeScrollWindowNew
//  HorizontalTables
//
//  Created by Felipe Laso on 8/19/11.
//  Copyright 2011 Felipe Laso. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ATPhotoScrollView.h"
#import "ATAppDelegate.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATEventDataStruct.h"
#import "ATPhotoScrollCell.h"
#import "ATConstants.h"

#define FIRST_TIME_CALL -999
#define GROUP_BACKGROUND_COLOR_1 0.0
#define GROUP_BACKGROUND_COLOR_2 0.4
#define SHARE_ICON_TAG 100
#define MAP_MARKER_TAG 200
#define NEW_NOT_SAVED_FILE_PREFIX @"NEW"

@implementation ATPhotoScrollView
{
}

@synthesize horizontalTableView = _horizontalTableView;


#pragma mark - Table View Data Source

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        //NSLog(@"-------------ATTimeScrollWindowNew  initWithFrame called");
        float tableLength = frame.size.width;
        float tableWith = frame.size.height;
        //NSLog(@" table  length %f   width %f",tableLength, tableWith);
        self.horizontalTableView = [[UITableView alloc] initWithFrame:frame];
        //self.horizontalTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kCellHeight_iPad, kTableLength_iPad)];
        self.horizontalTableView.showsVerticalScrollIndicator = NO;
        self.horizontalTableView.showsHorizontalScrollIndicator = NO;
        self.horizontalTableView.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);
        [self.horizontalTableView setFrame:CGRectMake(0, 0, tableLength, tableWith)];
        
        self.horizontalTableView.rowHeight = [ATConstants timeScrollCellWidth];
        
        self.horizontalTableView.dataSource = self;
        self.horizontalTableView.delegate = self;
        [self addSubview:self.horizontalTableView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        tap.numberOfTapsRequired =1;
        [self addGestureRecognizer:tap];
    }
    self.selectedAsThumbnailIndex = -1;
    return self;
}

//when scroll, will not come here, so have some heavy work such as calendar
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"number of photos:%d",[self.photoList count]);
    if (self.photoList != nil && [self.photoList count] > 0)
        return [self.photoList count];
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    static NSString *CellIdentifier = @"ATPhotoScrollCell";
    
    __block ATPhotoScrollCell *cell = (ATPhotoScrollCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[ATPhotoScrollCell alloc] initWithFrame:CGRectMake(0, 0, [ATConstants photoScrollCellWidth], [ATConstants photoScrollCellHeight])];
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (self.photoList == nil || [self.photoList count] == 0)
    {
        cell.photo.image = [UIImage imageNamed:@"no_photo.png"] ;
    }
    else
    {
        NSString* photoName = self.photoList[indexPath.row];

        cell.photo.image = [ATHelper readPhotoFromFile:photoName eventId:self.eventEditor.eventId];

        cell.photo.contentMode = UIViewContentModeScaleAspectFit;
        cell.photo.clipsToBounds = YES;
        UIImageView* iconShare = (UIImageView*)[cell.photo viewWithTag:SHARE_ICON_TAG];
        UIImageView* iconMapMarker = (UIImageView*)[cell.photo viewWithTag:MAP_MARKER_TAG];
        if (indexPath.row == self.selectedAsShareIndex)
        {
            if (iconShare == nil)
            {
                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 30)];
                imgView.image = [UIImage imageNamed:@"share.png"];
                imgView.tag = SHARE_ICON_TAG;
                [cell.photo addSubview:imgView];
            }
        }
        else if (iconShare != nil)
            [iconShare removeFromSuperview];
        
        if (indexPath.row == self.selectedAsThumbnailIndex)
        {
            if (iconMapMarker == nil)
            {
                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(60, 10, 30, 30)];
                imgView.image = [UIImage imageNamed:@"marker-selected.png"];
                imgView.tag = MAP_MARKER_TAG;
                [cell.photo addSubview:imgView];
            }
        }
        else if (iconMapMarker != nil)
            [iconMapMarker removeFromSuperview];
        //[cell setNeedsDisplay];
    }
    return cell;
}
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    return [ATConstants photoScrollCellHeight];
}

//have tap gesture achive two thing: prevent call tapGesture on parent mapView and process select a row action without a TableViewController
- (void)handleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer numberOfTouches] == 1)
    {
        NSIndexPath *index = [self.horizontalTableView indexPathForRowAtPoint: [gestureRecognizer locationInView:self.horizontalTableView]];
        //Following check is to make sure if "No Photo" displayed, do not select
        if ([self.photoList count] > 0 && index != nil)
            [self didSelectRowAtIndexPath:index];
    }
}

- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath  //called by tapGesture. This is not in a TableViewController, so no didSelect... delegate mechanism, have to process  by tap gesture
{
    //NSLog(@"select photo selected");
    self.selectedPhotoIndex = indexPath.row;
    [ATEventEditorTableController setSelectedPhotoIdx:indexPath.row];
    ATPhotoScrollCell *cell = (ATPhotoScrollCell*)[self.horizontalTableView cellForRowAtIndexPath:indexPath];
    [self.eventEditor showPhotoView:self.selectedPhotoIndex image:cell.photo.image];
    
    //TODO set selected filename for delete or set default phto
}
#pragma mark - Memory Management

- (NSString *) reuseIdentifier
{
    return @"HorizontalCell";
}


@end
