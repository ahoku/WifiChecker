//
//  OpeningViewController.h
//  WifiChecker
//
//  Created by Jason on 13/7/1.
//  Copyright (c) 2013年 Ahoku. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpeningViewController : UIViewController
-(IBAction)checkTrue:(id)sender;
extern NSString *fullURL;
extern NSString *fullIP;
extern UIActivityIndicatorView *ai;
@end
