//
//  QuickSettingsViewController.m
//  WifiChecker
//
//  Created by Jason on 13/7/18.
//  Copyright (c) 2013年 Ahoku. All rights reserved.
//

#import "QuickSettingsViewController.h"
#import "OpeningViewController.h"
#import "ViewController.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>

/********************************* 80  Length *********************************/
@interface QuickSettingsViewController ()


@end

@implementation QuickSettingsViewController{
    //Initializing variables that are to be used across the different methods.
    NSInteger conint; //integer describing the current connection type
    NSString *APssidString; //String with the SSID of the AP
    NSString *APpassString; //String with the Password of the AP
    NSString *objectSelected; //String with the SSID of the selected wifi network to connect to
    NSArray *wifiObject; //Array of the data from the selected wifi network to connect to
    NSString *ssidString; //String with the SSID of the wifi network to connect to
    NSString *passString; //String with the password of the wifi network to connect to
    NSString *WEPkey1; //String of the WEP password of the wifi network to connect to
    NSString *WEPkey2; //String of the WEP password of the wifi network to connect to
    NSString *WEPkey3; //String of the WEP password of the wifi network to connect to
    NSString *WEPkey4; //String of the WEP password of the wifi network to connect to
    NSInteger wepint; //integer of the WEP key to use as the password
    NSInteger securityint; //integer of the 4 different security options
    NSInteger encryptionint; //integer of the 1 or 2 different encryption options
    NSInteger wizardview; //integer of whether or not to try and retrieve the connection type or to change the AP to wired
    UIWebView *webViewx; //The webview that is used to submit data into
}

