//
//  ErrorViewController.m
//  WifiChecker
//
//  Created by Jason on 13/6/27.
//  Copyright (c) 2013年 Ahoku. All rights reserved.
//

#import "ErrorViewController.h"
#import "OpeningViewController.h"

@interface ErrorViewController ()

@end

@implementation ErrorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [ai stopAnimating];//Is allowed to control because ai is a global variable.
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
