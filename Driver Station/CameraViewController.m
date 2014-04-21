//
//  CameraViewController.m
//  Driver Station
//
//  Created by Connor on 4/16/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "CameraViewController.h"

#import "AppDelegate.h"
#import "MainViewController.h"

#import <objc/message.h>

@interface CameraViewController ()
{
    AppDelegate *delegate;
    
    NSTimer *timer;
    NSString *robotIP;
    
    int status;
    int cameraSocket;
    struct sockaddr_in robotCamera;
    
    int mode;
    int imageLength;
    int headerPosition;
    
    NSMutableData *buffer;
    UIImageView *imgView;
    UIImage *image;
}

@end

@implementation CameraViewController

int cameraPort = 1180;

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
    
    delegate = [[UIApplication sharedApplication] delegate];
    
    robotIP = [NSString stringWithFormat:@"10.%i.%i.2", delegate.teamNumber / 100, delegate.teamNumber % 100];
    
    buffer = [[NSMutableData alloc] initWithLength:2048];
    
    imgView.image = image;
}

- (void)viewWillAppear:(BOOL)animated
{
    ((MainViewController *) self.parentViewController).currentIndex = 3;
}

- (void)viewDidAppear:(BOOL)animated
{
    UIDeviceOrientation before = [[UIDevice currentDevice] orientation];
    
    if (UIInterfaceOrientationIsLandscape(before))
    {
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), UIInterfaceOrientationPortraitUpsideDown);
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), before);
    } else
    {
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), UIInterfaceOrientationLandscapeRight);
    }
    
    CGRect frame = self.cameraImage.frame;
    
    int camWidth = frame.size.height * (1 + 1 / 3);
    
    frame.origin.x = (self.view.frame.size.width / 2) - (camWidth / 2);
    frame.size.width = camWidth;
    
    self.cameraImage.frame = frame;
    
    [self updateStatus:CameraNotStarted];
    [self initCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)initCamera
{
    if ((cameraSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == -1)
	{
		NSLog(@"Camera socket creation Error: %i", errno);
        
		return false;
	}
    
	memset((char *) &robotCamera, 0, sizeof(robotCamera));
    
	robotCamera.sin_family = AF_INET;
	robotCamera.sin_port = htons(cameraPort);
    
	if (inet_aton([robotIP cStringUsingEncoding:NSASCIIStringEncoding], &robotCamera.sin_addr) != 1)
	{
		NSLog(@"Inavalid IP");
        
		return false;
	}
    
	fcntl(cameraSocket, F_SETFL, O_NONBLOCK);
    
	image = nil;
	imageLength = 0;
    
    mode = 0;
	headerPosition = 0;
    
    return true;
}

-(BOOL)connectCamera
{
	if (connect(cameraSocket, (struct sockaddr *)&robotCamera, sizeof(robotCamera)) == -1)
	{
		if (errno == EISCONN)
			return YES;
        
		//[self performSelector:@selector(connectCamera) withObject:nil afterDelay:.3];
		NSLog(@"Camera Connect Error:%i", errno);
        
		return false;
	}
    
	return true;
}

-(void)startTimer
{
	[self endTimer];
    
	timer = [NSTimer timerWithTimeInterval:.3 target:self selector:@selector(readCamera)
                                  userInfo:nil repeats:YES];
    
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
	[timer fire];
}

-(void)endTimer
{
	if (timer != nil)
		[timer invalidate];
    
	timer = nil;
}

- (void)readCamera
{
    if (status == CameraNotStarted)
	{
		if ([self initCamera])
            [self updateStatus:CameraNotConnected];
		else
			return;
	}
    
    BOOL startedNC = status == CameraNotConnected;
    
	if (status == CameraNotConnected)
	{
		BOOL connected = [self connectCamera];
		
        if (connected)
		{
			NSLog(@"Camera Connected");
            
            [self updateStatus:CameraConnected];
		} else
		{
			if (errno == EINPROGRESS)
			{
				[self connectCamera];
                
				return;
			}
            
			NSLog(@"Failed Connect");
            
            [self updateStatus:CameraNotConnected];
            
			if (!startedNC)
			{
				NSLog(@"Timer Slowdown");
                
				[self endTimer];
                
				timer = [NSTimer timerWithTimeInterval:.3 target:self selector:@selector(readCamera)userInfo:nil repeats:YES];
                
				[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
                
				[timer fire];
			}
		}
        
	}
    
	if (status == CameraConnected)
	{
		BOOL read = [self doRead];
        
		if (read && startedNC)
		{
			[self endTimer];
            
			timer = [NSTimer timerWithTimeInterval:.03 target:self selector:@selector(readCamera)userInfo:nil repeats:YES];
            
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
            
			[timer fire];
		}
	}
    
	if (status == CameraNotStarted)
	{
		if (![self initCamera])
		{
			NSLog(@"Camera Init Failure");
		}
	}
}

-(BOOL)doRead
{
	switch (mode)
	{
		case 0:
		{
			imageLength = 0;
            
			Byte b[4];
            
			if (recv(cameraSocket, &b, 4, 0) == -1)
			{
				NSLog(@"Header Recieve Error:%i", errno);
                
				if (errno == ECONNRESET)
				{
					//Connection Reset
                    
					[self endCamera];
					[self initCamera];
				}
                
				return NO;
			}
            
			if (b[0] == 1 && b[1] == b[2] == b[3] == 0)
			{
				mode++;
			} else
			{
				NSLog(@"Invalid Header");
			}
            
			break;
		}
		case 1:
		{
			char size[] = {0, 0, 0, 0};
            
			if (recv(cameraSocket, &size, 4, MSG_WAITALL) == -1)
			{
				NSLog(@"Get Size Error:%i", errno);
                
				if (errno == ECONNRESET)
				{
					//Connection Reset
                    
					[self endCamera];
					[self initCamera];
				}
                
				return NO;
			}
            
			imageLength = [Utilities getInt:&size];
			mode++;
            
			[buffer setLength:imageLength];
            
			break;
		}
		case 2:
		{
			if (recv(cameraSocket,[buffer mutableBytes],imageLength,0) == -1)
			{
				NSLog(@"Recieve Error:%i",errno);
                
				if (errno == ECONNRESET)
				{
					//Connection Reset
                    
					[self endCamera];
					[self initCamera];
				}
                
				return NO;
			}
            
			image = [UIImage imageWithData:buffer];
            
			[imgView setImage:image];
            
            image = nil;
            
			mode = 0;
			headerPosition = 0;
            
			break;
		}
	}
    
	return YES;
}

- (void)updateStatus:(int)stat
{
    status = stat;
    
    switch (status)
    {
        case CameraNotStarted:
            [self.cameraStatus setText:@"Camera Not Started"];
            [self.cameraStatus setHidden:false];
            
            break;
        case CameraNotConnected:
            [self.cameraStatus setText:@"Camera Not Connected"];
            [self.cameraStatus setHidden:false];
            
            break;
        case CameraConnected:
            [self.cameraStatus setHidden:true];
            
            break;
    }
    
    CGRect frame = self.cameraStatus.frame;
    
    frame.origin.x = (self.view.frame.size.width / 2) - (frame.size.width / 2);
    frame.origin.y = (self.view.frame.size.height / 2) - (frame.size.height / 2) - 10;
    
    self.cameraStatus.frame = frame;
}

-(void)endCamera
{
	close(cameraSocket);
    
	[self updateStatus:CameraNotStarted];
}

@end
