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

//These bits may be different with the new protocol
static short ENABLED_BIT    = 0x20;
static short AUTONOMOUS_BIT = 0x50;
static short TELEOP_BIT     = 0x40;

//Ports are probably different, I thought I saw it somewhere
static int fromPort = 1150;
static int toPort   = 1110;

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
    
    motion = [[CMMotionManager alloc] init];
    motion.accelerometerUpdateInterval  = 1.0 / 10.0; // Update at 10Hz
    
    _ipFormat = @"10.%i.%i.20";
    
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
    
    //Sets to teleop disabled
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

//Update the match time, called every second
- (void)updateTime
{
    self.currentTime++;
    
    if (self.autoTime != 0 && self.currentTime >= self.autoTime)
    {
        [self changeControl:false];
    }
}

//Setting up the packets and ip
//Sets the teamId to the team number, and version to version of driver station
- (BOOL)setupClient
{
    ipAddress = [NSString stringWithFormat:_ipFormat, delegate.teamNumber / 100, delegate.teamNumber % 100];
    
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

//Listens for commands that the robot sends us
- (BOOL)startListener
{
    if ((inputSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
	{
		NSLog(@"Error");
        
		return FALSE;
	}
    
	memset((char *) &myself, 0, sizeof(myself));
    
	myself.sin_family = AF_INET;
	myself.sin_port = htons(fromPort); //The port from the robot
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

//Sets up the robot to send commands
-(BOOL)startClient
{
	if ((outputSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
	{
		NSLog(@"Error creating Socket");
        
		return FALSE;
	}
    
	memset((char *) &robotMain, 0, sizeof(robotMain));
    
	robotMain.sin_family = AF_INET;
	robotMain.sin_port = htons(toPort); //The port to the robot
    
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
        //Starts the match timer
        secondTimer = [NSTimer timerWithTimeInterval:1.00 target:self selector:@selector(updateTime)
                                            userInfo:nil repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:secondTimer forMode:NSDefaultRunLoopMode];
        
        //Sets the control bit to enabled
        toRobotData.control += ENABLED_BIT;
    } else if (!enable && (delegate.state == RobotEnabled || delegate.state == RobotWatchdogNotFed || delegate.state == RobotAutonomous))
    {
        [secondTimer invalidate];
        
        secondTimer = nil;
        self.currentTime = 0;
        
        //Sets the control bit to disabled
        toRobotData.control -= ENABLED_BIT;
    }
}

- (void)updateAndSend
{
    [self updatePacket];
    
    ssize_t se = sendto(outputSocket, &toRobotData, 1024, 0, (struct sockaddr *)&robotMain, sizeof(robotMain));
    ssize_t re = recvfrom(inputSocket, &fromRobotData, 1152, 0, nil, 0);
    
    [self updateUI:(se != -1 && re != -1)];
    
    //From robot data length
    
    //Gets the user lines
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
            //Robot has not contacted us in over 600 ms
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
            //Sending enabled bit (we are telling the robot to become enabled)
            
            if ((fromRobotData.control & ENABLED_BIT) == ENABLED_BIT)
            {
                //Received the enable bit (they are telling us they enabled successfully)
                
                if ((fromRobotData.control & AUTONOMOUS_BIT) == AUTONOMOUS_BIT)
                {
                    //Telling us we are in auto
                    
                    delegate.state = RobotAutonomous;
                } else if ((fromRobotData.control & TELEOP_BIT) == TELEOP_BIT)
                {
                    //Telling us we are in teleop
                    
                    delegate.state = RobotEnabled;
                }
            } else
            {
                //If we do not receive the same bit back we have an error (watchdog not fed)
                
                delegate.state = RobotWatchdogNotFed;
            }
		} else
		{
			delegate.state = RobotDisabled;
		}
	}
}

-(void)updatePacket
{
    //Sets packet id to prev_id + 1
	[Utilities setShort:&toRobotData.packetIndex value:[Utilities getShort:&toRobotData.packetIndex] + 1];
    
    switch (self.teamColor)
    {
        case 0: //Set the teams color, either char R or B
            toRobotData.dsID_Alliance = 'R'; break;
        case 1:
            toRobotData.dsID_Alliance = 'B'; break;
    }
    
    switch (self.teamIndex)
    {
        case 0: //Set the team position 1-3
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
    
    //OR each button whether it is enabled or not.
    buttonsOut |= joystickController.button1Sel ? (1 << 0) : 0;
    buttonsOut |= joystickController.button2Sel ? (1 << 1) : 0;
    buttonsOut |= joystickController.button3Sel ? (1 << 2) : 0;
    buttonsOut |= joystickController.button4Sel ? (1 << 3) : 0;
    buttonsOut |= joystickController.button5Sel ? (1 << 4) : 0;
    buttonsOut |= joystickController.button6Sel ? (1 << 5) : 0;
    
    uint16_t buttonsOut1 = 0;
    uint16_t buttonsOut2 = 0;
    
    //OR each button whether it is enabled or not.
    buttonsOut1 |= joystickController.button1Sel ? (1 << 0) : 0;
    buttonsOut1 |= joystickController.button3Sel ? (1 << 1) : 0;
    buttonsOut1 |= joystickController.button5Sel ? (1 << 2) : 0;
    
    //OR each button whether it is enabled or not.
    buttonsOut2 |= joystickController.button2Sel ? (1 << 0) : 0;
    buttonsOut2 |= joystickController.button4Sel ? (1 << 1) : 0;
    buttonsOut2 |= joystickController.button6Sel ? (1 << 2) : 0;
    
    switch (joystickController.selectedJoystick.selectedSegmentIndex)
    {
        case 0:
        case 3: //Case 0 and 3 (joystick 1 and camera)
            toRobotData.stick0.stick0Axes[0] = [(NSNumber *)[stickArray objectAtIndex:0] intValue];
            toRobotData.stick0.stick0Axes[1] = [(NSNumber *)[stickArray objectAtIndex:1] intValue];
            toRobotData.stick0.stick0Axes[2] = [(NSNumber *)[stickArray objectAtIndex:2] intValue];
            toRobotData.stick0.stick0Axes[3] = [(NSNumber *)[stickArray objectAtIndex:3] intValue];
            
            //Joystick 1
            //Sets each of the 4 axes to their value, (Left stick X & Y, Right stick X & Y)
            
            [Utilities setShort:&toRobotData.stick0Buttons value:buttonsOut];
            
            break;
        case 1:
            toRobotData.stick1.stick1Axes[0] = [(NSNumber *)[stickArray objectAtIndex:0] intValue];
            toRobotData.stick1.stick1Axes[1] = [(NSNumber *)[stickArray objectAtIndex:1] intValue];
            toRobotData.stick1.stick1Axes[2] = [(NSNumber *)[stickArray objectAtIndex:2] intValue];
            toRobotData.stick1.stick1Axes[3] = [(NSNumber *)[stickArray objectAtIndex:3] intValue];
            
            //Joystick 2
            //Sets each of the 4 axes to their value, (Left stick X & Y, Right stick X & Y)
            
            [Utilities setShort:&toRobotData.stick1Buttons value:buttonsOut];
            
            break;
        case 2:
            toRobotData.stick0.stick0Axes[0] = [(NSNumber *)[stickArray objectAtIndex:0] intValue];
            toRobotData.stick0.stick0Axes[1] = [(NSNumber *)[stickArray objectAtIndex:1] intValue];
            toRobotData.stick1.stick1Axes[0] = [(NSNumber *)[stickArray objectAtIndex:2] intValue];
            toRobotData.stick1.stick1Axes[1] = [(NSNumber *)[stickArray objectAtIndex:3] intValue];
            
            //Joystick 1 & 2, (Left stick is joystick 1, right stick is joystick 2)
            
            [Utilities setShort:&toRobotData.stick0Buttons value:buttonsOut1];
            [Utilities setShort:&toRobotData.stick1Buttons value:buttonsOut2];
            
            break;
    }
    
    double x = acceleration.x;
    double y = acceleration.y;
    double z = acceleration.z;
    
    x *= (x < 0 ? 128 : 127);
    y *= (y < 0 ? 128 : 127);
    z *= (z < 0 ? 128 : 127);
    
    //Send accelerometer data as joystick 3
    
    toRobotData.stick3.stick3Axes[0] = (int) x;
    toRobotData.stick3.stick3Axes[1] = (int) y;
    toRobotData.stick3.stick3Axes[2] = (int) z;
    
    //Get change in acceleration for every direction
    double xyz = sqrt(x * x + y * y + z * z);
    
    //Find out if acceleration changed very rapidly, probably from a fall...
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
    
    //Send over analog data
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
    
    //I do not know where this comes from but it seems to only work with this bit added
    toRobotData.control |= 0x04; //Resync
    
    //Set the digital out
	toRobotData.dsDigitalIn = dI;
	toRobotData.CRC = 0;
    
    //Calculate the crc hash for the packet
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
