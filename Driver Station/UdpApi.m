//
//  UdpApi.m
//  Driver Station
//
//  Created by Connor on 2/13/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "UdpApi.h"

#import "AppDelegate.h"

@implementation UdpApi
{
    AppDelegate *delegate;
    
    int inputSocket, outputSocket;
    
    struct sockaddr_in robotMain;
    struct sockaddr_in myself;
    
    struct FRCCommonControlData toRobotData;
    struct RobotDataPacket fromRobotData;
    
    NSString *ipAddress;
    NSTimer *timer;
    
    int missed;
}

/*
int fromPort = 55055;
int toPort   = 55056;

- (void)startTimer
{
    [self closeSockets];
    
    [Utilities setShort:&toRobotData.teamID value:delegate.teamNumber];
    
    [self startListener];
	[self startClient];
    
	timer = [NSTimer timerWithTimeInterval:.019 target:self selector:@selector(updateAndSend)
                                   userInfo:nil repeats:YES];
    
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
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
    
    ipAddress = @"127.0.0.1";
    
    memset(&toRobotData, 0, 1024);
	memset(&fromRobotData, 0, 1024);
    
    toRobotData.control = 0x40;
    toRobotData.packetIndex = 0x00;
    
	toRobotData.dsID_Alliance = 0x52;
	toRobotData.dsID_Position = 0x31;
    
    [Utilities setLong:&toRobotData.versionData value:0x3130303230383030];
    
    return true;
}

- (BOOL)startListener
{
    if ((inputSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
	{
		NSLog(@"Error");
        
		return FALSE;
	}
    
	memset((char *) &myself,0,sizeof(myself));
    
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
    
	if (inet_aton([ipAddress cStringUsingEncoding:NSStringEncodingConversionAllowLossy], &robotMain.sin_addr)== 0)
	{
		NSLog(@"Error with iNet_aton function");
        
		return FALSE;
	}
    
	NSLog(@"Successfully created UDP Client");
    
	return TRUE;
}

- (BOOL)updateAndSend
{
    int amount = recvfrom(inputSocket, &fromRobotData, 1024, 0, nil, 0);
    
    [self updateUI:amount];
	//[self updatePacket];
    
    int sent=sendto(outputSocket, &toRobotData, 1024, 0, (struct sockaddr *)&robotMain, sizeof(robotMain));
    
	if (sent == -1)
    {
		NSLog(@"Send Error: %i", errno);
        
        return FALSE;
    } else {
        return TRUE;
    }
}

- (void)setupClientWithIP:(NSString *)ipAddress fromPort:(int)fPort toPort:(int)tPort
{
    delegate = [[UIApplication sharedApplication] delegate];
    
    self.udpSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    
	NSError *error = nil;
    
    ipAddress = @"127.0.0.1";
    
    NSString *connectIpAddress = @"127.0.0.1";//[NSString stringWithFormat:@"10.%i.%i.2", (delegate.teamNumber / 100), (delegate.teamNumber % 100)];
    
    [self.udpSocket enableBroadcast:YES error:nil];
    
	if (![self.udpSocket bindToPort:25555 error:&error])
	{
        NSLog(@"Error binding: %@", error);
        
		return;
    }
    
    [self.udpSocket receiveWithTimeout:30 tag:1];
    
    if (![self.udpSocket connectToHost:connectIpAddress onPort:55056 error:&error])
    {
        NSLog(@"Error connecting: %@", error);
        
		return;
    }
    
	NSLog(@"Ready");
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
    if (error.code == AsyncUdpSocketReceiveTimeoutError)
    {
        NSLog(@"Socket read timeout");
        
        delegate.state = RobotNotConnected;
        
        [self.udpSocket receiveWithTimeout:30 tag:tag];
    }
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Received: %@, Port: %i", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding], port);
    
    [self.udpSocket receiveWithTimeout:30 tag:tag];
    
    return true;
}
*/

@end