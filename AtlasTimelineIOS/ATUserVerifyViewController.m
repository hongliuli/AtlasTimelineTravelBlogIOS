//
//  ATUserVerifyViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 2/18/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATUserVerifyViewController.h"
#import "ATConstants.h"

@interface ATUserVerifyViewController ()

@end

@implementation ATUserVerifyViewController

NSString* verifyingUserEmail;
NSString* receivedSecurityCode; //use this to compare with user entered

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.securityCodeText.enabled = false;
    self.verifyButton.enabled = false;
    self.securityCodeText.backgroundColor = [UIColor lightGrayColor];
    self.verifyButton.backgroundColor = [UIColor lightGrayColor];
    
    [self.userEmailText setKeyboardType:UIKeyboardTypeEmailAddress];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (IBAction)getEmailAction:(id)sender {
    NSLog(@"getemail clicked");

    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if ([emailTest evaluateWithObject:self.userEmailText.text] == NO) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Email Format!" message:@"Please Enter Valid Email Address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    //continues to get from server
    NSURL* serviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/verifyusersetup?user_id=%@",[ATConstants ServerURL], self.userEmailText.text]];
    NSMutableURLRequest * serviceRequest = [NSMutableURLRequest requestWithURL:serviceUrl];

    //Get Responce hear----------------------
    NSURLResponse *response;
    NSError *error;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:serviceRequest returningResponse:&response error:&error];
    if (urlData == nil || [urlData length] >20)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connect Server Fail!" message:@"Metwork problem, Please try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    receivedSecurityCode = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
    NSLog(@"received security code: %@",receivedSecurityCode);
    self.securityCodeText.enabled = true;
    self.verifyButton.enabled = true;
    self.securityCodeText.backgroundColor = [UIColor whiteColor];
    self.verifyButton.backgroundColor = [UIColor whiteColor];
    
    verifyingUserEmail = self.userEmailText.text;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check Your Email!" message:@"Please enter the security code you received in your email!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)verifySecurityCodeAction:(id)sender {
    NSLog(@"verify email clicked");
    NSString* scStr = [self.securityCodeText.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* emailStr = [self.userEmailText.text stringByReplacingOccurrencesOfString:@" " withString:@""];

   if ([scStr isEqualToString:receivedSecurityCode]
       && [emailStr isEqualToString:verifyingUserEmail])
   {
       NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
       [userDefault setObject:verifyingUserEmail forKey:[ATConstants UserEmailKeyName]];
       [userDefault setObject:receivedSecurityCode forKey:[ATConstants UserSecurityCodeKeyName]];
       [userDefault synchronize];

       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Verify Success!" message:@"You can import/export from any device with the same email address!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       [self dismissViewControllerAnimated:true completion:nil];
       [alert show];
   }
   else
   {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Verify Failed!" message:@"Make sure you entered correct Security Code received in you email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
   }
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
