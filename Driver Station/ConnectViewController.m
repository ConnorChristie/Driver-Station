//
//  ConnectViewController.m
//  Driver Station
//
//  Created by Connor on 2/13/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "ConnectViewController.h"

#import "AppDelegate.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

@interface ConnectViewController ()
{
    AppDelegate *delegate;
}

@end

@implementation ConnectViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    delegate = [[UIApplication sharedApplication] delegate];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.section == 0)
    {
        [self.teamNumber becomeFirstResponder];
    } else if (indexPath.section == 1)
    {
        [self.teamNumber resignFirstResponder];
        
        delegate.teamNumber = [self.teamNumber.text intValue];
        
        NSString *ipAddress = [self getAddress];
        NSArray  *ip = [ipAddress componentsSeparatedByString:@"."];
        
        if ([[ip objectAtIndex:0] isEqualToString:@"10"] && [[ip objectAtIndex:1] isEqualToString:[NSString stringWithFormat:@"%i", (delegate.teamNumber / 100)]] && [[ip objectAtIndex:2] isEqualToString:[NSString stringWithFormat:@"%i", (delegate.teamNumber % 100)]])
        {
            NSLog(@"Good ip");
        } else
        {
            NSLog(@"Bad ip");
        }
        
        [self performSegueWithIdentifier:@"Main" sender:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(NSString*)getAddress
{
	NSString *ip = @"Check Wifi";
    
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
    
	int success = 0;
    
	success = getifaddrs(&interfaces);
    
	if(success == 0)
	{
		temp_addr = interfaces;
        
		while(temp_addr != NULL)
		{
			if(temp_addr->ifa_addr->sa_family == AF_INET)
			{
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					ip = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
					break;
				}
			}
            
			temp_addr = temp_addr->ifa_next;
		}
	}
    
	freeifaddrs(interfaces);
    
	return ip;
}

@end
