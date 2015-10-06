//
//  HorizontalTableCell.h
//  HorizontalTables
//
//  Created by Felipe Laso on 8/19/11.
//  Copyright 2011 Felipe Laso. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATEventEditorTableController;

@interface ATPhotoScrollView : UIView <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) NSMutableArray* photoList;
@property (nonatomic, retain) UITableView *horizontalTableView;
@property (weak, nonatomic) ATEventEditorTableController* eventEditor;
@property NSInteger selectedPhotoIndex;
@property NSMutableSet* selectedAsShareIndexSet;
@property NSMutableArray* selectedAsSortIndexList;
@property NSArray* photoSortedListFromMetaFile;
@property NSMutableDictionary* photoDescMap;

@end
