//
//  IOViewController.m
//  Driver Station
//
//  Created by Connor on 4/11/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "IOViewController.h"

#import "MainViewController.h"

#import <objc/message.h>

@interface IOViewController ()
{
    int widthDiff;
}

@end

@implementation IOViewController

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
    ((MainViewController *) self.parentViewController).currentIndex = 2;
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
    
    widthDiff = 568 - self.view.frame.size.width;
    
    NSArray *changeArr = @[[self.view viewWithTag:1],
                           [self.view viewWithTag:2],
                           [self.view viewWithTag:3],
                           [self.view viewWithTag:4],
                           
                           [self.view viewWithTag:11],
                           [self.view viewWithTag:12],
                           [self.view viewWithTag:13],
                           [self.view viewWithTag:14],
                           
                           [self.view viewWithTag:21],
                           [self.view viewWithTag:22],
                           [self.view viewWithTag:23],
                           [self.view viewWithTag:24],
                           
                           [self.view viewWithTag:99],
                           [self.view viewWithTag:98],
                           [self.view viewWithTag:97],
                           [self.view viewWithTag:96]];
    
    for (UIView *view in changeArr)
    {
        CGRect frame = view.frame;
        
        if ([view class] == [UISlider class])
        {
            frame.size.width -= widthDiff;
        } else
        {
            frame.origin.x -= widthDiff;
        }
        
        view.frame = frame;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)analogChanged:(id)sender
{
    UILabel *label = (UILabel *)[self.view viewWithTag:(100 - ((UISlider *) sender).tag)];
    
    [label setText:[NSString stringWithFormat:@"%i", (int)((UISlider *) sender).value]];
    
    switch (((UISlider *) sender).tag)
    {
        case 1:
            ((MainViewController *) self.parentViewController).analog1 = (int)((UISlider *) sender).value; break;
        case 2:
            ((MainViewController *) self.parentViewController).analog2 = (int)((UISlider *) sender).value; break;
        case 3:
            ((MainViewController *) self.parentViewController).analog3 = (int)((UISlider *) sender).value; break;
        case 4:
            ((MainViewController *) self.parentViewController).analog4 = (int)((UISlider *) sender).value; break;
    }
}

@end
