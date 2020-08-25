//
//  UITableView+HSBAnalytics.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/10.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "UITableView+HSBAnalytics.h"
#import "NSObject+HSBSwizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "HSBAnalyticsManager.h"

@implementation UITableView (HSBAnalytics)

+ (void)load {
    [UITableView hsb_swizzleMethod:@selector(setDelegate:) withMethod:@selector(hsb_setDelegate:)];
}

- (void)hsb_setDelegate:(id<UITableViewDelegate>)delegate {
    // 调用原始的设置代理的方法
    [self hsb_setDelegate:delegate];
    // 交换 delegate 中的 tableView:didSelectRowAtIndexPath: 方法
    [self hsb_swizzleDidSelectRowAtIndexPathMethodWithDelegate:delegate];
}

static void hsb_tableViewDidSelectRow(id object, SEL selector, UITableView *tableView, NSIndexPath *indexPath) {
    SEL destinationSelector = NSSelectorFromString(@"hsb_tableView:didSelectRowAtIndexPath:");
    // 通过消息发送，调用原始的 tableView:didSelectRowAtIndexPath: 方法实现
    ((void (*)(id, SEL, id, id))objc_msgSend)(object, destinationSelector, tableView, indexPath);

    // TODO: 触发 $AppClick 事件
    [[HSBAnalyticsManager sharedManager] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

- (void)hsb_swizzleDidSelectRowAtIndexPathMethodWithDelegate:(id)delegate {
    // 获取 delegate 的类
    Class delegateClass = [delegate class];
    
    // 方法名
    SEL sourceSelector = @selector(tableView:didSelectRowAtIndexPath:);
    // 当 delegate 中没有实现 tableView:didSelectRowAtIndexPath: 方法时，直接返回
    if (![delegate respondsToSelector:sourceSelector]) {
        return;
    }

    SEL destinationSelector = NSSelectorFromString(@"hsb_tableView:didSelectRowAtIndexPath:");
    // 当 delegate 中已经存在了 hsb_tableView:didSelectRowAtIndexPath: 方法，那就说明已经进行过 swizzle 了，因此就可以直接返回，不再进行 swizzle
    if ([delegate respondsToSelector:destinationSelector]) {
        return;
    }

    Method sourceMethod = class_getInstanceMethod(delegateClass, sourceSelector);
    const char *encoding = method_getTypeEncoding(sourceMethod);
    // 当该类中已经存在了相同的方法时，会失败。但是前面已经判断过是否存在，因此，此处一定会添加成功。
    if (!class_addMethod([delegate class], destinationSelector, (IMP)hsb_tableViewDidSelectRow, encoding)) {
        NSLog(@"Add %@ to %@ error", NSStringFromSelector(sourceSelector), [delegate class]);
        return;
    }
    // 添加成功之后，进行方法交换
    [delegateClass hsb_swizzleMethod:sourceSelector withMethod:destinationSelector];
}

@end
