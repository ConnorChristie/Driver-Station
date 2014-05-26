//
//  AppDelegate.h
//  Driver Station
//
//  Created by Connor on 2/13/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PacketDef.h"
#import "MainViewController.h"
#import "iMainViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UIViewController *mainController;

@property (assign, nonatomic) int teamNumber;
@property (assign, nonatomic) int state;

@property (assign, nonatomic) int width;

@end