////////////////////////////////////////////////////////////////////////////////
//These functions are built in functions that are being overriden.
#pragma mark - Override Functions
////////////////////////////////////////////////////////////////////////////////
//This runs when the view loads and will do some setup
- (void)viewDidLoad{
    //Set Integers
    conint = 1;
    wepint = 0;
    securityint = 0;
    encryptionint = 0;
    wizardview = 0;
    
	// Do any additional setup after loading the view.
    QRootElement *root = [[QRootElement alloc]init];
    root.title = @"Quick Settings";
    root.grouped = TRUE;
    self.root = root;
    
    //To allow grouped sections (makes everything look much better)
    QuickDialogTableView *view = [[QuickDialogTableView alloc] initWithController:self];
    self.quickDialogTableView = view;
    
    //Initializing using original wifi SSID and password
    APssidString = [self currentWifiSSID];
    APpassString = [self getAPPassword];
    
    //initialize the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:ai];
    
    [self StopActivityIndicator];//disable initially
    
    //To create the background webview that will be used to submit data (DO NOT CHANGE)
    webViewx = self.viewWeb;
    webViewx.delegate = self; //ignore this error as it allows for the webviewdidload.
    
    [self getConnectionType];//tries to set the connection type. and will call the first view.
    
    //Required as a saftey incase Apple changes the way that viewDidLoad works.
    [super viewDidLoad];
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    [webViewx stopLoading];
}
//This function will run when the webView (that is running in the "background") is finished loading. to allow Javascript to be run on those pages.
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"in webviewdidfinishload: %@", webView.request.URL.absoluteString);
    
    //This webview is the one that is the selector screen for wireless or wired will 
    if([webView.request.URL.absoluteString rangeOfString:[NSString stringWithFormat:@"%@%@%@",@"http://",fullIP,@"/wizard/wizard.asp"]].location != NSNotFound){
        switch (wizardview) {
            case 1:{//This will set the connection to use wired
                NSString *jsCall1 = [NSString stringWithFormat:@"radio_click('%i')",0];
                [webView stringByEvaluatingJavaScriptFromString:jsCall1];
                NSString *jsCall2 = @"next_()";
                [webView stringByEvaluatingJavaScriptFromString:jsCall2];
                NSLog(@"Done: %@", webView.request.URL.absoluteString);
                wizardview = 0;
                break;
            }
            case 2:{//This will check what connection type you were using to begin with (will be first run that will end up starting the first view.
                NSString *gi1 = @"function f(){if(document.wifi_sel_for.mode_sel[0].checked == true){return 0;}else{return 1;}} f();";
                NSString *result = [webView stringByEvaluatingJavaScriptFromString:gi1];
                NSLog(@"result: %@", result);
                conint = [result integerValue];
                wizardview = 0;
                [self QuickSettingsview1]; //Calls the first view after conint is set.
                break;
            }
            default:
                break;
        }
        
    }
    //This is when you finally click submit to set up the wireless
    if([webView.request.URL.absoluteString rangeOfString:[NSString stringWithFormat:@"%@%@%@",@"http://",fullIP,@"/wizard/wifi_config.asp"]].location != NSNotFound){
        NSString *js1 = [self JSsetval:@"spcli_ssid" toThis:ssidString];
        NSString *js4 = [self JSsetin:@"apcli_mode" toThis:securityint];
        NSString *js5 = @"SecurityModeSwitch()";
        NSString *js6 = [self JSsetin:@"apcli_enc" toThis:encryptionint];
        NSString *js7 = @"EncryptModeSwitch()";
        NSString *js8 = [self JSsetval:@"apcli_wpapsk" toThis:passString];
        NSString *js9 = [self JSsetin:@"apcli_default_key" toThis:wepint];
        NSString *js10 = [self JSsetval:@"apcli_key1"toThis:WEPkey1];
        NSString *js11 = [self JSsetval:@"apcli_key1"toThis:WEPkey2];
        NSString *js12 = [self JSsetval:@"apcli_key1"toThis:WEPkey3];
        NSString *js13 = [self JSsetval:@"apcli_key1"toThis:WEPkey4];
        NSString *jsf = @"next_()";
        
        [webView stringByEvaluatingJavaScriptFromString:js1];
        //        [webView stringByEvaluatingJavaScriptFromString:js2];
        //        [webView stringByEvaluatingJavaScriptFromString:js3];
        [webView stringByEvaluatingJavaScriptFromString:js4];
        [webView stringByEvaluatingJavaScriptFromString:js5];
        [webView stringByEvaluatingJavaScriptFromString:js6];
        [webView stringByEvaluatingJavaScriptFromString:js7];
        switch (securityint) {
            case 0:
            case 1:
                if (encryptionint == 0) {
                    [webView stringByEvaluatingJavaScriptFromString:js9];
                    [webView stringByEvaluatingJavaScriptFromString:js10];
                    [webView stringByEvaluatingJavaScriptFromString:js11];
                    [webView stringByEvaluatingJavaScriptFromString:js12];
                    [webView stringByEvaluatingJavaScriptFromString:js13];
                } else {
                }
                break;
                
            default:
                [webView stringByEvaluatingJavaScriptFromString:js8];
                break;
        }

        [webView stringByEvaluatingJavaScriptFromString:jsf];
        NSLog(@"Done: %@", webView.request.URL.absoluteString);
    }
    //This is to check if the submitting was sucessful and bring up next view
    if([webView.request.URL.absoluteString rangeOfString:[NSString stringWithFormat:@"%@%@%@",@"http://",fullIP,@"/wizard/connecting.asp"]].location != NSNotFound) {
        NSLog(@"Connecting");
        [self ConnectingView];
        [webViewx loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [webViewx stopLoading];
    }
    //This is to check if the submitting was sucessful and bring up next view
    if([webView.request.URL.absoluteString rangeOfString:[NSString stringWithFormat:@"%@%@%@",@"http://",fullIP,@"/wizard/eth_connecting.asp"]].location != NSNotFound){
        NSLog(@"Eth_Connecting");
        [self ConnectingView];
        [webViewx loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];        
        [webViewx stopLoading];
    }
    if([webView.request.URL.absoluteString rangeOfString:[NSString stringWithFormat:@"%@%@%@",@"http://",fullIP,@"/wizard/eth_configing.asp"]].location != NSNotFound){
        NSLog(@"Eth_Configing");
        [self ConnectingView];
        [webViewx loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [webViewx stopLoading];
    }
    if([webView.request.URL.absoluteString rangeOfString:[NSString stringWithFormat:@"%@%@%@",@"http://",fullIP,@"/wizard/configing.asp"]].location != NSNotFound){
        NSLog(@"Configing");
        [self ConnectingView];
        [webViewx loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [webViewx stopLoading];
    }
}
//Other Unused overrides
- (id)initWithNibName:(NSString *)nibNameOrNil
              bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



////////////////////////////////////////////////////////////////////////////////
//These functions are the Quick Dialog views that are built and shown to the user
#pragma mark - Quick Dialog Views.
////////////////////////////////////////////////////////////////////////////////
//This first view shows the AP settings including the SSID and password, and the connection type
- (void)QuickSettingsview1{    
    //Initialize the root controller that you will be adding stuff to.
    QRootElement *root = [[QRootElement alloc]init];
    root.title = @"Quick Settings";
    root.grouped = TRUE;
    
    //Initialize the first section
    QSection *initSection = [[QSection alloc] initWithTitle:@"Quick Settings: Wifi Travel Router"];
    //Initialize the 3 elements in the first section
    QEntryElement *SSID = [[QEntryElement alloc] initWithTitle:@"SSID" Value:APssidString Placeholder:[self currentWifiSSID]];
    QEntryElement *Pass = [[QEntryElement alloc] initWithTitle:@"Password" Value:APpassString Placeholder:[self getAPPassword]];
    QRadioElement *typeCon = [[QRadioElement alloc] initWithItems:[[NSArray alloc] initWithObjects:@"Cable Connection",@"Wireless Connection", nil] selected:conint title:@"Connection Type"];
    
    //Code to change settings when typeCon is changed
    id typeConid = typeCon;
    typeCon.onValueChanged = ^(QRootElement *el){
        //Save currently inputted 
        APssidString = SSID.textValue;
        APpassString = Pass.textValue;
        conint = ((QRadioElement *)typeConid).selected;
        //Refresh view
        [self QuickSettingsview1];
    };
    
    //Initialize the submit section
    QSection *submitSection = [[QSection alloc] init];
    //Initialize the submit button
    QButtonElement *submit = [[QButtonElement alloc] init];
    //Title the submit button depending on the current connection type
    if (conint == 0) {
        submit.title = @"Submit";
    } else{
        submit.title = @"Next";
    }
    //set submit action
    submit.controllerAction = @"Submit1:";
    //Code to save settings when submit is pressed
    id submitid = submit;
    submit.onSelected = ^(void){
        //Save input
        APssidString = SSID.textValue;
        APpassString = Pass.textValue;
        conint = typeCon.selected;
        //Code that does text validation before allowing next view
        if(SSID.textValue.length == 0 || Pass.textValue.length < 8){
            [self alertError:@"Text Length Error" withMessage:@"SSID must be at least 1 character long and Password must be longer than 8 characters"];
            //disable the controller action
            ((QButtonElement *)submitid).controllerAction = nil;
            //return to this view
            [self QuickSettingsview1];
        }
    };
    
    //Initialize Quit button
    QButtonElement *quit = [[QButtonElement alloc]initWithTitle:@"Quit"];
    //Add Action to Quit Button
    quit.controllerAction = @"Quit:";
    
    //Adding elements (Must keep in order)
    [initSection addElement:SSID];
    [initSection addElement:Pass];
    [initSection addElement:typeCon];
    [submitSection addElement:submit];
    [submitSection addElement:quit];
    
    //Adding Sections
    [root addSection:initSection];
    [root addSection:submitSection];
    
    //Applying view
    self.root = root;
    
    //stop animating
    [self StopActivityIndicator];
}
//This second view shows a list of SSID's that the Travel wifi sees.
- (void)QuickSettingsview2{    
    //Set up root
    QRootElement *root = [[QRootElement alloc] init];
    root.title = @"Quick Settings";
    root.grouped = TRUE;
    
    //Init some local variables
    NSMutableArray *ssidget; //array of ssid + data
    int ssidint = 0; //location of old ssid
    
    //Will not allow the second view if the connection is supposed to be wired
    if(conint == 0){
        return;
    }
    
    //Get array of ssid + data of what the AP can see
    ssidget = [self getSSIDs];
    //Get the old ssid that the AP had connected to before
    NSString *oldSSID = [self getOldSSID];
    
    //Look for the location of the old ssid in the array
    for(NSMutableArray *tempArray in ssidget){
        if([[tempArray objectAtIndex:0] isEqualToString:oldSSID]){
            break;
        }
        ssidint++;
    }
    
    //Create the selection section for the ssids
    QSelectSection *ssidSelectSection = [[QSelectSection alloc] initWithItems:[self SSIDStrings:ssidget] selected:ssidint title:@"External Wireless Devices: Select SSID"];
    //error prevention if no previous object exists, or else sets to the previous ssid.
    if(ssidint < ssidget.count){
        objectSelected = [ssidSelectSection.selectedItems objectAtIndex:0];
    }
    
    //code to save selected ssid
    id sssid = ssidSelectSection;
    ssidSelectSection.onSelected = ^(void){
        objectSelected = [((QSelectSection *)sssid).selectedItems objectAtIndex:0];
    };
    
    //Create submit section
    QSection *submitSection = [[QSection alloc] init];
    //create back button
    QButtonElement *back = [[QButtonElement alloc] initWithTitle:@"Back"];
    back.controllerAction = @"Back2:";
    
    //create submit button
    QButtonElement *submit = [[QButtonElement alloc] initWithTitle:@"Next"];
    submit.controllerAction = @"Submit2:";
    
    //code to do submission validation, to ensure that an option is selected or else it will not allow continuing (may not be necessary, but is nice for simplicity
    id submitid = submit;
    submit.onSelected = ^(void){
        if ([ssidSelectSection.selectedItems count] == 0) { //check if an item is selected or not
            //create an error alert
            [self alertError:@"Selection Error" withMessage:@"Must Select an object"];
            //disable the further action
            ((QButtonElement *)submitid).controllerAction = nil;
            //return to same view
            [self QuickSettingsview2];
        } else {//if an item IS selected it will set the array object with the necessary data
            wifiObject = [self SSIDArrayAndData:ssidget forString:objectSelected];
        }
    };
    
    //create quit button
    QButtonElement *quit = [[QButtonElement alloc]initWithTitle:@"Quit"];
    quit.controllerAction = @"Quit:";
    
    //Add elements
    [submitSection addElement:submit];
    [submitSection addElement:back];
    [submitSection addElement:quit];
    //Add Sections to root
    [root addSection:ssidSelectSection];
    [root addSection:submitSection];
    //set root to self.root (bring up view)
    self.root = root;
    
    //Stop Activity Indicators
    [self StopActivityIndicator];
}
//This third view shows the final settings for the wireless connection type such as encryption type and password
- (void)QuickSettingsview3{    
    //Create root element
    QRootElement *root = [[QRootElement alloc] init];
    root.title = @"Quick Settings";
    root.grouped = TRUE;
    
    //Create Settings section
    QSection *section = [[QSection alloc] initWithTitle:@"Wifi Settings"];
    
    QLabelElement *label = [[QLabelElement alloc] initWithTitle:ssidString Value:[wifiObject objectAtIndex:1]];
    
    //Create the entry element SSID
    QEntryElement *SSID = [[QEntryElement alloc] initWithTitle:@"SSID"
                                                         Value:ssidString
                                                   Placeholder:@"SSID"];
    
    //Create a local arrays to be used in the radio elements
    NSArray *securityArray = [[NSArray alloc] initWithObjects:@"OPEN",@"SHARED",@"WPAPSK",@"WPA2PSK", nil];
    NSArray *keyArray = [[NSArray alloc] initWithObjects:@"Key 1",@"Key 2",@"Key 3",@"Key 4", nil];
    
    //create the security selection element
    QRadioElement *Security = [[QRadioElement alloc] initWithItems:securityArray
                                                          selected:securityint
                                                             title:@"Security"];
    
    //create the encryption type element
    QRadioElement *EncryptionType = [[QRadioElement alloc]init];
    EncryptionType.title = @"Encryption Type";
    
    //Change the items in the radio element according to the selection from the security
    switch (securityint) {
        case 0:
            EncryptionType.items = [[NSArray alloc]initWithObjects:@"WEP",@"NONE", nil];
            break;
        case 1:
            EncryptionType.items = [[NSArray alloc]initWithObjects:@"WEP", nil];
            break;
        case 2:
        case 3:
            EncryptionType.items = [[NSArray alloc]initWithObjects:@"TKIP",@"AES", nil];
            break;
        default:
            break;
    }
    EncryptionType.selected = encryptionint;
    id Encryptionid = EncryptionType;
    
    //Create the passphrase element
    QEntryElement *passphrase = [[QEntryElement alloc] initWithTitle:@"Pass Phrase" Value:passString Placeholder:@""];
    //Create the elements for the WEP key setup
    QRadioElement *defaultpass = [[QRadioElement alloc] initWithItems:keyArray
                                                             selected:wepint
                                                                title:@"WEP Default Key"];
    QEntryElement *WEPkeyE1 = [[QEntryElement alloc] initWithTitle:@"WEP Key 1" Value:WEPkey1 Placeholder:@""];
    QEntryElement *WEPkeyE2 = [[QEntryElement alloc] initWithTitle:@"WEP Key 2" Value:WEPkey2 Placeholder:@""];
    QEntryElement *WEPkeyE3 = [[QEntryElement alloc] initWithTitle:@"WEP Key 3" Value:WEPkey3 Placeholder:@""];
    QEntryElement *WEPkeyE4 = [[QEntryElement alloc] initWithTitle:@"WEP Key 4" Value:WEPkey4 Placeholder:@""];
    
    
    //On Value Changed, save other values and refresh (as there may be a view change)
    id Securityid = Security;
    Security.onValueChanged = ^(QRootElement *el){
        securityint = ((QRadioElement *)Securityid).selected;
        encryptionint = 0;
        ssidString = SSID.textValue;
        wepint = defaultpass.selected;
        WEPkey1 = WEPkeyE1.textValue;
        WEPkey2 = WEPkeyE2.textValue;
        WEPkey3 = WEPkeyE3.textValue;
        WEPkey4 = WEPkeyE4.textValue;
        passString = passphrase.textValue;
        [self QuickSettingsview3];
    };
    EncryptionType.onValueChanged = ^(QRootElement *el){
        securityint = Security.selected;
        ssidString = SSID.textValue;
        encryptionint = ((QRadioElement *)Encryptionid).selected;
        wepint = defaultpass.selected;
        WEPkey1 = WEPkeyE1.textValue;
        WEPkey2 = WEPkeyE2.textValue;
        WEPkey3 = WEPkeyE3.textValue;
        WEPkey4 = WEPkeyE4.textValue;
        passString = passphrase.textValue;
        [self QuickSettingsview3];
    };
    
    //Submit Section initializations
    QSection *submitSection = [[QSection alloc] init];
    QButtonElement *submit = [[QButtonElement alloc] initWithTitle:@"Submit"];
    submit.controllerAction = @"Submit3:";
    id submitid = submit;
    submit.onSelected = ^(void){
        //Save values
        securityint = Security.selected;
        ssidString = SSID.textValue;
        encryptionint = EncryptionType.selected;
        wepint = defaultpass.selected;
        WEPkey1 = WEPkeyE1.textValue;
        WEPkey2 = WEPkeyE2.textValue;
        WEPkey3 = WEPkeyE3.textValue;
        WEPkey4 = WEPkeyE4.textValue;
        passString = passphrase.textValue;
        //Text Validation
        if (ssidString.length == 0) {
            [self alertError:@"Text Length Error" withMessage:@"SSID must be at least 1 character"];
            ((QButtonElement *)submitid).controllerAction = nil;
            [self QuickSettingsview3];
        }
        switch (securityint) {
            case 0:
            case 1:
                if (encryptionint == 0) {
                    switch (wepint) {
                        case 0:
                            if (WEPkey1.length == 0) {
                                [self alertError:@"Text Length Error" withMessage:@"Password must be at least 1 character"];
                                ((QButtonElement *)submitid).controllerAction = nil;
                                [self QuickSettingsview3];
                            }
                            break;
                        case 1:
                            if (WEPkey2.length == 0) {
                                [self alertError:@"Text Length Error" withMessage:@"Password must be at least 1 character"];
                                ((QButtonElement *)submitid).controllerAction = nil;
                                [self QuickSettingsview3];
                            }
                            break;
                        case 2:
                            if (WEPkey3.length == 0) {
                                [self alertError:@"Text Length Error" withMessage:@"Password must be at least 1 character"];
                                ((QButtonElement *)submitid).controllerAction = nil;
                                [self QuickSettingsview3];
                            }
                            break;
                        case 3:
                            if (WEPkey4.length == 0) {
                                [self alertError:@"Text Length Error" withMessage:@"Password must be at least 1 character"];
                                ((QButtonElement *)submitid).controllerAction = nil;
                                [self QuickSettingsview3];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
                break;
            default:
                if (passString.length == 0) {
                    [self alertError:@"Text Length Error" withMessage:@"Password must be at least 1 character"];
                    ((QButtonElement *)submitid).controllerAction = nil;
                    [self QuickSettingsview3];
                }
                break;
        }
    };
    
    //Initialize the other 2 buttons
    QButtonElement *back = [[QButtonElement alloc] initWithTitle:@"Back"];
    back.controllerAction = @"Back3:";
    QButtonElement *quit = [[QButtonElement alloc]initWithTitle:@"Quit"];
    quit.controllerAction = @"Quit:";
    
    //Add Elements
    [section addElement:label];
    [section addElement:SSID];
    [section addElement:Security];
    [section addElement:EncryptionType];
    //This checks what the security setup currently is and adds the elements accordingly
    switch (securityint) {
        case 0:
        case 1:
            if(encryptionint == 0){
                [section addElement:defaultpass];
                [section addElement:WEPkeyE1];
                [section addElement:WEPkeyE2];
                [section addElement:WEPkeyE3];
                [section addElement:WEPkeyE4];
            }
            break;
        case 2:
        case 3:
            [section addElement:passphrase];
            break;
        default:
            break;
    }
    
    //Add submit section
    [submitSection addElement:submit];
    [submitSection addElement:back];
    [submitSection addElement:quit];
    
    //Add sections to root
    [root addSection:section];
    [root addSection:submitSection];
    
    //Set self to use this root
    self.root = root;
    
    //Stop activity Indicators
    [self StopActivityIndicator];
}
//This last view is shown when the final submit button has been selected, (from either the first view or the third)
- (void)ConnectingView{
    //Create root element
    QRootElement *root =[[QRootElement alloc] init];
    //Create loading section
    QSection *section = [[QSection alloc] initWithTitle:@"Loading..."];
    //Initialize Elements
    QLabelElement *wait = [[QLabelElement alloc] initWithTitle:@"Please Wait" Value:@"Wifi Router is Restarting"];
    QLoadingElement *spinner = [[QLoadingElement alloc] init];
    QButtonElement *finish = [[QButtonElement alloc] initWithTitle:@"Finish"];
    finish.controllerAction = @"Finish:";
    //Add elements to section
    [section addElement:wait];
    [section addElement:spinner];
    [section addElement:finish];
    //Add section to root
    [root addSection:section];
    //set root
    self.root = root;
}


////////////////////////////////////////////////////////////////////////////////
//These functions are meant to be accessed from the buttons on the QuickDialog (QButtonElement).controllerAction
#pragma mark - Submitting/Starting Functions
////////////////////////////////////////////////////////////////////////////////
//This function quits this view controller
- (void)Quit:(QButtonElement *)buttonElement{
    [self.navigationController popViewControllerAnimated:YES];
    
    //stop activity indicator
    [self StopActivityIndicator];
    [webViewx loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"about:blank"]]]];
}
//This function quits after connection has been reestablished with the AP
- (void)Finish:(QButtonElement *)buttonElement{
    if([[self currentWifiSSID] isEqualToString:APssidString]){
        [self Quit:nil];
    } else {
        [self ConnectingView];
    }
    //stop activity indicator
    [self StopActivityIndicator];
}
//This function decides where to go after submitting the first view
- (void)Submit1:(QButtonElement *)buttonElement{
    //start the activity indicator in separate thread
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];
    
    switch (conint) {
        case 0:
            [self makeConnectionCable];
            break;
        case 1:
            [self QuickSettingsview2];
        default:
            break;
    }
}
//This function decides where to go after submitting the second view
- (void)Submit2:(QButtonElement *)buttonElement{
    //start the activity indicator in separate thread
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];
    
    //Set up Security according to security of selected SSID
    NSString *securityString = [wifiObject objectAtIndex:1];
    if ([securityString hasPrefix:@"WPAPSK"]) {
        securityint = 2;
    } else if([securityString hasPrefix:@"WPA"]){
        securityint = 3;
    } else if([securityString hasPrefix:@"WEP"]){
        securityint = 1;
    } else {
        securityint = 0;
    }
    
    //Set Up Encryption
    if ([securityString hasSuffix:@"AES"]){
        encryptionint = 1;
    } else {
        encryptionint = 0;
    }
    
    //Set up ssid/password strings
    ssidString = [wifiObject objectAtIndex:0];
    if([ssidString isEqualToString:[self getOldSSID]]){
        passString = [self getOldPassword];
    } else {
        passString = @"";
    }
    
    //open view 3
    [self QuickSettingsview3];
}
//This function decides where to go after submitting the third view
- (void)Submit3:(QButtonElement *)buttonElement{
    //start the activity indicator in separate thread
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];
    
    [self changeSSIDorPASS];
}
//This function allows returning to the first view from the second view
- (void)Back2:(QButtonElement *)buttonElement{
    //start the activity indicator in separate thread
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];

    [self QuickSettingsview1];
}
//This function allows returning to the second view from the third view
- (void)Back3:(QButtonElement *)buttonElement{
    //start the activity indicator in separate thread
    [NSThread detachNewThreadSelector:@selector(StartActivityIndicator) toTarget:self withObject:nil];
    
    [self QuickSettingsview2];
}



