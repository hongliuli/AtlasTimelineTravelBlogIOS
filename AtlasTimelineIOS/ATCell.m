//
//  ATCell.m
//  AtlasTimelineIOS
//
//  Created by Hong on 12/29/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import "ATCell.h"
#import "ATEventDataStruct.h"
#import "ATAppDelegate.h"

@implementation ATCell

@synthesize addressLabel, descLabel, dateLabel;


- (void)setEvent:(ATEventDataStruct *)newEntity {
    
    if (_entity != newEntity) {
        _entity = newEntity;
        
        addressLabel.text = _entity.address;
        descLabel.text = _entity.description;
        
        //not sure if do this is bad performance
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSDateFormatter *dateFormater = appDelegate.dateFormater;
        dateLabel.text = [dateFormater stringFromDate:_entity.eventDate];  ;

    }
}


@end

/*
 #import "QuoteCell.h"
 #import "Quotation.h"
 #import "HighlightingTextView.h"
 
 @implementation QuoteCell
 
 @synthesize characterLabel, quotationTextView, actAndSceneLabel, quotation;
 
 
 - (void)setQuotation:(Quotation *)newQuotation {
 
 if (quotation != newQuotation) {
 quotation = newQuotation;
 
 characterLabel.text = quotation.character;
 actAndSceneLabel.text = [NSString stringWithFormat:@"Act %d, Scene %d", quotation.act, quotation.scene];
 quotationTextView.text = quotation.quotation;
 }
 }
*/