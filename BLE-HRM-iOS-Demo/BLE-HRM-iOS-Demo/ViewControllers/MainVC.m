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


@interface MainVC ()
@property (nonatomic) BLEHRMController *hrmController;
@property (nonatomic) IBOutlet UILabel *hrValueLabel;
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refreshHRValueLabel];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Private methods

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
