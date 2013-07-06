//
//  ATInAppPurchaseViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 6/17/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface ATInAppPurchaseViewController : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver, UIAlertViewDelegate>

- (void) processInAppPurchase;
- (void)restorePreviousPurchases;

@end
