//
//  UIViewController+HSBSwizzler.m
//  HSBAnalyticsSDK
//
//  Created by Jerry Yao on 2020/8/7.
//  Copyright © 2020 huishoubao. All rights reserved.
//  页面浏览事件

#import "UIViewController+HSBSwizzler.h"
#import "HSBAnalyticsManager.h"
#import "NSObject+HSBSwizzler.h"

@implementation UIViewController (HSBSwizzler)

// 附加设置
// SDK工程的Build Settings -> other linker flags —> -ObjC
// DEMO工程的Build Settings -> other linker flags —>  -all_load
// 设置好以上两个地方，SDK的分类方法才会被加载
+ (void)load {
    [UIViewController hsb_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(hsb_viewDidAppear:)];
}

- (void)hsb_viewDidAppear:(BOOL)animated {
    // 调用原始方法，即viewDidAppear:
    [self hsb_viewDidAppear:animated];

    if ([self shouldTrackAppViewScreen]) {
        // 触发$AppViewScreen事件
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        [properties setValue:NSStringFromClass([self class]) forKey:@"$screen_name"];
        //        navigationItem.titleView的优先级高于navigationItem.title
        NSString *title = [self contentFromView:self.navigationItem.titleView];
        if (!title.length) {
            title = self.navigationItem.title;
        }
        [properties setValue:(title.length ? title : @"") forKey:@"$title"];
        [[HSBAnalyticsManager sharedManager] track:@"$AppViewScreen" properties:properties];
    }
}

- (BOOL)shouldTrackAppViewScreen {
    BOOL shouldTrack = YES;
    NSArray *blacklist = @[ @"UIInputWindowController" ];
    for (NSString *black in blacklist) {
        if ([NSStringFromClass([self class]) isEqualToString:black]) {
            shouldTrack = NO;
            break;
        }
    }
    return shouldTrack;
}

- (NSString *)contentFromView:(UIView *)rootView {
    if (rootView.isHidden) {
        return nil;
    }

    NSMutableString *elementContent = [NSMutableString string];

    if ([rootView isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)rootView;
        NSString *title = button.titleLabel.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }

    } else if ([rootView isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)rootView;
        NSString *title = label.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }

    } else if ([rootView isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)rootView;
        NSString *title = textView.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }

    } else {
        NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
        for (UIView *subview in rootView.subviews) {
            NSString *temp = [self contentFromView:subview];
            if (temp.length > 0) {
                [elementContentArray addObject:temp];
            }
        }

        if (elementContentArray.count > 0) {
            [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
        }
    }

    return [elementContent copy];
}

@end


