//
//  UICollectionView+HSBSwizzler.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/10.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "UICollectionView+HSBSwizzler.h"
#import "HSBAnalyticsDelegateProxy.h"
#import "NSObject+HSBSwizzler.h"
#import "UIScrollView+HSBSwizzler.h"

@implementation UICollectionView (HSBSwizzler)

+ (void)load {
    [UICollectionView hsb_swizzleMethod:@selector(setDelegate:) withMethod:@selector(hsb_setDelegate:)];
}

- (void)hsb_setDelegate:(id<UICollectionViewDelegate>)delegate {
    self.hsb_delegateProxy = nil;
    if (delegate) {
        HSBAnalyticsDelegateProxy *proxy = [HSBAnalyticsDelegateProxy proxyWithCollectionViewDelegate:delegate];
        self.hsb_delegateProxy = proxy;
        [self hsb_setDelegate:proxy];
    } else {
        [self hsb_setDelegate:nil];
    }
}

@end
