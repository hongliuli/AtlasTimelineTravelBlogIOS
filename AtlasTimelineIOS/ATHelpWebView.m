//
//  ATHelpWebView.m
//  AtlasTimelineIOS
//
//  Created by Hong on 2/27/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATHelpWebView.h"

@interface ATHelpWebView ()

@end

@implementation ATHelpWebView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.helpWebView == nil)
    {
        self.helpWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];// CGRectMake(0, 0, 500, 500)];
        [self.helpWebView setScalesPageToFit:true];
        // self.helpWebView.delegate=self;
        NSString *fullURL = @"http://www.chroniclemap.com/resources/help.html";
        NSURL *url = [NSURL URLWithString:fullURL];
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        [self.helpWebView loadRequest:requestObj];
        [self setView:_helpWebView]; //IMPORT: when use addSubView, the landscape view is bad, now it works
    }

}

- (void)didReceiveMemoryWarning
{
    //[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
   // [self setHelpWebView:nil];
    [super viewDidUnload];
}

@end
