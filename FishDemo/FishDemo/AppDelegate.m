//
//  AppDelegate.m
//  FishDemo
//
//  Created by ak on 2021/1/4.
//

#import "AppDelegate.h"
#import "fishhook.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

static void (*orgi_NSLog)(NSString *format, ...);
void my_NSLog(NSString *format, ...)
{
    printf("printf-> %s\n", format.UTF8String);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    rebind_symbols((struct rebinding[1]){{"NSLog", my_NSLog, (void *)&orgi_NSLog}}, 1);
//    rebind_symbols((struct rebinding[1]){{"NSLog", my_NSLog, (void *)&orgi_NSLog}}, 1);
//    rebind_symbols((struct rebinding[2]){{"close", my_close, (void *)&orig_close}, {"open", my_open, (void *)&orig_open}}, 2);
   
    NSLog(@"Hello world");
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
