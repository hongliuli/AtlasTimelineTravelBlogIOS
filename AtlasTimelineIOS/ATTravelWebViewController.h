//
//  ATTravelWebViewController.h
//  AtlasTravelReader
//
//  Created by Hong on 1/17/16.
//  Copyright © 2016 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface ATTravelWebViewController : UIViewController

-(void) loadFromHtmlText:(NSString*) htmlStr;
-(void) loadFromlUrl: (NSString*) url;

@end
