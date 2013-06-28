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

        self.image = [[UIImageView alloc] initWithFrame:frame];

        [self.contentView addSubview:self.image];
        
        self.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    }
    return self;
}



@end
