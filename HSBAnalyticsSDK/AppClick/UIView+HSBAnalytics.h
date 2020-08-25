//
//  UIView+HSBAnalytics.h
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/8.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (HSBAnalytics)

/** 获取控件类型 */
- (NSString *)elementType;

/** 获取控件文本 */
- (NSString *)elementContent;

/** 获取控件所属控制器 */
- (UIViewController *)elementViewController;

@end

NS_ASSUME_NONNULL_END
