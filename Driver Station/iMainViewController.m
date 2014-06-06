//
//  MainViewController.m
//  Driver Station
//
//  Created by Connor on 3/26/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "iMainViewController.h"

#import "AppDelegate.h"
#import "ControlView.h"
#import "iStatusViewController.h"
#import "iMainDetailViewController.h"

#import "CRCVerifier.h"
#import "TransferService.h"

static short ENABLED_BIT    = 0x20;
static short AUTONOMOUS_BIT = 0x50;
static short TELEOP_BIT     = 0x40;

static int fromPort = 1150;
static int toPort   = 1110;

//0x42 = TEST
//0x40 = TELEOP
//0x50 = AUTO

// + 20 == Enabled

/*
 Joysticks 1 - 3
 
 Axis     | Code Reference
  X Left  | 1
  Y Left  | 2
 
  X Right | 3
  Y Right | 4
 
 Button   | Code Reference
  1 Left  | 1
  2 Left  | 2
  3 Left  | 3
  4 Left  | 4
  5 Left  | 5
  6 Left  | 6
 
  1 Right | 7
  2 Right | 8
  3 Right | 9
  4 Right | 10
  5 Right | 11
  6 Right | 12
 
 
 Joystick 4 - Accelerometer
 
 Axis | Code Reference
  X   | 1
  Y   | 2
  Z   | 3
 
 */

@interface iMainViewController ()
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

@implementation iMainViewController

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
    
    self.presentsWithGesture = false;
    
    [self startTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
    delegate.width = self.view.frame.size.width;
    
    NSLog(@"Width: %f", self.view.frame.size.width);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.cbManager stopScan];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)startTimer
{
    [self stopTimer];
    [self closeSockets];
    
    [self setupClient];
    
    [self startListener];
	[self startClient];
    
    toRobotData.control = TELEOP_BIT;
    toRobotData.packetIndex = 0x00;
    
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
    if ((toRobotData.control & ENABLED_BIT) == ENABLED_BIT)
    {
        toRobotData.control -= ENABLED_BIT;
        
        delegate.state = RobotDisabled;
    }
    
    [self startTimer];
}

- (void)updateTime
{
    self.currentTime++;
    
    if (self.autoTime != 0 && self.currentTime >= self.autoTime)
    {
        [self changeControl:false];
    }
}

- (void)closeSockets
{
    NSLog(@"Closing Sockets");
    
	close(inputSocket);
	close(outputSocket);
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
    
	NSLog(@"Successfully Created UDP Server");
    
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
    
	if (inet_aton([ipAddress cStringUsingEncoding:NSStringEncodingConversionAllowLossy], &robotMain.sin_addr)== 0)
	{
		NSLog(@"Error with iNet_aton function");
        
		return FALSE;
	}
    
	NSLog(@"Successfully reated UDP Client");
    
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
    /*
    if (!self.isHost && self.blueConnected && ((JoystickViewController *)self.viewControllers[1]).selectedJoystick.selectedSegmentIndex == 2)
    {
        NSLog(@"Received: %@", self.cbReceiveData);
    } else
    {
        [self updatePacket];
        
        int se = sendto(outputSocket, &toRobotData, 1024, 0, (struct sockaddr *)&robotMain, sizeof(robotMain));
        int re = recvfrom(inputSocket, &fromRobotData, 1024, 0, nil, 0);
        
        [self updateUI:(se != -1 && re != -1)];
    }
    */
    
    [self updatePacket];
    
    ssize_t se = sendto(outputSocket, &toRobotData, 1024, 0, (struct sockaddr *)&robotMain, sizeof(robotMain));
    ssize_t re = recvfrom(inputSocket, &fromRobotData, 1152, 0, nil, 0);
    
    [self updateUI:(se != -1 && re != -1)];
    
    NSString *userLine1 = [self charsToString:fromRobotData.userLine1];
    NSString *userLine2 = [self charsToString:fromRobotData.userLine2];
    NSString *userLine3 = [self charsToString:fromRobotData.userLine3];
    NSString *userLine4 = [self charsToString:fromRobotData.userLine4];
    NSString *userLine5 = [self charsToString:fromRobotData.userLine5];
    NSString *userLine6 = [self charsToString:fromRobotData.userLine6];
    
    iMainDetailViewController *detailController = ((iMainDetailViewController *)((UINavigationController *)self.viewControllers[1]).viewControllers[0]);
    
    ControlView *controlView = (ControlView *) detailController.joystickView;
    
    UITextView *text = (UITextView *)[controlView viewWithTag:50];
    
    [text setText:[NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@", userLine1, userLine2, userLine3, userLine4, userLine5, userLine6]];
    [text setFont:[UIFont systemFontOfSize:19]];
    
    [((iStatusViewController *)((UINavigationController *)self.viewControllers[0]).viewControllers[0]).tableView reloadData];
    
    [((iMainDetailViewController *)((UINavigationController *)self.viewControllers[1]).viewControllers[0]) update];
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
        //NSString *toBlueString = [NSString stringWithFormat:@"%i:%.2X.%.2X", delegate.state, fromRobotData.batteryVolts, fromRobotData.batteryMV];
        
        /*
        [self.cbPeripheral writeValue:[toBlueString dataUsingEncoding:NSUTF8StringEncoding]
                    forCharacteristic:self.receiveCharacteristic
                                 type:CBCharacteristicWriteWithoutResponse];
         */
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
    
    iMainDetailViewController *detailController = ((iMainDetailViewController *)((UINavigationController *)self.viewControllers[1]).viewControllers[0]);
    
    ControlView *controlView = (ControlView *) detailController.joystickView;
    
    NSArray *stickArray = [controlView getAxisValues];
    
    uint16_t buttonsOut = 0;
    
    buttonsOut |= detailController.button1Sel ? (1 << 0) : 0;
    buttonsOut |= detailController.button2Sel ? (1 << 1) : 0;
    buttonsOut |= detailController.button3Sel ? (1 << 2) : 0;
    buttonsOut |= detailController.button4Sel ? (1 << 3) : 0;
    buttonsOut |= detailController.button5Sel ? (1 << 4) : 0;
    buttonsOut |= detailController.button6Sel ? (1 << 5) : 0;
    
    buttonsOut |= detailController.button21Sel ? (1 << 6) : 0;
    buttonsOut |= detailController.button22Sel ? (1 << 7) : 0;
    buttonsOut |= detailController.button23Sel ? (1 << 8) : 0;
    buttonsOut |= detailController.button24Sel ? (1 << 9) : 0;
    buttonsOut |= detailController.button25Sel ? (1 << 10) : 0;
    buttonsOut |= detailController.button26Sel ? (1 << 11) : 0;
    
    switch (detailController.selectedJoystick.selectedSegmentIndex)
    {
        case 0:
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
    
    /*
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
    */
    
    
    
    toRobotData.control |= 0x04;
    
	//toRobotData.dsDigitalIn = dI;
	toRobotData.CRC = 0;
    
	uint32_t crc = [verifier verify:&toRobotData length:1024];
	
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

@end
