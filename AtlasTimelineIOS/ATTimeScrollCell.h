//
//  ATTimeScrollCell
//  HorizontalTables
//
//  Created by Felipe Laso on 8/20/11.
//  Copyright 2011 Felipe Laso. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ATTimeScrollCell : UITableViewCell

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *subLabel;
@property (nonatomic, retain) UILabel *scallLabel;
@property (nonatomic, retain) NSDate *date; //for click on cell to color red 
@end
