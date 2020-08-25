//
//  ViewController.m
//  HSBAnalyticsDemo
//
//  Created by Jerry Yao on 2020/8/4.
//  Copyright © 2020 huishoubao. All rights reserved.
//

#import "ViewController.h"
#import <HSBAnalyticsSDK/HSBAnalyticsSDK.h>

static NSString * const kViewControllerTrackTimer = @"kViewControllerTrackTimer";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *tapLabel;
@property (weak, nonatomic) IBOutlet UILabel *longPressLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timg.jpeg"]];
    imageView.userInteractionEnabled = YES;
    imageView.frame = CGRectMake(50, 50, 100, 100);
    [self.view addSubview:imageView];
    
    UIControl *control = [[UIControl alloc] init];
    [control addTarget:self action:@selector(avatarImageClick) forControlEvents:UIControlEventTouchUpInside];
    control.frame = imageView.bounds;
    [imageView addSubview:control];
    
    
    // 手势
    self.tapLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerHandler)];
    [self.tapLabel addGestureRecognizer:tapGestureRecognizer];
    
    self.longPressLabel.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerHandler)];
    [self.longPressLabel addGestureRecognizer:longPressGestureRecognizer];
}

- (void)tapGestureRecognizerHandler {
    NSLog(@"tapGestureRecognizerHandler");
}

- (void)longPressGestureRecognizerHandler {
    NSLog(@"longPressGestureRecognizerHandler");
}

- (void)avatarImageClick {
    NSLog(@"avatarImageClick");
}

- (IBAction)btnClick:(id)sender {
    
}

- (IBAction)switchClick:(id)sender {
    
}

- (IBAction)sliderValueChanged:(id)sender {
    
}

- (IBAction)segmentControlClick:(id)sender {
    
}

- (IBAction)stepperClick:(id)sender {
    
}

#pragma mark - Timer
- (IBAction)trackTimerStart:(id)sender {
    [[HSBAnalyticsManager sharedManager] trackTimerStart:kViewControllerTrackTimer];
}

- (IBAction)trackTimerEnd:(id)sender {
    [[HSBAnalyticsManager sharedManager] trackTimerEnd:kViewControllerTrackTimer properties:nil];
}

- (IBAction)trackTimerPause:(id)sender {
    [[HSBAnalyticsManager sharedManager] trackTimerPause:kViewControllerTrackTimer];
}

- (IBAction)trackTimerResume:(id)sender {
    [[HSBAnalyticsManager sharedManager] trackTimerResume:kViewControllerTrackTimer];
}

- (IBAction)btnCrashClick:(id)sender {
    NSArray *array = @[@"first", @"second"];
    NSLog(@"%@", array[2]);
}

@end
