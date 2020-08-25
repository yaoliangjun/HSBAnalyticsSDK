//
//  HSBAnalyticsDelegateProxy.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/10.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "HSBAnalyticsDelegateProxy.h"
#import "HSBAnalyticsManager.h"

@interface HSBAnalyticsDelegateProxy ()

// 保存 delegate 对象
@property (nonatomic, weak) id delegate;

@end

@implementation HSBAnalyticsDelegateProxy


+ (instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate {
    HSBAnalyticsDelegateProxy *proxy = [HSBAnalyticsDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

+ (instancetype)proxyWithCollectionViewDelegate:(id<UICollectionViewDelegate>)delegate {
    HSBAnalyticsDelegateProxy *proxy = [HSBAnalyticsDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    // 返回 delegate 对象中对应的方法签名
    return [(NSObject *)self.delegate methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // 先执行 delegate 对象中的方法
    [invocation invokeWithTarget:self.delegate];
    // 判断是否是 cell 的点击事件的代理方法
    if (invocation.selector == @selector(tableView:didSelectRowAtIndexPath:)) {
        // 将方法名修改为进行数据采集的方法，即本类中的实例方法：hsb_tableView:didSelectRowAtIndexPath:
        invocation.selector = NSSelectorFromString(@"hsb_tableView:didSelectRowAtIndexPath:");
        // 执行数据采集相关的方法
        [invocation invokeWithTarget:self];
    } else if (invocation.selector == @selector(collectionView:didSelectItemAtIndexPath:)) {
        // 将方法名修改为进行数据采集的方法，即本类中的实例方法：hsb_collectionView:didSelectRowAtIndexPath:
        invocation.selector = NSSelectorFromString(@"hsb_collectionView:didSelectItemAtIndexPath:");
        // 执行数据采集相关的方法
        [invocation invokeWithTarget:self];
    }
}

- (void)hsb_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[HSBAnalyticsManager sharedManager] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

- (void)hsb_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [[HSBAnalyticsManager sharedManager] trackAppClickWithCollectionView:collectionView didSelectItemAtIndexPath:indexPath properties:nil];
}

@end
