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

UITextField *userEmailText;
UIButton *verifyButton;
UITextField *securityCodeText;

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
    
    securityCodeText = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 0.0, 180, 40)];
    [securityCodeText setBorderStyle:UITextBorderStyleLine];
    [securityCodeText setKeyboardType:UIKeyboardTypeNumberPad];
    [securityCodeText setPlaceholder:NSLocalizedString(@"Enter Code",nil)];
    verifyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    securityCodeText.enabled = false;
    verifyButton.enabled = false;
    securityCodeText.backgroundColor = [UIColor lightGrayColor];
    verifyButton.backgroundColor = [UIColor lightGrayColor];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Table view delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* customView = nil;
    // create the parent view that will hold header Label
    if (section == 0)
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400, 100)];
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 350, 100)];
        label.numberOfLines = 5;
        label.text = NSLocalizedString(@"Enter your email， tap [Send Code]. Then check your email to get security code.\nNext, enter the security code and tap [Verify] to login. Your email address will be your login ID!",nil);
        [customView addSubview:label];
    }
    if (section == 1)
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400, 50)];
        userEmailText = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 0.0, 180, 40)];
        [userEmailText setKeyboardType:UIKeyboardTypeEmailAddress];
        [userEmailText setBorderStyle:UITextBorderStyleLine];
        userEmailText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [userEmailText setPlaceholder:NSLocalizedString(@"Your email addr",nil)];
        UIButton *getEmailButton = [UIButton buttonWithType:UIButtonTypeSystem];
        getEmailButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
        getEmailButton.frame = CGRectMake(200, 0, 120, 50);
        [getEmailButton setTitle:NSLocalizedString(@"Send Me Code",nil) forState:UIControlStateNormal];
        //[addFriendButton.titleLabel setTextColor:[UIColor blueColor]];
        [getEmailButton addTarget:self action:@selector(getEmailAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:userEmailText];
        [customView addSubview:getEmailButton];
    }
    if (section == 2)
    {
        customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400, 100)];
        verifyButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
        verifyButton.frame = CGRectMake(200, 0, 120, 40);
        [verifyButton setTitle:NSLocalizedString(@"Verify",nil) forState:UIControlStateNormal];
        //[addFriendButton.titleLabel setTextColor:[UIColor blueColor]];
        [verifyButton addTarget:self action:@selector(verifySecurityCodeAction:) forControlEvents:UIControlEventTouchUpInside];
        [customView addSubview:securityCodeText];
        [customView addSubview:verifyButton];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            UIButton* btn = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn setFrame:CGRectMake(10.0, 50.0, 90, 100)];
            [btn setTitle:NSLocalizedString(@"Dismiss", nil) forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(dismissMeAction:) forControlEvents:UIControlEventTouchUpInside];
            [customView addSubview:btn];
        }
    }
    return customView;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return 100;
    if (section == 1)
        return 50;
    if (section == 2)
        return 100;
    return 50;
}
- (void)dismissMeAction:(id)sender{ //only iPhone comes here
    [self dismissViewControllerAnimated:true completion:nil];
}
- (IBAction)getEmailAction:(id)sender {
    //NSLog(@"getemail clicked");

    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if ([emailTest evaluateWithObject:userEmailText.text] == NO) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Email Format!",nil) message:NSLocalizedString(@"Please Enter Valid Email Address.",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    NSString* email = [userEmailText.text lowercaseString];
    //continues to get from server
    NSString* serviceUrl = [NSString stringWithFormat:@"%@/verifyusersetup?user_id=%@",[ATConstants ServerURL], email];
    NSString* responseStr  = [ATHelper httpGetFromServer:serviceUrl];
    if (responseStr == nil)
        return;
    else
        receivedSecurityCode = responseStr;
    //NSLog(@"received security code: %@",receivedSecurityCode);
    securityCodeText.enabled = true;
    verifyButton.enabled = true;
    securityCodeText.backgroundColor = [UIColor whiteColor];
    verifyButton.backgroundColor = [UIColor whiteColor];
    
    verifyingUserEmail = userEmailText.text;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check Your Email!",nil) message:NSLocalizedString(@"Please enter the security code you received in your email!",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)verifySecurityCodeAction:(id)sender {
    //NSLog(@"verify email clicked");
    NSString* scStr = [securityCodeText.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* emailStr = [userEmailText.text stringByReplacingOccurrencesOfString:@" " withString:@""];

   if ([scStr isEqualToString:receivedSecurityCode]
       && [emailStr isEqualToString:verifyingUserEmail])
   {
       NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
       [userDefault setObject:verifyingUserEmail forKey:[ATConstants UserEmailKeyName]];
       [userDefault setObject:receivedSecurityCode forKey:[ATConstants UserSecurityCodeKeyName]];
       [userDefault synchronize];

       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verify Success!",nil) message:NSLocalizedString(@"You can import/export from any device with the same email address!",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
       [alert show];
       if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            [self dismissViewControllerAnimated:true completion:nil];
       [ATHelper closeCreateUserPopover];
   }
   else
   {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Verify Failed!",nil) message:NSLocalizedString(@"Make sure you entered correct Security Code received in you email",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
   }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
