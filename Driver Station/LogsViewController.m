//
//  LogsViewController.m
//  Driver Station
//
//  Created by Connor on 5/16/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "LogsViewController.h"

#import "MainViewController.h"

#import <objc/message.h>

@interface LogsViewController ()

@end

@implementation LogsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    ((MainViewController *) self.parentViewController).currentIndex = 3;
}

- (void)viewDidAppear:(BOOL)animated
{
    UIDeviceOrientation before = [[UIDevice currentDevice] orientation];
    
    if (UIInterfaceOrientationIsLandscape(before))
    {
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), UIInterfaceOrientationPortraitUpsideDown);
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), before);
    } else
    {
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), UIInterfaceOrientationLandscapeRight);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
