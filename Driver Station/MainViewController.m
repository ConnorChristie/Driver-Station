//
//  MainViewController.m
//  Driver Station
//
//  Created by Connor on 3/26/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "MainViewController.h"

#import "AppDelegate.h"
#import "ControlView.h"
#import "IOViewController.h"
#import "StatusViewController.h"
#import "JoystickViewController.h"

#import "CRCVerifier.h"
#import "TransferService.h"

static short ENABLED_BIT    = 0x20;
static short AUTONOMOUS_BIT = 0x50;
static short TELEOP_BIT     = 0x40;

static int fromPort = 1150;
static int toPort  = 1110;

//0x42 = TEST
//0x40 = TELEOP
//0x50 = AUTO

// + 20 == Enabled

/*

    Joysticks 1 - 2

    Axis     | Code Reference
     X Left  | 1
     Y Left  | 2

     X Right | 3
     Y Right | 4

    Buttons are number for number for Code Reference
 
    Camera - Uses Joystick 1

    Joystick 4 - Accelerometer

    Axis | Code Reference
     X   | 1
     Y   | 2
     Z   | 3
 
 */

@interface MainViewController ()
{
    AppDelegate *delegate;
    
    int inputSocket, outputSocket;
    
    struct sockaddr_in robotMain;
    struct sockaddr_in myself;
    
    struct FRCCommonControlData toRobotData;
    struct RobotDataPacket fromRobotData;
    
    CRCVerifier *verifier;
    
    CMMotionManager *motion;
    NSOperationQueue *queue;
    
    CMAcceleration acceleration;
    UIAlertView *currentAlert;
    
    NSString *ipAddress;
    
    NSTimer *timer;
    NSTimer *secondTimer;
    
    int missed;
    double prevXYZ;
}

@end

@implementation MainViewController

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
    
    self.currentIndex = 0;
    
    delegate = [[UIApplication sharedApplication] delegate];
    delegate.teamNumber = 4095;
    delegate.mainController = self;
    
    verifier = [[CRCVerifier alloc] init];
	[verifier buildTable];
    
    //self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    //self.cbData    = [[NSMutableData alloc] init];
    
    motion = [[CMMotionManager alloc] init];
    motion.accelerometerUpdateInterval  = 1.0 / 10.0; // Update at 10Hz
    
    if (motion.accelerometerAvailable)
    {
        NSLog(@"Accelerometer avaliable");
        
        queue = [NSOperationQueue currentQueue];
        
        [motion startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
        {
            acceleration = accelerometerData.acceleration;
        }];
    }
    
    [self startTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.cbManager stopScan];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)blueJoystick:(BOOL)status
{
    /*
    if (status)
    {
        if (self.blueConnected)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth Joystick" message:@"Are you sure you want to disconnect the currently connected phone?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            
            alert.tag = 3;
            
            [alert show];
            
            return;
        }
        
        [self.cbManager stopScan];
        [self cleanup];
        
        self.cbpManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        [self.cbpManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
        
        currentAlert = [[UIAlertView alloc] initWithTitle:@"Bluetooth Joystick" message:@"Waiting for the host to allow your connection." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
        
        currentAlert.tag = 1;
        
        [currentAlert show];
    } else
    {
        BOOL eomSent = [self.cbpManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        if (eomSent)
        {
            NSLog(@"Sent: EOM");
        }
        
        [self.cbpManager stopAdvertising];
        
        self.cbPeripheral = nil;
        
        [self.cbManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    }
    */
}

/*
 
 Being a peripheral
 
 */

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state != CBPeripheralManagerStatePoweredOn)
    {
        return;
    }
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                         properties:CBCharacteristicPropertyNotify
                                                                              value:nil
                                                                        permissions:CBAttributePermissionsReadable];
        
        self.receiveCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:RECEIVE_CHARACTERISTIC_UUID]
                                                                        properties:CBCharacteristicPropertyWriteWithoutResponse
                                                                             value:nil
                                                                       permissions:CBAttributePermissionsWriteable];
        
        CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
        
        transferService.characteristics = @[_transferCharacteristic, _receiveCharacteristic];
        
        [self.cbpManager addService:transferService];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    //self.blueConnected = true;
    
    self.cbpData = [@"Hello from the driver station!" dataUsingEncoding:NSUTF8StringEncoding];
    self.cbpDataIndex = 0;
    
    [self sendData];
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self sendData];
}

