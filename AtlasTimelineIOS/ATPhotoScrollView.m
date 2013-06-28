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


#define FIRST_TIME_CALL -999
#define GROUP_BACKGROUND_COLOR_1 0.0
#define GROUP_BACKGROUND_COLOR_2 0.4

@implementation ATPhotoScrollView
{
}

@synthesize horizontalTableView = _horizontalTableView;


#pragma mark - Table View Data Source

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
       
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
    }
    self.selectedAsThumbnailIndex = -1;
    return self;
}

//when scroll, will not come here, so have some heavy work such as calendar
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.photoList != nil && [self.photoList count] > 0)
        return [self.photoList count];
    else
        return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    static NSString *CellIdentifier = @"ATPhotoScrollCell";
    
    __block UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [ATConstants timeScrollCellWidth], [ATConstants timeScrollCellHeight])];
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSString* photoFileDir = self.eventEditor.eventId;
    if (self.photoList == nil || [self.photoList count] == 0)
    {
        cell.imageView.image = [UIImage imageNamed:@"no_photo.png"] ;
    }
    else
    {
        NSString* photoName = self.photoList[indexPath.row];
        if ([photoName length] <= 8) //see EventEditor doneSelectPicture: where new added photos are temparirayly saved
        {
            photoName = [[ATHelper getNewUnsavedEventPhotoPath] stringByAppendingPathComponent:photoName];
        }
        else
        {
            photoName = [[[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:photoFileDir] stringByAppendingPathComponent:photoName];
        }
        cell.imageView.image = [self readPhotoFromFile:photoName];
    }
    return cell;
}

-(UIImage*)readPhotoFromFile:(NSString*)fileName
{
    NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:fileName];
    return [UIImage imageWithContentsOfFile:fullPathToFile];
}

- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath  //called by tapGesture. This is not in a TableViewController, so no didSelect... delegate mechanism, have to process  by tap gesture
{
    self.selectedPhotoIndex = indexPath.row;
    UITableViewCell *cell = (UITableViewCell*)[self.horizontalTableView cellForRowAtIndexPath:indexPath];
    [self.eventEditor showPhotoView:self.selectedPhotoIndex image:cell.imageView.image];
    
    //TODO set selected filename for delete or set default phto
}
#pragma mark - Memory Management

- (NSString *) reuseIdentifier
{
    return @"HorizontalCell";
}


@end
