//
//  ViewController.m
//  WifiChecker
//
//  Created by Jason on 13/6/24.
//  Copyright (c) 2013年 Ahoku. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"
#import "ErrorViewController.h"
#import "OpeningViewController.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

@interface ViewController ()

@end

@implementation ViewController{
    UIApplication* app;
}




- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //initialize the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:ai];
    
    //Doing some initializations
    NSString *URLString = [NSString stringWithFormat:@"%@/home.asp",fullURL];
    UIWebView *webView = self.viewWeb;
    
    webView.delegate = self; //needed in order to do the webview did start/finish loading (ignore warning)
    
    //load url in webview
    NSURL *url = [NSURL URLWithString:URLString];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [webView loadRequest:requestObj];
    
    //Allows for network spinner
    app = [UIApplication sharedApplication];
}

//Simple (kinda...) code to add back button in place of the nav button when applicable.
- (void)updateBackButton {
    if ([self.viewWeb canGoBack]){//first checks if webview can go back
        if(!self.navigationItem.leftBarButtonItem){//checks to see waht the button is currently (runs below code if not)
            [self.navigationItem setHidesBackButton:YES animated:YES];//hides current button (which is the back Nav button)
            UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backWasClicked:)];//creates back button instance
            [self.navigationItem setLeftBarButtonItem:backItem animated:YES];//adds button to navigation
        }
    }
    else {//if webview can no longer go back
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];//removes back button
        [self.navigationItem setHidesBackButton:NO animated:YES];//returns navigation back button
    }
}

//When the view is about to go background
- (void)viewWillDisappear:(BOOL)animated{
    //disable network indicator
    app.networkActivityIndicatorVisible = NO;
    //stop the activity indicator
    [ai stopAnimating];
}

//code runs when webview starts loading, will turn on indicator, and update the back button
- (void)webViewDidStartLoad:(UIWebView *)webView{
    //enable the network indicator
    app.networkActivityIndicatorVisible = YES;
    
    //start the activity indicator in separate thread
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];
    
    [self updateBackButton];
}

//code runs when webview stops loading, and stops indicators, and updates the back button
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    app.networkActivityIndicatorVisible = NO;
    [ai stopAnimating];
    [self updateBackButton];
}

//this is the action of the back button which will retun back on the webview
- (void)backWasClicked:(id)sender{
    if([self.viewWeb canGoBack]){
        [self.viewWeb goBack];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Required to start the animation of the activity indicator in a separate thread
- (void)StartActivityIndicator{
    [ai startAnimating];
}

@end
