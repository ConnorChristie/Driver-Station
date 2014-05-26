//
//  iMainDetailViewController.m
//  Driver Station
//
//  Created by Connor on 4/29/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "iMainDetailViewController.h"

#import "AppDelegate.h"
#import "iMainViewController.h"

#import <objc/message.h>

static short ENABLED_BIT = 0x20;

@interface iMainDetailViewController ()
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

@implementation iMainDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) { }
    
    return self;
}

double currentSpeed[] = {0, 0};

- (void)awakeFromNib
{
    self.splitViewController.delegate = self;
    
    self.menuBarButton.title = @"Status";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    delegate = [[UIApplication sharedApplication] delegate];
    
    //Init - M_PI / 11 - M_PI / 11 / 2
    //Final - M_PI - M_PI / 11 / 2 + 0.04
    
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
    
    [self.button21 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button21 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button21 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button22 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button22 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button22 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button23 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button23 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button23 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button24 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button24 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button24 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button25 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button25 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button25 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.button26 addTarget:self action:@selector(buttonHold:) forControlEvents:UIControlEventTouchDown];
    [self.button26 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [self.button26 addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)buttonHold:(id)sender
{
    //NSLog(@"Press: %li", (long)((UIButton *)sender).tag);
    
    switch (((UIButton *)sender).tag)
    {
        case 1: self.button1Sel = true; break;
        case 2: self.button2Sel = true; break;
        case 3: self.button3Sel = true; break;
        case 4: self.button4Sel = true; break;
        case 5: self.button5Sel = true; break;
        case 6: self.button6Sel = true; break;
            
        case 21: self.button21Sel = true; break;
        case 22: self.button22Sel = true; break;
        case 23: self.button23Sel = true; break;
        case 24: self.button24Sel = true; break;
        case 25: self.button25Sel = true; break;
        case 26: self.button26Sel = true; break;
    }
}

- (void)buttonRelease:(id)sender
{
    //NSLog(@"Release: %li", (long)((UIButton *)sender).tag);
    
    switch (((UIButton *)sender).tag)
    {
        case 1: self.button1Sel = false; break;
        case 2: self.button2Sel = false; break;
        case 3: self.button3Sel = false; break;
        case 4: self.button4Sel = false; break;
        case 5: self.button5Sel = false; break;
        case 6: self.button6Sel = false; break;
            
        case 21: self.button21Sel = false; break;
        case 22: self.button22Sel = false; break;
        case 23: self.button23Sel = false; break;
        case 24: self.button24Sel = false; break;
        case 25: self.button25Sel = false; break;
        case 26: self.button26Sel = false; break;
    }
}

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = @"Status";
    
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
}

- (void)splitViewController:(UISplitViewController *)splitController
     willShowViewController:(UIViewController *)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
}

- (void)moveArrow:(int)needle withAmount:(double)amount
{
    if (currentSpeed[needle] + amount > 100)
    {
        amount = 100 - currentSpeed[needle];
    } else if (currentSpeed[needle] + amount < 0)
    {
        amount = 0 - currentSpeed[needle];
    }
    
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    animation.fromValue = [NSNumber numberWithDouble:currentSpeed[needle] * (M_PI - M_PI / 16) / 100 + M_PI / 15 / 2];
    animation.toValue = [NSNumber numberWithDouble:((currentSpeed[needle] + amount) * (M_PI - M_PI / 16) / 100) + M_PI / 15 / 2];

    animation.fillMode = kCAFillModeBoth;
    animation.cumulative = YES;
    animation.additive = NO;
    animation.repeatCount = 1;
    animation.removedOnCompletion = NO;
    animation.duration = abs(amount) / 50;
    
    animation.delegate = self;
    
    switch (needle) {
        case 0:
            [self.speedNeedleImage.layer addAnimation:animation forKey:@"transform"]; break;
        case 1:
            [self.speedNeedleImage2.layer addAnimation:animation forKey:@"transform"]; break;
    }
    
    currentSpeed[needle] += amount;
}

- (void)update
{
    struct RobotDataPacket *fromData = [((iMainViewController *) delegate.mainController) getInputPacket];
    
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
    
    if (!stopCamera && !didReadCamera)
    {
        CGRect frame = self.cameraWebView.frame;
        
        NSString *htmlFile   = [[NSBundle mainBundle] pathForResource:@"mjpeg_viewer" ofType:@"html"];
        NSString *jqueryFile = [[NSBundle mainBundle] pathForResource:@"jquery-2.1.1.min.js" ofType:nil];
        
        NSString *htmlString   = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
        NSString *jqueryString = [NSString stringWithContentsOfFile:jqueryFile encoding:NSUTF8StringEncoding error:nil];
        
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{jquery}" withString:jqueryString];
        
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{te}" withString:[NSString stringWithFormat:@"%i", delegate.teamNumber / 100]];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{am}" withString:[NSString stringWithFormat:@"%i", delegate.teamNumber % 100]];
        
        NSLog(@"%f, %f", frame.size.width, frame.size.height);
        
        //NSString *url = [NSString stringWithFormat:@"http://10.%i.%i.11/mjpg/video.mjpg?resolution=640x480&fps=30", delegate.teamNumber / 100, delegate.teamNumber % 100];
        
        //NSString *html = [NSString stringWithFormat:@"<body style=\"padding: 0; margin: 0;\"><img src=\"%@\" width=\"%fpx\" height=\"%fpx\"/></body>", url, frame.size.width, frame.size.height];
        
        [self.cameraWebView loadHTMLString:htmlString baseURL:nil];
        
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
    NSLog(@"Done");
    
    [camTimer invalidate];
}

- (IBAction)controlClick:(id)sender
{
    NSLog(@"State Changed");
    
    struct FRCCommonControlData *data = [((iMainViewController *) delegate.mainController) getOutputPacket];
    
    if (delegate.state == RobotDisabled)
    {
        data->control += ENABLED_BIT;
    } else if (delegate.state == RobotEnabled || delegate.state == RobotWatchdogNotFed || delegate.state == RobotAutonomous)
    {
        data->control -= ENABLED_BIT;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        stopCamera = false;
    } else
    {
        //Display text on webview
        
        NSString *html = [NSString stringWithFormat:@"<body style=\"padding: 0; margin: 0; background: lightgray; text-align: center;\"><label style=\"position: relative; top: 48%%;\">Tap to refresh camera</label></body>"];
        
        [self.cameraWebView loadHTMLString:html baseURL:nil];
    }
}

@end
