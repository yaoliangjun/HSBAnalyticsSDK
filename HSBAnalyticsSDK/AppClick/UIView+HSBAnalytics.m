//
//  UIView+HSBAnalytics.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/8.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "UIView+HSBAnalytics.h"

@implementation UIView (HSBAnalytics)

/** 获取控件类型 */
- (NSString *)elementType {
    return NSStringFromClass([self class]);
}

- (NSString *)elementContent {
    // 如果是隐藏控件，则不获取控件内容
    if (self.isHidden) {
        return nil;
    }
    
    // 初始化数组，用于保存子控件的内容
    NSMutableArray *contents = [NSMutableArray array];
    for (UIView *view in self.subviews) {
        // 获取子控件的内容
        // 如果子类有内容，例如：UILabel 的 text，获取到的就是 text 属性；
        // 如果没有就递归调用此方法，获取其子控件的内容。
        NSString *content = [view elementContent];
        if (content.length) {
            // 当该子控件中有内容时，保存在数组中
            [contents addObject:content];
        }
    }
    
    // 当未获取到子控件内容时返回 accessibilityLabel。如果获取到多个子控件内容时，使用 - 拼接
    return contents.count == 0 ? self.accessibilityLabel : [contents componentsJoinedByString:@"-"];
}

- (UIViewController *)elementViewController {
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass: [UIViewController class]]){
            return (UIViewController *)responder;
        }
    }
    // 如果没有找到则返回 nil
    return nil;
}

@end
