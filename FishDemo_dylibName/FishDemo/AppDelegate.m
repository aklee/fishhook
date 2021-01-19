//
//  AppDelegate.m
//  FishDemo
//
//  Created by ak on 2021/1/4.
//

#import "AppDelegate.h"
#import <objc/message.h>
#import "fishhook.h"
#import "GTDylibCheck.h"
//#import <CoreLocation/CLLocationManager.h>
@interface AppDelegate ()

@end
@interface dddd : NSObject
@property (nonatomic, readonly) int accuracyAuthorization;
@end

@implementation AppDelegate
static AppDelegate* delegate;
static void (*orgi_NSLog)(NSString *format, ...);
void my_NSLog(NSString *format, ...)
{
    printf("printf-> %s\n", format.UTF8String);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 源码参考地址：https://chromium.googlesource.com/external/github.com/facebook/fishhook/
    
    //指定动态库名称
    // 失败，需要匹配动态库路径
    //    rebind_symbols((struct rebinding[1]){{"NSLog", "Foundation", my_NSLog, (void *)&orgi_NSLog}}, 1);
    // 失败，不匹配
    //    rebind_symbols((struct rebinding[1]){{"NSLog", my_NSLog, (void *)&orgi_NSLog}}, 1);
    // 成功hook
//    rebind_symbols((struct rebinding[1]){{"NSLog", "/System/Library/Frameworks/Foundation.framework/Foundation", my_NSLog, (void *)&orgi_NSLog}}, 1);
  
    // 检查app是否在Build Phase -> Link Binary With Libraries接入动态库
    int ret = gt_has_dylib_name("/System/Library/Frameworks/Foundation.framework/Foundation");
    NSLog(@"has_dylib_name %@",@(ret));
    ret = gt_has_dylib_name("/System/Library/Frameworks/CoreLocation.framework/CoreLocation");
    NSLog(@"has_dylib_name %@",@(ret));
    [self checkRuntime];
    delegate = self;
    NSLog(@"Hello world");
    return YES;
}

// 运行时中引入dylib，has_dylib_name 检测不到。 has_dylib_name只会检测当前app可执行文件中动态库列表
- (void)checkRuntime {
  // 运行时添加动态库，macho中loadCommands中不会有CoreLocation这个动态库的引入
  Class cls = NSClassFromString(@"CLLocationManager");
  dddd *test = [cls new];
    NSLog(@"%@",@([test accuracyAuthorization]));
    
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4), dispatch_get_main_queue(), ^{
      // 检查app是否接入动态库
      int ret = gt_has_dylib_name("/System/Library/Frameworks/Foundation.framework/Foundation");
      NSLog(@"has_dylib_name %@",@(ret));//1
      ret = gt_has_dylib_name("/System/Library/Frameworks/CoreLocation.framework/CoreLocation");
      NSLog(@"has_dylib_name %@",@(ret));//0
  });
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
