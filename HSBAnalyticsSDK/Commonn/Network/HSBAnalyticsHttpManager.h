//
//  HSBAnalyticsHttpManager.h
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/24.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBAnalyticsHttpManager : NSObject

/**
同步发送事件数据

@param events JSON 格式的
@return 初始化对象
*/
- (BOOL)flushEvents:(NSArray<NSString *> *)events;

@end

NS_ASSUME_NONNULL_END
