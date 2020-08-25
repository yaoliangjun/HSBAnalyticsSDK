//
//  HSBAnalyticsManager.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/4.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "HSBAnalyticsManager.h"
#include <sys/sysctl.h>
#import "UIView+HSBAnalytics.h"
#import <AFNetworking/AFNetworking.h>
#import "HSBAnalyticsExceptionManager.h"
#import "HSBAnalyticsHttpManager.h"
#import "HSBAnalyticsDatabaseManager.h"

static NSString *const HSBAnalyticsVersion = @"1.0.0";
static NSString *const HSBAnalyticsEventBeginKey = @"event_begin";
static NSString *const HSBAnalyticsEventDurationKey = @"event_duration";
static NSString *const HSBAnalyticsEventIsPauseKey = @"is_pause";
static NSString *const HSBAnalyticsEventDidEnterBackgroundKey = @"did_enter_background";
// 默认上传事件条数
static NSUInteger const HSBAnalyticsDefalutFlushEventCount = 50;

@interface HSBAnalyticsManager ()

// 由SDK默认自动采集的事件属性即预置属性
@property (nonatomic, strong) NSDictionary<NSString *, id> *automaticProperties;
// 标记应用程序是否已收到UIApplicationWillResignActiveNotification本地通知
@property (nonatomic) BOOL applicationWillResignActive;
// 是否为被动启动
@property (nonatomic, getter=isLaunchedPassively) BOOL launchedPassively;
// 事件时长计算
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *trackTimerDict;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

// 保存进入后台时，未暂停的事件
@property (nonatomic, strong) NSMutableArray<NSString *> *enterBackgroundTrackTimerEvents;

/// 数据库存储对象
@property (nonatomic, strong) HSBAnalyticsDatabaseManager *database;

@property (nonatomic, strong) NSURL *serverURL;
/// 数据上传等网络请求对象
@property (nonatomic, strong) HSBAnalyticsHttpManager *network;
/// 定时上传事件的 Timer
@property (nonatomic, strong) NSTimer *flushTimer;

@end

@implementation HSBAnalyticsManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static HSBAnalyticsManager *sdk = nil;
    dispatch_once(&onceToken, ^{
        sdk = [[HSBAnalyticsManager alloc] init];
    });

    return sdk;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _automaticProperties = [self collectAutomaticProperties];
        // 设置是否被动启动标记
        _launchedPassively = UIApplication.sharedApplication.backgroundTimeRemaining != UIApplicationBackgroundFetchIntervalNever;
        _trackTimerDict = [NSMutableDictionary dictionary];
        _enterBackgroundTrackTimerEvents = [NSMutableArray array];
        _serialQueue = dispatch_queue_create("com.huishooubao.analytics.serial.queue", DISPATCH_QUEUE_SERIAL);
        // 添加应用程序状态监听
        [self setupListeners];
        // 调用异常处理单例对象，进行初始化
        [HSBAnalyticsExceptionManager sharedManager];
        
        // 初始化 HSBAnalyticsDatabase 类的对象，使用默认路径
        _database = [[HSBAnalyticsDatabaseManager alloc] init];
        _flushBulkSize = 100;
        _flushInterval = 60;
        _network = [[HSBAnalyticsHttpManager alloc] init];
        [self startFlushTimer];
    }
    return self;
}

- (void)track:(NSString *)eventName properties:(NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    // 设置事件名称
    event[@"event"] = eventName;
    // 设置事件发生的时间戳，单位为毫秒
    event[@"time"] = [NSNumber numberWithLong:NSDate.date.timeIntervalSince1970 * 1000];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary]; // 添加预置属性
    [eventProperties addEntriesFromDictionary:self.automaticProperties];
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties]; // 设置事件属性
    event[@"properties"] = eventProperties;
    // 判断是否为被动启动状态
    if (self.isLaunchedPassively) {
        // 添加应用程序状态属性
        eventProperties[@"$app_state"] = @"background";
    }
    
    dispatch_async(self.serialQueue, ^{
        [self printEvent:event];
        [self.database insertEvent:event];
    });

    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
}

#pragma mark - 点击
- (void)trackAppClickWithView:(UIView *)view properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    // 获取控件类型
    eventProperties[@"$element_type"] = [view elementType];
    // 获取控件显示文本
    eventProperties[@"$element_content"] = [view elementContent];
    // 获取控件所在的 UIViewController
    UIViewController *vc = [view elementViewController];
    // 设置页面相关属性
    eventProperties[@"$screen_name"] = NSStringFromClass(vc.class);

    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [self track:@"$AppClick" properties:eventProperties];
}

- (void)trackAppClickWithTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];

    // TODO: 获取用户点击的 UITableViewCell 控件对象
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // TODO: 设置被用户点击的 UITableViewCell 控件上的内容（$element_content）
    eventProperties[@"$element_content"] = [cell elementContent];
    // TODO: 设置被用户点击的 UITableViewCell 控件所在的位置（$element_position）
    eventProperties[@"$element_position"] = [NSString stringWithFormat:@"section:%ld, row:%ld", (long)indexPath.section, (long)indexPath.row];

    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [self trackAppClickWithView:tableView properties:eventProperties];
}

