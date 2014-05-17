//
//  ATUserVerifyViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 2/18/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import "ATUserVerifyViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"

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
    //NSLog(@"getemail clicked");

    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if ([emailTest evaluateWithObject:self.userEmailText.text] == NO) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Email Format!",nil) message:NSLocalizedString(@"Please Enter Valid Email Address.",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    //continues to get from server
    NSString* serviceUrl = [NSString stringWithFormat:@"%@/verifyusersetup?user_id=%@",[ATConstants ServerURL], self.userEmailText.text];
    NSString* responseStr  = [ATHelper httpGetFromServer:serviceUrl];
    if (responseStr == nil)
        return;
    else
        receivedSecurityCode = responseStr;
    //NSLog(@"received security code: %@",receivedSecurityCode);
    self.securityCodeText.enabled = true;
    self.verifyButton.enabled = true;
    self.securityCodeText.backgroundColor = [UIColor whiteColor];
    self.verifyButton.backgroundColor = [UIColor whiteColor];
    
    verifyingUserEmail = self.userEmailText.text;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check Your Email!",nil) message:NSLocalizedString(@"Please enter the security code you received in your email!",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)verifySecurityCodeAction:(id)sender {
    //NSLog(@"verify email clicked");
    NSString* scStr = [self.securityCodeText.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* emailStr = [self.userEmailText.text stringByReplacingOccurrencesOfString:@" " withString:@""];

   if ([scStr isEqualToString:receivedSecurityCode]
       && [emailStr isEqualToString:verifyingUserEmail])
   {
       NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
       [userDefault setObject:verifyingUserEmail forKey:[ATConstants UserEmailKeyName]];
       [userDefault setObject:receivedSecurityCode forKey:[ATConstants UserSecurityCodeKeyName]];
       [userDefault synchronize];

       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verify Success!",nil) message:NSLocalizedString(@"You can import/export from any device with the same email address!",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       [self dismissViewControllerAnimated:true completion:nil];
       [alert show];
   }
   else
   {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verify Failed!",nil) message:NSLocalizedString(@"Make sure you entered correct Security Code received in you email",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
