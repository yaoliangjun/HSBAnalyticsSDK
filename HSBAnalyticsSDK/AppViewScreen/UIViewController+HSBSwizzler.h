//
//  UIViewController+HSBSwizzler.h
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/7.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (HSBSwizzler)

- (void)hsb_viewDidAppear:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