- (void)sendData
{
    NSData *chunk = [NSData dataWithBytes:self.cbpData.bytes + self.cbpDataIndex length:self.cbpData.length];
    
    BOOL didSend = [self.cbpManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
    
    // If it didn't work, drop out and wait for the callback
    if (!didSend)
    {
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
    
    NSLog(@"Sent: %@", stringFromData);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    self.cbReceiveData = [[NSString alloc] initWithData:((CBATTRequest *)[requests objectAtIndex:0]).value encoding:NSUTF8StringEncoding];
    
    if ([self.cbReceiveData isEqualToString:@"connect"])
    {
        self.blueConnected = true;
        
        [currentAlert dismissWithClickedButtonIndex:0 animated:true];
    } else if ([self.cbReceiveData isEqualToString:@"disconnect"])
    {
        [self blueJoystick:false];
        
        ((JoystickViewController *)self.viewControllers[1]).selectedJoystick.selectedSegmentIndex = 0;
        
        [currentAlert dismissWithClickedButtonIndex:0 animated:YES];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth Joystick" message:@"Your attempt to become a bluetooth joystick has been denied." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alert show];
    } else if ([self.cbReceiveData isEqualToString:@"disconnect_n"])
    {
        [self blueJoystick:false];
        
        ((JoystickViewController *)self.viewControllers[1]).selectedJoystick.selectedSegmentIndex = 0;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    self.blueConnected = false;
}

/*
 
 Stop being peripheral
 
 */

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1 && !self.blueConnected)
    {
        self.cbpData = [@"disconnect_n" dataUsingEncoding:NSUTF8StringEncoding];
        self.cbpDataIndex = 0;
        
        [self sendData];
        
        /*
        self.blueConnected = false;
        
        [self blueJoystick:false];
        
        ((JoystickViewController *)self.viewControllers[1]).selectedJoystick.selectedSegmentIndex = 0;
         */
    } else if (alertView.tag == 2)
    {
        if (buttonIndex == 0)
        {
            //self.disallowPeripheral = true;
            
            [self.cbPeripheral writeValue:[@"disconnect" dataUsingEncoding:NSUTF8StringEncoding]
                        forCharacteristic:self.receiveCharacteristic
                                     type:CBCharacteristicWriteWithoutResponse];
        } else
        {
            [self.cbPeripheral writeValue:[@"connect" dataUsingEncoding:NSUTF8StringEncoding]
                        forCharacteristic:self.receiveCharacteristic
                                     type:CBCharacteristicWriteWithoutResponse];
            
            self.blueConnected = true;
        }
    } else if (alertView.tag == 3)
    {
        if (buttonIndex == 0)
        {
            //No
            
            ((JoystickViewController *)self.viewControllers[1]).selectedJoystick.selectedSegmentIndex = 0;
        } else if (buttonIndex == 1)
        {
            //Yes
            
            NSLog(@"Yes");
            
            ((JoystickViewController *)self.viewControllers[1]).selectedJoystick.selectedSegmentIndex = 0;
            
            self.cbpData = [@"disconnect_n" dataUsingEncoding:NSUTF8StringEncoding];
            self.cbpDataIndex = 0;
            
            [self sendData];
            
            self.blueConnected = false;
            
            [self blueJoystick:true];
        }
    }
}

/*
 
 Being a Manager
 
 */

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [self.cbManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        
        NSLog(@"Scanning started");
    } else
    {
        NSLog(@"No Bluetooth");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    if (self.cbPeripheral != peripheral)
    {
        [self.cbManager stopScan];
        
        [((JoystickViewController *)self.viewControllers[1]).selectedJoystick setEnabled:false forSegmentAtIndex:2];
        
        currentAlert = [[UIAlertView alloc] initWithTitle:@"Bluetooth Joystick" message:@"A bluetooth joystick is attempting to connect, do you want to allow?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        
        currentAlert.tag = 2;
        
        [currentAlert show];
        
        self.cbPeripheral = peripheral;
        
        [self.cbManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self cleanup];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected");
    
    [self.cbManager stopScan];
    
    NSLog(@"Scanning stopped");
    
    [self.cbData setLength:0];
    
    peripheral.delegate = self;
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        [self cleanup];
        
        return;
    }
    
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID], [CBUUID UUIDWithString:RECEIVE_CHARACTERISTIC_UUID]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        [self cleanup];
        
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
        {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            self.transferCharacteristic = (CBMutableCharacteristic *) characteristic;
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RECEIVE_CHARACTERISTIC_UUID]])
        {
            self.receiveCharacteristic = (CBMutableCharacteristic *) characteristic;
        }
    }
    
    /*
    if (self.disallowPeripheral)
    {
        NSLog(@"Hello");
        
        [self.cbPeripheral writeValue:[@"disconnect" dataUsingEncoding:NSUTF8StringEncoding]
                    forCharacteristic:self.receiveCharacteristic
                                 type:CBCharacteristicWriteWithoutResponse];
        
        self.disallowPeripheral = false;
        
        return;
    }
    */
    
    //self.blueConnected = true;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error");
        
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    NSLog(@"Data: %@", stringFromData);
    
    if ([stringFromData isEqualToString:@"EOM"])
    {
        if (currentAlert != nil)
        {
            [currentAlert dismissWithClickedButtonIndex:1 animated:true];
            
            currentAlert = nil;
        }
        
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        [self.cbManager cancelPeripheralConnection:peripheral];
    } else if ([stringFromData isEqualToString:@"disconnect_n"])
    {
        [currentAlert dismissWithClickedButtonIndex:0 animated:YES];
        
        [self.cbPeripheral writeValue:[@"disconnect_n" dataUsingEncoding:NSUTF8StringEncoding]
                    forCharacteristic:self.receiveCharacteristic
                                 type:CBCharacteristicWriteWithoutResponse];
        
        //self.disallowPeripheral = false;
        
        //self.blueConnected = false;
    }
    
    [self.cbData appendData:characteristic.value];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] && ![characteristic.UUID isEqual:[CBUUID UUIDWithString:RECEIVE_CHARACTERISTIC_UUID]])
    {
        return;
    }
    
    if (characteristic.isNotifying)
    {
        NSLog(@"Notification began on %@", characteristic);
    } else
    {
        [self.cbManager cancelPeripheralConnection:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.cbPeripheral = nil;
    
    [self.cbManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

- (void)cleanup
{
    [((JoystickViewController *)self.viewControllers[1]).selectedJoystick setEnabled:true forSegmentAtIndex:2];
    
    self.blueConnected = false;
    self.isHost = false;
    
    if (self.cbPeripheral.services != nil)
    {
        for (CBService *service in self.cbPeripheral.services)
        {
            if (service.characteristics != nil)
            {
                for (CBCharacteristic *characteristic in service.characteristics)
                {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:RECEIVE_CHARACTERISTIC_UUID]])
                    {
                        if (characteristic.isNotifying)
                        {
                            [self.cbPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            self.cbPeripheral = nil;
                            
                            return;
                        }
                    }
                }
            }
        }
    }
    
    [self.cbManager cancelPeripheralConnection:self.cbPeripheral];
    
    self.cbPeripheral = nil;
}

/*
 
 Stop being manager
 
 */

- (void)startTimer
{
    [self stopTimer];
    [self closeSockets];
    
    [self setupClient];
    
    [self startListener];
	[self startClient];
    
    toRobotData.control = TELEOP_BIT;
    toRobotData.packetIndex = 0x00;
    
    //Timing to send packets has to be EXACTLY 0.02 seconds...
	timer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(updateAndSend)
                                  userInfo:nil repeats:YES];
    
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)stopTimer
{
    if (timer != nil)
    {
        [timer invalidate];
        
        timer = nil;
    }
}

