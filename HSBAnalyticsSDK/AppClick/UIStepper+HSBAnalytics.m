//
//  UIStepper+HSBAnalytics.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/8.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "UIStepper+HSBAnalytics.h"

@implementation UIStepper (HSBAnalytics)

/** 获取控件文本 */
- (NSString *)elementContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end
