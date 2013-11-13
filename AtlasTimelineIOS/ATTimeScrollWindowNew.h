//
//  HorizontalTableCell.h
//  HorizontalTables
//
//  Created by Felipe Laso on 8/19/11.
//  Copyright 2011 Felipe Laso. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATViewController;

@interface ATTimeScrollWindowNew : UIView <UITableViewDelegate, UITableViewDataSource,UIScrollViewDelegate>
@property (weak, nonatomic) ATViewController* parent; //will call parent to change slider
@property (nonatomic, retain) UITableView *horizontalTableView;

- (IBAction)handlePinch:(UIPanGestureRecognizer *)recognizer;
- (void) setNewFocusedDateFromAnnotation:(NSDate*) newFocusedDate; //put in interface because parent map view will call this after focuse annotation

@end
