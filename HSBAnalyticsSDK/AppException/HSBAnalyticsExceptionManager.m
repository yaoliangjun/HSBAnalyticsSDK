//
//  HSBAnalyticsExceptionManager.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/19.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "HSBAnalyticsExceptionManager.h"
#import "HSBAnalyticsManager.h"

static NSString *const HSBSignalExceptionHandlerName = @"SignalExceptionHandler";
static NSString *const HSBSignalExceptionHandlerUserInfo = @"SignalExceptionHandlerUserInfo";

@interface HSBAnalyticsExceptionManager ()

@property (nonatomic) NSUncaughtExceptionHandler *previousExceptionHandler;

@end

@implementation HSBAnalyticsExceptionManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static HSBAnalyticsExceptionManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HSBAnalyticsExceptionManager alloc] init];
    });

    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _previousExceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&hsb_uncaught_exception_handler);

        // 定义信号集结构体
        struct sigaction sig;
        // 将信号集初始化为空
        sigemptyset(&sig.sa_mask);
        // 在回调函数中传入 __siginfo 参数
        sig.sa_flags = SA_SIGINFO;
        // 设置信号集回调处理函数
        sig.sa_sigaction = &hsb_signal_exception_handler;
        // 定义需要采集的信号类型
        int signals[] = {SIGILL, SIGABRT, SIGBUS, SIGFPE, SIGSEGV};
        for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
            // 注册信号回调
            int err = sigaction(signals[i], &sig, NULL);
            if (err) {
                NSLog(@"Errored while trying to set up sigaction for signal %d", signals[i]);
            }
        }
    }
    return self;
}

static void hsb_uncaught_exception_handler(NSException *exception) {
    // 采集$AppCrashed事件
    [[HSBAnalyticsExceptionManager sharedManager] trackAppCrashedWithException:exception];
    NSUncaughtExceptionHandler *handle = [HSBAnalyticsExceptionManager sharedManager].previousExceptionHandler;
    if (handle) {
        handle(exception);
    }
}

static void hsb_signal_exception_handler(int sig, struct __siginfo *info, void *context) {
    NSDictionary *userInfo = @{ HSBSignalExceptionHandlerUserInfo : @(sig) };
    NSString *reason = [NSString stringWithFormat:@"Signal %d was raised.", sig];
    // 创建一个异常对象，用于采集崩溃信息数据
    NSException *exception = [NSException exceptionWithName:HSBSignalExceptionHandlerName reason:reason userInfo:userInfo];

    HSBAnalyticsExceptionManager *handler = [HSBAnalyticsExceptionManager sharedManager];
    [handler trackAppCrashedWithException:exception];
}

- (void)trackAppCrashedWithException:(NSException *)exception {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 异常名称
    NSString *name = [exception name];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常的堆栈信息
    NSArray *stacks = [exception callStackSymbols] ?: [NSThread callStackSymbols];
    // 将异常信息组装
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception name：%@\nException reason：%@\nException stack：%@", name, reason, stacks];
    // 设置 $AppCrashed 的事件属性 $app_crashed_reason
    properties[@"$app_crashed_reason "] = exceptionInfo;

//#ifdef DEBUG
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:exceptionInfo forKey:@"hsb_app_crashed_reason"];
//    [defaults synchronize];
//#endif

    [[HSBAnalyticsManager sharedManager] track:@"$AppCrashed" properties:properties];

    // 采集 $AppEnd 回调 block
    dispatch_block_t trackAppEndBlock = ^{
        // 判断应用是否处于运行状态
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            // 触发事件
            [[HSBAnalyticsManager sharedManager] track:@"$AppEnd" properties:nil];
        }
    };

    // 获取主线程
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // 判断当前线程是否为主线程
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(mainQueue)) == 0) {
        // 如果当前线程是主线程，直接调用 block
        trackAppEndBlock();
    } else {
        // 如果当前线程不是主线程，则同步调用 block
        dispatch_sync(mainQueue, trackAppEndBlock);
    }

    // 获取 HSBAnalyticsSDK 中的 serialQueue
    dispatch_queue_t serialQueue = [[HSBAnalyticsManager sharedManager] valueForKeyPath:@"serialQueue"];
    if (serialQueue) {
        // 阻塞当前线程，让 serialQueue 执行完成
        dispatch_sync(serialQueue, ^{});
    }
    
    // 获取数据存储时的线程
    dispatch_queue_t databaseQueue = [[HSBAnalyticsManager sharedManager] valueForKeyPath:@"database.queue"];
    if (databaseQueue) {
        // 阻塞当前线程，让 $AppCrashed 及 $AppEnd 事件完成入库
        dispatch_sync(databaseQueue, ^{});
    }

    NSSetUncaughtExceptionHandler(NULL);

    int signals[] = {SIGILL, SIGABRT, SIGBUS, SIGFPE, SIGSEGV};
    for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
        signal(signals[i], SIG_DFL);
    }
}
                           
@end
