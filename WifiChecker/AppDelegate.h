//
//  AppDelegate.h
//  WifiChecker
//
//  Created by Jason on 13/6/24.
//  Copyright (c) 2013年 Ahoku. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Reachability;

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    Reachability *internetReach;
}

@property (strong, nonatomic) UIWindow *window;

@end
