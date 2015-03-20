//
//  MainVC.m
//  BLE-HRM-iOS-Demo
//
//  Created by Alexander Gorbunov on 20/03/15.
//  Copyright (c) 2015 Noveo. All rights reserved.
//


#import "MainVC.h"
#import "BLEHRMController.h"
#import "KVCUtils.h"


static void *const kvoContext = (void *)&kvoContext;
static NSInteger const heartAnimationFPS = 20;
static NSTimeInterval const animationDurationForward = 0.3;
static NSTimeInterval const animationDurationBackward = 0.1;


@interface MainVC ()
@property (nonatomic) BLEHRMController *hrmController;
@property (nonatomic) IBOutlet UILabel *hrValueLabel;
@property (nonatomic) IBOutlet UILabel *heartLabel;
@property (nonatomic) NSInteger skippedFrames;
@property (nonatomic) NSTimer *heartTimer;
@end


@implementation MainVC

#pragma mark - VC lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _hrmController = [[BLEHRMController alloc] init];
        [_hrmController addObserver:self forKeyPath:STR_PROP(heartRate)
            options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
            context:kvoContext];
    }
    return self;
}

- (void)dealloc
{
    [_hrmController removeObserver:self forKeyPath:STR_PROP(heartRate) context:kvoContext];
    [_heartTimer invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.heartLabel.alpha = 0;
    self.heartLabel.text = @"❤\U0000FE0E";
    
    [self refreshHRValueLabel];
    
    self.heartTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/heartAnimationFPS target:self
        selector:@selector(heartAnimationTick:) userInfo:nil repeats:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Private methods

- (void)heartAnimationTick:(NSTimer *)sender
{
    NSInteger bpmHeartRate = self.hrmController.heartRate;

    // HR value is not available, no animation needed.
    if (bpmHeartRate < 0) {
        return;
    }
    
    float bpsHeartRate = (float)bpmHeartRate / 60.0f;
    NSInteger framesToSkip =  heartAnimationFPS / bpsHeartRate;
    
    // Wait for animation.
    if (self.skippedFrames < framesToSkip) {
        self.skippedFrames += 1;
    }
    
    // Time to start heart animation.
    else {
        self.skippedFrames = 0;
        [self animateHeart];
    }
}

- (void)animateHeart
{
    self.heartLabel.transform = CGAffineTransformMakeScale(0, 0);
    self.heartLabel.alpha = 1;
    [UIView animateWithDuration:animationDurationForward delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5
        options:0 animations:^{
            self.heartLabel.transform = CGAffineTransformMakeScale(1, 1);
        }
        completion:^(BOOL finished) {
            [UIView animateWithDuration:animationDurationBackward animations:^{
                    self.heartLabel.alpha = 0;
                }];
        }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
    context:(void *)context
{
    // It's not our notification.
    if (context != kvoContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    // Check if we've got notification from HRM.
    if (object == self.hrmController) {
        [self refreshHRValueLabel];
    }
}

- (void)refreshHRValueLabel
{
    // Show a hint when no value available.
    if (self.hrmController.heartRate < 0) {
        self.hrValueLabel.text = NSLocalizedString(@"NoHRValueHint",);
    }
    
    // Normal case, show HR value.
    else {
        self.hrValueLabel.text = [NSString stringWithFormat:@"%ld", (long)self.hrmController.heartRate];
    }
}

@end
