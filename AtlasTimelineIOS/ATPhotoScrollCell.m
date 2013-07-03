//
//  ATTimeScrollCell.m
//  HorizontalTables
//
//  Created by Felipe Laso on 8/20/11.
//  Copyright 2011 Felipe Laso. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ATPhotoScrollCell.h"
#import "ATConstants.h"

@implementation ATPhotoScrollCell


#pragma mark - View Lifecycle

- (NSString *)reuseIdentifier 
{
    return @"ATTimeScrollCell";
}
- (id)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self)
    {
        self.contentView.backgroundColor = [UIColor blackColor];
        [self.contentView.layer setBorderColor:[UIColor blackColor].CGColor];
        [self.contentView.layer setBorderWidth:5.0f];
        self.photo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [ATConstants photoScrollCellWidth], [ATConstants photoScrollCellHeight])];
        [self.contentView addSubview:self.photo];
        self.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    }
    return self;
}



@end
