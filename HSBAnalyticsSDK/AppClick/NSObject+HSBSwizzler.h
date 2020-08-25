//
//  NSObject+HSBSwizzler.h
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/7.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (HSBSwizzler)

/**
 交换方法名为originalSEL和方法名为targetSEL两个方法的实现
 originalSEL原始方法名
 targetSEL要交换的方法名称
*/
+ (BOOL)hsb_swizzleMethod:(SEL)originalSEL withMethod:(SEL)targetSEL;

@end

NS_ASSUME_NONNULL_END
