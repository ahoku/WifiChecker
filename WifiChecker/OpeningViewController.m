//
//  OpeningViewController.m
//  WifiChecker
//
//  Created by Jason on 13/7/1.
//  Copyright (c) 2013年 Ahoku. All rights reserved.
//

#import "OpeningViewController.h"
#import "ErrorViewController.h"
#import "ViewController.h"
#import "QuickSettingsViewController.h"
#import "Reachability.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>

@interface OpeningViewController ()

@end

@implementation OpeningViewController

//All these are ok to be public.
UIActivityIndicatorView *ai;
NSString* const DEFAULTWIFITRAVEL = @"Travel_WiFi";
NSString *fullURL;
NSString *fullIP = @"192.168.16.254";


#pragma mark - Overrides
- (void)viewDidLoad{
    [super viewDidLoad];
    
    
    //initialize activity indicator    
    ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:ai];
    //start the activity indicator in separate thread
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];
    
    //run the potentially time consuming operations
    [self runCheckOperations:TRUE];
    
    //stop activity indicator.
    [ai stopAnimating];
}
//When the view is about to go background (used to stop the activity indicator)
-(void)viewWillDisappear:(BOOL)animated{
    [ai stopAnimating];
}
//Memory Warning, not changed
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//Initialization of views
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - Button Actions
//Button Action to check if it should shortcut into the WebView or re-run Check Operations
-(IBAction)checkTrue:(id)sender{
    //start activity indicator
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];
    [self runCheckOperations:FALSE];
    
}
//Button Action to run new Quick Settings
-(IBAction)quickSettingsButton:(id)sender{
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];
    [self runCheckOperations:TRUE];
}


