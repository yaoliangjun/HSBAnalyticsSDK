//
//  UISlider+HSBAnalytics.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/8.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "UISlider+HSBAnalytics.h"

@implementation UISlider (HSBAnalytics)

/** 获取控件文本 */
- (NSString *)elementContent {
    return [NSString stringWithFormat:@"%.2f", self.value];
}

@end
