//
//  ATTimeScrollWindow.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/30/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATViewController;

@interface ATTimeScrollWindow : UIView

@property int startX;
@property int startY;
@property int endX;
@property int endY;


@property (weak, nonatomic) ATViewController* parent; //will call parent to change slider
@property int pinchFlag; //put in interface b/c parent will set it too.   0-set in Pinch, so redraw will not shift, set to 1 always

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;
- (IBAction)handlePinch:(UIPanGestureRecognizer *)recognizer;
- (void) redrawTimeScrollWindow:(int)zoomingActionFlag; //parent map view will call this after slider change

@end
