//
//  ATUserVerifyViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 2/18/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATUserVerifyViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UITextField *userEmailText;
@property (weak, nonatomic) IBOutlet UIButton *verifyButton;
@property (weak, nonatomic) IBOutlet UITextField *securityCodeText;
- (IBAction)getEmailAction:(id)sender;
- (IBAction)verifySecurityCodeAction:(id)sender;
- (IBAction)dismiss:(id)sender;


@end
