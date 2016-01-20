//
//  ATTravelWebViewController.m
//  AtlasTravelReader
//
//  Created by Hong on 1/17/16.
//  Copyright © 2016 hong. All rights reserved.
//

#import "ATTravelWebViewController.h"
#import <WebKit/WebKit.h>

@interface ATTravelWebViewController ()

@end

@implementation ATTravelWebViewController

WKWebView* webView;

- (void)viewDidLoad {
    [super viewDidLoad];
    //this is called after call WKWebView loadRequest
}

-(void) loadFromHtmlText:(NSString*) htmlStr
{
    [webView loadHTMLString:htmlStr baseURL:nil];
}
-(void) loadFromlUrl: (NSString*) url
{
    /*
     * since iOS9, have to add following key to info.plist:
     *   NSAllowsArbitraryLoads -> YES
     * otherwise, http://... will not work, only https:// works
     * This discovery take me long long time (Fuck you Apple)
     */
    NSURL * urlObj = [NSURL URLWithString:url];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:urlObj];
    [webView loadRequest:requestObj];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //Following can not be in viewDidLoad because it is called after call WKWebView loadRequest()
        if (webView == nil)
        {
            webView = [[WKWebView alloc] initWithFrame: [[self view] bounds]];
            webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            [self.view addSubview:webView];
        }
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