#pragma mark - Add-on Functions
//Needs to be separate to run on a different thread
-(void)StartActivityIndicator{
    [ai startAnimating];
}
//checks if ip address is valid
-(BOOL)isValidIPAddress:(NSString*)ipAddress{
    struct sockaddr_in sa;
    int result = inet_pton(AF_INET, [ipAddress UTF8String], &(sa.sin_addr));
    return result != 0;
}
//operations that check if wifi is available, then check if it can connect to the gateway host ip address.
-(void)runCheckOperations:(BOOL)whichOpen{//True is for Quick Settings, False is for WebView Settings
    //First step is to retrieve the IP address stored in the settings (whether or not the user changed it)
    NSString *settingsIP = [self retrieveFromUserDefaults:@"IP_Address"];
    
    //This step is to check if the IP address that the user may have edited is valid
    if([self isValidIPAddress:settingsIP]){ //if valid then set the ip to the settings set IP
        fullIP = settingsIP;
    } else { //if not, restore value with Past run or default (depending on if new run or not)
        [self saveToUserDefaults:@"IP_Address" value:fullIP];
    }
    
    //Set the full url to include the full ip address.
    fullURL = [@"http://" stringByAppendingString:fullIP];
    
    //This step is to check if wifi is enabled or not
    if(![self checkWifiStatus]){ //if it is not enabled it will give a specific pop-up and open the error view
        UIAlertView *alertViewWifiError = [[UIAlertView alloc] initWithTitle:@"Wifi is Not Enabled"
                                                                     message:@"You must be connected to wifi to continue" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertViewWifiError show];
        [self openErrorView];
    } else {//if wifi is enabled...
        //This will use the combined check method to determine if this network is correct (first checks current IP, and then checks if IP is connectable)
        if(![self combinedCheck]){//if combined check determines that the network failed
            UIAlertView *alertViewError = [[UIAlertView alloc] initWithTitle:@"Not Connected to a Travel Wifi Network!"
                                                                     message:[@"Please change your Wifi Network. You are currently connected to:\r" stringByAppendingString:[self currentWifiSSID]] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertViewError show];
            [self openErrorView];
        } else {//this is if everything is working as it should be
            if (whichOpen) {//if true will open quick settings
                [self openQuickSettings];
            } else{ //if false will open webview
                [self openWebView];
            }
        }
    }
    return;
    
}
// Get IP Address of the current device
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}
//will compare first 3 numbers in ip. Will probably (possibly) significantly speed up the error check process
-(BOOL)checkIPAddress {
    int compareIP[4];
    int ipQuads[4];
    if([self isValidIPAddress:fullIP]){
        const char *compareipAddress = [fullIP cStringUsingEncoding:NSUTF8StringEncoding];
        sscanf(compareipAddress, "%d.%d.%d.%d", &compareIP[0], &compareIP[1], &compareIP[2], &compareIP[3]);
    } else {
        return false;
    }
    
    
    NSString* gottenIPAddress = [self getIPAddress];
    if([self isValidIPAddress:gottenIPAddress]){
        const char *ipAddress = [[self getIPAddress] cStringUsingEncoding:NSUTF8StringEncoding];
        sscanf(ipAddress, "%d.%d.%d.%d", &ipQuads[0], &ipQuads[1], &ipQuads[2], &ipQuads[3]);
    } else {
        return false;
    }
    
    return compareIP[0] == ipQuads[0] && compareIP[1] == ipQuads[1] && compareIP[2] == ipQuads[2];
}
//Fast check ip and error page
- (BOOL)combinedCheck {
    if([self checkIPAddress]){
        return [self checkAvailablePage];
    } else {
        return false;
    }
}
//Get the SSID
- (NSString *)currentWifiSSID {
    
    NSString *ssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for(NSString *ifnam in ifs){
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam,info);
        if(info[@"SSID"]) ssid = info[@"SSID"];
    }
    if (ssid != nil){
        return ssid;
    } else {
        return @"ERROR-NO WIFI NETWORK FOUND";
    }
    
    
}
//Default Travel Wifi SSID Compare (currently will not use until further examination)
- (BOOL)travelSSIDCompare {
    NSString* SSID = [self currentWifiSSID];
    if([SSID length] < [DEFAULTWIFITRAVEL length]) return false;
    return [SSID hasPrefix:DEFAULTWIFITRAVEL];
}
//Function that checks if gateway host ip address is connectable. 
- (bool)checkAvailablePage{
    NSURL *myURL = [NSURL URLWithString: fullURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: myURL];
    [request setHTTPMethod: @"HEAD"];
    NSURLResponse *response;
    NSError *error;
    NSData *myData = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
    return myData;
}
//Checks if wifi is enabled
- (bool)checkWifiStatus{return [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi;}
//To set values in settings
- (void)saveToUserDefaults:(NSString*)key value:(NSString*)valueString{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
	if (standardUserDefaults) {
		[standardUserDefaults setObject:valueString forKey:key];
		[standardUserDefaults synchronize];
	} else {
		NSLog(@"Unable to save %@ = %@ to user defaults", key, valueString);
	}
}
//To get values from settings
- (NSString*)retrieveFromUserDefaults:(NSString*)key{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	NSString *val = nil;
    
	if (standardUserDefaults)
		val = [standardUserDefaults objectForKey:key];
	if (val == nil) {
		NSLog(@"user defaults may not have been loaded from Settings.bundle ... doing that now ...");
		//Get the bundle path
		NSString *bPath = [[NSBundle mainBundle] bundlePath];
		NSString *settingsPath = [bPath stringByAppendingPathComponent:@"Settings.bundle"];
		NSString *plistFile = [settingsPath stringByAppendingPathComponent:@"Root.plist"];
        
		//Get the Preferences Array from the dictionary
		NSDictionary *settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:plistFile];
		NSArray *preferencesArray = [settingsDictionary objectForKey:@"PreferenceSpecifiers"];
        
		//Loop through the array
		NSDictionary *item;
		for(item in preferencesArray)
		{
			//Get the key of the item.
			NSString *keyValue = [item objectForKey:@"Key"];
            
			//Get the default value specified in the plist file.
			id defaultValue = [item objectForKey:@"DefaultValue"];
            
			if (keyValue && defaultValue) {
				[standardUserDefaults setObject:defaultValue forKey:keyValue];
				if ([keyValue compare:key] == NSOrderedSame)
					val = defaultValue;
			}
		}
		[standardUserDefaults synchronize];
	}
	return val;
}


#pragma mark - Opening Views
//opens error view controller
-(void) openErrorView{
    ErrorViewController *evc = [self.storyboard instantiateViewControllerWithIdentifier:@"ErrorView"];
    [self.navigationController pushViewController:evc animated:YES];
}
//opens web view controller
-(void) openWebView{
    ViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}
//opens quick settings vie controller
-(void) openQuickSettings{
    ViewController *qsvc = [self.storyboard instantiateViewControllerWithIdentifier:@"QuickSettings"];
    [self.navigationController pushViewController:qsvc animated:YES];
}


@end