- (void)trackAppClickWithCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];

    // 获取用户点击的 UITableViewCell 控件对象
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    // 设置被用户点击的 UITableViewCell 控件上的内容（$element_content）
    eventProperties[@"$element_content"] = [cell elementContent];
    // 设置被用户点击的 UITableViewCell 控件所在的位置（$element_position）
    eventProperties[@"$element_position"] = [NSString stringWithFormat:@"section:%ld, row:%ld", (long)indexPath.section, (long)indexPath.row];

    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [self trackAppClickWithView:collectionView properties:eventProperties];
}

#pragma mark - 时间
- (void)trackTimerStart:(NSString *)event {
    // 记录事件开始时间 -> 记录事件开始时系统启动时间
    self.trackTimerDict[event] = @{ HSBAnalyticsEventBeginKey : @([HSBAnalyticsManager systemUpTime]) };
}

- (void)trackTimerPause:(NSString *)event {
    NSMutableDictionary *eventTimer = [self.trackTimerDict[event] mutableCopy];
    // 如果没有开始，直接返回
    if (!eventTimer) {
        return;
    }
    
    // 如果该事件时长统计已经暂停，直接返回，不做任何处理
    if ([eventTimer[HSBAnalyticsEventIsPauseKey] boolValue]) {
        return;
    }
    
    // 获取当前系统启动时间
    double systemUpTime = [HSBAnalyticsManager systemUpTime];
    // 获取开始时间
    double beginTime = [eventTimer[HSBAnalyticsEventBeginKey] doubleValue];
    // 计算暂停前统计的时长
    double duration = [eventTimer[HSBAnalyticsEventDurationKey] doubleValue] + systemUpTime - beginTime;
    eventTimer[HSBAnalyticsEventDurationKey] = @(duration);
    // 事件处于暂停状态
    eventTimer[HSBAnalyticsEventIsPauseKey] = @(YES);
    self.trackTimerDict[event] = eventTimer;
}

- (void)trackTimerResume:(NSString *)event {
    NSMutableDictionary *eventTimer = [self.trackTimerDict[event] mutableCopy];
    // 如果没有开始，直接返回
    if (!eventTimer) {
        return;
    }
    
    // 如果该事件时长统计没有暂停，直接返回，不做任何处理
    if (![eventTimer[HSBAnalyticsEventIsPauseKey] boolValue]) {
        return;
    }
    
    // 获取当前系统启动时间
    double systemUpTime = [HSBAnalyticsManager systemUpTime];
    // 重置事件开始时间
    eventTimer[HSBAnalyticsEventBeginKey] = @(systemUpTime);
    // 将事件暂停标记设置为 NO
    eventTimer[HSBAnalyticsEventIsPauseKey] = @(NO);
    self.trackTimerDict[event] = eventTimer;
}

- (void)trackTimerEnd:(NSString *)event properties:(NSDictionary *)properties {
    NSDictionary *eventTimer = self.trackTimerDict[event];
    if (!eventTimer) {
        return [self track:event properties:properties];
    }

    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:properties];
    // 移除
    [self.trackTimerDict removeObjectForKey:event];

    // 如果该事件时长统计没有暂停，直接返回，不做任何处理
    if ([eventTimer[HSBAnalyticsEventIsPauseKey] boolValue]) {
        // 获取事件时长
        double eventDuration = [eventTimer[HSBAnalyticsEventDurationKey] doubleValue];
        // 设置事件时长属性
        p[@"$event_duration"] = @([[NSString stringWithFormat:@"%.3f", eventDuration] floatValue]);
        
    } else {
        // 事件开始时间
        double beginTime = [(NSNumber *)eventTimer[HSBAnalyticsEventBeginKey] doubleValue];
        // 获取当前时间 -> 获取当前系统启动时间
        double currentTime = [HSBAnalyticsManager systemUpTime];
        // 计算事件时长
        double eventDuration = currentTime - beginTime + [eventTimer[HSBAnalyticsEventDurationKey] doubleValue];
        // 设置事件时长属性
        p[@"$event_duration"] = @([[NSString stringWithFormat:@"%.3f", eventDuration] floatValue]);
    }

    // 触发事件
    [self track:event properties:p];
}

+ (double)systemUpTime {
    return NSProcessInfo.processInfo.systemUptime * 1000;
}

