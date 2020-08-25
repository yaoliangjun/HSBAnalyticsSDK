//
//  AppDelegate.m
//  HSBAnalyticsDemo
//
//  Created by Jerry Yao on 2020/8/4.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "AppDelegate.h"
#import <HSBAnalyticsSDK/HSBAnalyticsSDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[HSBAnalyticsManager sharedManager] track:@"testEvent" properties:@{ @"testKey" : @"testValue" }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"%s", __FUNCTION__);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"%s", __FUNCTION__);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"%s", __FUNCTION__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"%s", __FUNCTION__);
}

@end
