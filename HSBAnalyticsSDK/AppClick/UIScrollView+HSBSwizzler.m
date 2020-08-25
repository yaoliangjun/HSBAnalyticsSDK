//
//  UIScrollView+HSBSwizzler.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/10.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "UIScrollView+HSBSwizzler.h"
#import <objc/runtime.h>
#import "HSBAnalyticsDelegateProxy.h"

@implementation UIScrollView (HSBSwizzler)

- (void)setHsb_delegateProxy:(HSBAnalyticsDelegateProxy *)hsb_delegateProxy {
    objc_setAssociatedObject(self, @selector(setHsb_delegateProxy:), hsb_delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (HSBAnalyticsDelegateProxy *)hsb_delegateProxy {
    return objc_getAssociatedObject(self, @selector(hsb_delegateProxy));
}

@end
