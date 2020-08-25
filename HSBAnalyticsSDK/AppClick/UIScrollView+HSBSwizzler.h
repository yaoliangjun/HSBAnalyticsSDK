//
//  UIScrollView+HSBSwizzler.h
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/10.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HSBAnalyticsDelegateProxy;

@interface UIScrollView (HSBSwizzler)

@property (nonatomic, strong) HSBAnalyticsDelegateProxy *hsb_delegateProxy;


@end

NS_ASSUME_NONNULL_END
