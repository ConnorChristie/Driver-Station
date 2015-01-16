//
//  JoystickViewController.m
//  Driver Station
//
//  Created by Connor on 3/28/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "JoystickViewController.h"

#import "AppDelegate.h"
#import "MainViewController.h"

#import <objc/message.h>

@interface JoystickViewController ()
{
    AppDelegate *delegate;
    
    int widthDiff;
    
    BOOL isVisible;
    BOOL didReadCamera;
    
    BOOL loaded;
    
    NSTimer *camTimer;
}

@end

@implementation JoystickViewController

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
    
    delegate = [[UIApplication sharedApplication] delegate];
    
    self.currentState = -1;
    self.cameraWebView.delegate = self;
    
    [self.button1 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button1 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button1 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button2 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button2 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button2 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button3 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button3 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button3 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button4 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button4 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button4 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button5 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button5 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button5 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button6 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button6 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button6 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    self.control.titleLabel.textColor = [UIColor grayColor];
    
    loaded = true;
}

- (void)viewWillAppear:(BOOL)animated
{
    ((MainViewController *) self.parentViewController).currentIndex = 1;
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
    
    if (loaded)
    {
        widthDiff = 568 - self.view.frame.size.width;
        
        delegate.width = self.view.frame.size.width;
        
        CGRect frame = self.cameraWebView.frame;
        
        frame.origin.x = (self.view.frame.size.width / 2) - (frame.size.width / 2);
        
        self.cameraWebView.frame = frame;
        
        /*
        int camHeight = frame.size.width * (1 + 1 / 3);
        
        frame.origin.x = (self.view.frame.size.width / 2) - (frame.size.width / 2);
        frame.size.height = camHeight;
        
        self.cameraWebView.frame = frame;
         */
        self.cameraWebView.hidden = true;
        
        NSArray *changeArr = @[[self.view viewWithTag:1],
                               [self.view viewWithTag:2],
                               [self.view viewWithTag:3],
                               [self.view viewWithTag:4],
                               [self.view viewWithTag:5],
                               [self.view viewWithTag:6],
                               [self.view viewWithTag:15],
                               [self.view viewWithTag:16],
                               [self.view viewWithTag:17],
                               [self.view viewWithTag:18]];
        
        for (UIView *view in changeArr)
        {
            frame = view.frame;
            
            if ([view class] == [UISegmentedControl class])
            {
                frame.size.width -= widthDiff;
            } else
            {
                frame.origin.x -= widthDiff / 2;
            }
            
            view.frame = frame;
        }
        
        loaded = false;
    }
    
    isVisible = true;
}

- (void)viewDidDisappear:(BOOL)animated
{
    isVisible = false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)joystickChanged:(id)sender
{
    UISegmentedControl *joy = (UISegmentedControl *)sender;
    
    if (joy.selectedSegmentIndex == 2)
    {
        [self.button1 setTitle:@"1" forState:UIControlStateNormal];
        [self.button3 setTitle:@"2" forState:UIControlStateNormal];
        [self.button5 setTitle:@"3" forState:UIControlStateNormal];
        
        [self.button2 setTitle:@"1" forState:UIControlStateNormal];
        [self.button4 setTitle:@"2" forState:UIControlStateNormal];
        [self.button6 setTitle:@"3" forState:UIControlStateNormal];
    } else if (joy.selectedSegmentIndex == 3)
    {
        //[((MainViewController *) self.parentViewController) blueJoystick:false];
        
        self.cameraWebView.hidden = false;
    } else
    {
        //[((MainViewController *) self.parentViewController) blueJoystick:false];
        
        self.cameraWebView.hidden = true;
        
        [self.button1 setTitle:@"1" forState:UIControlStateNormal];
        [self.button2 setTitle:@"2" forState:UIControlStateNormal];
        [self.button3 setTitle:@"3" forState:UIControlStateNormal];
        [self.button4 setTitle:@"4" forState:UIControlStateNormal];
        [self.button5 setTitle:@"5" forState:UIControlStateNormal];
        [self.button6 setTitle:@"6" forState:UIControlStateNormal];
    }
}