////////////////////////////////////////////////////////////////////////////////
//These functions are subfunctions that may be used more than once throughout the program
#pragma mark - Useful Helper Methods
////////////////////////////////////////////////////////////////////////////////
//This function takes a URL string and returns the HTML from that site
- (NSString *)getHTML:(NSString *)urlString{
    return [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSASCIIStringEncoding error:nil];
}
//This function returns the SSIDs and other information that the travel wifi adapter can view. (The format is a mutable array of mutable arrays containing strings with 0:SSID, 1:Encryption, 2:Channel, 3:Signal Strength)
- (NSMutableArray *)getSSIDs {
    //Creating the request
    NSMutableArray *returnArray = [[NSMutableArray alloc]init];
    NSMutableArray *tempArray = [[NSMutableArray alloc]init];
    //getting the full HTML of the webpage
    NSString *theURL = [NSString stringWithFormat:@"%@%@%@%@%@%@",@"http://",fullIP,@"/wizard/list.asp?ap_ssid=",APssidString,@"&ap_pass=",APpassString];
    //Cutting down the HTML to the important parts (This is very specific to the HTML on the webpage)
    NSString *theDatainHTML = [self getHTML:theURL];
    NSRange range = [theDatainHTML rangeOfString:@"<tr align=\"center\"  onClick=\"radio_click(0);\">"];
    NSString *FrontCutHTML = [theDatainHTML substringFromIndex:range.location];
    NSRange range2 = [FrontCutHTML rangeOfString:@"<table   width=\"100%\" id=\"buttonx\" border=\"0\" cellpadding=\"2\" cellspacing=\"1\">"];
    NSString *FastCutHTML = [FrontCutHTML substringToIndex:range2.location];
    NSRange range3 = [FastCutHTML rangeOfString:@"</table>"];
    NSString *CleanCutHTML = [FastCutHTML substringToIndex:range3.location];
    
    //Putting the data into the arrays
    NSString *regexStr = @"<td>([^>]*)</td>";//The string of wanted code is between the <td> and </td>
    NSInteger i = 0;
    //This method will take the regexStr and search through the HTML code and pull out the data between that regex string. and add it too the array
    while (i < [CleanCutHTML length]){
        NSRegularExpression *testRegex = [NSRegularExpression regularExpressionWithPattern:regexStr options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *result = [testRegex firstMatchInString:CleanCutHTML options:0 range:NSMakeRange(i, [CleanCutHTML length] - i)];
        NSRange range = [result rangeAtIndex:1];
        if(range.location == 0){
            break;
        }
        NSString *stringData = [CleanCutHTML substringWithRange:range];
        stringData = [self fixWeirdHTML:stringData];
        NSLog(@"Cut Data: %@",stringData);
        [tempArray addObject:stringData];
        i = range.location;
        i = i+range.length;
    }
    
    //Take the one large array and create the array of arrays, grouped by 4.
    NSMutableArray *smalltemp = [[NSMutableArray alloc] init];
    for(NSString *st in tempArray){
        [smalltemp addObject:st];
        if([smalltemp count] == 4){
            [returnArray addObject:smalltemp];
            smalltemp = [[NSMutableArray alloc] init];
        }
    }
    return returnArray;
}
//This function will take the array from the (getSSIDs) function and return an array of just the SSID strings for easier printing out. 
- (NSArray *)SSIDStrings:(NSMutableArray *)ssidArray {
    NSString *tempString;
    NSMutableArray *tempMArray = [[NSMutableArray alloc] init];
    for(NSMutableArray *tempa in ssidArray){//loop to pull out the SSIDs
        //This option is if you want to include extra data on your array, BUT you will need to edit the later implementation of selecting which item you selected (see getSSID's for some help) You will also have to edit the arraydata() function.
        //tempString = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@", @"SSID: ",[tempa objectAtIndex:0],@" Security: ",[tempa objectAtIndex:1], @" Channel: ", [tempa objectAtIndex:2], @" Signal(%): ", [tempa objectAtIndex:3]];
        
        //This option just shows SSID on the array
        tempString = [NSString stringWithFormat:@"%@%@",@"SSID: ", [tempa objectAtIndex:0]];
        NSLog(@"Added String: %@",tempString);
        
        //Add string to array
        [tempMArray addObject:tempString];
    }
    //Convert the mutablearray into a regular array
    NSArray *returnArray = [[NSArray alloc] initWithArray:tempMArray];
    NSLog(@"FinishSSIDStrings");
    return returnArray;
}
//This function will get the wifi SSID of whatever you are connected to now on your iOS device
- (NSString *)currentWifiSSID {
    //Code I copied to find ssid info from Reachability
    NSString *ssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for(NSString *ifnam in ifs){
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam,info);
        if(info[@"SSID"]) ssid = info[@"SSID"];
    }
    
    //check return info
    if (ssid != nil){
        return ssid;
    } else {
        return @"ERROR-NO WIFI NETWORK FOUND";
    }
    
    
}
//Will take any string and take out any HTML nuiances and replacing with the correct characters
- (NSString *)fixWeirdHTML:(NSString *)weirdString{
    //These are 3 common HTML changes, there may be more, so please add them as necessary
    weirdString = [weirdString stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    weirdString = [weirdString stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    weirdString = [weirdString stringByReplacingOccurrencesOfString:@"amp;" withString:@"&"];
    return weirdString;
}
//Will return the array that contains the (forString)string in the first column and return the array.
- (NSArray *)SSIDArrayAndData:(NSArray *)searchArray
            forString:(NSString *)searchTarget{
    NSRange range = [searchTarget rangeOfString:@"SSID:"];
    NSString *searchTarget2 = [searchTarget substringFromIndex:(range.location+range.length + 1)];
    //Could probably cut this down because SSID: is always going to be 6 away from the value we want.
    
    //Searches for the array by comparing the ssid to the first object in the array.
    for(NSMutableArray *temparray in searchArray){
        if([[temparray objectAtIndex:0] isEqualToString:searchTarget2]){
            return temparray;
        }
    }
    return nil;
}
//Will get the password of your Travel adapter device
- (NSString *)getAPPassword{
    NSString *theURL = [NSString stringWithFormat:@"%@%@%@",@"http://",fullIP,@"/wizard/wifi_ap.asp"];
    //Gets the html from that site
    NSString *theHTML = [self getHTML:theURL];
    NSRange range1 = [theHTML rangeOfString:@"<input class=\"inputx\" type=text id=\"ap_pass\" name=\"ap_pass\" size=20 maxlength=32 value=\""];
    NSString *firstCut = [theHTML substringFromIndex:(range1.location+range1.length)];
    NSRange range2 = [firstCut rangeOfString:@"\" ></td>"];
    NSString *finalCut = [firstCut substringToIndex:range2.location];
    
    //Returns the final cut data
    return finalCut;
}
//Will get the password of the last wifi network your travel adapter was connected to
- (NSString *)getOldPassword{
    //See get password1
    NSString *theURL = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",@"http://",fullIP,@"/wizard/wifi_config.asp?ch=", [wifiObject objectAtIndex:2],@"&ssid=",[wifiObject objectAtIndex:0],@"&sec=",[wifiObject objectAtIndex:1],@"&ap_ssid=",APssidString,@"&ap_pass=",APpassString];
    NSString *theHTML = [self getHTML:theURL];
    NSRange range1 = [theHTML rangeOfString:@"var pass_old=\""];
    NSString *cut1 = [theHTML substringFromIndex:(range1.location+range1.length)];
    NSRange range2 = [cut1 rangeOfString:@"\";"];
    NSString *finalcut = [cut1 substringToIndex:range2.location];
    return finalcut;
}
//will get the ssid of the last wifi network your travel adapter was connected to
- (NSString *)getOldSSID{
    //See get password 1
    NSString *theURL = [NSString stringWithFormat:@"%@%@%@",@"http://",fullIP,@"/wizard/wifi_config.asp"];
    NSString *theHTML = [self getHTML:theURL];
    NSRange range1 = [theHTML rangeOfString:@"var ssid_old=\""];
    NSString *cut1 = [theHTML substringFromIndex:(range1.location+range1.length)];
    NSRange range2 = [cut1 rangeOfString:@"\";"];
    NSString *finalcut = [cut1 substringToIndex:range2.location];
    return finalcut;
}
//will set the travel wifi device to cable only connection
- (void)makeConnectionCable{
    wizardview = 1;
    [webViewx loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@%@",@"http://",fullIP,@"/wizard/wizard.asp?ap_ssid=",APssidString,@"&ap_pass=",APpassString]]]];
}
//will submit the data from the final page
- (void)changeSSIDorPASS{
    [webViewx loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",@"http://",fullIP,@"/wizard/wifi_config.asp?ch=", [wifiObject objectAtIndex:2],@"&ssid=",[wifiObject objectAtIndex:0],@"&sec=",[wifiObject objectAtIndex:1],@"&ap_ssid=",APssidString,@"&ap_pass=",APpassString]]]];
}
//Shortcut code for javascript setting dropdowns
- (NSString *)JSsetin:(NSString *)thisID
              toThis:(NSInteger)thisIndex{
    return [NSString stringWithFormat:@"document.getElementById(\"%@\").options.selectedIndex = %i;",thisID,thisIndex];
}
//shortcut code for javascript setting textfields
- (NSString *)JSsetval:(NSString *)thisID
               toThis:(NSString *)thisValue{
    return [NSString stringWithFormat:@"document.getElementById(\"%@\").value = '%@';",thisID,thisValue];
}
//Creates an alert error for the user
- (void)alertError:(NSString *)title
      withMessage:(NSString*)message{
    UIAlertView *alertViewError = [[UIAlertView alloc] initWithTitle:title
                                                             message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertViewError show];
}
//gets the connection type by calling the webview.
- (void)getConnectionType{
    wizardview = 2;
    [webViewx loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@%@",@"http://",fullIP,@"/wizard/wizard.asp?ap_ssid=",APssidString,@"&ap_pass=",APpassString]]]];
}
//Required to Enable Activity Indicator
- (void)StartActivityIndicator{
    [ai startAnimating];
}
//Disables activity indicator
- (void)StopActivityIndicator{
    [ai stopAnimating];
}



@end
