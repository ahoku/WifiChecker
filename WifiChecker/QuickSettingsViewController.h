//
//  QuickSettingsViewController.h
//  WifiChecker
//
//  Created by Jason on 13/7/18.
//  Copyright (c) 2013年 Ahoku. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuickSettingsViewController : QuickDialogController
//Quick Dialog Controller is provided by escoz.com under the Apache License V2.0
//This allows us to create the nice table views that we have within this section.
//It provides the framework for the inputs, selections, and buttons.
//Official Website: escoz.com/open-source/quickdialog

@property (weak, nonatomic) IBOutlet UIWebView *viewWeb;

@end
