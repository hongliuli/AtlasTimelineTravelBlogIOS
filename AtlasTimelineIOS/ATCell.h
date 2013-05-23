//
//  ATCell.h
//  AtlasTimelineIOS
//
//  Created by Hong on 12/29/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ATEventDataStruct;

@interface ATCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;


@property (nonatomic, strong) ATEventDataStruct *entity;

@end


/*
 
 @class HighlightingTextView;
 @class Quotation;
 
 
 @interface QuoteCell : UITableViewCell
 
 @property (nonatomic, weak) IBOutlet UILabel *characterLabel;
 @property (nonatomic, weak) IBOutlet UILabel *actAndSceneLabel;
 @property (nonatomic, weak) IBOutlet HighlightingTextView *quotationTextView;
 
 @property (nonatomic, strong) Quotation *quotation;
 
 @end
*/