#pragma mark - Application lifecycle
- (void)setupListeners {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // 注册监听UIApplicationDidEnterBackgroundNotification本地通知 // 即当应用程序进入后台后，调用通知方法
    [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    // 注册监听UIApplicationDidBecomeActiveNotification本地通知 // 即当应用程序进入前台并处于活动状态之后，调用通知方法
    [center addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    // 注册监听UIApplicationWillResignActiveNotification本地通知
    [center addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    // 注册监听UIApplicationDidFinishLaunchingNotification本地通知
    [center addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSLog(@"Application did enter background.");
    // 还原标记位
    self.applicationWillResignActive = NO;

    // 触发$AppEnd事件
//    [self track:@"$AppEnd" properties:nil];
    [self trackTimerEnd:@"$AppEnd" properties:nil];
    
    
    UIApplication *application = UIApplication.sharedApplication;
    // 初始化标识符
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    // 结束后台任务
    void (^endBackgroundTask)(void) = ^() {
        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    };
    // 标记长时间运行的后台任务
    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        endBackgroundTask();
    }];

    dispatch_async(self.serialQueue, ^{
        // 发送数据
        [self flushByEventCount:HSBAnalyticsDefalutFlushEventCount background:YES];
        // 结束后台任务
        endBackgroundTask();
    });
    
    // 暂停所有事件时长统计
    [self.trackTimerDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj[HSBAnalyticsEventIsPauseKey] boolValue]) {
            [self.enterBackgroundTrackTimerEvents addObject:key];
            [self trackTimerPause:key];
        }
    }];
    
    // 停止计时器
    [self stopFlushTimer];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"Application did become active.");
    // 还原标记位
    if (self.applicationWillResignActive) {
        self.applicationWillResignActive = NO;
        return;
    }

    // 将被动启动标记设为NO，正常记录事件
    self.launchedPassively = NO;

    // 触发$AppStart事件
    [self track:@"$AppStart" properties:nil];
    
    // 恢复所有事件时长统计
    for (NSString *event in self.enterBackgroundTrackTimerEvents) {
        [self trackTimerResume:event];
    }
    [self.enterBackgroundTrackTimerEvents removeAllObjects];
    
    // 开始$AppEnd事件计时
    [self trackTimerStart:@"$AppEnd"];
    
    // 开始计时器
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    // 标记已接收到UIApplicationWillResignActiveNotification本地通知
    self.applicationWillResignActive = YES;
    NSLog(@"Application will resign active.");
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // 当应用程序在后台运行时，触发被动启动事件
    if (self.isLaunchedPassively) {
        // 触发被动启动事件
        [self track:@"$AppStartPassively" properties:nil];
    }
    NSLog(@"Application did finish launching.");
}

#pragma mark - Flush
- (void)flush {
    dispatch_async(self.serialQueue, ^{
        // 默认一次向服务端发送 50 条数据
        [self flushByEventCount:HSBAnalyticsDefalutFlushEventCount background:NO];
    });
}

- (void)flushByEventCount:(NSUInteger)count background:(BOOL)background {
    #ifdef DEBUG
        
    #else
    if (background) {
        __block BOOL isContinue = YES;
        dispatch_sync(dispatch_get_main_queue(), ^{
            // 当运行时间大于于请求的超时时间时，为保证数据库删除时应用不被强杀，不再继续上传
            isContinue = UIApplication.sharedApplication.backgroundTimeRemaining >= 30;
        });
        if (!isContinue) {
            return;
        }
    }
    #endif

    // 获取本地数据
    NSArray<NSString *> *events = [self.database selectEventsForCount:count];
    // 当本地存储的数据为 0 或者上传失败时，直接返回，退出递归调用
    if (events.count == 0 || ![self.network flushEvents:events]) {
        return;
    }
    
    // 当删除数据失败时，直接返回退出递归调用，防止死循环
    if (![self.database deleteEventsForCount:count]) {
        return;
    }

    // 继续上传本地的其他数据
    [self flushByEventCount:count background:background];
}

#pragma mark - FlushTimer

/// 开启上传数据的定时器
- (void)startFlushTimer {
    if (self.flushTimer) {
        return;
    }
    NSTimeInterval interval = self.flushInterval < 5 ? 5 : self.flushInterval;
    self.flushTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(flush) userInfo:nil repeats:YES];
    [NSRunLoop.currentRunLoop addTimer:self.flushTimer forMode:NSRunLoopCommonModes];
}

// 停止上传数据的定时器
- (void)stopFlushTimer {
    [self.flushTimer invalidate];
    self.flushTimer = nil;
}

#pragma mark - Properties
- (NSDictionary<NSString *, id> *)collectAutomaticProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary]; //操作系统类型

    properties[@"$os"] = @"iOS";
    // SDK平台类型
    properties[@"$lib"] = @"iOS";                      //设备制造商
    properties[@"$manufacturer"] = @"Apple";           //SDK版本号
    properties[@"$lib_version"] = HSBAnalyticsVersion; //手机型号
    properties[@"$model"] = [self deviceModel];        //操作系统版本号
    properties[@"$os_version"] = [UIDevice currentDevice].systemVersion;
    //应用程序版本号
    properties[@"$app_version"] = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    return [properties copy];
}

- (void)setFlushInterval:(NSUInteger)flushInterval {
    if (_flushInterval != flushInterval) {
        _flushInterval = flushInterval;
        // 上传本地所有事件数据
        [self flush];
        // 先暂停计时器
        [self stopFlushTimer];
        // 重新开启定时器
        [self startFlushTimer];
    }
}

/// 获取手机型号
- (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}

- (void)printEvent:(NSDictionary *)event {
#if DEBUG
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"JSON Serialized Error: %@", error);
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[Event]: %@", json);
#endif
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
