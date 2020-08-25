//
//  UISwitch+HSBAnalytics.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/8.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "UISwitch+HSBAnalytics.h"

@implementation UISwitch (HSBAnalytics)

/** 获取控件文本 */
- (NSString *)elementContent {
    return self.on ? @"checked" : @"unchecked";
}

@end