- (void)buttonHold:(id)sender
{
    //NSLog(@"Press: %li", (long)((UIButton *)sender).tag);
    
    switch (((UIButton *)sender).tag)
    {
        case 1:
            self.button1Sel = true; break;
        case 2:
            self.button2Sel = true; break;
        case 3:
            self.button3Sel = true; break;
        case 4:
            self.button4Sel = true; break;
        case 5:
            self.button5Sel = true; break;
        case 6:
            self.button6Sel = true; break;
    }
}

- (void)buttonRelease:(id)sender
{
    //NSLog(@"Release: %li", (long)((UIButton *)sender).tag);
    
    switch (((UIButton *)sender).tag)
    {
        case 1:
            self.button1Sel = false; break;
        case 2:
            self.button2Sel = false; break;
        case 3:
            self.button3Sel = false; break;
        case 4:
            self.button4Sel = false; break;
        case 5:
            self.button5Sel = false; break;
        case 6:
            self.button6Sel = false; break;
    }
}

- (void)update
{
    struct RobotDataPacket *fromData = [((MainViewController *) self.parentViewController) getInputPacket];
    
    self.battery.text = [NSString stringWithFormat:@"%.2X.%.2XV", fromData->batteryVolts, fromData->batteryMV];
    
    switch (delegate.state)
    {
        case RobotNotConnected:
            [self.control setTitle:@"Enable" forState:UIControlStateNormal];
            [self.control.titleLabel setTextColor:[UIColor grayColor]];
            [self.control setEnabled:false];
            
            break;
        case RobotWatchdogNotFed:
            [self.control setTitle:@"Disable" forState:UIControlStateNormal];
            [self.control.titleLabel setTextColor:[UIColor redColor]];
            [self.control setEnabled:true];
            
            break;
        case RobotDisabled:
            [self.control setTitle:@"Enable" forState:UIControlStateNormal];
            [self.control.titleLabel setTextColor:[UIColor colorWithRed:0 green:207 / 255.0f blue:65 / 255.0f alpha:1]];
            [self.control setEnabled:true];
            
            break;
        case RobotEnabled:
        case RobotAutonomous:
            [self.control setTitle:@"Disable" forState:UIControlStateNormal];
            [self.control.titleLabel setTextColor:[UIColor redColor]];
            [self.control setEnabled:true];
            
            break;
    }
    
    if (self.selectedJoystick.selectedSegmentIndex == 3 && !didReadCamera)
    {
        CGRect frame = self.cameraWebView.frame;
        
        NSString *htmlFile   = [[NSBundle mainBundle] pathForResource:@"mjpeg_viewer" ofType:@"html"];
        NSString *jqueryFile = [[NSBundle mainBundle] pathForResource:@"jquery-2.1.1.min.js" ofType:nil];
        
        NSString *htmlString   = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
        NSString *jqueryString = [NSString stringWithContentsOfFile:jqueryFile encoding:NSUTF8StringEncoding error:nil];
        
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{jquery}" withString:jqueryString];
        
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{te}" withString:[NSString stringWithFormat:@"%i", delegate.teamNumber / 100]];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{am}" withString:[NSString stringWithFormat:@"%i", delegate.teamNumber % 100]];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{width}" withString:[NSString stringWithFormat:@"%i", (int) frame.size.width]];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{height}" withString:[NSString stringWithFormat:@"%i", (int) frame.size.height]];
        
        NSLog(@"%f, %f", frame.size.width, frame.size.height);
        
        [self.cameraWebView loadHTMLString:htmlString baseURL:nil];
        
        NSLog(@"Reading camera");
        
        didReadCamera = true;
    }
}

- (IBAction)controlClick:(id)sender
{
    NSLog(@"State Changed");
    
    struct FRCCommonControlData *data = [((MainViewController *) self.parentViewController) getOutputPacket];
    
    if (delegate.state == RobotDisabled)
    {
        data->control += ENABLED_BIT;
    } else if (delegate.state == RobotEnabled || delegate.state == RobotWatchdogNotFed || delegate.state == RobotAutonomous)
    {
        data->control -= ENABLED_BIT;
    }
}

@end
