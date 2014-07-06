//
//  ATMySearchDisplayController.m
//  AtlasTimelineReader
//
//  Created by Hong on 7/1/14.
//  Copyright (c) 2014 hong. All rights reserved.
//

#import "ATMySearchDisplayController.h"
//SearchDisplayController will hide navigation while I do not want to, so used this tech
@implementation ATMySearchDisplayController
- (void)setActive:(BOOL)visible animated:(BOOL)animated
{
    [super setActive: visible animated: animated];
    
    [self.searchContentsController.navigationController setNavigationBarHidden: NO animated: NO];
}
@end
