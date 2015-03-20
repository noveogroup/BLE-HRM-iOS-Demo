//
//  AppDelegate.m
//  BLE-HRM-iOS-Demo
//
//  Created by Alexander Gorbunov on 20/03/15.
//  Copyright (c) 2015 Noveo. All rights reserved.
//


#import "AppDelegate.h"
#import "MainVC.h"


@interface AppDelegate ()
@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:
    (NSDictionary *)launchOptions {

    CGRect screenFrame = [UIScreen mainScreen].bounds;
    self.window = [[UIWindow alloc] initWithFrame:screenFrame];

    MainVC *mainVC = [[MainVC alloc] init];
    self.window.rootViewController = mainVC;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
