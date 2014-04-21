//
//  MainViewController.h
//  Driver Station
//
//  Created by Connor on 3/26/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MainViewController : UITabBarController <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate, UIAlertViewDelegate>

@property (nonatomic) int currentIndex;

@property (nonatomic) int teamColor;
@property (nonatomic) int teamIndex;

@property (nonatomic) int analog1;
@property (nonatomic) int analog2;
@property (nonatomic) int analog3;
@property (nonatomic) int analog4;

@property (nonatomic) BOOL isHost;
@property (nonatomic) BOOL blueConnected;
@property (nonatomic) BOOL disallowPeripheral;

@property (strong, nonatomic) CBCentralManager *cbManager;
@property (strong, nonatomic) CBPeripheral *cbPeripheral;

@property (strong, nonatomic) NSMutableData *cbData;

@property (strong, nonatomic) NSString *cbReceiveData;

@property (strong, nonatomic) CBPeripheralManager *cbpManager;

@property (strong, nonatomic) CBMutableCharacteristic *transferCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *receiveCharacteristic;

@property (strong, nonatomic) NSData *cbpData;
@property (nonatomic, readwrite) NSInteger cbpDataIndex;

- (void)changeTeam;
- (void)blueJoystick:(BOOL)status;

-(struct RobotDataPacket*)getInputPacket;
-(struct FRCCommonControlData*)getOutputPacket;

@end
