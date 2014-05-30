//
//  iMainDetailViewController.h
//  Driver Station
//
//  Created by Connor on 4/29/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ControlView.h"

@interface iMainDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (weak, nonatomic) IBOutlet ControlView *joystickView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *selectedJoystick;
@property (weak, nonatomic) IBOutlet UIImageView *speedNeedleImage;
@property (weak, nonatomic) IBOutlet UIImageView *speedNeedleImage2;

@property (weak, nonatomic) IBOutlet UIWebView *cameraWebView;
@property (weak, nonatomic) IBOutlet UILabel *battery;
@property (weak, nonatomic) IBOutlet UIButton *control;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarButton;

@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UIButton *button3;
@property (weak, nonatomic) IBOutlet UIButton *button4;
@property (weak, nonatomic) IBOutlet UIButton *button5;
@property (weak, nonatomic) IBOutlet UIButton *button6;

@property (weak, nonatomic) IBOutlet UIButton *button21;
@property (weak, nonatomic) IBOutlet UIButton *button22;
@property (weak, nonatomic) IBOutlet UIButton *button23;
@property (weak, nonatomic) IBOutlet UIButton *button24;
@property (weak, nonatomic) IBOutlet UIButton *button25;
@property (weak, nonatomic) IBOutlet UIButton *button26;

@property (nonatomic) BOOL button1Sel;
@property (nonatomic) BOOL button2Sel;
@property (nonatomic) BOOL button3Sel;
@property (nonatomic) BOOL button4Sel;
@property (nonatomic) BOOL button5Sel;
@property (nonatomic) BOOL button6Sel;

@property (nonatomic) BOOL button21Sel;
@property (nonatomic) BOOL button22Sel;
@property (nonatomic) BOOL button23Sel;
@property (nonatomic) BOOL button24Sel;
@property (nonatomic) BOOL button25Sel;
@property (nonatomic) BOOL button26Sel;

- (void)update;
- (void)moveArrow:(int)needle withAmount:(double)amount;

@end
