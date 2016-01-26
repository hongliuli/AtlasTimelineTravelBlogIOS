//
//  ATTravelWebViewController.m
//  AtlasTravelReader
//
//  Created by Hong on 1/17/16.
//  Copyright © 2016 hong. All rights reserved.
//

#import "ATTravelWebViewController.h"
#import <WebKit/WebKit.h>
#import "SWRevealViewController.h"
#import "ATConstants.h"

@interface ATTravelWebViewController ()

@end

@implementation ATTravelWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwiper];
    //this is called after call WKWebView loadRequest
}

-(void) loadFromHtmlText:(NSString*) htmlStr
{
    [self.webView loadHTMLString:htmlStr baseURL:nil];
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
    [self.webView loadRequest:requestObj];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //Following can not be in viewDidLoad because it is called after call WKWebView loadRequest()
        if (self.webView == nil)
        {
            self.webView = [[WKWebView alloc] initWithFrame: [[self view] bounds]];
            [self setFrame];
            [self.view addSubview:self.webView];
        }
    }
    return self;
}

- (void) setFrame
{
    self.webView.frame = CGRectMake(0, 0, [ATConstants revealViewEventEditorWidth], self.view.frame.size.height);
}

- (void)swipeRight {
    SWRevealViewController *revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
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
