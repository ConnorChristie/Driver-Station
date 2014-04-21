//
//  UdpApi.h
//  Driver Station
//
//  Created by Connor on 2/13/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>
#include <ifaddrs.h>

#import "ConnectViewController.h"

#import "PacketDef.h"
#import "Utilities.h"

@interface UdpApi : NSObject

//- (BOOL)setupClient;

@end
