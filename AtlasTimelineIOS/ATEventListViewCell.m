//
//  ATEventListViewCell.m
//  AtlasTimelineIOS
//
//  Created by Hong on 6/1/14.
//  Copyright (c) 2014 hong. All rights reserved.
//

#import "ATEventListViewCell.h"
#import "ATConstants.h"


@implementation ATEventListViewCell

- (NSString *)reuseIdentifier
{
    return @"reuseIdentifier";
}

// use iOS7 way http://stackoverflow.com/questions/13216135/wrapping-text-in-a-uitextview-around-a-uiimage-without-coretext
// in my code, only iOS7 has this event list view feature
// CoreText is too complicated

- (id)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self)
    {
        CGRect imageFrame = CGRectMake(5, 5, [ATConstants eventListViewPhotoWidht],[ATConstants eventListViewPhotoHeight]); //a little different frame in ATEventListView.m
        CGRect textFrame = CGRectMake(5, 0, [ATConstants eventListViewCellWidth],[ATConstants eventListViewCellHeight]);
        
        self.photoImage = [[UIImageView alloc] initWithFrame:imageFrame];
        [self.contentView addSubview:self.photoImage];
        
        self.checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake([ATConstants eventListViewCellWidth] -25, 7, 20, 20)];
        [self.checkIcon setImage:[UIImage imageNamed:@"focuseIcon.png"]];
        [self.contentView addSubview:self.checkIcon];
        
        self.eventDescView = [[UITextView alloc] initWithFrame:textFrame];
        [self.eventDescView setBackgroundColor: [UIColor clearColor]];
        [self.eventDescView setEditable:false];
        [self.eventDescView setScrollEnabled:false];
        [self.contentView addSubview:self.eventDescView];
        [self.contentView setBackgroundColor:[UIColor clearColor]];
        [self setBackgroundColor:[UIColor clearColor]];
      
    }
    return self;
}
/*
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(0,0,50,40);
    self.textLabel.frame = CGRectMake(45, 0, self.frame.size.width -45, self.frame.size.height);
}
*/
@end
