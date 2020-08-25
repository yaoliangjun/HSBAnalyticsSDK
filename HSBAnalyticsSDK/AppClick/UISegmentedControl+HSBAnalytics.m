//
//  UISegmentedControl+HSBAnalytics.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/8.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "UISegmentedControl+HSBAnalytics.h"

@implementation UISegmentedControl (HSBAnalytics)

/** 获取控件文本 */
- (NSString *)elementContent {
    return [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

@end
