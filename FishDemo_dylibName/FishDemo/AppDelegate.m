//
//  AppDelegate.m
//  FishDemo
//
//  Created by ak on 2021/1/4.
//

#import "AppDelegate.h"
#import "fishhook.h"
#import <objc/message.h>
@interface AppDelegate ()

@end

@implementation AppDelegate
static AppDelegate* delegate;
static void (*orgi_NSLog)(NSString *format, ...);
void my_NSLog(NSString *format, ...)
{
    printf("printf-> %s\n", format.UTF8String);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    rebind_symbols((struct rebinding[1]){{"NSLog", my_NSLog, (void *)&orgi_NSLog}}, 1);// 传入的是orgi_NSLog的地址指针，在替换完成后会将orgi_NSLog地址写回变量中
    
    //rebind_symbols((struct rebinding[1]){{"NSLog", my_NSLog, nil}}, 1);//效果相同，因为fishhook内部没有对orgi_NSLog做判断，只要方法名和my_NSLog存在就可以完成替换，但是orgi_NSLog就不会被更新了
    
//    rebind_symbols((struct rebinding[1]){{"NSLog", my_NSLog, (void *)&orgi_NSLog}}, 1);
//    rebind_symbols((struct rebinding[2]){{"close", my_close, (void *)&orig_close}, {"open", my_open, (void *)&orig_open}}, 2);
    delegate = self;
//    hookStart();
    NSLog(@"Hello world");
    return YES;
}

#if TARGET_IPHONE_SIMULATOR
void hookStart() {
    //需真机
}
#else

#define call(value) \
__asm volatile ("stp x8, x9, [sp, #-16]!\n"); \
__asm volatile ("mov x12, %0\n" :: "r"(value)); \
__asm volatile ("ldp x8, x9, [sp], #16\n"); \
__asm volatile ("blr x12\n");

#define save() \
__asm volatile ( \ 
"stp x8, x9, [sp, #-16]!\n" \
"stp x6, x7, [sp, #-16]!\n" \
"stp x4, x5, [sp, #-16]!\n" \
"stp x2, x3, [sp, #-16]!\n" \
"stp x0, x1, [sp, #-16]!\n");

#define load() \
__asm volatile ( \
"ldp x0, x1, [sp], #16\n" \
"ldp x2, x3, [sp], #16\n" \
"ldp x4, x5, [sp], #16\n" \
"ldp x6, x7, [sp], #16\n" \
"ldp x8, x9, [sp], #16\n" );

__unused static id (*orig_objc_msgSend)(id, SEL, ...);

uintptr_t l_ptr_t[10000];
int cur = 0;
void pre_objc_msgSend(id self, SEL _cmd, uintptr_t lr) {
    @synchronized (delegate) {
        printf("pre action...\n");
      // 做一个简单对测试，输出 ObjC 方法名
        printf("\t%s\n", object_getClassName(self));
    //    printf("\t%s\n", _cmd);
        l_ptr_t[cur ++] = lr;
    }
}
 
uintptr_t post_objc_msgSend() {
    @synchronized (delegate) {
        printf("post action...\n");
        if (cur != 0) {
            cur --;
        }
        return l_ptr_t[cur];
    }
}

__attribute__((__naked__))
static void hook_Objc_msgSend() {
    // 记录上下文
    save()
    
    // 将 lr 传入 x2 用于 pre_objc_msgSend 传参
    __asm volatile ("mov x2, lr\n");

    // 调用 pre_objc_msgSend
    call(&pre_objc_msgSend)

    // 还原上下文
    load()
    
    // 调用 objc_msgSend 原方法
    call(orig_objc_msgSend)
//    call(objc_msgSend)
    
    // 记录上下文
    save()
    
    // 调用 post_objc_msgSend
    call(&post_objc_msgSend)
    
    // 还原 lr
    __asm volatile ("mov lr, x0\n");
    
    // 还原上下文
    load()
    
    // return
    __asm volatile ("ret\n");
}


// 启动Hook 入口
void hookStart() {
    static dispatch_once_t onceToken;
    orig_objc_msgSend = objc_msgSend;
    dispatch_once(&onceToken, ^{
        rebind_symbols((struct rebinding[6]){
            {
       "objc_msgSend",
       (void *)hook_Objc_msgSend,
       (void **)&orig_objc_msgSend
//                (void **)&objc_msgSend
      },
        }, 1);
          
    });
}

#endif
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
