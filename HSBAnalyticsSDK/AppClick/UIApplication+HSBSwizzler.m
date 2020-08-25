//
//  UIApplication+HSBSwizzler.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/8.
//  Copyright © 2020 huishoubao. All rights reserved.
//  控件点击事件

#import "UIApplication+HSBSwizzler.h"
#import "HSBAnalyticsManager.h"
#import "NSObject+HSBSwizzler.h"
#import "UIView+HSBAnalytics.h"

@implementation UIApplication (HSBSwizzler)

+ (void)load {
    [UIApplication hsb_swizzleMethod:@selector(sendAction:to:from:forEvent:) withMethod:@selector(hsb_sendAction:to:from:forEvent:)];
}

- (BOOL)hsb_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    if ([sender isKindOfClass:UISwitch.class] ||
        [sender isKindOfClass:UISegmentedControl.class] ||
        [sender isKindOfClass:UIStepper.class] ||
        event.allTouches.anyObject.phase == UITouchPhaseEnded) {
        // 触发 $AppClick 事件
        [[HSBAnalyticsManager sharedManager] trackAppClickWithView:sender properties:nil];
    }
    
    // 调用原有实现，即sendAction:to:from:forEvent:方法
    return [self hsb_sendAction:action to:target from:sender forEvent:event];
}

@end