- (void)changeTeam
{
    [self changeControl:false];
    
    [self startTimer];
}

- (void)closeSockets
{
    NSLog(@"Closing Sockets");
    
	close(inputSocket);
	close(outputSocket);
}

- (void)updateTime
{
    self.currentTime++;
    
    if (self.autoTime != 0 && self.currentTime >= self.autoTime)
    {
        [self changeControl:false];
    }
}

- (BOOL)setupClient
{
    ipAddress = [NSString stringWithFormat:@"10.%i.%i.2", delegate.teamNumber / 100, delegate.teamNumber % 100];
    
    //ipAddress = @"127.0.0.1";
    
    NSLog(@"IP: %@", ipAddress);
    
    memset(&toRobotData, 0, 1024);
	memset(&fromRobotData, 0, 1024);
    
	toRobotData.dsID_Alliance = 0x52;
	toRobotData.dsID_Position = 0x31;
    
    [Utilities setShort:&toRobotData.teamID value:delegate.teamNumber];
    [Utilities setLong:&toRobotData.versionData value:0x3031303431343030];
    
    return true;
}

- (BOOL)startListener
{
    if ((inputSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
	{
		NSLog(@"Error");
        
		return FALSE;
	}
    
	memset((char *) &myself, 0, sizeof(myself));
    
	myself.sin_family = AF_INET;
	myself.sin_port = htons(fromPort);
	myself.sin_addr.s_addr = htonl(INADDR_ANY);
    
	fcntl(inputSocket, F_SETFL, O_NONBLOCK);
    
	if (bind(inputSocket,(struct sockaddr*)&myself, sizeof(myself)) == -1)
	{
		NSLog(@"Bind Error");
        
		return FALSE;
	}
    
	NSLog(@"Succesfully Created UDP Server");
    
    return TRUE;
}

-(BOOL)startClient
{
	if ((outputSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
	{
		NSLog(@"Error creating Socket");
        
		return FALSE;
	}
    
	memset((char *) &robotMain, 0, sizeof(robotMain));
    
	robotMain.sin_family = AF_INET;
	robotMain.sin_port = htons(toPort);
    
	if (inet_aton([ipAddress cStringUsingEncoding:NSStringEncodingConversionAllowLossy], &robotMain.sin_addr) == 0)
	{
		NSLog(@"Error with iNet_aton function");
        
		return FALSE;
	}
    
	NSLog(@"Successfully created UDP Client");
    
	return TRUE;
}

- (void)changeControl:(BOOL)enable
{
    if (enable && delegate.state == RobotDisabled)
    {
        secondTimer = [NSTimer timerWithTimeInterval:1.00 target:self selector:@selector(updateTime)
                                            userInfo:nil repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:secondTimer forMode:NSDefaultRunLoopMode];
        
        toRobotData.control += ENABLED_BIT;
    } else if (!enable && (delegate.state == RobotEnabled || delegate.state == RobotWatchdogNotFed || delegate.state == RobotAutonomous))
    {
        [secondTimer invalidate];
        
        secondTimer = nil;
        self.currentTime = 0;
        
        toRobotData.control -= ENABLED_BIT;
    }
}

- (void)updateAndSend
{
    if (!self.isHost && self.blueConnected && ((JoystickViewController *)self.viewControllers[1]).selectedJoystick.selectedSegmentIndex == 2)
    {
        NSLog(@"Received: %@", self.cbReceiveData);
    } else
    {
        [self updatePacket];
        
        ssize_t se = sendto(outputSocket, &toRobotData, 1024, 0, (struct sockaddr *)&robotMain, sizeof(robotMain));
        ssize_t re = recvfrom(inputSocket, &fromRobotData, 1152, 0, nil, 0);
        
        [self updateUI:(se != -1 && re != -1)];
    }
    
    //From robot data length
    
    NSString *userLine1 = [self charsToString:fromRobotData.userLine1];
    NSString *userLine2 = [self charsToString:fromRobotData.userLine2];
    NSString *userLine3 = [self charsToString:fromRobotData.userLine3];
    NSString *userLine4 = [self charsToString:fromRobotData.userLine4];
    NSString *userLine5 = [self charsToString:fromRobotData.userLine5];
    NSString *userLine6 = [self charsToString:fromRobotData.userLine6];
    
    UITextView *text = (UITextView *)[((UIViewController *)self.viewControllers[3]).view viewWithTag:2];
    
    [text setText:[NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@", userLine1, userLine2, userLine3, userLine4, userLine5, userLine6]];
    [text setFont:[UIFont systemFontOfSize:19]];
    
    [((StatusViewController *)self.viewControllers[0]).tableView reloadData];
    
    [((JoystickViewController *)self.viewControllers[1]) update];
}

- (NSString *)charsToString:(char[])chars
{
    NSString *str = @"";
    
    for (int i = 0; i < 21; i++)
    {
        str = [NSString stringWithFormat:@"%@%c", str, chars[i]];
    }
    
    return str;
}

- (void)updateUI:(BOOL)received
{
    if (!received)
	{
		if (missed >= 30) //600 ms
		{
			delegate.state = RobotNotConnected;
		}
        
		missed++;
        
        //[((JoystickViewController *)self.viewControllers[1]).selectedJoystick setEnabled:true forSegmentAtIndex:2];
	} else
	{
		missed = 0;
        
        //[((JoystickViewController *)self.viewControllers[1]).selectedJoystick setEnabled:false forSegmentAtIndex:2];
        
        //NSLog(@"0x%.2X - 0x%.2X", toRobotData.control, fromRobotData.control);
        
		if ((toRobotData.control & ENABLED_BIT) == ENABLED_BIT)
		{
            if ((fromRobotData.control & ENABLED_BIT) == ENABLED_BIT)
            {
                if ((fromRobotData.control & AUTONOMOUS_BIT) == AUTONOMOUS_BIT)
                {
                    delegate.state = RobotAutonomous;
                } else if ((fromRobotData.control & TELEOP_BIT) == TELEOP_BIT)
                {
                    delegate.state = RobotEnabled;
                }
            } else
            {
                delegate.state = RobotWatchdogNotFed;
            }
		} else
		{
			delegate.state = RobotDisabled;
		}
	}
    
    if (self.blueConnected)
    {
        NSString *toBlueString = [NSString stringWithFormat:@"%i:%.2X.%.2X", delegate.state, fromRobotData.batteryVolts, fromRobotData.batteryMV];
    
        [self.cbPeripheral writeValue:[toBlueString dataUsingEncoding:NSUTF8StringEncoding]
                forCharacteristic:self.receiveCharacteristic
                             type:CBCharacteristicWriteWithoutResponse];
    }
}

-(void)updatePacket
{
	[Utilities setShort:&toRobotData.packetIndex value:[Utilities getShort:&toRobotData.packetIndex] + 1];
    
    switch (self.teamColor)
    {
        case 0:
            toRobotData.dsID_Alliance = 'R'; break;
        case 1:
            toRobotData.dsID_Alliance = 'B'; break;
    }
    
    switch (self.teamIndex)
    {
        case 0:
            toRobotData.dsID_Position = 0x31; break;
        case 1:
            toRobotData.dsID_Position = 0x32; break;
        case 2:
            toRobotData.dsID_Position = 0x33; break;
    }
    
    JoystickViewController *joystickController = [self.viewControllers objectAtIndex:1];
    ControlView *controlView = (ControlView *) joystickController.joystickView;
    
    NSArray *stickArray = [controlView getAxisValues];
    
    uint16_t buttonsOut = 0;
    
    buttonsOut |= joystickController.button1Sel ? (1 << 0) : 0;
    buttonsOut |= joystickController.button2Sel ? (1 << 1) : 0;
    buttonsOut |= joystickController.button3Sel ? (1 << 2) : 0;
    buttonsOut |= joystickController.button4Sel ? (1 << 3) : 0;
    buttonsOut |= joystickController.button5Sel ? (1 << 4) : 0;
    buttonsOut |= joystickController.button6Sel ? (1 << 5) : 0;
    
    switch (joystickController.selectedJoystick.selectedSegmentIndex)
    {
        case 0:
        case 3:
            toRobotData.stick0.stick0Axes[0] = [(NSNumber *)[stickArray objectAtIndex:0] intValue];
            toRobotData.stick0.stick0Axes[1] = [(NSNumber *)[stickArray objectAtIndex:1] intValue];
            toRobotData.stick0.stick0Axes[2] = [(NSNumber *)[stickArray objectAtIndex:2] intValue];
            toRobotData.stick0.stick0Axes[3] = [(NSNumber *)[stickArray objectAtIndex:3] intValue];
            
            [Utilities setShort:&toRobotData.stick0Buttons value:buttonsOut];
            
            break;
        case 1:
            toRobotData.stick1.stick1Axes[0] = [(NSNumber *)[stickArray objectAtIndex:0] intValue];
            toRobotData.stick1.stick1Axes[1] = [(NSNumber *)[stickArray objectAtIndex:1] intValue];
            toRobotData.stick1.stick1Axes[2] = [(NSNumber *)[stickArray objectAtIndex:2] intValue];
            toRobotData.stick1.stick1Axes[3] = [(NSNumber *)[stickArray objectAtIndex:3] intValue];
            
            [Utilities setShort:&toRobotData.stick1Buttons value:buttonsOut];
            
            break;
        case 2:
            toRobotData.stick2.stick2Axes[0] = [(NSNumber *)[stickArray objectAtIndex:0] intValue];
            toRobotData.stick2.stick2Axes[1] = [(NSNumber *)[stickArray objectAtIndex:1] intValue];
            toRobotData.stick2.stick2Axes[2] = [(NSNumber *)[stickArray objectAtIndex:2] intValue];
            toRobotData.stick2.stick2Axes[3] = [(NSNumber *)[stickArray objectAtIndex:3] intValue];
            
            [Utilities setShort:&toRobotData.stick2Buttons value:buttonsOut];
            
            break;
            /*
        case 3:
            toRobotData.stick3.stick3Axes[0] = [(NSNumber *)[stickArray objectAtIndex:0] intValue];
            toRobotData.stick3.stick3Axes[1] = [(NSNumber *)[stickArray objectAtIndex:1] intValue];
            toRobotData.stick3.stick3Axes[2] = [(NSNumber *)[stickArray objectAtIndex:2] intValue];
            toRobotData.stick3.stick3Axes[3] = [(NSNumber *)[stickArray objectAtIndex:3] intValue];
            
            [Utilities setShort:&toRobotData.stick3Buttons value:buttonsOut];
            
            break;
             */
    }
    
    double x = acceleration.x;
    double y = acceleration.y;
    double z = acceleration.z;
    
    x *= (x < 0 ? 128 : 127);
    y *= (y < 0 ? 128 : 127);
    z *= (z < 0 ? 128 : 127);
    
    toRobotData.stick3.stick3Axes[0] = (int)x;
    toRobotData.stick3.stick3Axes[1] = (int)y;
    toRobotData.stick3.stick3Axes[2] = (int)z;
    
    double xyz = sqrt(x * x + y * y + z * z);
    
    //NSLog(@"Fall: %f, %f", prevXYZ, xyz - prevXYZ);
    
    if (prevXYZ < 20)
    {
        if (xyz - prevXYZ > 200)
        {
            NSLog(@"Device fell...");
            
            if ((toRobotData.control & ENABLED_BIT) == ENABLED_BIT)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Robot Disabled" message:@"It seems like you dropped your phone... We disabled the robot just for safety!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                
                [alert show];
                
                toRobotData.control -= ENABLED_BIT;
                
                delegate.state = RobotDisabled;
            }
        }
    }
    
    prevXYZ = xyz;
    
    //NSLog(@"Accel: %i", toRobotData.stick3.stick3Axes[0]);
    
    [Utilities setShort:&toRobotData.analog1 value:(uint16_t)self.analog1];
    [Utilities setShort:&toRobotData.analog2 value:(uint16_t)self.analog2];
    [Utilities setShort:&toRobotData.analog3 value:(uint16_t)self.analog3];
    [Utilities setShort:&toRobotData.analog4 value:(uint16_t)self.analog4];
    
    IOViewController *io = [self.viewControllers objectAtIndex:2];
    
	uint8_t dI = 0;
    
	for (int i = 0; i < 4; i++)
	{
		BOOL temp = false;
        
        switch (i)
        {
            case 0: temp = io.digital1.on; break;
            case 1: temp = io.digital2.on; break;
            case 2: temp = io.digital3.on; break;
            case 3: temp = io.digital4.on; break;
        }
		
        if (temp)
		{
			dI = dI | (1 << i);
		}
	}
    
    toRobotData.control |= 0x04; //Resync
    
	toRobotData.dsDigitalIn = dI;
	toRobotData.CRC = 0;
    
	uint32_t crc = [verifier verify:&toRobotData length:1024];
    
    //NSLog(@"%X", crc);
	
	[Utilities setInt:&toRobotData.CRC value:crc];
}

-(struct RobotDataPacket *)getInputPacket
{
	return &fromRobotData;
}

-(struct FRCCommonControlData *)getOutputPacket
{
	return &toRobotData;
}

- (BOOL)shouldAutorotate
{
    return true;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (self.currentIndex == 0)
    {
        return UIInterfaceOrientationMaskPortrait;
    } else if (self.currentIndex > 0)
    {
        return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

@end
