//
//  iMainViewController.h
//  Driver Station
//
//  Created by Connor on 3/26/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreBluetooth/CoreBluetooth.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>
#include <ifaddrs.h>

#import "Utilities.h"
#import "PacketDef.h"

@interface iMainViewController : UISplitViewController <UIAlertViewDelegate>

@property (nonatomic) int autoTime;
@property (nonatomic) int currentTime;
@property (nonatomic) int currentIndex;

@property (nonatomic) int teamColor;
@property (nonatomic) int teamIndex;

@property (nonatomic) int analog1;
@property (nonatomic) int analog2;
@property (nonatomic) int analog3;
@property (nonatomic) int analog4;

- (void)stopTimer;
- (void)closeSockets;

- (void)changeTeam;
- (void)updateAndSend;
- (void)changeControl:(BOOL)enable;

- (struct RobotDataPacket *)getInputPacket;
- (struct FRCCommonControlData *)getOutputPacket;

@end
