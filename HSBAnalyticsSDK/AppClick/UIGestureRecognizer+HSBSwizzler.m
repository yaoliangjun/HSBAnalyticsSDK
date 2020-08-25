//
//  UIGestureRecognizer+HSBSwizzler.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/11.
//  Copyright © 2020 huishoubao. All rights reserved.
//  手势事件

#import "UIGestureRecognizer+HSBSwizzler.h"
#import "HSBAnalyticsManager.h"
#import "NSObject+HSBSwizzler.h"

@implementation UIGestureRecognizer (HSBSwizzler)

+ (void)load {
    // Swizzle initWithTarget:action: 方法
    [UIGestureRecognizer hsb_swizzleMethod:@selector(initWithTarget:action:) withMethod:@selector(hsb_initWithTarget:action:)];
    // Swizzle addTarget:action: 方法
    [UIGestureRecognizer hsb_swizzleMethod:@selector(addTarget:action:) withMethod:@selector(hsb_addTarget:action:)];
}

- (instancetype)hsb_initWithTarget:(id)target action:(SEL)action {
    // 调用原始的初始化方法进行对象初始化
    [self hsb_initWithTarget:target action:action];
    // 调用添加 Target-Action 方法，添加埋点的 Target-Action
    // 这里其实调用的是 hsb_addTarget:action: 里的实现方法，因为已经进行了 swizzle
    [self addTarget:target action:action];
    return self;
}

- (void)hsb_addTarget:(id)target action:(SEL)action {
    if ([self respondsToSelector:@selector(hsb_addTarget:action:)]) {
        // 调用原始的方法，添加 Target-Action
        [self hsb_addTarget:target action:action];
        // 新增 Target-Action，用于埋点
        [self hsb_addTarget:self action:@selector(hsb_trackGestureAction:)];
    }
}

- (void)hsb_trackGestureAction:(id)sender {
    // 子类实现该方法做自定义采集功能
}

- (void)trackWithView:(UIView *)view {
    // 暂定只采集 UILabel 和 UIImageView
    BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
    if (!isTrackClass) {
        return;
    }
    
    // $AppClick 事件的属性，这里只需要设置 $element_type，其他的事件属性在 trackAppClickWithView:properties: 中可自动获取
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[@"$element_type"] = NSStringFromClass(self.class);
    
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        properties[@"$element_content"] = label.text ?: @"";
    }
    
    // 触发 $AppClick 事件
    [[HSBAnalyticsManager sharedManager] trackAppClickWithView:view properties:properties];
}

@end

@implementation UITapGestureRecognizer (HSBSwizzler)

- (void)hsb_trackGestureAction:(id)sender {
    // 获取手势识别器的控件
    UIView *view = ((UITapGestureRecognizer *)sender).view;
    [self trackWithView:view];
}

@end

@implementation UILongPressGestureRecognizer (HSBSwizzler)

- (void)hsb_trackGestureAction:(id)sender {
    UILongPressGestureRecognizer *longPressSender = (UILongPressGestureRecognizer *)sender;
    if (longPressSender.state != UIGestureRecognizerStateEnded) {
        return;
    }

    // 获取手势识别器的控件
    UIView *view = longPressSender.view;
    [self trackWithView:view];
}

@end

