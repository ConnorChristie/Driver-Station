//
//  JoystickViewController.h
//  Driver Station
//
//  Created by Connor on 3/28/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JoystickViewController : UIViewController <UIAlertViewDelegate, NSURLConnectionDataDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *cameraWebView;
@property (weak, nonatomic) IBOutlet UIView *joystickView;

@property (weak, nonatomic) IBOutlet UILabel *battery;
@property (weak, nonatomic) IBOutlet UIButton *control;

@property (weak, nonatomic) IBOutlet UISegmentedControl *selectedJoystick;

@property (nonatomic) int currentState;

@property (nonatomic) BOOL button1Sel;
@property (nonatomic) BOOL button2Sel;
@property (nonatomic) BOOL button3Sel;
@property (nonatomic) BOOL button4Sel;
@property (nonatomic) BOOL button5Sel;
@property (nonatomic) BOOL button6Sel;

@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UIButton *button3;
@property (weak, nonatomic) IBOutlet UIButton *button4;
@property (weak, nonatomic) IBOutlet UIButton *button5;
@property (weak, nonatomic) IBOutlet UIButton *button6;

- (void)update;

@end