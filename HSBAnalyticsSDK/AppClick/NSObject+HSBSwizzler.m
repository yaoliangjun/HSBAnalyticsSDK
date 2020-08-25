//
//  NSObject+HSBSwizzler.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/7.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "NSObject+HSBSwizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (HSBSwizzler)

/**
 交换方法名为originalSEL和方法名为targetSEL两个方法的实现
 originalSEL原始方法名
 targetSEL要交换的方法名称
*/
+ (BOOL)hsb_swizzleMethod:(SEL)originalSEL withMethod:(SEL)targetSEL {
    // 获取原始方法
    Method originalMethod = class_getInstanceMethod(self, originalSEL);
    // 当原始方法不存在时，返回NO，表示Swizzling失败
    if (!originalMethod) {
        return NO;
    }
    
    // 获取要交换的方法
    Method targetMethod = class_getInstanceMethod(self, targetSEL);
    // 当需要交换的方法不存在时，返回NO，表示Swizzling失败
    if (!targetMethod) {
        return NO;
    }
    
    // 交换两个方法的实现
    method_exchangeImplementations(originalMethod, targetMethod);
    // 返回YES，表示Swizzling成功
    return YES;
}

@end
