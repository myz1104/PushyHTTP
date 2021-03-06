//
//  TWAppDelegate.m
//  ThreadedWeb
//
//  Created by Chen Zhang on 3/5/13.
//  Copyright (c) 2013 Chen Zhang. All rights reserved.
//

#import "TWAppDelegate.h"
#import "TWConnectionDelegate.h"

@interface TWAppDelegate ()
@property (strong,nonatomic) HTTPServer *server;
@property (strong,nonatomic) TWConnectionDelegate *connDelegate;
@property (strong,nonatomic) TWConnectionTestSource *source;
@end
@implementation TWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        TWConnectionTestSource *source = [[TWConnectionTestSource alloc] initWithInterval:10.];
        self.source = source;
        
        TWConnectionDelegate *dele = [[TWConnectionDelegate alloc] init];
        self.connDelegate = dele;
        
        self.server = [[HTTPServer alloc] init];
        [self.server setType:@"_http._tcp."];
        [self.server setName:@"Pushy"];
        [self.server setPort:3333];
        [self.server setDelegate:dele];
        [self.server start:nil];
        
        [[NSRunLoop currentRunLoop] run];
    });
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
