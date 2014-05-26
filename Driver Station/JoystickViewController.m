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

static short ENABLED_BIT = 0x20;

@interface JoystickViewController ()
{
    AppDelegate *delegate;
    
    int widthDiff;
    
    BOOL isVisible;
    BOOL stopCamera;
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
        
        int camWidth = frame.size.height * (1 + 1 / 3);
        
        frame.origin.x = (self.view.frame.size.width / 2) - (camWidth / 2);
        frame.size.width = camWidth;
        
        self.cameraWebView.frame = frame;
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
        [((MainViewController *) self.parentViewController) blueJoystick:true];
        
        self.cameraWebView.hidden = true;
        
        stopCamera = false;
    } else if (joy.selectedSegmentIndex == 3)
    {
        [((MainViewController *) self.parentViewController) blueJoystick:false];
        
        self.cameraWebView.hidden = false;
    } else
    {
        [((MainViewController *) self.parentViewController) blueJoystick:false];
        
        self.cameraWebView.hidden = true;
        
        stopCamera = false;
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
            self.control.titleLabel.text = @"Enable";
            self.control.titleLabel.textColor = [UIColor grayColor];
            self.control.enabled = false;
            
            break;
        case RobotWatchdogNotFed:
            self.control.titleLabel.text = @"Disable";
            self.control.titleLabel.textColor = [UIColor redColor];
            self.control.enabled = true;
            
            break;
        case RobotDisabled:
            self.control.titleLabel.text = @"Enable";
            self.control.titleLabel.textColor = [UIColor colorWithRed:0 green:207 / 255.0f blue:65 / 255.0f alpha:1];
            self.control.enabled = true;
            
            break;
        case RobotEnabled:
            self.control.titleLabel.text = @"Disable";
            self.control.titleLabel.textColor = [UIColor redColor];
            self.control.enabled = true;
            
            break;
        case RobotAutonomous:
            self.control.titleLabel.text = @"Disable";
            self.control.titleLabel.textColor = [UIColor redColor];
            self.control.enabled = true;
            
            break;
    }
    
    if (self.selectedJoystick.selectedSegmentIndex == 3 && !stopCamera && !didReadCamera)
    {
        CGRect frame = self.cameraWebView.frame;
        
        NSString *url = [NSString stringWithFormat:@"http://10.%i.%i.11/mjpg/video.mjpg?resolution=640x480&fps=30", delegate.teamNumber / 100, delegate.teamNumber % 100];
        
        NSString *html = [NSString stringWithFormat:@"<body style=\"padding: 0; margin: 0;\"><img src=\"%@\" width=\"%fpx\" height=\"%fpx\"/></body>", url, frame.size.width, frame.size.height];
        
        [self.cameraWebView loadHTMLString:html baseURL:nil];
        
        //NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        
        //[self.cameraWebView loadRequest:urlRequest];
        
        NSLog(@"Reading camera");
        
        /*
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://10.%i.%i.11/mjpg/video.mjpg?resolution=640x480&fps=30", delegate.teamNumber / 100, delegate.teamNumber % 100]]];
        
        [request setTimeoutInterval:3];
        
        //NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://141.89.114.58/cgi-bin/image320x240.jpg?dummy=1397745356691"]];
        
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
        */
        
        didReadCamera = true;
    }
}

- (void)cancelWeb
{
    stopCamera = true;
    didReadCamera = false;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error" message:[NSString stringWithFormat:@"We could not find the camera on its default IP of: 10.%i.%i.11.", delegate.teamNumber / 100, delegate.teamNumber % 100] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Try Again", nil];
    
    [alert show];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    camTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(cancelWeb) userInfo:nil repeats:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [camTimer invalidate];
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

- (BOOL)dataIsValidJPEG:(NSData *)data
{
    if (!data || data.length < 2) return false;
    
    NSInteger total = data.length;
    const char *bytes = (const char *)[data bytes];
    
    return (bytes[0] == (char)0xFF &&
            bytes[1] == (char)0xD8 &&
            bytes[total - 2] == (char)0xFF &&
            bytes[total - 1] == (char)0xD9);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        stopCamera = false;
    } else
    {
        self.selectedJoystick.selectedSegmentIndex = 0;
        
        [self joystickChanged:self.selectedJoystick];
    }
}

@end
