//
//  ATTimeScrollCell.m
//  HorizontalTables
//
//  Created by Felipe Laso on 8/20/11.
//  Copyright 2011 Felipe Laso. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ATTimeScrollCell.h"
#import "ATConstants.h"

@implementation ATTimeScrollCell

@synthesize titleLabel = _titleLabel;

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
        //CGRect cellFrame = CGRectMake(0, 0,[ATConstants timeScrollCellWidth],[ATConstants timeScrollCellHeight]);
        CGRect titleFrame = CGRectMake(0, 0,[ATConstants timeScrollCellWidth],[ATConstants timeScrollCellHeight]*0.4);
        CGRect textFrame = CGRectMake(0, [ATConstants timeScrollCellHeight]*0.4,[ATConstants timeScrollCellWidth],[ATConstants timeScrollCellHeight]*0.3);
        CGRect scallFrame = CGRectMake(0, [ATConstants timeScrollCellHeight]*0.75,[ATConstants timeScrollCellWidth],[ATConstants timeScrollCellHeight]*0.25);
        self.titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
        self.titleLabel.opaque = YES;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        //self.titleLabel.numberOfLines = 3;
        [self.contentView addSubview:self.titleLabel];
        
        self.subLabel = [[UILabel alloc] initWithFrame:textFrame];
        self.subLabel.text=@"";
        self.subLabel.textColor = [UIColor whiteColor];
        self.subLabel.font = [UIFont boldSystemFontOfSize:15];
        self.subLabel.backgroundColor = [UIColor clearColor];
        self.subLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.subLabel];
    
        self.scallLabel = [[UILabel alloc] initWithFrame:scallFrame];
        self.scallLabel.textColor = [UIColor whiteColor];
        self.scallLabel.font = [UIFont boldSystemFontOfSize:14];
        self.scallLabel.backgroundColor = [UIColor clearColor];
        self.scallLabel.textAlignment = NSTextAlignmentCenter;
        self.scallLabel.layer.borderColor=[UIColor whiteColor].CGColor;
        self.scallLabel.layer.borderWidth = 1;
        [self.contentView addSubview:self.scallLabel];
        
        self.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    }
    return self;
}



@end
